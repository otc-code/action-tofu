#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC2129,SC2034,SC2054,SC2140,SC2030,SC2031,SC2128,SC2269

set_defaults() {
	####################
	# Set Defaults
	###################
	# Add home bin directory to path
	export PATH="$HOME/bin:$PATH"
	ERROR=false
	# Supported Action & Tools
	AVAILABLE_ACTIONS=("info","install","fmt","init","validate","lint","checkov_scan", "kics_scan","plan","apply","destroy","update_toc","tf_docs","pike_docs","static_checks")
	AVAILABLE_TOOLS=("jq","terraform","checkov","tflint","tf-summarize","terraform-docs","reviewdog","pike","actionlint","shellcheck","shfmt","aws-cli","az-cli","tofu","gh")
	STANDARD_TF_TOOLS=("jq","tofu","checkov","tflint","tf-summarize","terraform-docs","reviewdog","pike","aws-cli","az-cli","gh")

	# Color for Outputs
	OK='\033[0;32m✓ '
	INF='\033[0;33m'
	ERR='\033[0;31m✗ '
	NC='\033[0m'

	# Executable for running IaC Code
	if [[ -z "$TFE" ]]; then TFE="tofu"; fi
	if [[ -z $TF_PARAMETER ]]; then TF_PARAMETER=none; fi
	# Set default action if not set
	#if [[ -z "$TF_ACTION" ]]; then TF_ACTION="info"; fi
	# Set default DRY_RUN OPTION if not set
	if [[ -z "$DRY_RUN" ]]; then DRY_RUN="false"; fi
	# Install forced
	if [[ -z "$FORCE_INSTALL" ]]; then FORCE_INSTALL="false"; fi
	# Get Repository info's with git
	# shellcheck disable=SC2046
	REPO=$(basename -s .git $(git config --get remote.origin.url))
	REF=$(git branch | sed -n '/\* /s///p')

	# Set defaults for Github Actions
	if [[ -n "$GITHUB_WORKSPACE" ]]; then
		local DIR="$GITHUB_WORKSPACE/$TF_DIR"
		TF_ROOT_DIR=${DIR%%/f}
		WORKFLOW_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
		WORKFLOW="$GITHUB_WORKFLOW with $GITHUB_EVENT_NAME ($WORKFLOW_URL)"
	else
		TF_ROOT_DIR="$TF_DIR"
		WORKFLOW="unknown (local)"
	fi
	# Set defaults for reviewdog
	if [ -n "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
		if [[ $GITHUB_EVENT_NAME == "pull_request" ]]; then
			if [[ $TF_ACTION == "inspec_tests" ]] || [[ $TF_PARAMETER == "plan" ]]; then
				REVIEWDOG_REPORTER="github-pr-check"
			else
				REVIEWDOG_REPORTER="github-pr-review"
			fi
		else REVIEWDOG_REPORTER="github-check"; fi
	else
		REVIEWDOG_REPORTER="local"
	fi
	if [[ -n "$MD_FILE" ]]; then
		MD_FILE="$MD_FILE"
	else
		MD_FILE="$TF_ROOT_DIR/README.md"
	fi
}

function create_tmp_files() {
	STDLOG="$(mktemp --suffix=.std.log)" || {
		echo -e "${ERR}Failed to create std.log temp file${NC}"
		exit 1
	}
	ERRLOG="$(mktemp --suffix=.error.log)" || {
		echo -e "${ERR}Failed to create error.log temp file${NC}"
		exit 1
	}
	TMPDIR="$(mktemp -d)" || {
		echo -e "${ERR}Failed to create temp dir${NC}"
		exit 1
	}
	STEP_SUM_MD="$(mktemp --suffix=.step.md)" || {
		echo -e "${ERR}Failed to create step.md dir${NC}"
		exit 1
	}
}

function set_auth_header() {
	if [ -n "${GITHUB_COM_TOKEN:-}" ]; then
		echo "  Setting Github.com AUTH Header (Private Repo)."
		git config --global user.name github-actions
		git config --global user.email github-actions@github.com
		git config --global --add url."https://x-access-token:$GITHUB_COM_TOKEN@github".insteadOf "https://github"
		git config --global --add url."https://x-access-token:$GITHUB_COM_TOKEN@github".insteadOf "ssh://git@github"
		git config --global --add url."https://x-access-token:$GITHUB_COM_TOKEN@github".insteadOf "git@github"
	fi
	if [ -n "${GH_ENTERPRISE_TOKEN:-}" ]; then
		echo "  Setting $GH_HOST AUTH Header."
		git config --global user.name github-actions
		git config --global user.email github-actions@$GH_HOST
		git config --global --add url."https://x-access-token:$GH_ENTERPRISE_TOKEN@$GH_HOST".insteadOf "https://$GH_HOST"
		git config --global --add url."https://x-access-token:$GH_ENTERPRISE_TOKEN@$GH_HOST".insteadOf "ssh://git@$GH_HOST"
		git config --global --add url."https://x-access-token:$GH_ENTERPRISE_TOKEN@$GH_HOST".insteadOf "git@$GH_HOST"
	fi
}

unset_auth_header() {
	git config --global --unset-all url."https://x-access-token:$GITHUB_COM_TOKEN@github".insteadOf || true
	git config --global --unset-all url."https://x-access-token:$GH_ENTERPRISE_TOKEN@$GH_HOST".insteadOf || true
}

function clean_tmp_files() {
	rm -rf "$TMPDIR" &>/dev/null
	rm $STDLOG $ERRLOG $STEP_SUM_MD &>/dev/null
}

function clean_exit() {
	echo -e "${OK}Cleaning up${NC}"
	if [[ $GH_STEP_SUMMARY == "true" ]]; then
		echo "  Create Step Summary"
		cat $STEP_SUM_MD >>$GITHUB_STEP_SUMMARY
	fi
	if [[ $GH_PR_COMMENTS == "true" ]] && [[ $GITHUB_EVENT_NAME == "pull_request" ]]; then
		PR=$(IFS='/' read -r -a REF <<<"$GITHUB_REF" && echo ${REF[2]})
		echo "  Commenting PR - $PR"
		# Maybe add a logic to prevent duplicate entries
		gh pr comment $PR --body-file $STEP_SUM_MD
	fi
	echo "  Unset Github.com AUTH Header (Private Repo)"
	unset_auth_header
	hr
	if [[ $DEBUG == "INFO" ]]; then cat $STDLOG; fi
	if [[ $DEBUG == "WARN" ]]; then cat $ERRLOG; fi
	if [[ $DEBUG == "DEBUG" ]]; then cat $STDLOG $ERRLOG; fi

	if [[ $ERROR == "true" ]]; then
		echo -e "${ERR}Errors were found, please check the logs${NC}:"
		cat $ERRLOG
		clean_tmp_files
		hr
		exit 1
	else
		echo -e "${OK}No errors${NC}"
		clean_tmp_files
		hr
		exit 0
	fi
}

function hr() {
	set +x
	for i in {1..100}; do echo -n -; done
	echo ""
	if [[ $DEBUG == "TRACE" ]]; then set -x; fi
}

function show_info() {
	if [[ -z "$GITHUB_TOKEN" ]]; then TOKEN="GH token not set!"; else TOKEN="GH token was set."; fi
	hr
	echo -e "♈ Action: $WORKFLOW"
	echo -e "♎ Repository: ${INF}$REPO${NC} on $REF"
	echo -e "☸ Running script: ${INF}$(basename $0)${NC} in $SCRIPT_DIRECTORY"
	echo -e "🔒 Github Token: ${INF}$TOKEN${NC}"
	#statements
	hr
	if [[ "${AVAILABLE_ACTIONS[*]}" =~ $TF_ACTION ]]; then
		echo -e "${OK}TF_ACTION${NC}: ${INF}$TF_ACTION${NC}"
	else
		echo -e "${ERR}TF_ACTION${NC}: ${INF}$TF_ACTION${NC} is not supported!"
		ERROR=true
		clean_exit
	fi
	echo -e "${OK}TF_PARAMETER: ${INF}$TF_PARAMETER${NC}"
	if [[ -z "$TF_DIR" ]]; then
		echo -e "  TF_DIR: ${INF}No TF_DIR${NC} set!"
	fi
	echo -e "${OK}TF_DIR${NC}: Using ${INF}$TF_ROOT_DIR${NC} as tf root dir."

	# Set Debug Level
	case "$DEBUG" in
	"INFO")
		echo -e "${OK}Debug${NC}: ${INF}Enabled${NC} Level: ${INF}$DEBUG${NC}"
		gh auth status
		export TF_LOG=INFO
		;;
	"WARN")
		echo -e "${OK}Debug${NC}: ${INF}Enabled${NC} Level: ${INF}$DEBUG${NC}"
		echo -e "🔒 Github Access:"
		gh auth status
		export TF_LOG=WARN
		;;
	"DEBUG")
		echo -e "${OK}Debug${NC}: ${INF}Enabled${NC} Level: ${INF}$DEBUG${NC}"
		echo -e "🔒 Github Access:"
		gh auth status
		hr
		echo -e "☃ Environment variables:"
		printenv | sort
		export TF_LOG=DEBUG
		;;
	"TRACE")
		echo -e "${OK}Debug${NC}: ${INF}Enabled${NC} Level: ${INF}$DEBUG${NC}"
		echo -e "🔒 Github Access:"
		gh auth status
		hr
		echo -e "☃ Environment variables:"
		printenv | sort
		set -x
		export TF_LOG=TRACE
		;;
	*)
		echo -e "  Debug: ${INF}Disabled${NC}"
		DEBUG="false"
		;;
	esac
	hr
}

function gh_annotation() {
	if [[ $GH_ANNOTATIONS == "true" ]]; then
		local type=$1
		local title=$2
		local message=$3

		message="${message//'%'/'%25'}"
		message="${message//$'\n'/'%0A'}"
		message="${message//$'\r'/'%0D'}"
		echo "::$type title=$title::$message"
	fi
}

git_push() {
	if [[ ! $GITHUB_EVENT_NAME == "pull_request" ]]; then
		MINWAIT=1
		MAXWAIT=45
		if [[ "$CI" == "true" ]]; then
			local commit_message="action-tfe: $TF_ACTION: $GITHUB_EVENT_NAME, $GITHUB_WORKFLOW"
		else
			local commit_message="action-tfe: $TF_ACTION: Local"
		fi

		git config --global user.name github-actions 1>>$STDLOG 2>>$ERRLOG
		git config --global user.email github-actions@github.com 1>>$STDLOG 2>>$ERRLOG
		git config pull.rebase true
		git config fetch.prune true
		if git diff --exit-code 1>>$STDLOG 2>>$ERRLOG; then
			echo -e "${OK}git diff:${NC} nothing to commit"
			echo "git diff: nothing to commit." >>$STEP_SUM_MD
		else
			echo -e "${OK}git status ($REF):${NC} \n$(git status --short)"
			echo "  git status ($REF):" >>$STEP_SUM_MD
			git status --short >>$STEP_SUM_MD
			if [[ "$DRY_RUN" == "false" ]]; then
				git commit -a -m "$commit_message"
				if ! git push; then
					echo -e "  * ${INF}Push rejected${NC}: Local branch not up to date, will pull again !"
					sleep $((MINWAIT + RANDOM % (MAXWAIT - MINWAIT)))
					git fetch
					git merge --no-ff
					git pull 1>>$STDLOG 2>>$ERRLOG
					git push 1>>$STDLOG 2>>$ERRLOG
					if ! git push; then
						echo -e "${ERR}Push rejected${NC}: Check github token permission !"
						gh_annotation "error" "$TF_ACTION ($(basename $TF_ROOT_DIR)): Push rejected" "Check github token permission !"
					fi
				else
					echo -e "${OK}git push:${NC} $commit_message"
					echo -e "✓ git push: $commit_message" >>$STEP_SUM_MD
					gh_annotation "notice" "Codebase changed, please update local branch."
					echo "git push: $commit_message" >>$STEP_SUM_MD
				fi
			fi
		fi
	else
		echo -e " ${INF}git push${NC}: No commits on PR!"
		gh_annotation "warning" "No commits on PR!"
	fi
}

set_defaults
