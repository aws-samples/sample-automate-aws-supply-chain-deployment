# This directory can be used as a standalone repository that deploys AWS Supply Chain Instance and Datasets

We have shown its deployment using HashiCorp Terraform and Python.

## Contents

* [Automated Deployment](#automated-deployment)
  * [Pre-Requisites](#pre-requisites)
    * [Setup of the GitHub repository](#setup-of-the-github-repo)
    * [Setup GitHub environments](#setup-github-environments)
    * [Setup environment values in the workflow files](#setup-environment-values-in-the-workflow-files)
      * [ASC Datasets flows](#asc-datasetsyml)
      * [Destroy workflow](#destroy-workflowyml)
  * [Workflow Steps](#workflow-steps)
    * [Deployment Workflow](#deployment-workflow)
    * [Destroy Workflow](#destroy-workflow)
* [Manual Deployment](#manual-deployment)
  * [Deployment of the resources](#deployment-of-the-resources)
  * [Destroying the resources](#destroying-the-resources)

## Automated Deployment
  GitHub Actions workflow is used to deploy the solution in an automated fashion from [.github](.github).
  GitHub workflows connect securely to your AWS environment using OIDC, which you should have configured from [Pre-Requisistes](../README.md#pre-requisites)

  **NOTE**
  - For maintaining Artifacts, we have used **JFrog** as the solution for enterprise grade Artifacts management as part of the GitHub workflow deployment.
  - If you want to proceed without using **JFrog**, please follow the [Manual Deployment](#manual-deployment) instructions, where we have used **Amazon S3** for enterprise grade Artifacts management.

### Pre-Requisites

#### Setup of the GitHub repo

1. Clone this repository to your local machine.
```bash
git clone https://github.com/aws-samples/sample-automate-aws-supply-chain-deployment.git
cd ASC-Deployment
```

2. Copy [ASC-Datasets](../ASC-Datasets/) directory to a new location
```bash
cp -r ASC-Datasets ../ASC-Datasets-standalone
cd ../ASC-Datasets-standalone
```

3. Setup [ASC-Datasets](../ASC-Datasets/) as a standalone repository in your GitHub organization.
```bash
git init
git add .
git commit -m "Initial commit: ASC-Datasets standalone repository"
git remote add origin <INSERT_ASC_DATASETS_GITHUB_URL>
git branch -M dev
```

4. Configure the branch to be used for deployment in the [Deployment Workflow File](.github/workflows/asc-datasets.yml). This should be reflected in the [Setup GitHub environments](#setup-github-environments) section as well.
    ```yaml
    on:
      workflow_dispatch:
      push:
        branches:
          - dev     #Change to any other branch preferred for deployment
    ```

#### Setup GitHub environments

This is used for isolating the deployments to the specific environments with specific branches.
1. For each branch used for deployment, create an [environment](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) with its name. Eg: dev branch would have dev environment
2. For each branch used for deployment, create an [approval environment](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) with its name and add the required approvers. Eg: dev branch would have dev-approval environment

#### Setup environment values in the workflow files
##### [asc-datasets.yml](.github/workflows/asc-datasets.yml)

-   The following environment values are configured in the workflow file:

    | **Parameter**                             | **Value / Description**                                                            |
    |-------------------------------------------|------------------------------------------------------------------------------------|
    | **PROJECT_NAME**                          | `asc-deployment-poc`                                                               |
    | **REGION**                                | AWS Deployment Region                                                              |
    | **ACCOUNT_ID**                            | AWS Deployment Account ID                                                          |
    | **REPO_NAME**                             | Repository Name for ASC Datasets                                                   |
    | **JFROG_PROJECT_KEY**                     | JFrog Project Key created from [Pre-Requisites](../README.md#pre-requisites)       |
    | **JFROG_ARTIFACTS_REPO**                  | JFrog Repository Name created from [Pre-Requisites](../README.md#pre-requisites)   | 
    | **ENVIRONMENT**                           | `dev`, or `prod` (based on the branch)                                             |
    | **LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM**    | `lambdaOutput` (used during Terraform deployment)                                  |
    | **LAMBDA_LAYER_TEMP_DIR_TERRAFORM**       | `layerOutput` (used during Terraform deployment)                                   |
    | **AWS_ROLE**                              | The deployment role ARN used by the workflow                                       |
    | **AWS_USER_ROLE**                         | The user's role ARN to access the AWS Console                                      |

##### [destroy-workflow.yml](.github/workflows/destroy-workflow.yml)

-   The following environment values are configured in the workflow file:

    | **Parameter**                             | **Value / Description**                                                            |
    |-------------------------------------------|------------------------------------------------------------------------------------|
    | **PROJECT_NAME**                          | `asc-deployment-poc`                                                               |
    | **REGION**                                | AWS Deployment Region                                                              |
    | **ACCOUNT_ID**                            | AWS Deployment Account ID                                                          |
    | **REPO_NAME**                             | Repository Name for ASC Datasets                                                   |
    | **JFROG_PROJECT_KEY**                     | JFrog Project Key created from [Pre-Requisites](../README.md#pre-requisites)       |
    | **JFROG_ARTIFACTS_REPO**                  | JFrog Repository Name created from [Pre-Requisites](../README.md#pre-requisites)   | 
    | **ENVIRONMENT**                           | `dev`, or `prod` (based on the branch)                                             |
    | **LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM**    | `lambdaOutput` (used during Terraform deployment)                                  |
    | **LAMBDA_LAYER_TEMP_DIR_TERRAFORM**       | `layerOutput` (used during Terraform deployment)                                   |
    | **AWS_ROLE**                              | The deployment role ARN used by the workflow                                       |
    | **AWS_USER_ROLE**                         | The user's role ARN to access the AWS Console                                      |
  
- Push your changes to the repository that you created for ASC-Datasets, to the same branch that you had configured for deployment.
```bash
git push -u origin dev
```

- The workflow should begin from the respective branch.
 
### Workflow Steps
#### [Deployment Workflow](.github/workflows/asc-datasets.yml)
- This is used to deploy the resources needed for this solution

- The workflow performs the following steps in an overview - 
  - Assumes AWS_ROLE for the given ACCOUNT_ID and REGION.
  - Sets up terraform's latest version.
  - Performs JFrog Login to store artifacts.
  - [Setup Terraform S3 bucket](./scripts/setup-terraform.sh) if it doesn't exist.
  - [Generates Terraform Configs](./scripts/generate-terraform-config.sh) to setup backend and providers.
  - Performs terraform init and validate.
  - Performs terraform plan.
  - Uploads artifacts to JFrog.
  - Waits for user's approval.
  - Sets up Python 3.13.
  - Login's to JFrog to download the artifacts.
  - Peforms terraform init and apply.
  - [Update ASC KMS Key Policy](./scripts/update-asc-kms-policy.sh) with the service's requirements.
  - [Update AWS KMS key policies](./scripts/update-kms-policy.sh) with the IAM roles created by this repository.
  - Upload outputs of this repository to JFrog.

#### [Destroy Workflow](.github/workflows/destroy-workflow.yml)
- This is used to destroy the deployed resources needed for this solution.
- This should be run manually from the GitHub actions workflows page **Destroy workflow** from the respective branch used for deployment.

- The workflow performs the following steps in an overview -
  - Validates the branch that triggered the flow to destroy resources (Only dev or main is allowed).
  - [Check terraform S3 backend bucket exists](./scripts/terraform-setup-status.sh) for destroying its resources.
  - Assumes AWS_ROLE for the given ACCOUNT_ID and REGION.
  - Sets up terraform's latest version.
  - Performs JFrog Login to store artifacts.
  - [Generates Terraform Configs](./scripts/generate-terraform-config.sh) to setup backend and providers.
  - Performs terraform init and validate.
  - Performs terraform plan destroy.
  - Uploads artifacts to JFrog.
  - Waits for user's approval.
  - Login's to JFrog to download the artifacts.
  - [Empty S3 buckets](./scripts/empty-s3-buckets.sh) excluding Server Access logging bucket.
  - Peforms terraform init and apply.
  - Deletes the output file from JFrog.


## Manual Deployment
### Deployment of the resources

```bash
#Clone this repository to your local machine.
git clone https://github.com/aws-samples/sample-automate-aws-supply-chain-deployment.git
```

``` bash
# Go to terraform's directory
cd ASC-Deployment/ASC-Datasets/terraform-deployment
```

```bash
# Assume the IAM role used for deployment
aws sts assume-role --role-arn <enter AWS user role ARN> --role-session-name <your-session-name>
```

```bash
# Export Environment variables
export REGION=<Enter deployment region>
export REPO_NAME=<Enter Current ASC Datasets dir name>
export PROJECT_NAME="asc-deployment-poc"
export ACCOUNT_ID=<Enter deployment Account ID>
export ENVIRONMENT="dev"
export LAMBDA_LAYER_TEMP_DIR_TERRAFORM="layerOutput"
export LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM="lambdaOutput"
export AWS_USER_ROLE=<Enter user role ARN for AWS Console access and deployment>
export S3_TERRAFORM_ARTIFACTS_BUCKET_NAME="$PROJECT_NAME-$ACCOUNT_ID-$REGION-terraform-artifacts-$ENVIRONMENT"
```

```bash
# Setup terraform bucket
chmod +x ../scripts/setup-terraform.sh
../scripts/setup-terraform.sh
```

```bash
# Setup terraform artifacts bucket
chmod +x ../scripts/setup-terraform-artifacts-bucket.sh
../scripts/setup-terraform-artifacts-bucket.sh
```

```bash
# Setup terraform backend and providers config if they don't exist
chmod +x ../scripts/generate-terraform-config.sh
../scripts/generate-terraform-config.sh
```

```bash
# Run terraform init and validate
terraform init
terraform validate
```

```bash
# Run terraform plan
terraform plan \
-var-file="tfInputs/$ENVIRONMENT.tfvars" \
-var="project_name=$PROJECT_NAME" \
-var="environment=$ENVIRONMENT" \
-var="user_role=$AWS_USER_ROLE" \
-var="lambda_temp_dir=$LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM" \
-var="layer_temp_dir=$LAMBDA_LAYER_TEMP_DIR_TERRAFORM" \
-parallelism=40 \
-out='tfplan.out'
```

```bash
# Run terraform apply
terraform apply tfplan.out
```

```bash
# Update AWS Supply Chain KMS Key policy with the service's requirements
chmod +x ../scripts/update-asc-kms-policy.sh
../scripts/update-asc-kms-policy.sh
```

```bash
# Update AWS KMS Keys' policy with IAM roles
chmod +x ../scripts/update-kms-policy.sh
../scripts/update-kms-policy.sh
```

```bash
# Create terraform outputs file to be used as input variables
terraform output -json > raw_output.json
jq -r 'to_entries | map(
  if .value.type == "string" then
      "\(.key) = \"\(.value.value)\""
  else
      "\(.key) = \(.value.value | tojson)"
  end
) | .[]' raw_output.json > $REPO_NAME-outputs.tfvars
```

```bash
# Upload reformed outputs file to Amazon S3 terraform artifacts bucket (For retrieval from other repositories)
aws s3 cp $REPO_NAME-outputs.tfvars s3://$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME/$REPO_NAME-outputs.tfvars
rm -f raw_output.json
rm -f $REPO_NAME-outputs.tfvars
```

### Destroying the resources

```bash
#Clone this repository to your local machine.
git clone https://github.com/aws-samples/sample-automate-aws-supply-chain-deployment.git
```

``` bash
# Go to terraform's directory
cd ASC-Deployment/ASC-Datasets/terraform-deployment
```

```bash
# Assume the IAM role used for deployment
aws sts assume-role --role-arn <enter AWS user role ARN> --role-session-name <your-session-name>
```

```bash
# Export Environment variables
export REGION=<Enter deployment region>
export REPO_NAME=<Enter Current ASC Datasets dir name>
export PROJECT_NAME="asc-deployment-poc"
export ACCOUNT_ID=<Enter deployment Account ID>
export ENVIRONMENT="dev"
export LAMBDA_LAYER_TEMP_DIR_TERRAFORM="layerOutput"
export LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM="lambdaOutput"
export AWS_USER_ROLE=<Enter user role ARN for AWS Console access and deployment>
export S3_TERRAFORM_ARTIFACTS_BUCKET_NAME="$PROJECT_NAME-$ACCOUNT_ID-$REGION-terraform-artifacts-$ENVIRONMENT"
```

```bash
# Setup terraform backend and providers config if they don't exist
chmod +x ../scripts/generate-terraform-config.sh
../scripts/generate-terraform-config.sh
```

```bash
# Run terraform init and validate
terraform init
terraform validate
```

```bash
# Run terraform plan for destroy
terraform plan -destroy\
-var-file="tfInputs/$ENVIRONMENT.tfvars" \
-var="project_name=$PROJECT_NAME" \
-var="environment=$ENVIRONMENT" \
-var="user_role=$AWS_USER_ROLE" \
-var="lambda_temp_dir=$LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM" \
-var="layer_temp_dir=$LAMBDA_LAYER_TEMP_DIR_TERRAFORM" \
-parallelism=40 \
-out='tfplan.out'
```

```bash
# Delete S3 buckets excluding server access logging bucket
chmod +x ../scripts/empty-s3-buckets.sh
../scripts/empty-s3-buckets.sh tfplan.out
```

```bash
# Run terraform apply
terraform apply tfplan.out
```

```bash
# Delete the outputs file
aws s3 rm s3://$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME/$REPO_NAME-outputs.tfvars
```