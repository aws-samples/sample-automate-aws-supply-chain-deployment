# Automate the deployment of AWS Supply Chain data lake through GitHub Actions CI/CD, Artifactory and Terraform in a multi-repo setup

> **Not for production use without additional security testing.** This sample demonstrates a Terraform + GitHub Actions deployment pattern. Review [SECURITY.md](./SECURITY.md) for the accepted security debt and the production recommendations before deploying beyond a non-production account.

AWS Supply Chain, as stated by the [AWS documentation](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/what-is-service.html), is a cloud-based supply chain management application that works with your existing enterprise resource planning (ERP) and supply chain management systems. Using AWS Supply Chain, you can connect and extract your inventory, supply, and demand related data from existing ERP or supply chain systems into one unified AWS Supply Chain data model.

## Problem Statement

In a traditional data lake architecture, some of the problems faced in its deployment setup are -

1. Setting up the required Infrastructrue for the Data Lake
2. Knowledge of AWS Glue scripting to fetch the data from its source and feed it to the Data lake through Data pipelines.
3. Setting up the integration of the Data lake with tools used for analysis like Amazon QuickSight.
4. In a large Data lake like the one used for Supply Chain management, this process could be cumbersome.

## Benefits of this solution

Some of the benefits of using AWS Supply Chain Data lake are -

1. It provides a seamless way for organizations to store data in a Data lake without having to worry about managing its infrastructure.
2. Automatic update of the Databases used when new data is stored in its source (Amazon S3).
3. Knowledge of SQL transformation is sufficient to manage the data pipelines.
4. In-house [insights](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/insights.html) provided by AWS Supply Chain and its in-built [analytics](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/analytics.html) integration with Amazon QuickSight.

In this solution, we will be focussing on automating the creation of AWS Supply Chain Instance, AWS Supply Chain Datasets and AWS Supply Chain Integration flows.

Please follow the guidelines given below to deploy the solution and then proceed to the part of using AWS Supply Chain Analytics for analyzing the data, powered through Amazon QuickSight.

## Acronyms used in this solution

**ASC** - [AWS Supply Chain service](https://docs.aws.amazon.com/aws-supply-chain/latest/adminguide/getting-started.html)

## Solution Concepts

- **AWS Supply Chain Instance** - 

1. It is a managed application provided by the [AWS Supply Chain service](https://docs.aws.amazon.com/aws-supply-chain/latest/adminguide/getting-started.html) to get insights on organisations’ Supply Chain data.
2. It consists of various components like namespace, dataset, etc. which are used for analysis of the data.
3. It encompasses a private instance that can be connected from within the [Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) privately. 

- **AWS Supply Chain Namespace** - 

1. It is the AWS Supply Chain service’s database that can be used for grouping ASC Datasets.
2. Multiple custom namespaces can be created to store multiple ASC Datasets.
3. By default, the service provides an **asc** namespace, which is configured to provide insights on the ingested data, that is shown in this solution.

- **AWS Supply Chain Dataset** -

1. It represents the individual table of a namespace that gets data stored in it from the AWS Supply Chain Staging Amazon S3 Bucket.
2. The [AWS Supply Chain service](https://docs.aws.amazon.com/aws-supply-chain/latest/adminguide/getting-started.html) uses the datasets of the **asc** namespace to generate its pre-configured insights. 
3. For custom datasets, we can integration [Amazon QuickSight](https://aws.amazon.com/quicksight/) to get analysis done on their data.

## Pre-Requisites
Ensure the following are installed in your local machine 

- [Setup Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) v1.12 or higher
- [Setup Python](https://www.python.org/downloads/) v3.13
- [Setup AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Setup Git CLI](https://docs.github.com/en/get-started/git-basics/set-up-git)

Follow these steps to deploy this solution:

- Have an active AWS Account

- Create a VPC with 2 private subnets in your AWS Account in the region of your choice.

- Setting up the deployment role used for this solution -
    1. The deployment IAM role must have a **scoped** permission set — not "Full Access" on whole services. Grant only the actions below, restricted to this project's resource ARNs. Replace `<ACCOUNT_ID>`, `<REGION>`, and `<PROJECT_NAME>` (defaults to `asc-deployment`) with your own values. A ready-to-use example policy follows the table.

        | Service | Why it is needed | Scope |
        |---|---|---|
        | [AWS Supply Chain](https://docs.aws.amazon.com/aws-supply-chain/latest/adminguide/getting-started.html) | Create / manage the ASC instance, namespaces, datasets, and integration flows | `arn:aws:scn:<REGION>:<ACCOUNT_ID>:instance/*` |
        | [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) | Create and manage the two project KMS keys (artifacts bucket, ASC staging bucket) | `arn:aws:kms:<REGION>:<ACCOUNT_ID>:key/*` with condition `kms:ResourceAliases` matching `alias/<PROJECT_NAME>-kms-*` |
        | [Amazon S3](https://aws.amazon.com/s3/) | Create and manage the Artifacts, Server-Access-Logs, and ASC Staging buckets (and the Terraform state bucket for manual deployment) | `arn:aws:s3:::<PROJECT_NAME>-<ACCOUNT_ID>-<REGION>-*` and `arn:aws:s3:::aws-supply-chain-*` |
        | [AWS Lambda](https://aws.amazon.com/lambda/) | Create the deployer Lambda functions | `arn:aws:lambda:<REGION>:<ACCOUNT_ID>:function:<PROJECT_NAME>-*` |
        | [AWS IAM](https://aws.amazon.com/iam/) | Create the Lambda execution roles and their inline/managed policies | `arn:aws:iam::<ACCOUNT_ID>:role/<PROJECT_NAME>-*`, `arn:aws:iam::<ACCOUNT_ID>:policy/<PROJECT_NAME>-*` |
        | [Amazon EC2 / VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) | Manage security groups and VPC interface endpoints inside the pre-created VPC (the VPC itself is created by you — the role does **not** need `ec2:CreateVpc`) | Resource-level ARNs for `security-group/*` and `vpc-endpoint/*`; `ec2:Describe*` on `*` |
        | [Amazon CloudWatch Logs](https://aws.amazon.com/cloudwatch/) | Create and manage project log groups | `arn:aws:logs:<REGION>:<ACCOUNT_ID>:log-group:/aws/lambda/<PROJECT_NAME>-*:*` |

        <details>
        <summary>Example scoped deployment-role policy (click to expand)</summary>

        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "SupplyChain",
              "Effect": "Allow",
              "Action": [
                "scn:CreateInstance", "scn:DescribeInstance", "scn:GetInstance",
                "scn:ListInstances", "scn:UpdateInstance",
                "scn:CreateDataLakeDataset", "scn:GetDataLakeDataset",
                "scn:ListDataLakeDatasets", "scn:UpdateDataLakeDataset", "scn:DeleteDataLakeDataset",
                "scn:CreateDataLakeNamespace", "scn:GetDataLakeNamespace",
                "scn:ListDataLakeNamespaces", "scn:UpdateDataLakeNamespace", "scn:DeleteDataLakeNamespace",
                "scn:TagResource", "scn:UntagResource"
              ],
              "Resource": "arn:aws:scn:<REGION>:<ACCOUNT_ID>:instance/*"
            },
            {
              "Sid": "S3Project",
              "Effect": "Allow",
              "Action": [
                "s3:CreateBucket", "s3:DeleteBucket", "s3:ListBucket", "s3:GetBucket*",
                "s3:PutBucketPolicy", "s3:PutBucketVersioning", "s3:PutBucketTagging",
                "s3:PutBucketLogging", "s3:PutBucketNotification", "s3:PutBucketOwnershipControls",
                "s3:PutBucketPublicAccessBlock", "s3:PutBucketObjectLockConfiguration",
                "s3:PutLifecycleConfiguration", "s3:PutEncryptionConfiguration",
                "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListAllMyBuckets"
              ],
              "Resource": [
                "arn:aws:s3:::<PROJECT_NAME>-<ACCOUNT_ID>-<REGION>-*",
                "arn:aws:s3:::<PROJECT_NAME>-<ACCOUNT_ID>-<REGION>-*/*",
                "arn:aws:s3:::aws-supply-chain-*",
                "arn:aws:s3:::aws-supply-chain-*/*"
              ]
            },
            {
              "Sid": "KMSProject",
              "Effect": "Allow",
              "Action": [
                "kms:CreateKey", "kms:CreateAlias", "kms:DeleteAlias",
                "kms:DescribeKey", "kms:EnableKey", "kms:DisableKey",
                "kms:EnableKeyRotation", "kms:DisableKeyRotation",
                "kms:GetKeyPolicy", "kms:PutKeyPolicy", "kms:ListAliases",
                "kms:ListResourceTags", "kms:TagResource", "kms:UntagResource",
                "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
                "kms:Encrypt", "kms:Decrypt", "kms:ReEncryptFrom", "kms:ReEncryptTo",
                "kms:GenerateDataKey*", "kms:CreateGrant", "kms:RetireGrant", "kms:RevokeGrant"
              ],
              "Resource": "arn:aws:kms:<REGION>:<ACCOUNT_ID>:key/*",
              "Condition": {
                "ForAnyValue:StringLike": {
                  "kms:ResourceAliases": "alias/<PROJECT_NAME>-kms-*"
                }
              }
            },
            {
              "Sid": "Lambda",
              "Effect": "Allow",
              "Action": [
                "lambda:CreateFunction", "lambda:DeleteFunction", "lambda:GetFunction*",
                "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration",
                "lambda:ListFunctions", "lambda:TagResource", "lambda:UntagResource",
                "lambda:InvokeFunction", "lambda:PublishLayerVersion",
                "lambda:DeleteLayerVersion", "lambda:GetLayerVersion", "lambda:AddPermission",
                "lambda:RemovePermission"
              ],
              "Resource": [
                "arn:aws:lambda:<REGION>:<ACCOUNT_ID>:function:<PROJECT_NAME>-*",
                "arn:aws:lambda:<REGION>:<ACCOUNT_ID>:layer:<PROJECT_NAME>-*"
              ]
            },
            {
              "Sid": "IAMForLambda",
              "Effect": "Allow",
              "Action": [
                "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:ListRoles",
                "iam:PassRole", "iam:TagRole", "iam:UntagRole",
                "iam:AttachRolePolicy", "iam:DetachRolePolicy",
                "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
                "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
                "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy", "iam:ListPolicies",
                "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
                "iam:ListPolicyVersions", "iam:GetPolicyVersion"
              ],
              "Resource": [
                "arn:aws:iam::<ACCOUNT_ID>:role/<PROJECT_NAME>-*",
                "arn:aws:iam::<ACCOUNT_ID>:policy/<PROJECT_NAME>-*"
              ]
            },
            {
              "Sid": "VPCEndpointsAndSecurityGroups",
              "Effect": "Allow",
              "Action": [
                "ec2:CreateVpcEndpoint", "ec2:DeleteVpcEndpoints", "ec2:ModifyVpcEndpoint",
                "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateTags", "ec2:DeleteTags"
              ],
              "Resource": [
                "arn:aws:ec2:<REGION>:<ACCOUNT_ID>:security-group/*",
                "arn:aws:ec2:<REGION>:<ACCOUNT_ID>:vpc-endpoint/*"
              ]
            },
            {
              "Sid": "EC2Describe",
              "Effect": "Allow",
              "Action": [
                "ec2:Describe*"
              ],
              "Resource": "*"
            },
            {
              "Sid": "CloudWatchLogs",
              "Effect": "Allow",
              "Action": [
                "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy", "logs:AssociateKmsKey", "logs:DisassociateKmsKey",
                "logs:TagResource", "logs:UntagResource"
              ],
              "Resource": "arn:aws:logs:<REGION>:<ACCOUNT_ID>:log-group:/aws/lambda/<PROJECT_NAME>-*:*"
            }
          ]
        }
        ```

        </details>

    2. If you prefer to deploy through the GitHub workflows -
        - [Setup OIDC](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws#configuring-the-role-and-trust-policy) for the IAM role with the permissions mentioned above.
        - Ensure you create an IAM role with similar permissions to access the AWS Console as well. You can refer the below step for it.
    
    3. If you prefer to do manual deployment -
        - Create an IAM user to assume the IAM role with the permissions mentioned above with the help of [delegate permissions for an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html).
        - [Assume the role](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-role.html) in your local terminal. 

- Fill the VPC ID and Subnet ID values in the following files based on your deployment branch/environment -
    1. [Dev environment inputs for ASC Datasets repository](./ASC-Datasets/terraform-deployment/tfInputs/dev.tfvars)
    2. [Prod environment inputs for ASC Datasets repository](./ASC-Datasets/terraform-deployment/tfInputs/prod.tfvars)
    3. [Dev environment inputs for ASC integration flows repository](./ASC-Integration-Flows/terraform-deployment/tfInputs/dev.tfvars)
    4. [Prod environment inputs for ASC integration flows repository](./ASC-Integration-Flows/terraform-deployment/tfInputs/prod.tfvars)

-  If you prefer the deployment to happen through GitHub Actions workflows, do the following -

    1. Setup [JFrog Artifactory account](https://jfrog.com/artifactory/) to get the host name, login username and login access token.

    2. Setup [JFrog Project key and repository](https://jfrog.com/help/r/jfrog-platform-administration-documentation/step-1-set-up-a-new-project) for storing Artifacts.
    
    3. [Setup secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets#creating-secrets-for-an-organization) in your GitHub organization. This will be stored securely in GitHub

    | **Secret**                                | **Value / Description**                                                                                |
    |-------------------------------------------|--------------------------------------------------------------------------------------------------------|
    | **ACCOUNT_ID_DEV**                        | AWS Deployment Account ID for Dev environment                                                          |
    | **ACCOUNT_ID_PROD**                       | AWS Deployment Account ID for Prod environment                                                         |
    | **AWS_ROLE_DEV**                          | Deployment role ARN for Dev environment                                                                |
    | **AWS_ROLE_PROD**                         | Deployment role ARN for Prod environment if you need Production pipeline                               |
    | **AWS_USER_ROLE_DEV**                     | User's AWS console role ARN for Dev environment (With similar permissions as the deployment role)      |
    | **AWS_USER_ROLE_PROD**                    | User's AWS console role ARN for Prod environment (With similar permissions as the deployment role)     |
    | **ARTIFACTORY_HOST**                      | JFrog Artifactory Domain name                                                                          | 
    | **ARTIFACTORY_USERNAME**                  | JFrog Artifactory Login Username                                                                       |
    | **ARTIFACTORY_ACCESS_TOKEN**              | JFrog Artifactory Login Access Token                                                                   |

## This repository contains two folders -

1. [ASC-Datasets](./ASC-Datasets/) - Infrastructure required for this solution

    - This is a standalone repository and its configurations should be deployed first.
    - Instructions to deploy this is given in its [README](./ASC-Datasets/README.md)

2. [ASC-Integration-Flows](./ASC-Integration-Flows/) - Infrastructure required to enable the Data pipelines for this solution

    - This is a standalone repository and should be deployed after Step 1.
    - Instructions to deploy this is given in its [README](./ASC-Integration-Flows/README.md)

3. Operational Flow for this solution begins from [Data ingestion](#upload-sample-data-for-the-datasets)

    - This shows how we can upload some sample CSV dataset files to test this solution.

## Architecture

### Automated deployment through GitHub Actions workflows 
![ASC Deployment Flow through GitHub workflows](./Images/Architecture%20Automated.png)

**Artifactory Management** - 
**JFrog Artifactory** for Artifacts management. It will be used for storing resource information and outputs to be used for in a multi-repo deployment.

#### Steps involved -
1. Deploy ASC Datasets infrastructure and the Databases, through the deployment steps mentioned in [README](./ASC-Datasets/README.md). Follow the automated deployment approach using GitHub workflows.
2. [AWS VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html), [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html), [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) keys, and [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) log groups are created.
3. The following AWS Supply Chain resources are created -
    - ASC Instance [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the ASC instance.
    - ASC Namespace [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the ASC namesapces.
    - ASC Dataset [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the ASC datasets.
    - AWS Supply Chain Staging [Amazon S3](https://aws.amazon.com/s3/) bucket is created.
4. Deploy ASC Integration Flows infrastructure and the data pipelines required for it, through the deployment steps mentioned in [README](./ASC-Integration-Flows/README.md). Follow the automated deployment approach using GitHub workflows.
    - ASC Integration Flows [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the integration flows.
5. Source data can now be ingested to the AWS Supply Chain Staging [Amazon S3](https://aws.amazon.com/s3/) bucket. Some of the [preferred methods](#secure-data-ingestion-from-source-systems-to-amazon-s3) and the [data ingestion for this solution](#upload-sample-data-for-the-datasets) is mentioned below.
6. Once any data lands on the AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket, the service automatically triggers the integration flow which was created in this solution, to the ASC Datasets.
7. The AWS Supply Chain service integrates with [Amazon QuickSight](https://aws.amazon.com/quicksight/) Analytics to produce dashboards based on the ingested data.

### Manual deployment through Terraform
![ASC Deployment Flow through Terraform](./Images/Architecture%20Manual.png)

**Artifactory Management** - 
**Amazon S3** for Artifacts management. It will be used for storing resource information and outputs to be used for in a multi-repo deployment.

#### Steps involved -
1. Deploy ASC Datasets infrastructure and the Databases, through the deployment steps mentioned in [README](./ASC-Datasets/README.md). Follow the manual deployment approach from your local machine using Terraform.
2. [AWS VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html), [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html), [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) keys, and [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) log groups are created.
3. The following AWS Supply Chain resources are created -
    - ASC Instance [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the ASC instance.
    - ASC Namespace [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the ASC namesapces.
    - ASC Dataset [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the ASC datasets.
    - AWS Supply Chain Staging [Amazon S3](https://aws.amazon.com/s3/) bucket is created.
4. Deploy ASC Integration Flows infrastructure and the data pipelines required for it, through the deployment steps mentioned in [README](./ASC-Integration-Flows/README.md). Follow the manual deployment approach from your local machine using Terraform.
    - ASC Integration Flows [AWS Lambda](https://aws.amazon.com/lambda/) that creates/updates/deletes the integration flows.
5. Source data can now be ingested to the AWS Supply Chain Staging [Amazon S3](https://aws.amazon.com/s3/) bucket. Some of the [preferred methods](#secure-data-ingestion-from-source-systems-to-amazon-s3) and the [data ingestion for this solution](#upload-sample-data-for-the-datasets) is mentioned below.
6. Once any data lands on the AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket, the service automatically triggers the integration flow which was created in this solution, to the ASC Datasets.
7. The AWS Supply Chain service integrates with [Amazon QuickSight](https://aws.amazon.com/quicksight/) Analytics to produce dashboards based on the ingested data.

## Secure Data Ingestion from Source Systems to Amazon S3

Before data can be automatically ingested into AWS Supply Chain, source data needs to be sent to the AWS Supply Chain S3 staging bucket.
In this solution, we have demonstrated direct upload of sample datasets to the AWS Supply Chain Staging S3 Bucket. While, in a complete implementation, the following may be preferred.

1. Source system is in an AWS environment

- A dedicated AWS IAM role is used for providing access to the AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket and the [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) key used by it.
- The AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket policy should allow access for the source system's AWS IAM role.
- The [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) key used by the AWS Supply Chain service should allow access for the source system's IAM role in its key policy.
- The server that is writing to the AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket should be present inside an [Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html).
- The data transfer should go through AWS private network with the help of a [Amazon VPC Gateway Endpoint](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html) to [Amazon S3](https://aws.amazon.com/s3/).

2. Source system is outside the AWS environment

- A dedicated AWS IAM role is used for providing access to the AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket and the [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) key used by it.
- The AWS Supply Chain staging [Amazon S3](https://aws.amazon.com/s3/) bucket policy should allow access for the source system's AWS IAM role.
- The [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) key used by the AWS Supply Chain service should allow access for the source system's IAM role in its key policy.
- The data transfer goes through the public network to the [Amazon S3](https://aws.amazon.com/s3/) endpoint.

## Upload Sample data for the datasets

- Based on the datasets that we created, [Calendar](./ASC-Datasets/dataset-schemas/calendar.json) and [Outbound Order Line](./ASC-Datasets/dataset-schemas/outbound_order_line.json), create sample CSV files for them with varied data.
- Fetch the AWS Supply Chain Instance ID **asc_instance_id** from the [terraform outputs](./ASC-Datasets/terraform-deployment/output.tf) directory.
- Note down the S3 bucket name for AWS Supply Chain that got created through our deployment - **aws-supply-chain-data-<Instance_ID>**.

**Upload using AWS CLI:**
```bash
# Upload Calendar CSV file
aws s3 cp calendar_sample.csv s3://aws-supply-chain-data-<Instance_ID>/calendar-data/

# Upload Outbound Order Line CSV file  
aws s3 cp outbound_order_line_sample.csv s3://aws-supply-chain-data-<Instance_ID>/outbound-order-line-data/
```

- This should start the AWS Supply Chain Integration flows for both the datasets.

## Setting up AWS Supply Chain access

1. Search for the AWS Supply Chain service in the AWS Console.
2. Head over to the Instance that we created from the dashboard. 
    - This solution uses the name of **asc-deployment-dev-asc-instance**
3. We use AWS IAM Identity Center to manage user access to the AWS Supply Chain instance.
4. Login as the Admin of the application to ensure complete access in utilising this solution.

## Analyzing data with AWS Supply Chain Analytics

1. Setup AWS Supply Chain analytics with this [AWS guide](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/setting_analytics.html)

2. In this solution, we have demonstrated the creation of **Calendar** and **Outbound_Order_Line** datasets. We will create an Analysis that uses these datasets.

3. AWS Supply Chain provides a prebuilt dashboard for analysing the mentioned datasets. We will use the **Seasonality Analysis** Dashboard. Follow the steps mentioned in this [AWS guide](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/prebuilt_dashboards.html) to add the dashboard.

4. Click on the dashboard to see its analysis that would look like this (Based on sample CSV files for Calendar data and Outbound Order Line data) - 

![Year Over Demand History](./Images/Seasonality%20Dashboard%201.png)
![Seasonality Heatmap](./Images/Seasonality%20Dashboard%202.png)

- The Dashboard provides insights on Demand over the years based on the datasets and the ingested data over it.
- We can further specify the ProductID, CustomerID, years, etc. to view the analysis over those values.

## Using Amazon Q to ask questions related to your AWS Supply Chain Instance

- [Setup Amazon Q](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/enabling_QinASC.html) in AWS Supply Chain.

- The chat interface in the right side would answer queries like this, based on this solution.
<div align="center">
![Amazon Q in AWS Supply Chain](./Images/Amazon%20Q%20in%20AWS%20Supply%20Chain.png)
</div>

This solution can be replicated for more datasets as per the requirements and be queried for further analysis, through AWS Supply Chain provided prebuilt-dashboards or custom integration with Amazon QuickSight.

## Limitations of this Solution

- The [AWS Supply Chain Instance](https://docs.aws.amazon.com/aws-supply-chain/latest/adminguide/getting-started.html) doesn’t support complex data transformation techniques as of now.

- The service’s usage is most suited for Supply Chain domains as it provides in-built analytics and insights for it. For any other domain, it can still be used as a data store as part of the data lake architecture.

- [AWS Lambda](https://aws.amazon.com/lambda/) functions used in this solution may need to be enhanced to handle API retries and memory management in a production scale deployment.

## Security
See [SECURITY.md](./SECURITY.md) for the accepted security debt in this sample and the production recommendations that apply to each item. For responsible-disclosure of a vulnerability, see [CONTRIBUTING](./CONTRIBUTING.md).

## License
This library is licensed under the MIT-0 License. See the [LICENSE](./LICENSE) file.