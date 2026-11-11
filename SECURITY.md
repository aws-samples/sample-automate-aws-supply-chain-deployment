# Security

> **This sample is not intended for production use without additional security testing.** It demonstrates how to deploy AWS Supply Chain components through a Terraform + GitHub Actions pipeline. It accepts specific security debt for brevity and readability. Before using any part of it in a production environment, review the items below, apply the production recommendations, and run your own security review.

## Reporting a vulnerability

If you believe you have found a security issue in this sample, please follow the process in [CONTRIBUTING.md](./CONTRIBUTING.md#security-issue-notifications). Do not open a public GitHub issue for security reports.

## Accepted security debt in this sample

The items below are intentionally accepted in the published sample because they are reasonable for a non-production reference and simplify the walk-through. Each one is listed with the risk it carries and the change required to make it production-ready.

### 1. Broad KMS key policy for root, user, and GitHub roles

The KMS key policy enumerates every KMS action and grants it to the AWS account root principal, the user console role, and the GitHub Actions role. This mirrors AWS's default key-policy pattern — delegating authority to the account root so IAM policies can grant key use.

- **If reused for production data:** the CI role that deploys the stack can also decrypt all data under the key, and a compromised pipeline can schedule key deletion.
- **Production recommendation:** split a "KMS administrators" statement (no `Encrypt`, `Decrypt`, `GenerateDataKey*`) from a "KMS users" statement, and restrict `kms:ScheduleKeyDeletion` and `kms:PutKeyPolicy` to the deployment role only.

### 2. Deployment role has no IAM permissions boundary

Because the sample's deployment role creates its own IAM roles (for the Lambda functions), it needs `iam:CreateRole`, `iam:PutRolePolicy`, and `iam:AttachRolePolicy`. The example in the README scopes these to project-prefixed ARNs but does not require a permissions boundary.

- **If unaddressed:** whoever controls the deployment role can create a `<project>-x` role and attach `AdministratorAccess` — classic privilege escalation.
- **Production recommendation:** require `iam:PermissionsBoundary` on `CreateRole` / `PutRolePolicy` and restrict `iam:AttachRolePolicy` with `iam:PolicyARN`.

### 3. Lambda functions have no X-Ray tracing

Short-lived helpers invoked synchronously by Terraform.

- **If unaddressed:** harder to troubleshoot multi-step failures in a real environment.
- **Production recommendation:** add `tracing_config { mode = "Active" }` on each `aws_lambda_function`, and `xray:PutTraceSegments` / `xray:PutTelemetryRecords` on the role.

### 4. Lambda functions have no dead-letter queue

The functions are invoked synchronously by `aws_lambda_invocation`; a DLQ does not apply.

- **If unaddressed:** if an asynchronous trigger is added later (e.g. an EventBridge rule), failed events are lost silently.
- **Production recommendation:** add a KMS-encrypted SQS DLQ whenever an async trigger is wired in.

### 5. No AWS Lambda code signing

Would require an AWS Signer profile outside the scope of this sample.

- **If unaddressed:** anyone with write access to the artifacts bucket can replace the package and run code with the Lambda role.
- **Production recommendation:** add an `aws_lambda_code_signing_config` with `UntrustedArtifactOnDeployment = "Enforce"` and restrict `s3:PutObject` on the artifacts bucket to the deployment role.

### 6. Broad exception handling in Lambda code

Handlers catch broad `Exception`, do not validate the event schema, and return exception text in the response. Only Terraform invokes these handlers in the sample.

- **If unaddressed:** if a handler is later exposed through an API or event source, attackers can send malformed input and read internal error text.
- **Production recommendation:** catch specific `botocore.exceptions.ClientError` subclasses, return generic error messages, validate events with a schema (e.g. `pydantic`), and bound the polling loops.

### 7. Terraform plan integrity depends on JFrog Artifactory

The plan file is uploaded to JFrog by the plan job and downloaded by the apply job. Approval environment and repository access controls gate `apply`.

- **If unaddressed:** someone with write access to the JFrog repo could replace the plan between approval and apply.
- **Production recommendation:** record the plan's SHA-256 in the plan job, and verify it in the apply job before `terraform apply`.

## Additional non-blocking items

These are tracked for future improvement:

- **No cross-region replication on S3 buckets.** Resilience, not security; enable with a KMS-encrypted destination if production-bound.
- **Author emails in Git history.** Publish from a fresh or squashed history before the first public push.
- **`destroy-workflow` conditional uses an invalid context (`steps.<id>.exitCode`).** Use `steps.<id>.outcome == 'success'` and test in a dev account.
- **`local-exec` build steps use `timestamp()` triggers.** Replace with content-hash triggers and move the build into CI.
- **Dependency CVE coverage is limited** (no `pip-audit` run in the published scan). After pinning `boto3`, run `pip-audit -r requirements.txt` and attach the result.
