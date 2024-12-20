# Test Example

<!-- BEGIN_TOC -->
## Table of Contents

- [Test Example](#test-example)
- [Usage](#usage)
  - [Overview](#overview)
  - [Examples](#examples)
- [Automated documentation](#automated-documentation)
  - [terraform-docs](#terraform-docs)
    - [Requirements](#requirements)
    - [Providers](#providers)
    - [Modules](#modules)
    - [Resources](#resources)
    - [Inputs](#inputs)
    - [Outputs](#outputs)
  - [Checkov findings (none)](#checkov-findings-none)
  - [Permissions (Pike)](#permissions-pike)
<!-- END_TOC -->


# Usage

## Overview
This is only an Example

## Examples
Her should the example go!

# Automated documentation

<!-- BEGIN_TF_DOCS -->
## terraform-docs
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.1 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_common"></a> [common](#module\_common) | git::ssh://git@github.com/otc-code/res-common.git | main |

### Resources

| Name | Type |
|------|------|
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/3.6.1/docs/resources/string) | resource |

### Inputs

No inputs.

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_Name_Prefix"></a> [Name\_Prefix](#output\_Name\_Prefix) | The prefix for the name of the resources |
| <a name="output_password"></a> [password](#output\_password) | Random Password |
| <a name="output_text"></a> [text](#output\_text) | Hello, World! |
<!-- END_TF_DOCS -->

<!-- BEGIN_CHECKOV -->
## Checkov findings (none)
> 🎉 CONGRATS! No findings found in Code.

**Skipped checks**:
  - CKV_TF_1 # OTC-Code Modules are versioned from a trusted source

<!-- END_CHECKOV -->

 <!-- BEGIN_KICS -->
 <!-- END_KICS -->

<!-- BEGIN_PIKE_DOCS -->
## Permissions (Pike)
```hcl
resource "aws_iam_policy" "terraform_pike" {
  name_prefix = "terraform_pike"
  path        = "/"
  description = "Pike Autogenerated policy from IAC"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:PutItem"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
})
}

```
<!-- END_PIKE_DOCS -->
