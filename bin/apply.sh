#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2129
apply() {
	# varfile=FILE, -refresh-only -target=resource -replace=resource -refresh=false -destroy
	echo -e "  $TF_ACTION - TF_PARAMETER: ${INF}$TF_PARAMETER${NC}"
	APPLY_CMD="-chdir=$TF_ROOT_DIR apply --auto-approve "

	IFS=',' read -r -a ARRAY <<<"$TF_PARAMETER"
	for parameter in "${ARRAY[@]}"; do

		case ${parameter%%=*} in
		help)
			echo -e "${OK}Help${NC} - ${INF}$TF_ACTION${NC}:"
			echo "  varfile: apply with -var-file="
			echo "  target: apply with -target="
			echo "  replace: apply with -replace="
			echo "  norefresh: appy with -refresh=false"
			echo "  apply_destroy: apply with -destroy"
			;;
		target) APPLY_CMD="$APPLY_CMD-target=${parameter##*=} " ;;
		replace) APPLY_CMD="$APPLY_CMD-replace=${parameter##*=} " ;;
		norefresh) APPLY_CMD="$APPLY_CMD-refresh=false " ;;
		apply_destroy)
			APPLY_CMD="$APPLY_CMD-destroy "
			TF_ACTION="destroy"
			;;
		varfile)
			if [[ -n "$GITHUB_WORKSPACE" ]]; then
				VAR_FILE="$GITHUB_WORKSPACE/${parameter##*=}"
			else
				VAR_FILE="${parameter##*=}"
			fi
			if [ ! -f $VAR_FILE ]; then
				echo -e "${ERR}$TF_ACTION${NC}: varfile ${INF}$VAR_FILE${NV} not found!"
				exit_on_error
			else
				APPLY_CMD="$APPLY_CMD-var-file=$VAR_FILE "
			fi
			;;
		ignore_plan)
			if [ -f $TF_ROOT_DIR/plan.out ]; then rm $TF_ROOT_DIR/plan.out; fi
			;;
		none) echo -e "  No TF_PARAMETER found." ;;
		*)
			echo -e "${ERR}TERRAFORM_ACTION${NC}: Unknown Parameter, try help."
			exit_on_error
			;;
		esac
	done
	if [ -f $TF_ROOT_DIR/plan.out ]; then
		echo -e "  $TF_ACTION: Plan file found, using ${INF}$TF_ROOT_DIR/plan.out${NC} for apply."
		APPLY_CMD="$APPLY_CMD $TF_ROOT_DIR/plan.out"
	fi
	if [[ $TF_ACTION == "apply" ]]; then
		echo -e "## appy\n" >>$STEP_SUM_MD
		echo -e "Parameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	fi
	echo -e "  $TF_ACTION: ${INF}$APPLY_CMD${NC}"
	if $TFE $APPLY_CMD; then
		echo -e "${OK}$TFE $TF_ACTION${NC}: apply successfull."
		echo -e "✓ $TF_ACTION successfull" >>$STEP_SUM_MD
		if [[ ! $TF_ACTION == "destroy" ]]; then
			echo -e "Parameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
			echo -e "\`\`\`\n$($TFE -chdir=$TF_ROOT_DIR output -no-color)\n\`\`\`\n" >>$STEP_SUM_MD
			gh_annotation "notice" "terraform apply ($(basename $TF_ROOT_DIR)), outputs:$(basename $TF_ROOT_DIR)" "$($TFE -chdir=$TF_ROOT_DIR output -no-color)"
		fi
		if [ -f $TF_ROOT_DIR/plan.out ]; then rm $TF_ROOT_DIR/plan.out; fi
	else
		echo -e "${ERR}$TFE $TF_ACTION${NC}: apply failed."
		echo -e "✗ $TFE apply: Terraform apply not successfull!" >>$STEP_SUM_MD

		exit_on_error
	fi
}
