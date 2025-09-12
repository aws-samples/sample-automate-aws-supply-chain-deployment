# Software (software, scripts or sample code) is licensed under the Apache License  Version 2.0.
# Author: AWS Professional Services

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

**ASC** - AWS Supply Chain Service

## Pre-Requisites

- Create a VPC with 2 private subnets in your AWS Account in the region of your choice.
- Setting up the deployment role used for this solution -
    1. Sufficient permissions are required for the IAM role to the following services -
        - AWS Supply Chain service   (Full Access preferred for deploying its components like Datasets and Integration Flows, along with accessing it from the AWS Console)
        - Amazon Chime               (For use by the AWS Supply Chain service)
        - Amazon EventBridge         (For use by the AWS Supply Chain service)
        - AWS KMS                    (For access to the AWS KMS keys used for the Amazon S3 Artifacts bucket and the Amazon S3 ASC Staging Bucket)
        - Amazon S3                  (For access to the Amazon S3 Artifacts bucket, Amazon S3 Server access logging bucket, and the Amazon S3 ASC Staging bucket. If you are using manual deployment, permissions for Amazon S3 Terraform Artifacts bucket is also required)
        - Amazon EC2                 (For Amazon EC2 Security groups and AWS VPC endpoints)
        - AWS Lambda                 (For creating the AWS Lambda functions that deploys the AWS Supply Chain components)
        - AWS IAM                    (For creating AWS Lambda service roles)
        - Amazon CloudWatch          (For creating and managing Amazon CloudWatch log groups)

    2. If you prefer to deploy through the GitHub workflows -
        - [Setup OIDC](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws#configuring-the-role-and-trust-policy) for the IAM role with the permissions mentioned above.
    
    3. If you prefer to do manual deployment -
        - Ensure AWS CLI is configured in your local machine.
        - Create an IAM user to assume the IAM role with the permissions mentioned above with the help of [delegate permissions for an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html).
        - [Assume the role](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-role.html) in your local terminal. 

- Fill the VPC ID and Subnet ID values in the following files based on your deployment branch/environment -
    1. [Dev environment inputs for ASC Datasets repository](./ASC-Datasets/terraform-deployment/tfInputs/dev.tfvars)
    2. [Prod environment inputs for ASC Datasets repository](./ASC-Datasets/terraform-deployment/tfInputs/prod.tfvars)
    3. [Dev environment inputs for ASC integration flows repository](./ASC-Integration-Flows/terraform-deployment/tfInputs/dev.tfvars)
    4. [Prod environment inputs for ASC integration flows repository](./ASC-Integration-Flows/terraform-deployment/tfInputs/prod.tfvars)

-  If you prefer the deployment to happen through GitHub Actions workflows, do the following -

    1. Setup [JFrog Artifactory account](https://jfrog.com/artifactory/?utm_source=google&utm_medium=cpc_search&utm_campaign=SearchDSKBrandAPACIN202506&utm_term=jfrog%20cloud&gads_network=g&utm_content=u-bin&gads_campaign_id=22674833884&gads_adgroup_id=184501797241&gads_extension_id=233003714635&gads_target_id=aud-312135645780:kwd-1598615735032&gads_matchtype=b&gad_source=1&gad_campaignid=22674833884&gbraid=0AAAAADqV85U5B37iapTR9IIFHBvydF5AQ&gclid=CjwKCAjwiY_GBhBEEiwAFaghvqdNV-odNLZXPHjT7NAwf8lA-QuMtg666hgvDW1oCJ4nn7wvf869_xoCW4IQAvD_BwE) to get the host name, login username and login access token.

    2. Setup [JFrog Project key and repository](https://jfrog.com/help/r/jfrog-platform-administration-documentation/step-1-set-up-a-new-project) for storing Artifacts.
    
    3. [Setup secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets#creating-secrets-for-an-organization) in your GitHub organization. This will be stored securely in GitHub

    | **Secret**                                | **Value / Description**                                                                    |
    |-------------------------------------------|--------------------------------------------------------------------------------------------|
    | **ACCOUNT_ID_DEV**                        | AWS Deployment Account ID for Dev environment                                              |
    | **ACCOUNT_ID_PROD**                       | AWS Deployment Account ID for Prod environment                                             |
    | **AWS_ROLE_DEV**                          | Deployment role ARN for Dev environment                                                    |
    | **AWS_ROLE_PROD**                         | Deployment role ARN for Prod environment if you need Production pipeline                   |
    | **AWS_USER_ROLE_DEV**                     | User's role ARN for Dev environment (With similar permissions as the deployment role)      |
    | **AWS_USER_ROLE_PROD**                    | User's role ARN for Prod environment (With similar permissions as the deployment role)     |
    | **ARTIFACTORY_HOST**                      | JFrog Artifactory Domain name                                                              | 
    | **ARTIFACTORY_USERNAME**                  | JFrog Artifactory Login Username                                                           |
    | **ARTIFACTORY_ACCESS_TOKEN**              | JFrog Artifactory Login Access Token                                                       |

## This repository contains two folders -

1. ### [ASC-Datasets](./ASC-Datasets/) - Infrastructure required for this solution

    - This is a standalone repository and its configurations should be deployed first.
    - Instructions to deploy this is given in its [README](./ASC-Datasets/README.md)

2. ### [ASC-Integration-Flows](./ASC-Integration-Flows/) - Infrastructure required to enable the Data pipelines for this solution

    - This is a standalone repository and should be deployed after Step 1.
    - Instructions to deploy this is given in its [README](./ASC-Integration-Flows/README.md)

3. ### Operational Flow for this solution begins from [Data ingestion](#upload-sample-data-for-the-datasets)

    - This shows how we can upload some sample CSV dataset files to test this solution.

## Architecture

### Automated deployment through GitHub Actions workflows 
![ASC Deployment Flow through GitHub workflows](./Images/Architecture%20Automated.png)

**Artifactory Management** - 
**JFrog Artifactory** for enterprise grade Artifacts management. It will be used for storing resource information and outputs to be used for in a multi-repo deployment.

#### Steps involved -
1. Deploy ASC Datasets infrastructure and the Databases, through the deployment steps mentioned in [README](./ASC-Datasets/README.md). Follow the automated deployment approach using GitHub workflows.
2. AWS VPC endpoints, AWS Security Groups, AWS KMS keys, and AWS CloudWatch log groups are created.
3. The following AWS Supply Chain resources are created -
    - ASC Instance AWS Lambda that creates the ASC instance.
    - ASC Namespace AWS Lambda that creates/updates/deletes the ASC namesapces.
    - ASC Dataset AWS Lambda that creates/updates/deletes the ASC datasets.
    - AWS Supply Chain Staging S3 bucket is created.
4. Deploy ASC Integration Flows infrastructure and the data pipelines required for it, through the deployment steps mentioned in [README](./ASC-Integration-Flows/README.md). Follow the automated deployment approach using GitHub workflows.
    - ASC Integration Flows AWS Lambda that creates/updates/deletes the integration flows.
5. Source data can now be ingested to the AWS Supply Chain Staging S3 bucket. Some of the [preferred methods](#secure-data-ingestion-from-source-systems-to-amazon-s3) and the [data ingestion for this solution](#upload-sample-data-for-the-datasets) is mentioned below.
6. Once any data lands on the AWS Supply Chain staging bucket, the service automatically triggers the integration flow which was created in this solution, to the ASC Datasets.
7. The AWS Supply Chain service integrates with Amazon QuickSight Analytics to produce dashboards based on the ingested data.

### Manual deployment through Terraform
![ASC Deployment Flow through Terraform](./Images/Architecture%20Manual.png)

**Artifactory Management** - 
**Amazon S3** for enterprise grade Artifacts management. It will be used for storing resource information and outputs to be used for in a multi-repo deployment.

#### Steps involved -
1. Deploy ASC Datasets infrastructure and the Databases, through the deployment steps mentioned in [README](./ASC-Datasets/README.md). Follow the manual deployment approach from your local machine using Terraform.
2. AWS VPC endpoints, AWS Security Groups, AWS KMS keys, and AWS CloudWatch log groups are created.
3. The following AWS Supply Chain resources are created -
    - ASC Instance AWS Lambda that creates the ASC instance.
    - ASC Namespace AWS Lambda that creates/updates/deletes the ASC namesapces.
    - ASC Dataset AWS Lambda that creates/updates/deletes the ASC datasets.
    - AWS Supply Chain Staging S3 bucket is created.
4. Deploy ASC Integration Flows infrastructure and the data pipelines required for it, through the deployment steps mentioned in [README](./ASC-Integration-Flows/README.md). Follow the manual deployment approach from your local machine using Terraform.
    - ASC Integration Flows AWS Lambda that creates/updates/deletes the integration flows.
5. Source data can now be ingested to the AWS Supply Chain Staging S3 bucket. Some of the [preferred methods](#secure-data-ingestion-from-source-systems-to-amazon-s3) and the [data ingestion for this solution](#upload-sample-data-for-the-datasets) is mentioned below.
6. Once any data lands on the AWS Supply Chain staging bucket, the service automatically triggers the integration flow which was created in this solution, to the ASC Datasets.
7. The AWS Supply Chain service integrates with Amazon QuickSight Analytics to produce dashboards based on the ingested data.

## Secure Data Ingestion from Source Systems to Amazon S3

Before data can be automatically ingested into AWS Supply Chain, source data needs to be sent to the AWS Supply Chain S3 staging bucket.
In this solution, we have demonstrated direct upload of sample datasets to the AWS Supply Chain Staging S3 Bucket. While, in a complete implementation, the following may be preferred.

### A popular and secure option is to use real-time Data Streaming with Amazon Kinesis Data Firehose

**Setup Process:**
1. Create a Amazon Kinesis Data Firehose delivery stream targeting the AWS Supply Chain S3 bucket.
2. Configure delivery stream with appropriate prefixes (calendar-data/, outbound-order-line-data/).
3. Set up AWS IAM roles with minimal permissions for Amazon Data Firehose to write to Amazon S3 ASC Staging Bucket, along with permissions for their AWS KMS keys.
4. Configure your organizations' source environment to send data records to the Amazon Firehose stream.

**Security Features:**
- **Encryption in Transit**: All data sent to Firehose is encrypted using HTTPS/TLS.
- **Encryption at Rest**: Configure AWS KMS encryption for Amazon S3 delivery using the AWS KMS ASC staging key that was created by this solution.
- **Access Control**: Use AWS IAM roles with least-privilege permissions for Firehose delivery.
- **Data Transformation**: Optional Lambda functions can validate and transform data before Amazon S3 delivery.
- **Monitoring**: Amazon CloudWatch metrics and logs for delivery success/failure tracking.

**Benefits:**
- Built-in data compression and format conversion.
- Handles high-volume streaming data with automatic scaling.
- No infrastructure management required.
- Fault tolerance with automatic retries.

## Upload Sample data for the datasets

- Based on the datasets that we created, [Calendar](./ASC-Datasets/dataset-schemas/calendar.json) and [Outbound Order Line](./ASC-Datasets/dataset-schemas/outbound_order_line.json), create sample CSV files for them with varied data.
- Fetch the AWS Supply Chain **Instance ID** from the terraform outputs of the [asc_instance_id](./ASC-Datasets/terraform-deployment/output.tf) directory.
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
    - This solution uses the name of **asc-deployment-poc-dev-asc-instance**
3. We use IAM Identity Center to manager user access to the AWS Supply Chain instance.
4. Login as the Admin of the application to ensure complete access in utilising this solution.

## Analyzing data with AWS Supply Chain Analytics

1. Setup AWS Supply Chain analytics with this [AWS guide](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/setting_analytics.html)

2. In this solution, we have demonstrated the creation of **Calendar** and **Outbound_Order_Line** datasets. We will create an Analysis that uses these datasets.

3. AWS Supply Chain provides a prebuilt dashboard for analying the mentioned datasets. We will use the **Seasonability Analysis** Dashboard. Follow the steps mentioned in this [AWS guide](https://docs.aws.amazon.com/aws-supply-chain/latest/userguide/prebuilt_dashboards.html) to add the dashboard.

4. Click on the dashboard to see its analysis that would look like this (Based on sample CSV files for Calendar data and Outbound Order Line data) - 

![Year Over Demand History](./Images/Seasonality%20Dashboard%201.png)
![Seasonality Heatmap](./Images/Seasonality%20Dashboard%202.png)

- The Dashboard provides insights on Demand over the years based on the datasets and the ingested data over it.
- We can further specify the ProductID, CustomerID, years, etc. to view the analysis over those values.

5. This solution can be replicated for more datasets as per the requirements and be queried for further analysis, through AWS Supply Chain provided prebuilt-dashboards or cutom integration with Amazon QuickSight.

## Security
See [CONTRIBUTING](./CONTRIBUTING.md) for more information.

## License
This library is licensed under the MIT-0 License. See the [LICENSE](./LICENSE) file.