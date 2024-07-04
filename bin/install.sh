#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC2129

install_help() {
	echo -e "${OK}Help${NC} - ${INF}$TF_ACTION${NC}:"
	echo "  TF_PARAMETER:"
	echo "  * <tool> - install only a specific tool"
	echo "  * ALL - install all tools, not only necessary for this action"
	echo "  Additional environment variables:"
	echo "  * FORCE_INSTALL: true / false force install of tools, also whe already installed"
	echo "  * <TOOL>_VERSION: Install a specific version of a tool (default latest)."
	exit 0
}

install_github_release() {
	local tool=$1
	local version=$2
	local owner=$3
	local repo=$4
	local url=$5
	local file=$6
	local symlink=$7
	local trail=$8
	local strip=$9
	#shellcheck disable=SC2154
	echo -e "Checking: ${INF}$tool$forced${NC}."
	if ! command -v "$tool" &>/dev/null || [[ "$FORCE_INSTALL" == "true" ]]; then
		if [[ -z "$version" ]]; then
			if [[ -z "$GITHUB_COM_TOKEN" ]]; then
				echo -e "  ${INF}GITHUB_COM_TOKEN:${NC} GITHUB_COM_TOKEN not set, API call is unauthenticated and rate limit can apply"
				GET_LIMIT=$(curl -H "Accept: application/vnd.github+json" https://api.github.com/rate_limit 2>/dev/null | jq .rate.remaining)
			else
				echo -e "${OK}GITHUB_COM_TOKEN:${NC} GITHUB_COM_TOKEN is set."
				GET_LIMIT=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: bearer $GITHUB_COM_TOKEN" https://api.github.com/rate_limit 2>/dev/null | jq .rate.remaining)

			fi
			if [[ $GET_LIMIT == 0 ]]; then
				echo -e "${ERR}Github RATE LIMIT:${NC} Remaining API limit is ${ERR}$GET_LIMIT${NC}."
				exit_on_error
			else
				echo -e "  Github RATE LIMIT:${NC} Remaining API limit is ${INF}$GET_LIMIT${NC}."
			fi
			if [[ -z "$GITHUB_COM_TOKEN" ]]; then
				version=$(curl -s https://api.github.com/repos/$owner/$repo/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
			else
				version=$(curl -H "Authorization: bearer $GITHUB_COM_TOKEN" -s https://api.github.com/repos/$owner/$repo/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
			fi
			echo -e "  $tool latest:${NC} Latest version is ${INF}$version${NC}."
		fi

		version="${version//v/}"
		filename="${file/<VERSION>/$version}"
		echo -e "  $tool not found: ${INF}Installing $owner/$repo ($version)${NC}$forced."
		download_url="$url/$trail$version/$filename"
		echo -e "  Download from: ${INF}$download_url${NC}."
		wget "${download_url}" -O $TMPDIR/$filename 1>$STDLOG 2>$ERRLOG
		if [[ "$DRY_RUN" == "false" ]]; then
			mkdir -p ~/$tool-"$version" 1>>$STDLOG 2>>$ERRLOG
			if [[ "$filename" == *.zip ]]; then
				echo -e "  Unzip to: ${INF}~/$tool-$version${NC}."
				unzip -o $TMPDIR/$filename -d ~/$tool-$version 1>>$STDLOG 2>>$ERRLOG
			else
				if [[ "$filename" == *.tar.gz ]]; then
					echo -e "  Tar.GZ to: $filename ${INF}~/$tool-$version${NC}."
					tar xvzf $TMPDIR/$filename -C ~/$tool-$version $strip 1>>$STDLOG 2>>$ERRLOG
				else
					if [[ "$filename" == *.tar.xz ]]; then
						echo -e "  Tar.XZ to: ${INF}~/$tool-$version${NC}."
						tar -xvJf $TMPDIR/$filename -C ~/$tool-$version "$strip" 1>>$STDLOG 2>>$ERRLOG
					else
						echo -e "  Copy file to: ${INF}~/$tool-$version/$tool${NC}."
						cp $TMPDIR/$filename ~/$tool-$version/$tool
						chmod 755 ~/$tool-$version/$tool 1>>$STDLOG 2>>$ERRLOG
					fi
				fi
			fi
			echo -e "  Creating symblic link: From ${INF}~/$tool-$version/$symlink${NC} to ${INF}~/bin/$tool${NC}."
			ln --symbolic --force ~/$tool-$version/$symlink ~/bin/$tool 1>>$STDLOG 2>>$ERRLOG
			echo -e "- Installed $tool from $owner/$repo ($version)" >>$STEP_SUM_MD

		fi
		if ! command -v $tool &>/dev/null; then
			echo -e "${ERR}$tool not found:${NC} $tool not found or not in path!${NC}"
			if [ "$DRY_RUN" = "false" ]; then
				ERROR=true
				clean_exit
			fi
		fi

	fi
	if $tool --version &>/dev/null; then echo -e "${OK}$tool:${NC} $(which $tool), version: ${INF}$($tool --version | grep -m 1 -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}')${NC}"; else
		if $tool -v &>/dev/null; then echo -e "${OK}$tool:${NC} $(which $tool), version: ${INF}$($tool -v | grep -m 1 -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}')${NC}"; fi
	fi
	hr
}

function install_tofu() {
	local bin="tofu"
	local owner="opentofu"
	local repo="opentofu"
	local download_url="https://github.com/opentofu/opentofu/releases/download"
	local file="tofu_<VERSION>_linux_amd64.zip"
	local symlink="tofu"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$TOFU_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_jq() {
	local bin="jq"
	local owner="jqlang"
	local repo="jq"
	local download_url="https://github.com/jqlang/jq/releases/download"
	local file="jq-linux-amd64"
	local symlink="jq"
	local prefix=""
	local strip=""
	install_github_release "$bin" "$JQ_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}
function install_gh() {
	local bin="gh"
	local owner="cli"
	local repo="cli"
	local download_url="https://github.com/cli/cli/releases/download"
	# https://github.com/cli/cli/releases/download/v2.44.1/gh_2.44.1_linux_amd64.tar.gz
	local file="gh_<VERSION>_linux_amd64.tar.gz"
	local symlink="bin/gh"
	local prefix="v"
	local strip="--strip-components=1"
	install_github_release "$bin" "$GH_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_terraform() {
	local bin="terraform"
	local owner="hashicorp"
	local repo="terraform"
	local download_url="https://releases.hashicorp.com/terraform"
	local file="terraform_<VERSION>_linux_amd64.zip"
	local symlink="terraform"
	local prefix=""
	local strip=""
	install_github_release "$bin" "$TERRAFORM_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_checkov() {
	local bin="checkov"
	local owner="bridgecrewio"
	local repo="checkov"
	local download_url="https://github.com/bridgecrewio/checkov/releases/download"
	local file="checkov_linux_X86_64.zip"
	local symlink="dist/checkov"
	local prefix=""
	local strip=""
	install_github_release "$bin" "$CHECKOV_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_tflint() {
	local bin="tflint"
	local owner="terraform-linters"
	local repo="tflint"
	local download_url="https://github.com/terraform-linters/tflint/releases/download"
	local file="tflint_linux_amd64.zip"
	local symlink="tflint"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$TFLINT_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_tf-summarize() {
	local bin="tf-summarize"
	local owner="dineshba"
	local repo="tf-summarize"
	local download_url="https://github.com/dineshba/tf-summarize/releases/download"
	local file="tf-summarize_linux_amd64.tar.gz"
	local symlink="tf-summarize"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$TF_SUMMARIZE_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_terraform-docs() {
	local bin="terraform-docs"
	local owner="terraform-docs"
	local repo="terraform-docs"
	local download_url="https://github.com/terraform-docs/terraform-docs/releases/download"
	local file="terraform-docs-v<VERSION>-linux-amd64.tar.gz"
	local symlink="terraform-docs"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$TERRAFORM_DOCS_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_reviewdog() {
	local bin="reviewdog"
	local owner="reviewdog"
	local repo="reviewdog"
	local download_url="https://github.com/reviewdog/reviewdog/releases/download"
	local file="reviewdog_<VERSION>_Linux_x86_64.tar.gz"
	local symlink="reviewdog"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$REVIEWDOG_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_pike() {
	local bin="pike"
	local owner="JamesWoolfenden"
	local repo="pike"
	local download_url="https://github.com/JamesWoolfenden/pike/releases/download"
	local file="pike_<VERSION>_linux_amd64.tar.gz"
	local symlink="pike"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$PIKE_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_actionlint() {
	local bin="actionlint"
	local owner="rhysd"
	local repo="actionlint"
	local download_url="https://github.com/rhysd/actionlint/releases/download"
	local file="actionlint_<VERSION>_linux_amd64.tar.gz"
	local symlink="actionlint"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$ACTIONLINT_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_shellcheck() {
	local bin="shellcheck"
	local owner="koalaman"
	local repo="shellcheck"
	local download_url="https://github.com/koalaman/shellcheck/releases/download"
	local file="shellcheck-v<VERSION>.linux.x86_64.tar.xz"
	local symlink="shellcheck"
	local prefix="v"
	local strip="--strip-components=1"
	install_github_release "$bin" "$SHELLCHECK_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_shfmt() {
	local bin="shfmt"
	local owner="mvdan"
	local repo="sh"
	local download_url="https://github.com/mvdan/sh/releases/download"
	local file="shfmt_v<VERSION>_linux_amd64"
	local symlink="shfmt"
	local prefix="v"
	local strip=""
	install_github_release "$bin" "$SHFMT_VERSION" "$owner" "$repo" "$download_url" "$file" "$symlink" "$prefix" "$strip"
}

function install_aws-cli {
	local tool=aws
	local download_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
	echo -e "Checking: ${INF}aws-cli$forced${NC}."
	if ! command -v $tool &>/dev/null || [[ "$FORCE_INSTALL" == "true" ]]; then
		echo -e "  $tool not found: ${INF}Installing aws-cli (v2)${NC}$forced."
		echo -e "  Download from: ${INF}$download_url${NC}."

		curl $download_url -o "$TMPDIR/awscliv2.zip" 1>$STDLOG 2>$ERRLOG
		unzip $TMPDIR/awscliv2.zip -d $TMPDIR/awscli 1>>$STDLOG 2>>$ERRLOG
		$TMPDIR/awscli/aws/install --bin-dir ~/bin --install-dir ~/aws-cli --update 1>>$STDLOG 2>>$ERRLOG
		echo -e "- Installed $tool (v2)" >>$STEP_SUM_MD
	fi
	if $tool --version &>/dev/null; then echo -e "${OK}$tool:${NC} $(which $tool), version: ${INF}$($tool --version | grep -m 1 -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}' | head -n1)${NC}"; else
		echo -e "${ERR}$tool not found:${NC} $tool not found or not in path!${NC}"
		if [ "$DRY_RUN" = "false" ]; then
			ERROR=true
			clean_exit
		fi
	fi
	hr
}

function install_az-cli {
	local tool=az
	echo -e "Checking: ${INF}azure-cli${NC}."
	if ! command -v $tool &>/dev/null; then
		wget https://bootstrap.pypa.io/get-pip.py
		python3 ./get-pip.py
		rm ./get-pip.py
		python3 -m pip install azure-cli --upgrade azure-cli
		~/.local/bin/az upgrade -y
		echo -e "  Creating symblic link: From ${INF}~/.local/bin/az${NC} to ${INF}~/bin/$tool${NC}."
		ln --symbolic --force ~/.local/bin/az ~/bin/$tool 1>>$STDLOG 2>>$ERRLOG
		echo -e "- Installed azure-cli" >>$STEP_SUM_MD
	fi

	if $tool --version &>/dev/null; then echo -e "${OK}$tool:${NC} $(which $tool), version: ${INF}$($tool --version | grep -m 1 -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}')${NC}"; else
		echo -e "${ERR}$tool not found:${NC} $tool not found or not in path!${NC}"
		if [ "$DRY_RUN" = "false" ]; then
			ERROR=true
		fi
	fi
	hr
}

function install_inspec {
	local tool=inspec
	echo -e "Checking: ${INF}chef inspec${NC}."
	if ! command -v $tool &>/dev/null; then
		# Install inspec in latest 5.x Version, cause from v6 it will need a license
		curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec -v 5.22.36 1>>$STDLOG 2>>$ERRLOG
		echo -e "- Installed inspec" >>$STEP_SUM_MD
	fi

	if $tool --version &>/dev/null; then echo -e "${OK}$tool:${NC} $(which $tool), version: ${INF}$($tool --version | grep -m 1 -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}')${NC}"; else
		echo -e "${ERR}$tool not found:${NC} $tool not found or not in path!${NC}"
		if [ "$DRY_RUN" = "false" ]; then
			# shellcheck disable=SC2034
			ERROR=true
			clean_exit
		fi
	fi
	hr
}
