#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2046,SC2034
SCRIPT_DIRECTORY=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIRECTORY/backend_aws.sh"
source "$SCRIPT_DIRECTORY/backend_azr.sh"
# source "$SCRIPT_DIRECTORY/backend_gcp.sh"

function aws_backend_file() {
	if [[ -n "$REGION" ]]; then
		AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account')
		NAME=$(aws iam list-account-aliases | jq -r ".AccountAliases[]")
		ID=$(echo $AWS_ACCOUNT $REGION | sha1sum | cut -c 1-10)
		echo "  AWS Account: $AWS_ACCOUNT / $NAME"
		cat >$TMPDIR/auto.tfbackend <<EOT
region         = "$REGION"
bucket         = "tfe-tfstate-$REGION-$ID"
dynamodb_table = "tfe-tfstate-$REGION-$ID.locks"
key            = "$REPO/$(basename $TF_ROOT_DIR).tfstate"
encrypt        = true
EOT
	else
		echo -e "${ERR}AutoPilot${NC}: Missing region in TF_PARAMETER, cannot create remote backend file."
		ERROR=true
		clean_exit
	fi
}

function azr_backend_file() {
	if az account show 1>>$STDLOG 2>>$ERRLOG; then
		AZURE_SUBSCRIPTION_ID=$(az account show | jq -r '.id')
		AZURE_SUBSCRIPTION_NAME=$(az account show | jq -r '.name')
		echo "  Subscription: $AZURE_SUBSCRIPTION_ID / $AZURE_SUBSCRIPTION_NAME"
		ID=$(echo $AZURE_SUBSCRIPTION_ID $REGION | sha1sum | cut -c 1-10)
	else
		echo -e "${ERR}Azure CLI login not configured, cannot get Account details!"
		ERROR=true
		clean_exit
	fi
	cat >$TMPDIR/auto.tfbackend <<EOT
resource_group_name  = "tfe-tfstate-$REGION-$ID-rg"
storage_account_name = "tfestate$ID"
container_name       = "tfe-tfstate"
key                  = "$REPO/$(basename $TF_ROOT_DIR).tfstate"
EOT
		echo "✓ Created backend file:" >>$STEP_SUM_MD
		echo -e "\`\`\`\n$(cat $TMPDIR/auto.tfbackend)\n\`\`\`\n" >>$STEP_SUM_MD
}

function consul_backend_file() {
	cat >$TMPDIR/auto.tfbackend <<EOT
  key                  = "$REPO/$(basename $TF_ROOT_DIR).tfstate"
EOT
}

function rewrite_backend_config() {
	case $PROVIDER in
	aws) local provider_backend="backend \"s3\" {}" ;;
	azr) local provider_backend="backend \"azurerm\" {}" ;;
	consul) local provider_backend="backend \"consul\" {}" ;;
	*)
		echo -e "${ERR}Backend${NC}: Provider $PROVIDER not supported!"
		ERROR=true
		clean_exit
		;;
	esac
	if ! grep -n "$provider_backend" $TF_ROOT_DIR/*.tf &>/dev/null; then
		echo -e "  Backend: No ${INF}$provider_backend${NC} found in terraform files, try to rewrite local!"
		if grep -n 'backend "local" {}' $TF_ROOT_DIR/*.tf &>/dev/null; then
			echo -e "  Backend: ${INF}backend \"local\" {}${NC} found in terraform files, rewrite to $provider_backend!"
			grep -rl 'backend "local" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "local" {}/'"$provider_backend"'/g'
		else
			echo -e "${ERR}Backend${NC}: Cannot use/rewrite backend configuration: ${INF}$(grep -nH 'backend' $TF_ROOT_DIR/*.tf)${NC}!"
			ERROR=true
			clean_exit
		fi
	else
		echo -e "${OK}Backend${NC}: ${INF}$provider_backend${NC} found in terraform files"
	fi
}

function autocreate() {
	if [[ "$CREATE" == "backend_config_aws" ]] || [[ "$CREATE" == "backend_config_azr" ]]; then
		echo -e "  AutoCreate${NC}: Check & create ${INF}$BACKEND_FILE${NC} in $REGION."
		if [[ -z "$BACKEND_FILE" ]]; then
			echo -e "${ERR}AutoCreate${NC}: No terraform backend config file provided. Abort"
			exit_on_error
		fi
		eval $(sed -r '/[^=]+=[^=]+/!d;s/\s+=\s/=/g' "$BACKEND_FILE")
		$CREATE
	else
		echo -e "${ERR}AutoCreate${NC}: Provider $PROVIDER is not supported."
		ERROR=true
		clean_exit
	fi
}

function autopilot() {
  echo $CREATE
  case $CREATE in
  azr_backend_file) $CREATE;;
  aws_backend_file) $CREATE;;
  consul_backend_file) $CREATE ;;
*) echo -e "${ERR}AutoPilot${NC}: Provider $PROVIDER is not supported."
  		ERROR=true
  		clean_exit
esac

	if [[ "$DRY_RUN" == "false" ]]; then
		echo -e "  AutoPilot: Check and configure ${INF}$PROVIDER${NC} backend."
		BACKEND_FILE=$TMPDIR/auto.tfbackend
		CREATE=backend_config_$PROVIDER
		autocreate
	else
		echo -e "${INF}AutoPilot${NC}: Dry Run, will not check & configure $PROVIDER backend."
		gh_annotation "notice" "$TFE $TF_ACTION ($(basename $TF_ROOT_DIR))" "Dry run, will not check & configure $PROVIDER backend!"
	fi
}
