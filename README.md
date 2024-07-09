# action-tofu (A Github composite action for running tofu in enterprise style)

[![LOGO](images/logo.png)](#)

<!-- BEGIN_TOC -->
## Table of Contents

- [action-tofu (A Github composite action for running tofu in enterprise style)](#action-tofu-a-github-composite-action-for-running-tofu-in-enterprise-style)
- [Overview](#overview)
- [Details](#details)
- [Files](#files)
  - [action.yml](#actionyml)
    - [Purpose](#purpose)
    - [Key Components](#key-components)
    - [Detailed Configuration](#detailed-configuration)
    - [Usage](#usage)
- [Automated docs](#automated-docs)
<!-- END_TOC -->

# Overview

 The repository 'action-tofu' is a GitHub composite action designed to run OpenTofu (a modern IaC tool) in an enterprise-style manner. It simplifies the execution of Terraform actions within CI/CD pipelines, making it easier for enterprises to manage infrastructure as code. Use cases include automating Terraform deployments, running tests against infrastructure changes, and ensuring compliance with policies through automated workflows.

# Details

 The "Composite Action for OpenTofu" is designed to facilitate the use of Infrastructure as Code (IaC) within GitHub Actions using OpenTofu. Key features include:

1.  **Inputs**:

    -   `TF_DIR`: Specifies the relative path to the Terraform root directory.
    -   `TF_ACTION`: Allows specifying which Terraform action to execute, with a default of an empty string.
    -   `TF_PARAMETER`: Parameters for the action to be executed, defaults to an empty string.
    -   `DEBUG`: Enables debug output, with a default value of 'false'.

2.  **Execution**:

    -   The action runs a Bash script located at `$GITHUB_ACTION_PATH/bin/tf.sh` to execute the specified Terraform actions based on the provided inputs.

3.  **Environment Variables**:
    -   `DEBUG`, `TF_DIR`, and `TF_ACTION` are set as environment variables within the action, allowing for dynamic execution of Terraform commands with debugging capabilities if enabled.

# Files

```console
/home/jkritzen/src/otc-code/action-tofu
├── bin
│   ├── backend
│   │   ├── aws
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── variables.tf
│   │   │   └── versions.tf
│   │   ├── azr
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfstate.backup
│   │   │   ├── variables.tf
│   │   │   └── versions.tf
│   │   ├── csl
│   │   │   └── placeholder.txt
│   │   ├── gcp
│   │   │   └── placeholder.txt
│   │   ├── http
│   │   │   └── placeholder.txt
│   │   └── k8s
│   │       └── placeholder.txt
│   ├── apply.sh
│   ├── backend_aws.sh
│   ├── backend_azr.sh
│   ├── backend.sh
│   ├── checkov.sh
│   ├── checkov.yml
│   ├── docs.sh
│   ├── fmt.sh
│   ├── functions.sh
│   ├── init.sh
│   ├── install.sh
│   ├── kics.sh
│   ├── lint.sh
│   ├── markdown-toc.sh
│   ├── plan.sh
│   ├── tflint.hcl
│   ├── tf.sh
│   └── validate.sh
├── iac-code
│   ├── aws
│   │   ├── main.tf
│   │   └── Test.md
│   └── plain
│       ├── main.tf
│       ├── outputs.tf
│       ├── README.md
│       ├── README.md.template
│       ├── Test.md
│       └── variables.tf
├── action.yml
├── LICENSE
└── TEMPLATE.md
```

## action.yml

 The file `action.yml` describes a composite GitHub Action designed to facilitate the use of Infrastructure as Code (IaC) using Terraform within GitHub Actions, with specific features tailored for enterprise environments. Here's an overview of its purpose and key components:

### Purpose

The primary purpose of this action is to provide a structured way to execute Terraform operations in a GitHub Actions workflow, offering flexibility and integration capabilities suitable for enterprise settings.

### Key Components

-   **Inputs**: The file defines several inputs that can be configured when the action is triggered. These include:
    -   `TF_DIR`: Specifies the relative path to the root directory of the Terraform code.
    -   `TF_ACTION`: Allows specifying which Terraform action (e.g., init, plan, apply) to execute.
    -   `TF_PARAMETER`: Parameters for the Terraform execution.
    -   `DEBUG`: Enables debug output.
    -   Various tokens and flags for authentication and interaction with GitHub and GitHub Enterprise, such as `GITHUB_TOKEN`, `GH_ENTERPRISE_TOKEN`, annotations, comments, etc.
-   **Runs**: The action specifies that it uses a composite runner (`using: "composite"`). It includes a single step where it runs a Bash script located at `${{ github.action_path }}/bin/tf.sh`.
-   **Environment Variables**: The environment variables are set based on the inputs, ensuring that each step in the workflow has access to necessary configurations and tokens for execution.

### Detailed Configuration

The action is configured to handle various aspects of a Terraform workflow, including:

-   **Debugging**: Enables or disables debug output as specified by the `DEBUG` input.
-   **Execution Context**: Specifies the directory (`TF_DIR`) where the Terraform code resides and the specific action (`TF_ACTION`) to perform.
-   **Token Management**: Utilizes GitHub tokens for authentication, ensuring that actions can interact with GitHub APIs securely.
-   **Annotations and Comments**: Supports annotations and comments via `GH_ANNOTATIONS`, `GH_STEP_SUMMARY`, and `GH_PR_COMMENTS` inputs, which are enabled by default but configurable based on the workflow's needs.
-   **Enterprise Support**: Includes options for GitHub Enterprise, with a hostname (`GH_HOST`) and an enterprise token (`GH_ENTERPRISE_TOKEN`), allowing integration with private or internal GitHub instances.

### Usage

This action file is intended to be used in conjunction with other GitHub Actions workflows, where it provides a modular way to include Terraform execution as part of the CI/CD pipeline. It simplifies configuration and management of Terraform operations within enterprise environments by leveraging GitHub's ecosystem effectively.

# Automated docs

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->

<!-- BEGIN_CHECKOV -->

<!-- END_CHECKOV -->

<!-- BEGIN_PIKE_DOCS -->

<!-- END_PIKE_DOCS -->
