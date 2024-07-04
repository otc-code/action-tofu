#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2086

function fmt() {
	# Available TF_PARAMETER: check,recursive
	echo -e "$TFE fmt${NC}"
	if [[ $TF_ACTION == "fmt" ]]; then
		echo -e "## fmt\nParameter: $TF_PARAMETER" >>$STEP_SUM_MD
	fi
	echo -e "  $TF_ACTION: ${INF}$TF_PARAMETER${NC}"
	IFS=',' read -r -a ARRAY <<<"$TF_PARAMETER"
	for parameter in "${ARRAY[@]}"; do
		case ${parameter%%=*} in
		check)
			echo -e "$TFE fmt check with $REVIEWDOG_REPORTER\n" >>$STEP_SUM_MD
			echo -e "  $TFE fmt${NC} - Check $REVIEWDOG_REPORTER"
			if ! $TFE -chdir=$TF_ROOT_DIR fmt -recursive 1>>$STEP_SUM_MD 2>>$ERRLOG; then
				echo -e "${ERR}$TFE fmt${NC} - Check failed!"
				gh_annotation "warning" "$TFE $TF_ACTION ($(basename $TF_ROOT_DIR))" "Code not properly formatted!"
				echo -e "✗ Code not properly formatted!" >>$STEP_SUM_MD
			else
				echo -e "${OK}$TFE fmt${NC}"
				echo "✓ Code is properly formatted!" >>$STEP_SUM_MD
			fi
			TMPFILE=$(mktemp)
			git diff >$TMPFILE || true
			#git diff
			git stash -u || true &>/dev/null
			git stash drop || true &>/dev/null
			if [[ $GITHUB_EVENT_NAME == "pull_request" ]]; then
				echo $REVIEWDOG_REPORTER
				reviewdog -f=diff -f.diff.strip=1 -reporter=github-pr-review -filter-mode=nofilter -name="TF fmt" -level=warning <$TMPFILE #1>>$STDLOG 2>>$ERRLOG
			else
				echo -e "${INF}$TFE fmt${NC} - reviewdog code suggestions only supported on PR!"
				gh_annotation "warning" "$TFE $TF_ACTION ($(basename $TF_ROOT_DIR))" "reviewdog code suggestions only supported on PR!"
			fi
			rm $TMPFILE
			;;
		recursive)
			local TF_CMD="-chdir=$TF_ROOT_DIR fmt -recursive"
			echo "✓ fmt(recursive)" >>$STEP_SUM_MD
			echo -e "${OK}$TFE fmt${NC}"
			$TFE $TF_CMD 1>>$STDLOG 2>>$ERRLOG
			PUSH="true"
			;;
		none)
			local TF_CMD="-chdir=$TF_ROOT_DIR fmt "
			echo "✓ fmt" >>$STEP_SUM_MD
			echo -e "${OK}$TFE fmt${NC}"
			$TFE $TF_CMD 1>>$STDLOG 2>>$ERRLOG
			PUSH="true"
			;;
		*)
			echo -e "${ERR}TERRAFORM_ACTION${NC}: Unknown Parameter, try help."
			if [ "$DRY_RUN" = "false" ]; then
				ERROR=true
				clean_exit
			fi
			;;
		esac
	done
}
