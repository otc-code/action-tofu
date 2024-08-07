#!/bin/bash
#shellcheck disable=SC1091,SC2086
SCRIPT_DIRECTORY=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIRECTORY/functions.sh"
source "$SCRIPT_DIRECTORY/install.sh"
source "$SCRIPT_DIRECTORY/fmt.sh"
source "$SCRIPT_DIRECTORY/init.sh"
source "$SCRIPT_DIRECTORY/validate.sh"
source "$SCRIPT_DIRECTORY/lint.sh"
source "$SCRIPT_DIRECTORY/checkov.sh"
source "$SCRIPT_DIRECTORY/kics.sh"
source "$SCRIPT_DIRECTORY/plan.sh"
source "$SCRIPT_DIRECTORY/apply.sh"
source "$SCRIPT_DIRECTORY/docs.sh"

function info() {
	echo -e "## info ($(basename $TF_ROOT_DIR))" >>$STEP_SUM_MD
	echo -e "Runtime: $TFE" >>$STEP_SUM_MD
	echo -e "${OK}$TF_ACTION${NC}: This action is for executing terraform IaC Code within Github Actions."
	echo -e "  Documentation: ${INF}https://github.com/otc-code/action-tofu${NC}."
	echo -e "${OK}Supported Actions${NC}: ${INF}$AVAILABLE_ACTIONS${NC}."
	echo -e "${OK}Supported tools${NC}: ${INF}$AVAILABLE_TOOLS${NC}."
	echo -e "${OK}Required tools${NC}: ${INF}$STANDARD_TF_TOOLS${NC}."
	echo -e "  Parameters: [${INF}$TF_PARAMETER${NC}]."

	if ! command -v "$TFE" &>/dev/null; then
		echo -e "${ERR}Executable:${NC} No ${INF}$TFE${NC} executable found"
		echo -e "✗ No <$TFE> executable found, use install action to install necessary tools!\n" >>$STEP_SUM_MD
	else
		echo -e "${OK}Executable:${NC} $(which "$TFE") - $("$TFE" --version -json | jq -r '.terraform_version')"
		echo "✓ Executable: $(which "$TFE") - $("$TFE" --version -json | jq -r '.terraform_version')" >>$STEP_SUM_MD
	fi
	hr
}

function install() {
	#shellcheck disable=SC2034
	if [[ "$FORCE_INSTALL" == "true" ]]; then forced=" - (forced install)"; fi
	if [[ "$TF_PARAMETER" == "help" ]]; then install_help; fi
	echo -e "## install ($(basename $TF_ROOT_DIR))\nParameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	mkdir -p ~/bin
	if [[ "$TF_PARAMETER" == "none" ]] || [[ "$TF_PARAMETER" == "ALL" ]]; then
		#shellcheck disable=SC2128
		if [[ "$TF_PARAMETER" == "ALL" ]]; then
			IFS=',' read -r -a ARRAY <<<"$AVAILABLE_TOOLS"
		else
			IFS=',' read -r -a ARRAY <<<"$STANDARD_TF_TOOLS"
		fi
		for tool in "${ARRAY[@]}"; do
			install_"$tool"
		done
	else
		IFS=',' read -r -a ARRAY <<<"$TF_PARAMETER"
		for tool in "${ARRAY[@]}"; do
			if [[ "${AVAILABLE_TOOLS[*]}" =~ $tool ]]; then
				install_"$tool"
			else
				echo -e "${ERR}Install:${NC} Installation of ${INF}$tool${NC} not supported!"
			fi
		done
	fi
}
function static_checks() {
	echo -e "## Static checks & Docs ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
	echo -e "${OK}$TF_ACTION${NC}: Running all static tests."
	if [[ $GITHUB_EVENT_NAME == "pull_request" ]]; then
		TF_PARAMETER=check fmt
	else
		TF_PARAMETER=recursive fmt
	fi

	TF_PARAMETER=nobackend init
	validate
	lint
	checkov_scan
	tf_docs
	pike_docs
	update_toc
}

function destroy() {
	echo -e "  $TF_ACTION - TF_PARAMETER: ${INF}$TF_PARAMETER${NC}"
	echo -e "## destroy\n" >>$STEP_SUM_MD
	TF_PARAMETER="$TF_PARAMETER,apply_destroy,norefresh,ignore_plan" apply
}

show_info
create_tmp_files

$TF_ACTION 2>>$ERRLOG
if [[ $PUSH == "true" ]]; then
	echo "  Git Push: $TF_ACTION"
	git_push
fi
clean_exit
