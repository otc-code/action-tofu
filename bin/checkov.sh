#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2129,SC2153,SC2034
checkov_scan() {
	if [[ $TF_ACTION == "checkov_scan" ]]; then
		echo -e "## Checkov scan ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
		echo -e "Parameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	fi
	if [[ $TF_PARAMETER == "plan" ]]; then
		if [[ -z "$TF_DIR" ]]; then
			echo -e "${INF}checkov_scan${NC}: No TF_DIR set, running checkov plan scan without plan enrichment."
			local INFO=",plan"
			echo -e "✓ checkov_scan: No TF_DIR set, running checkov plan scan without plan enrichment." >>$STEP_SUM_MD
			CHECKOV_CMD="--file=$TF_ROOT_DIR/plan.json "
			if [ ! -f $TF_ROOT_DIR/plan.json ]; then
				echo -e "${ERR}checkov_scan${NC}: checkov error, plan file not found, did you run plan before?"
				ERROR=true
				clean_exit
			fi
		else
			echo -e "${INF}checkov_scan${NC}: Running checkov plan scan with plan enrichment."
			local INFO=",plan enrichment"
			echo -e "✓ checkov_scan: TF_DIR set, running checkov plan scan with plan enrichment." >>$STEP_SUM_MD
			CHECKOV_CMD="--file=$TF_ROOT_DIR/plan.json --repo-root-for-plan-enrichment $TF_ROOT_DIR --deep-analysis "
			if [ ! -f $TF_ROOT_DIR/plan.json ]; then
				echo -e "${ERR}checkov_scan${NC}: checkov error, plan file not found,did you run plan before?"
				ERROR=true
				clean_exit
			fi
		fi
	else
		echo -e "${OK}TF_ACTION${NC}: Scan directory $TF_ROOT_DIR"
		echo -e "✓ checkov_scan: Scan directory $TF_ROOT_DIR" >>$STEP_SUM_MD
		CHECKOV_CMD="--directory=$TF_ROOT_DIR  " # --skip-download
	fi
	# Get Config File
	if [[ -f "$TF_ROOT_DIR/.checkov.yml" ]]; then
		CHECKOV_CMD="$CHECKOV_CMD --config-file $TF_ROOT_DIR/.checkov.yml "
		CONFIG_FILE=$TF_ROOT_DIR/.checkov.yml
		echo -e "${OK}checkov_scan${NC}: Found custom checkov config, using  ${INF}$TF_ROOT_DIR/.checkov.yml${NC} config."
		echo -e "✓ checkov_scan: Found custom checkov config, using $TF_ROOT_DIR/.checkov.yml config." >>$STEP_SUM_MD
	else
		if [[ -f "$GITHUB_WORKSPACE/.checkov.yml" ]]; then
			CHECKOV_CMD="$CHECKOV_CMD --config-file $GITHUB_WORKSPACE/.checkov.yml "
			CONFIG_FILE=$GITHUB_WORKSPACE/.checkov.yml
			echo -e "${OK}checkov_scan${NC}: Found checkov config in root, using  ${INF}$GITHUB_WORKSPACE/.checkov.yml${NC} config."
			echo -e "✓ checkov_scan: Found checkov config in root, using  $GITHUB_WORKSPACE/.checkov.yml config." >>$STEP_SUM_MD
		else
			CHECKOV_CMD="$CHECKOV_CMD --config-file $SCRIPT_DIRECTORY/checkov.yml "
			CONFIG_FILE=$SCRIPT_DIRECTORY/.checkov.yml
			echo -e "${OK}checkov_scan${NC}: No tflint config found, using  ${INF}$SCRIPT_DIRECTORY/checkov.yml${NC} config."
			echo -e "✓ checkov_scan: No checkov config found, using  $SCRIPT_DIRECTORY/checkov.yml config file." >>$STEP_SUM_MD
		fi
	fi

	echo -e "  checkov: running with ${INF}$CHECKOV_CMD${NC}."
	if checkov $CHECKOV_CMD -o github_failed_only -o sarif --output-file-path $TMPDIR; then
		echo -e "${OK}checkov_scan${NC}: checkov finished."
		cat $TMPDIR/results_github_failed_only.md | tail -n +2 >>$STEP_SUM_MD
		cat $TMPDIR/results_sarif.sarif | reviewdog -f=sarif -filter-mode nofilter -reporter $REVIEWDOG_REPORTER -name "Checkov ($(basename $TF_ROOT_DIR)$INFO)"
		echo -e "✓ checkov_scan: Reported via $REVIEWDOG_REPORTER." >>$STEP_SUM_MD
		checkov_docs
		echo -e "✓ checkov_scan:  checkov finished." >>$STEP_SUM_MD
	else
		echo -e "${ERR}checkov${NC}: checkov error, did you run init before or disabled soft fail?"
		echo -e "✗ checkov: checkov error, did you run init before or disabled soft fail?" >>$STEP_SUM_MD
		ERROR=true
		clean_exit
	fi
}
