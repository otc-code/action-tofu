#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2086,SC2129,SC2034
source "$SCRIPT_DIRECTORY/backend.sh"
source "$SCRIPT_DIRECTORY/functions.sh"
function init() {
	# Available TF_PARAMETER: help, backendfile=file, autocreate, autopilot, nobackend, help
	echo -e "$TFE init${NC}"
	if [[ $TF_ACTION == "init" ]]; then
		echo -e "## init ($(basename $TF_ROOT_DIR))\nParameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	fi
	echo -e "  $TF_ACTION - TF_PARAMETER: ${INF}$TF_PARAMETER${NC}"
	INIT_CMD="-chdir=$TF_ROOT_DIR init "
	IFS=',' read -r -a ARRAY <<<"$TF_PARAMETER"
	for parameter in "${ARRAY[@]}"; do

		case ${parameter%%=*} in
		help)
			echo -e "${OK}Help${NC} - ${INF}$TF_ACTION${NC}:"
			echo "  nobackend: init with -backend=false"
			echo "  upgrade: init with -upgrade"
			echo "  backendfile=<file>': init with partital backend file"
			echo "  autocreate=<PROVIDER>,region=<CLOUD_REGION>: create backend from backendfile when not exists before init"
			echo "  autopilot=<PROVIDER>,region=<CLOUD_REGION>: create backend configuration & remote backend before init"
			;;
		nobackend) INIT_CMD="$INIT_CMD-backend=false " ;;
		upgrade) INIT_CMD="$INIT_CMD-upgrade " ;;
		reconfigure) INIT_CMD="$INIT_CMD-reconfigure " ;;
		backendfile)
			if [[ -n "$GITHUB_WORKSPACE" ]]; then
				INIT_CMD="$INIT_CMD-backend-config=$GITHUB_WORKSPACE/${parameter##*=} "
			else
				INIT_CMD="$INIT_CMD-backend-config=${parameter##*=} "
			fi
			BACKEND_FILE=${parameter##*=}
			;;
		region) REGION=${parameter##*=} ;;
		update_backend) UPDATE_BACKEND=true ;;
		state_key) STATE_KEY=${parameter##*=} ;;
		autocreate)
			echo -e "${OK}AutoCreate${NC}: Will check & create remote backend from given file."
			PROVIDER=${parameter##*=}
			if [[ "$PROVIDER" != "autocreate" ]]; then
				CREATE="${parameter##*=}_backend_config"
			else
				echo -e "${ERR}AutoCreate${NC}: Missing backend provider (aws/azr/gcp) in TF_PARAMETER autocreate, cannot create remote backend file."
				ERROR=true
				clean_exit
			fi
			AUTOCREATE=true
			;;
		autopilot)
			echo -e "${OK}AutoPilot${NC}: Autogenerated remote backend."
			PROVIDER=${parameter##*=}
			if [[ "$PROVIDER" != "autopilot" ]]; then
				CREATE="${parameter##*=}_backend_file"
				AUTOPILOT=true
			else
				echo -e "${ERR}AutoPilot${NC}: Missing backend provider (aws/azr/gcp) in TF_PARAMETER, cannot create remote backend file."
				ERROR=true
				clean_exit
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
	set_auth_header
	if [[ $AUTOCREATE == true ]]; then
		echo -e "  ${INF}AutoCreate${NC}: Using $BACKEND_FILE in $REGION ($APPD_ID)."
		export CREATE=backend_config_$PROVIDER
		autocreate
		rewrite_backend_config
	fi
	if [[ $AUTOPILOT == true ]]; then
		echo -e "  ${INF}AutoPilot${NC}: Using $PROVIDER in $REGION for remote backend."
		autopilot
		rewrite_backend_config
		INIT_CMD="$INIT_CMD-backend-config=$TMPDIR/auto.tfbackend -reconfigure"
		BACKEND_FILE=$TMPDIR/auto.tfbackend
	fi
	echo -e "  $TF_ACTION: ${INF}$INIT_CMD${NC}"

	if [[ "$DRY_RUN" == "false" ]]; then
		if $TFE $INIT_CMD; then
			echo -e "${OK}$TFE init${NC}: Init successfull."
			echo -e "✓ Init successfull" >>$STEP_SUM_MD
			echo -e "Providers:" >>$STEP_SUM_MD
			$TFE -chdir=$TF_ROOT_DIR --version -json | jq -r '.provider_selections | keys[] as $k |"\($k): \(.[$k] | .)"' >>$STEP_SUM_MD
		else
			echo -e "${ERR}$TFE init${NC}: Init failed."
			ERROR=true
			clean_exit
		fi
	else
		echo -e "  ${INF}Init${NC}: Dry Run, will not run $TFE $INIT_CMD."
		gh_annotation "notice" "$TFE $TF_ACTION ($(basename $TF_ROOT_DIR))" "Dry run, will not run $TFE $INIT_CMD."
	fi
}