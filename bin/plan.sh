#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2126,SC2034
plan() {
	# varfile=FILE, -refresh-only -target=resource -replace=resource -refresh=false -destroy
	if [[ $TF_ACTION == "plan" ]]; then
		echo -e "## plan ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
		echo -e "Parameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	fi
	echo -e "  $TF_ACTION - TF_PARAMETER: ${INF}$TF_PARAMETER${NC}"
	PLAN_CMD="-chdir=$TF_ROOT_DIR plan "
	IFS=',' read -r -a ARRAY <<<"$TF_PARAMETER"
	for parameter in "${ARRAY[@]}"; do

		case ${parameter%%=*} in
		help)
			echo -e "${OK}Help${NC} - ${INF}$TF_ACTION${NC}:"
			echo "  varfile: plan with -var-file="
			echo "  target: plan with -target="
			echo "  replace: plan with -replace="
			echo "  norefresh: plan with -refresh=false"
			echo "  plan_destroy: plan with -destroy"
			;;
		target) PLAN_CMD="$PLAN_CMD-target=${parameter##*=} " ;;
		replace) PLAN_CMD="$PLAN_CMD-replace=${parameter##*=} " ;;
		norefresh) PLAN_CMD="$PLAN_CMD-refresh=false " ;;
		plan_destroy) PLAN_CMD="$PLAN_CMD-destroy " ;;
		varfile)
			if [[ -n "$GITHUB_WORKSPACE" ]]; then
				VAR_FILE="$GITHUB_WORKSPACE/${parameter##*=}"
			else
				VAR_FILE="${parameter##*=}"
			fi
			if [ ! -f $VAR_FILE ]; then
				echo -e "${ERR}$TF_ACTION${NC}: varfile ${INF}$VAR_FILE${NV} not found!"
				ERROR=true
				clean_exit
			else
				PLAN_CMD="$PLAN_CMD-var-file=$VAR_FILE "
			fi
			;;
		none) echo -e "  No TF_PARAMETER found." ;;
		*)
			echo -e "${ERR}TERRAFORM_ACTION${NC}: Unknown Parameter, try help."
			ERROR=true
			clean_exit
			;;
		esac
	done
	echo -e "  $TF_ACTION: ${INF}$PLAN_CMD${NC}"
	if $TFE $PLAN_CMD -out $TF_ROOT_DIR/plan.out 1>>$STDLOG 2>>$ERRLOG; then
		echo -e "${OK}$TFE plan${NC}: plan successfull."
		echo -e "✓ Plan successfull" >>$STEP_SUM_MD
		$TFE -chdir=$TF_ROOT_DIR show -json $TF_ROOT_DIR/plan.out >$TF_ROOT_DIR/plan.json
		cat $TF_ROOT_DIR/plan.json | tf-summarize
		echo -e "✓ Plan summary:\n" >>$STEP_SUM_MD
		cat $TF_ROOT_DIR/plan.json | tf-summarize -md >>$STEP_SUM_MD
		# We need to strip the single quotes that are wrapping it so we can parse it with JQ
		plan=$(cat $TF_ROOT_DIR/plan.json | sed "s/^'//g" | sed "s/'$//g")
		# Get the count of the number of resources being created
		create=$(echo "$plan" | jq -r ".resource_changes[].change.actions[]" | grep "create" | wc -l | sed 's/^[[:space:]]*//g')
		# Get the count of the number of resources being updated
		update=$(echo "$plan" | jq -r ".resource_changes[].change.actions[]" | grep "update" | wc -l | sed 's/^[[:space:]]*//g')
		# Get the count of the number of resources being deleted
		delete=$(echo "$plan" | jq -r ".resource_changes[].change.actions[]" | grep "delete" | wc -l | sed 's/^[[:space:]]*//g')
		echo -e "${OK}$TFE plan:${NC} ${OK}$create to add${NC}, ${INF}$update to change${NC} and ${ERR}$delete to delete${NC}!"
		if [ $delete -ne 0 ]; then
			gh_annotation "warning" "Deleted resources ($(basename $TF_ROOT_DIR))" "This plan will delete $delete resources!"
			echo -e "\n▲ This plan will delete $delete resources!" >>$STEP_SUM_MD
		fi
		gh_annotation "notice" "$TFE plan ($(basename $TF_ROOT_DIR))" "$TFE plan: $create to add, $update to change, $delete to destroy."
		echo -e "\n✓ $TFE plan: $create to add, $update to change, $delete to destroy." >>$STEP_SUM_MD
	else
		echo -e "${ERR}$TFE plan${NC}: plan failed."
		echo -e "✗ $TFE plan: Terraform plan not successfull!" >>$STEP_SUM_MD
		ERROR=true
		clean_exit
	fi
}
