# Infrastructure deployment exercise

Using Terraform, automate the build of the following application in AWS. For the purposes of this challenge, use any Linux based AMI id for the two EC2 instances and simply show how they would be provisioned with the connection details for the RDS cluster.

![diagram](./images/diagram.png)

There are a lot of additional resources to create even in this simple setup, you can use the code we have made available that will create some structure and deploy the networking environment to make it possible to plan/apply the full deployment. Feel free to use and/or modify as much or as little of it as you like.

Document any assumptions or additions you make in the README for the code repository. You may also want to consider and make some notes on:

Q: How would a future application obtain the load balancer’s DNS name if it wanted to use this service?

A:
```
terraform output -raw load_balancer_dns_name
```

Q: What aspects need to be considered to make the code work in a CD pipeline (how does it successfully and safely get into production)?

A: an example of a pipeline is added in `.github/workflows/terraform.yml`.

## Route 53 and Application Load Balancer

The application is publicly exposed through a stable DNS name managed by Route 53 rather than exposing the AWS-generated Application Load Balancer DNS name directly.

Route 53 provides the public DNS name used to access the application. This decouples users and other services from the ALB's generated AWS DNS name. If the ALB is replaced, the Route 53 record can continue to provide the stable application endpoint. TLS is terminated at the ALB using an AWS Certificate Manager certificate.

## Database credentials

RDS is configured with manage_master_user_password = true, allowing AWS to generate and manage the master password using AWS Secrets Manager. The plaintext password must not be stored in Terraform configuration nor committed to the repository.

The EC2 instances receive the RDS endpoint, port, database name and Secrets Manager secret ARN through their bootstrap configuration. An IAM instance role grants the application permission to call secretsmanager:GetSecretValue against the specific RDS secret. The database password is not persisted to the EC2 filesystem.

This approach protects the database credentials and allows for them to be rotated without requiring the credentials to be embedded in the AMI, Terraform source code, or Git repository.

## Terraform and environments

The infrastructure is separated into independent environments to prevent changes in one environment from affecting another. The main environments are:

- Development (dev) — used for development and experimentation.
- Production (prod) — contains the live application infrastructure.

An S3 bucket `cint-code-test-terraform-state` in AWS region `us-east-1` will store the terraform state for each environment, the bucket should be generated before running the pipeline, it is [recommended to enable versioning for the bucket](https://developer.hashicorp.com/terraform/language/backend/s3).

Therefore Terraform should be initialized with the backend configuration for the environment being deployed:

```
terraform init \
  -backend-config=environments/prod/backend.hcl
```

## Required GitHub configuration

The workflow expects these GitHub Environment variables:

```
dev:
  AWS_TERRAFORM_ROLE_ARN

production:
  AWS_TERRAFORM_ROLE_ARN
```

The required configuration is AWS would be:

### 1. Create the GitHub OIDC provider

The provider URL is: `https://token.actions.githubusercontent.com`
The audience should be: `sts.amazonaws.com`

### 2. Create IAM roles

It is recommended to use separate IAM roles for development and production:

```text
AWS Account
│
├── github-actions-terraform-dev
│
└── github-actions-terraform-prod
```

The `dev` GitHub Environment will then contain the development role ARN:

```text
AWS_TERRAFORM_ROLE_ARN =
arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform-dev
```

The `production` GitHub Environment contains:

```text
AWS_TERRAFORM_ROLE_ARN =
arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform-prod
```

### 3. Restrict which GitHub workflows can assume the role

The IAM role and trust policy should restrict access to the specific repository and, preferably, the relevant branch/environment.

For example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPOSITORY:environment:dev"
        }
      }
    }
  ]
}
```

### 4. Permissions required by Terraform

The IAM role needs permissions to manage the AWS resources defined by the Terraform configuration.

For this project include resources such as:

```text
VPC
Subnets
Route tables
Internet Gateway
NAT Gateway
Elastic IP
Security Groups
Application Load Balancer
Target Groups
Auto Scaling Group
Launch Template
IAM roles / instance profiles
RDS
Route 53
ACM
Secrets Manager
S3 Terraform state
```

The exact policy should follow the principle of least privilege and be based on the resources Terraform actually needs to manage.

Avoid using:

```text
AdministratorAccess
```

for the production role unless there is a specific requirement to do so.

### 5. S3 state permissions

The Terraform roles also need access to the Terraform state bucket.

For example:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::cint-code-test-terraform-state/app/dev/terraform.tfstate",
    "arn:aws:s3:::cint-code-test-terraform-state/app/dev/terraform.tfstate.tflock"
  ]
}
```

The production role should instead have access to prod.

The roles should also have permission to inspect the bucket itself where required by the Terraform S3 backend, for example:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket"
  ],
  "Resource": "arn:aws:s3:::cint-code-test-terraform-state"
}
```

The S3 state bucket should have:

* Block Public Access enabled
* Versioning enabled
* Server-side encryption enabled
* Restricted IAM access
* Separate state paths for each environment

### 6. No AWS credentials in GitHub Secrets

GitHub obtains a short-lived OIDC token and AWS STS exchanges it for temporary credentials associated with the appropriate IAM role.
