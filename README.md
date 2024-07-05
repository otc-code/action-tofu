# action-tofu

[![Action OpenTofu Tests](https://github.com/otc-code/action-tofu/actions/workflows/tests.yml/badge.svg)](https://github.com/otc-code/action-tofu/actions/workflows/tests.yml)

The `action-tofu` repository is a GitHub composite action designed to execute Terraform IaC operations in an enterprise-style environment. It provides various scripts and tools to manage infrastructure deployments, including backend configurations for AWS and Azure, static analysis with Checkov, documentation generation, and code formatting. This action can be used in GitHub Actions workflows to automate Terraform deployments, validate configurations, and generate reports, making it a valuable tool for DevOps teams and enterprise environments.

<!-- BEGIN_TOC -->
## Table of Contents

- [action-tofu](#action-tofu)
- [Overview](#overview)
  - [Files](#files)
  - [action.yml](#actionyml)
<!-- END_TOC -->

# Overview

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

## action.yml

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
