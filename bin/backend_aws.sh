#!/bin/bash
#shellcheck disable=SC1091,SC2016,SC2086,SC2154,SC2034
SCRIPT_DIRECTORY=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

backend_destroy_aws() {
	local TF_ROOT_DIR=$SCRIPT_DIRECTORY/backend/aws
	echo -e "${OK}AWS${NC} Backend destroy - Region: ${INF}$region${NC}, Bucket: ${INF}$bucket${NC}, DynamoDB: ${INF}$dynamodb_table${NC}"
	if $TFE -chdir=$TF_ROOT_DIR init -migrate-state -force-copy -input=false 1>>$STDLOG 2>>$ERRLOG; then
		echo -e "${OK}Backend destroy${NC}: State migrated to local${NC}"
	else
		ERROR=true
		clean_exit
	fi
	if $TFE -chdir=$TF_ROOT_DIR destroy --auto-approve; then
		echo -e "${OK}Backend destroy${NC}: AWS backend destroyed."
		echo "✓ AWS Remote backend destroyed!" >>$STEP_SUM_MD
		rm $TF_ROOT_DIR/terraform.tfstate
		clean_exit
		exit 0
	else
		echo -e "${OK}Backend destroy${NC}: AWS backend destroyed."
		echo "✓ AWS Remote backend could not be destroyed!" >>$STEP_SUM_MD
		ERROR=true
		clean_exit
	fi
}

backend_config_aws() {
	local TF_ROOT_DIR=$SCRIPT_DIRECTORY/backend/aws
	local PLAN_FILE=$TF_ROOT_DIR/bootstrap.local
	export TF_VAR_cloud_region=$region
	export TF_VAR_s3_bucket_name=$bucket
	export TF_VAR_dynamodb_table_name=$dynamodb_table
	export TF_VAR_appd_id=$APPD_ID
	export TF_VAR_workflow=$WORKFLOW_URL
	echo -e "${OK}AWS${NC} - Region: ${INF}$region${NC}, Bucket: ${INF}$bucket${NC}, DynamoDB: ${INF}$dynamodb_table${NC}"
	grep -rl 'backend "local" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "local" {}/backend "s3" {}/g'
	if ! $TFE -chdir=$TF_ROOT_DIR init -reconfigure -input=false \
		-backend-config="region=$TF_VAR_cloud_region" \
		-backend-config="bucket=$TF_VAR_s3_bucket_name" \
		-backend-config="dynamodb_table=$TF_VAR_dynamodb_table_name" \
		-backend-config="key=bootstrap.aws" \
		-backend-config="encrypt=true" 1>>$STDLOG 2>>$ERRLOG; then
		echo -e "  ${INF}Backend${NC}: not configured or accessible, deploying AWS backend."
		echo "Creating backend: AWS-Region: $region, Bucket: $bucket, DynamoDB: $dynamodb_table" >>$STEP_SUM_MD
		grep -rl 'backend "s3" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "s3" {}/backend "local" {}/g'
		if $TFE -chdir=$TF_ROOT_DIR init -reconfigure 1>>$STDLOG 2>>$ERRLOG; then
			echo -e "  Backend: local backend reconfigured."
		else
			echo -e "${ERR}Backend${NC}: failed to reconfigure backend to local."
			ERROR=true
			clean_exit
		fi
		if $TFE -chdir=$TF_ROOT_DIR plan -out=$PLAN_FILE -input=false 1>>$STDLOG 2>>$ERRLOG; then
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
		grep -rl 'backend "local" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "local" {}/backend "s3" {}/g'
		if $TFE -chdir=$TF_ROOT_DIR init -migrate-state -force-copy \
			-backend-config="region=$region" \
			-backend-config="bucket=$bucket" \
			-backend-config="dynamodb_table=$dynamodb_table" \
			-backend-config="key=bootstrap.aws" \
			-backend-config="encrypt=$encrypt" 1>>$STDLOG 2>>$ERRLOG; then
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
		grep -rl 'backend "s3" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "s3" {}/backend "local" {}/g'
		echo -e "${OK}Backend${NC}: AWS Remote backend created & ready to use."
		echo "✓ AWS Remote backend created & ready to use." >>$STEP_SUM_MD
	else
		grep -rl 'backend "s3" {}' $TF_ROOT_DIR/*.tf | xargs sed -i 's/backend "s3" {}/backend "local" {}/g'
		echo -e "${OK}Backend${NC}: AWS Remote backend accessible & ready to use."
		echo "✓ AWS Remote backend accessible & ready to use." >>$STEP_SUM_MD
	fi
	if [[ $BACKEND_DESTROY == "true" ]]; then
		backend_destroy_aws
		exit 0
	fi
}
