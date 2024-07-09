# action-tofu (A Github composite action for running tofu in enterprise style)

[![LOGO](images/logo.png)](#)

<!-- BEGIN_TOC -->
## Table of Contents

- [action-tofu (A Github composite action for running tofu in enterprise style)](#action-tofu-a-github-composite-action-for-running-tofu-in-enterprise-style)
- [Overview](#overview)
  - [Usage](#usage)
- [Details](#details)
- [Files](#files)
  - [action.yml](#actionyml)
    - [Purpose](#purpose)
    - [Key Components](#key-components)
    - [Detailed Configuration](#detailed-configuration)
    - [Usage](#usage)
  - [Other files](#other-files)
  - [Files](#files)
<!-- END_TOC -->

# Overview

 The repository 'action-tofu' is a GitHub composite action designed to run OpenTofu (a modern IaC tool) in an enterprise-style manner. It simplifies the execution of Terraform actions within CI/CD pipelines, making it easier for enterprises to manage infrastructure as code. Use cases include automating Terraform deployments, running tests against infrastructure changes, and ensuring compliance with policies through automated workflows.

## Usage

| Name                | Description                                                                                     | Required | Default                  |
| ------------------- | ----------------------------------------------------------------------------------------------- | -------- | ------------------------ |
| TF_DIR              | Relative path to IaC - terraform root dir                                                       | False    | `None`                   |
| TF_ACTION           | Terraform Action to execute                                                                     | False    | `''`                     |
| TF_PARAMETER        | Parameters for the action to be executed                                                        | False    | `''`                     |
| DEBUG               | Enable debug output                                                                             | False    | `false`                  |
| GITHUB_TOKEN        | The Github Workflow token, for annotations & content changes.                                   | False    | None                     |
| GITHUB_COM_TOKEN    | Token for accessing github.com to avoid rate limits / download from github private repositories | False    | None                     |
| GH_ANNOTATIONS      | Enable GH Annotations                                                                           | False    | `true`                   |
| GH_STEP_SUMMARY     | Enable GITHUB_STEP_SUMMARY                                                                      | False    | `true`                   |
| GH_PR_COMMENTS      | Enable GH_PR_COMMENTS for steps                                                                 | False    | `true`                   |
| GH_HOST             | GitHub Enterprise hostname when not running on github.com                                       | False    | `github.com`             |
| GITHUB_API          | The Github API URL for reviewdog                                                                | False    | `https://api.github.com` |
| GH_ENTERPRISE_TOKEN | Token for accessing github enterprise with gh cli & git                                         | False    | None                     |
| DRY_RUN             | Only dry run without real changes.                                                              | False    | `false`                  |

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

## Other files

## Files

| file                | description                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| action.yml          | The 'action.yml' file defines a composite GitHub Action designed to execute Terraform IaC operations, offering various inputs and configurations for customization within GitHub Actions workflows.                                                                                                                                                                                          |
| bin/apply.sh        | The script `bin/apply.sh` is designed to manage Terraform deployments by parsing specific parameters for applying or destroying infrastructure, handling variable files, and outputting results including success statuses and relevant outputs.                                                                                                                                             |
| bin/backend_aws.sh  | The script manages AWS backend configurations for Terraform, including initialization, migration, and destruction of remote state management using S3 and DynamoDB. It handles both setting up an AWS backend and tearing it down based on a flag.                                                                                                                                           |
| bin/backend_azr.sh  | The script manages an Azure remote backend for Terraform using Bash, handling both creation and destruction based on specified conditions. It configures backend settings, migrates state, and ensures proper logging and error handling throughout the process.                                                                                                                             |
| bin/backend.sh      | The script `bin/backend.sh` manages remote state configuration for AWS and Azure using Terraform by generating backend configuration files, rewriting local backend configurations in Terraform files, and handling errors gracefully with logging mechanisms.                                                                                                                               |
| bin/checkov.sh      | The script `bin/checkov.sh` is designed to perform static analysis on Terraform configurations using Checkov, with options for plan enrichment and custom configuration files. It supports scanning directories or utilizing existing plan JSON files, logging results via ReviewDog and generating documentation upon completion.                                                           |
| bin/docs.sh         | The script `bin/docs.sh` manages documentation updates for various tools like terraform-docs, Checkov, and Pike by checking for specific markers, replacing content, and updating table of contents (TOC). It supports actions such as generating TOC, updating Terraform docs, scanning with Checkov, and running Pike for permissions checks.                                              |
| bin/fmt.sh          | The script defines a function `fmt` that formats Terraform code according to specified parameters, using tools like TFE (Terraform CLI) and Reviewdog for checking and reporting code formatting issues, with support for GitHub PR annotations.                                                                                                                                             |
| bin/functions.sh    | The script `bin/functions.sh` appears to define various utility functions for use across different parts of a software project, including error handling, logging, and common operations like creating directories or checking file existence. These functions are designed to enhance code reusability and maintainability by encapsulating frequently used logic in reusable modules.      |
| bin/init.sh         | The script initializes Terraform with various parameters such as backend configuration files and remote backends, handling both automatic creation from specified provider details or autogeneration based on given providers and regions. It also supports dry runs for testing purposes without executing actual commands.                                                                 |
| bin/install.sh      | The `bin/install.sh` script automates the installation process for a software application by cloning a repository, setting up virtual environments, and installing necessary dependencies. It ensures a consistent setup across different systems.                                                                                                                                           |
| bin/kics.sh         | The script `bin/kics.sh` is designed to execute a KICS (Knowledge Is Code Security) scan using Docker, pulling the latest version from Docker Hub and scanning the specified directory for vulnerabilities. It then formats the results with ReviewDog before generating documentation and cleaning up temporary files.                                                                      |
| bin/lint.sh         | The script `bin/lint.sh` is designed to perform linting operations on Terraform configurations using tflint and reviewdog, handling various parameters such as var-files and custom configuration files. It dynamically sets up tflint with the appropriate configuration based on the environment and runs the linter against the specified directory, reporting results through ReviewDog. |
| bin/markdown-toc.sh | The script generates a table of contents for markdown files by parsing headings and creating links to them, ignoring code blocks as specified. It handles different levels of headers and formats links without special characters or spaces.                                                                                                                                                |
| bin/plan.sh         | The script `bin/plan.sh` is designed to execute Terraform plan operations with various parameters such as var-file, target, replace, refresh settings, and destroy option. It handles input parsing, command construction, execution, and outputs the results including resource changes summary for further processing or reporting.                                                        |
| bin/tf.sh           | The script is designed to manage Terraform IaC operations within GitHub Actions, supporting various actions like installation, initialization, validation, linting, and documentation generation. It ensures necessary tools are installed and runs static checks before executing Terraform commands such as apply or destroy.                                                              |
| bin/validate.sh     | The script `bin/validate.sh` is designed to validate Terraform configurations by checking for errors and warnings, then it reports these results using ReviewDog for further analysis and possibly integrates with GitHub annotations if needed.                                                                                                                                             |
