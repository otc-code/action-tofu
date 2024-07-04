#!/bin/bash
#shellcheck disable=SC1091,SC2086
lint() {
	# init, varfile=FILE
	if [[ $TF_ACTION == "lint" ]]; then
		echo -e "## TF lint ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
		echo -e "Parameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	fi
	echo -e "  $TF_ACTION - TF_PARAMETER: ${INF}$TF_PARAMETER${NC}"
	LINT_CMD="--chdir=$TF_ROOT_DIR "
	IFS=',' read -r -a ARRAY <<<"$TF_PARAMETER"
	for parameter in "${ARRAY[@]}"; do

		case ${parameter%%=*} in
		help)
			echo -e "${OK}Help${NC} - ${INF}$TF_ACTION${NC}:"
			echo "  varfile: lint with --var-file"
			;;
		varfile)
			if [[ -n "$GITHUB_WORKSPACE" ]]; then
				LINT_CMD="$LINT_CMD--var-file=$GITHUB_WORKSPACE/${parameter##*=} "
			else
				LINT_CMD="$LINT_CMD--var-file=${parameter##*=} "
			fi
			;;
		none) echo -e "  No TF_PARAMETER found." ;;
		*)
			echo -e "${ERR}TERRAFORM_ACTION${NC}: Unknown Parameter, try help."
			exit_on_error
			;;
		esac
	done

	mkdir -p ~/.tflint.d
	mkdir -p ~/.tflint.d/plugins/
	if [[ -f "$TF_ROOT_DIR/.tflint.hcl" ]]; then
		TFLINT_CONFIG="$TF_ROOT_DIR/.tflint.hcl"
		echo -e "${OK}tflint${NC}: Found custom tflint config, using  ${INF}$TFLINT_CONFIG${NC} config."
		echo -e "✓ tflint: Found custom tflint config, using  $TFLINT_CONFIG config." >>$STEP_SUM_MD
	else
		if [[ -f "$GITHUB_WORKSPACE/.tflint.hcl" ]]; then
			TFLINT_CONFIG="$GITHUB_WORKSPACE/.tflint.hcl"
			echo -e "${OK}tflint${NC}: Found tflint config in root, using  ${INF}$TFLINT_CONFIG${NC} config."
			echo -e "✓ tflint: Found tflint config in root, using  $TFLINT_CONFIG config." >>$STEP_SUM_MD
		else
			TFLINT_CONFIG="$SCRIPT_DIRECTORY/tflint.hcl"
			echo -e "${OK}tflint${NC}: No tflint config found, using  ${INF}$TFLINT_CONFIG${NC} config."
			echo -e "✓ tflint: No tflint config, using  $TFLINT_CONFIG config file." >>$STEP_SUM_MD
		fi
	fi

	if GITHUB_TOKEN=$GITHUB_COM_TOKEN tflint --init -c $TFLINT_CONFIG; then
		echo -e "${OK}tflint${NC}: init successfull."
		echo -e "✓ tflint: init successfull." >>$STEP_SUM_MD
	else
		echo -e "${ERR}tflint${NC}: init error, github api limit, did you set GITHUB_COM_TOKEN?"
		echo -e "✗ tflint: init error, github api limit, did you set GITHUB_COM_TOKEN?" >>$STEP_SUM_MD
		exit_on_error
	fi

	ruleset=$(tflint -c $TFLINT_CONFIG --version | grep +)
	echo -e "  ${INF}tflint${NC} rulesets:"
	echo -e "$ruleset"
	echo -e "\ntflint rulesets:\n$ruleset\n" >>$STEP_SUM_MD
	echo -e "  tflint: running with ${INF}$LINT_CMD${NC}."
	if tflint $LINT_CMD --force -c $TFLINT_CONFIG --format=sarif | reviewdog -f=sarif -filter-mode nofilter -reporter $REVIEWDOG_REPORTER -name "TF lint ($(basename $TF_ROOT_DIR))" 2>$ERRLOG; then
		echo -e "${OK}tflint${NC}: tflint finished."
		echo -e "✓ tflint: Reported via $REVIEWDOG_REPORTER." >>$STEP_SUM_MD
	else
		echo -e "${ERR}tflint${NC}: tflint error, did you run init before?"
		echo -e "✗ tflint: tflint error, did you run init before?" >>$STEP_SUM_MD
		exit_on_error
	fi
}
