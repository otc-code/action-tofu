#!/bin/bash
#shellcheck disable=SC1091,SC2016,SC2086,SC2154,SC2034
SCRIPT_DIRECTORY=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

backend_destroy_azr() {
	local TF_ROOT_DIR=$SCRIPT_DIRECTORY/backend/azr
	echo -e "${OK}AZR${NC} Backend destroy - Region: ${INF}$REGION${NC}, Storage: ${INF}$storage_account_name${NC}, Container: ${INF}$container_name${NC}"
	if $TFE -chdir=$TF_ROOT_DIR init -migrate-state -force-copy -input=false 1>>$STDLOG 2>>$ERRLOG; then
		echo -e "${OK}Backend destroy${NC}: State migrated to local${NC}"
	else
		exit_on_error
	fi
	if $TFE -chdir=$TF_ROOT_DIR destroy --auto-approve; then
		echo -e "${OK}Backend destroy${NC}: AZR backend destroyed."
		echo "✓ AZR Remote backend destroyed!" >>$STEP_SUM_MD
		rm $TF_ROOT_DIR/terraform.tfstate
		clean_exit
		exit 0
	else
		echo -e "${OK}Backend destroy${NC}: AZR backend destroyed."
		echo "✓ AZR Remote backend could not be destroyed!" >>$STEP_SUM_MD
		ERROR=true
		clean_exit
	fi
}

backend_config_azr() {
	local TF_ROOT_DIR=$SCRIPT_DIRECTORY/backend/azr
	local PLAN_FILE=$TF_ROOT_DIR/bootstrap.local
	if [[ -z "$ALLOWED_IPS" ]]; then ALLOWED_IPS='["0.0.0.0/0"]'; fi
	export TF_VAR_cloud_region=$REGION
	export TF_VAR_resource_group_name=$resource_group_name
	export TF_VAR_storage_account_name=$storage_account_name
	export TF_VAR_container_name=$container_name
	export TF_VAR_workflow=$WORKFLOW_URL
	echo -e "${OK}AZR${NC} - RG: ${INF}$resource_group_name${NC}, Region: ${INF}$REGION${NC}, Storage: ${INF}$storage_account_name${NC}, Container: ${INF}$container_name${NC}"
	grep -rl 'backend "local" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "local" {}/backend "azurerm" {}/g'
	if ! $TFE -chdir=$TF_ROOT_DIR init -reconfigure -input=false \
		-backend-config="resource_group_name=$TF_VAR_resource_group_name" \
		-backend-config="storage_account_name=$TF_VAR_storage_account_name" \
		-backend-config="container_name=$TF_VAR_container_name" \
		-backend-config="key=bootstrap.azure" >>$STDLOG 2>>$ERRLOG; then
		echo -e "  ${INF}Backend${NC}: not configured or accessible, deploying AZR backend."
		echo "Creating backend: AZR-Region: $REGION, Storage: $storage_account_name, Container: $container_name" >>$STEP_SUM_MD
		grep -rl 'backend "azurerm" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "azurerm" {}/backend "local" {}/g'
		if $TFE -chdir=$TF_ROOT_DIR init -reconfigure 1>>$STDLOG 2>>$ERRLOG; then
			echo -e "  Backend: local backend reconfigured."
		else
			echo -e "${ERR}Backend${NC}: failed to reconfigure backend to local."
			ERROR=true
			clean_exit
		fi
		if $TFE -chdir=$TF_ROOT_DIR plan -out=$PLAN_FILE -input=false; then #  1>>$STDLOG 2>>$ERRLOG;
			echo -e "${OK}Backend${NC}: Plan successfull."
		else
			echo -e "${ERR}Backend${NC}: failed to plan backend."
			ERROR=true
			clean_exit
		fi
		echo -e "  Backend: ${INF}Apply Bootstrap Plan${NC}"
		if $TFE -chdir=$TF_ROOT_DIR apply $PLAN_FILE; then
			echo -e "${OK}Backend${NC}: apply successfull."
		else
			echo -e "${ERR}Backend${NC}: failed to apply backend."
			ERROR=true
			clean_exit
		fi
		echo -e "  Backend: ${INF}Migrating state to backend.${NC}"
		grep -rl 'backend "local" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "local" {}/backend "azurerm" {}/g'
		if $TFE -chdir=$TF_ROOT_DIR init -migrate-state -force-copy \
			-backend-config="resource_group_name=$TF_VAR_resource_group_name" \
			-backend-config="storage_account_name=$TF_VAR_storage_account_name" \
			-backend-config="container_name=$TF_VAR_container_name" \
			-backend-config="key=bootstrap.azure" 1>>$STDLOG 2>>$ERRLOG; then
			echo -e "${OK}Backend${NC}: state migration successfull."
		else
			echo -e "${ERR}Backend${NC}: failed to migrate backend."
			ERROR=true
			clean_exit
		fi
		echo -e "  Backend: ${INF}Refresh state${NC}"
		if $TFE -chdir=$TF_ROOT_DIR apply -refresh-only -input=false --auto-approve 1>>$STDLOG 2>>$ERRLOG; then
			echo -e "${OK}Backend${NC}: state refresh successfull."
		else
			echo -e "${ERR}Backend${NC}: failed to plan backend."
			ERROR=true
			clean_exit
		fi
		rm $TF_ROOT_DIR/terraform.tfstate $PLAN_FILE
		grep -rl 'backend "azurerm" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "azurerm" {}/backend "local" {}/g'
		echo -e "${OK}Backend${NC}: AZR Remote backend created & ready to use."
		echo "✓ AZR Remote backend created & ready to use." >>$STEP_SUM_MD
	else
		grep -rl 'backend "azurerm" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "azurerm" {}/backend "local" {}/g'
		echo -e "${OK}Backend${NC}: AZR Remote backend accessible & ready to use."
		echo "✓ AZR Remote backend accessible & ready to use." >>$STEP_SUM_MD
	fi
	if [[ $BACKEND_DESTROY == "true" ]]; then
		backend_destroy_azr
	fi
}
