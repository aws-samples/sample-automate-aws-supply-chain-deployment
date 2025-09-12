# Software (software, scripts or sample code) is licensed under the Apache License  Version 2.0.
# Author: AWS Professional Services

This folder is a standalone repository that deploys ASC integration flows. It uses Hashicorp Terraform and python for deployment.

## Contents

* [Automated Deployment](#automated-deployment)
  * [Pre-Requisites](#pre-requisites)
    * [Setup of the GitHub repository](#setup-of-the-github-repo)
    * [Setup GitHub environments](#setup-github-environments)
    * [Setup environment values in the workflow files](#setup-environment-values-in-the-workflow-files)
      * [ASC Integration flows](#asc-integration-flowsyml)
      * [Destroy workflow](#destroy-workflowyml)
  * [Workflow Steps](#workflow-steps)
    * [Deployment Workflow](#deployment-workflow)
    * [Destroy Workflow](#destroy-workflow)
* [Manual Deployment](#manual-deployment)
  * [Deployment of the resources](#deployment-of-the-resources)
  * [Destroying the resources](#destroying-the-resources)

## Automated Deployment
  GitHub Actions workflow is used to deploy the solution in an automated fashion from [.github](.github).
  GitHub workflows connect securely to your AWS environment using OIDC, which you should have configured from [here](../README.md#pre-requisites)

  **NOTE**
  - For maintaining Artifacts, we have used **JFrog** as the solution for enterprise grade Artifacts management as part of the GitHub workflow deployment.
  - If you want to proceed without using **JFrog**, please follow the [Manual Deployment](#manual-deployment) instructions, where we have used **Amazon S3** for enterprise grade Artifacts management.

### Pre-Requisites

#### Setup of the GitHub repo

1. Setup [ASC-Integration-Flows](../ASC-Integration-Flows/) as a standalone reposoitory in your GitHub organization

2. Configure the branch to be used for deployment in the [Deployment Workflow File](.github/workflows/asc-integration-flows.yml). This should be reflected in the [Setup GitHub environments](#setup-github-environments) section as well.
    ```yaml
    on:
      workflow_dispatch:
      push:
        branches:
          - dev     #Change to any other branch preferred for deployment
    ```

3. Setup values for the following in the [Deployment Workflow File](.github/workflows/asc-integration-flows.yml) and [Destroy Workflow File](.github/workflows/destroy-workflow.yml)- 
    ```yaml
    env:
      REPO_NAME: "<Current ASC Integration Flows repo name>"
      ASC_DATASET_VARS_REPO: "<ASC Datasets repo name>"
      JFROG_PROJECT_KEY: "<JFrog Project Key name>"
      JFROG_ARTIFACTS_REPO: "<JFrog Artifacts repo name>"
    ```

#### Setup GitHub environments

This is used for isolating the deployments to the specific environments with specific branches.
1. For each branch used for deployment, create an [environment](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) with its name. Eg: dev branch would have dev environment
2. For each branch used for deployment, create an [approval environment](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) with its name and add the required approvers. Eg: dev branch would have dev-approval environment

#### Setup environment values in the workflow files
##### [asc-integration-flows.yml](.github/workflows/asc-integration-flows.yml)

-   The following environment values are configured in the workflow file:

    | **Parameter**                             | **Value / Description**                                                            |
    |-------------------------------------------|------------------------------------------------------------------------------------|
    | **PROJECT_NAME**                          | `asc-deployment-poc`                                                               |
    | **REGION**                                | AWS Deployment Region                                                              |
    | **ACCOUNT_ID**                            | AWS Deployment Account ID                                                          |
    | **REPO_NAME**                             | Repository Name for ASC Integration Flows                                          |
    | **JFROG_PROJECT_KEY**                     | JFrog Project Key created from [Pre-Requisites](../README.md#pre-requisites)       |
    | **JFROG_ARTIFACTS_REPO**                  | JFrog Repository Name created from [Pre-Requisites](../README.md#pre-requisites)   |
    | **ENVIRONMENT**                           | `dev`, or `prod` (based on the branch)                                             |
    | **LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM**    | `lambdaOutput` (used during Terraform deployment)                                  |
    | **LAMBDA_LAYER_TEMP_DIR_TERRAFORM**       | `layerOutput` (used during Terraform deployment)                                   | 
    | **AWS_ROLE**                              | The deployment role used by the workflow                                           |
    | **ASC_DATASET_VARS_REPO**                 | The repository name of ASC Datasets                                                |

##### [destroy-workflow.yml](.github/workflows/destroy-workflow.yml)

-   The following environment values are configured in the workflow file:

    | **Parameter**                             | **Value / Description**                                       |
    |-------------------------------------------|---------------------------------------------------------------|
    | **PROJECT_NAME**                          | `asc-deployment-poc`                                          |
    | **REGION**                                | AWS Deployment Region                                         |
    | **ACCOUNT_ID**                            | AWS Deployment Account ID                                     |
    | **REPO_NAME**                             | Repository Name for ASC Integration Flows                     |
    | **JFROG_PROJECT_KEY**                     | JFrog Project Key                                             |
    | **JFROG_ARTIFACTS_REPO**                  | JFrog Repository Name                                         | 
    | **ENVIRONMENT**                           | `dev`, or `prod` (based on the branch)                        |
    | **LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM**    | `lambdaOutput` (used during Terraform deployment)             |
    | **LAMBDA_LAYER_TEMP_DIR_TERRAFORM**       | `layerOutput` (used during Terraform deployment)              |
    | **AWS_ROLE**                              | The deployment role used by the workflow                      |
    | **ASC_DATASET_VARS_REPO**                 | The repository name of ASC Datasets                           |
 
### Workflow Steps
#### [Deployment Workflow](.github/workflows/asc-integration-flows.yml)
- This is used to deploy the resources needed for this solution

- The workflow performs the following steps in an overview - 
  - Assumes AWS_ROLE for the given ACCOUNT_ID and REGION.
  - Sets up terraform's latest version.
  - Performs JFrog Login to store artifacts.
  - [Generates Terraform Configs](./scripts/generate-terraform-config.sh) to setup backend and providers.
  - Performs terraform init and validate.
  - [Downloads ASC Datasets Vars](./scripts/download-vars-through-jfrog.sh) to sync with the current repository.
  - Performs terraform plan.
  - Uploads artifacts to JFrog.
  - Waits for user's approval.
  - Sets up Python 3.13.
  - Login's to JFrog to download the artifacts.
  - Peforms terraform init and apply.
  - [Updates AWS KMS key policies](./scripts/update-kms-policy-through-jfrog.sh) with the IAM roles created by this repository.
  - Upload outputs of this repository to JFrog.

#### [Destroy Workflow](.github/workflows/destroy-workflow.yml)
- This is used to destroy the deployed resources needed for this solution

- The workflow performs the following steps in an overview -
  - Validates the branch that triggered the flow to destroy resources (Only dev or main is allowed).
  - [Check terraform S3 backend bucket exists](./scripts/terraform-setup-status.sh) for destroying its resources.
  - Assumes AWS_ROLE for the given ACCOUNT_ID and REGION.
  - Sets up terraform's latest version.
  - Performs JFrog Login to store artifacts.
  - [Generates Terraform Configs](./scripts/generate-terraform-config.sh) to setup backend and providers.
  - Performs terraform init and validate.
  - [Downloads ASC Datasets Vars](./scripts/download-vars-through-jfrog.sh) to sync with the current repository.
  - Performs terraform plan destroy.
  - Uploads artifacts to JFrog.
  - Waits for user's approval.
  - Login's to JFrog to download the artifacts.
  - Peforms terraform init and apply.
  - Deletes the output file from JFrog.


## Manual Deployment
### Deployment of the resources

We use S3 bucket for artifacts instead of JFrog for the purpose of this solution.

- Setup Terraform v1.12 or higher
- Setup Python 3.13

``` bash
# Go to terraform's directory
cd terraform-deployment
```

```bash
# Export Environment variables
export REGION=<Enter deployment region>
export REPO_NAME=<Enter Current ASC Integration Flows repo name or the directory name>
export ASC_DATASET_VARS_REPO=<Enter Current ASC Datasets repo name or the directory name>  #Must be the same repo/directory name used for ASC Datasets deployment
export PROJECT_NAME="asc-deployment-poc"
export ACCOUNT_ID=<Enter deployment Account ID>
export ENVIRONMENT="dev"
export LAMBDA_LAYER_TEMP_DIR_TERRAFORM="layerOutput"
export LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM="lambdaOutput"
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
# Download and merge ASC DATASET tfvars
chmod +x ../scripts/download-vars-through-s3.sh
../scripts/download-vars-through-s3.sh $ASC_DATASET_VARS_REPO
```

```bash
# Run terraform plan
terraform plan \
-var-file="tfInputs/$ENVIRONMENT.tfvars" \
-var="project_name=$PROJECT_NAME" \
-var="environment=$ENVIRONMENT" \
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
# Update AWS KMS Keys' policy with IAM roles
chmod +x ../scripts/update-kms-policy-through-s3.sh
../scripts/update-kms-policy-through-s3.sh $ASC_DATASET_VARS_REPO
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

We use S3 bucket for artifacts instead of JFrog for the purpose of this solution.

- Setup Terraform v1.12 or higher
- Setup Python 3.13

``` bash
# Go to terraform's directory
cd terraform-deployment
```

```bash
# Export Environment variables
export REGION=<Enter deployment region>
export REPO_NAME=<Enter Current ASC Integration Flows repo name>
export ASC_DATASET_VARS_REPO=<Enter Current ASC Datasets repo name>  #Must be the same repo name used for ASC Datasets deployment
export PROJECT_NAME="asc-deployment-poc"
export ACCOUNT_ID=<Enter deployment Account ID>
export ENVIRONMENT="dev"
export LAMBDA_LAYER_TEMP_DIR_TERRAFORM="layerOutput"
export LAMBDA_FUNCTION_TEMP_DIR_TERRAFORM="lambdaOutput"
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
# Download and merge ASC DATASET tfvars
chmod +x ../scripts/download-vars-through-s3.sh
../scripts/download-vars-through-s3.sh $ASC_DATASET_VARS_REPO
```

```bash
# Run terraform plan for destroy
terraform plan -destroy \
-var-file="tfInputs/$ENVIRONMENT.tfvars" \
-var="project_name=$PROJECT_NAME" \
-var="environment=$ENVIRONMENT" \
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
# Delete the outputs file
aws s3 rm s3://$S3_TERRAFORM_ARTIFACTS_BUCKET_NAME/$REPO_NAME-outputs.tfvars
```