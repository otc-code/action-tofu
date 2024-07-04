#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2129,SC2153,SC2034
check_markers() {
	if ! grep "$MD_START" "$MD_FILE" >/dev/null; then
		echo -e "  ${INF}Update $TF_ACTION${NC}: $MD_START not found in $MD_FILE, skipping."
		echo -e "  $TF_ACTION:  Update docs, \`$MD_START\` not found in $MD_FILE, skipping." >>$STEP_SUM_MD
		clean_exit
	else
		if ! grep "$MD_END" "$MD_FILE" &>/dev/null; then
			echo -e "  ${INF}Update $TF_ACTION${NC} docs: $MD_END not found in $MD_FILE, skipping."
			echo -e "  $TF_ACTION:  Update docs, \`$MD_END\` not found in $MD_FILE, skipping." >>$STEP_SUM_MD
			clean_exit
		fi
	fi
}

replace() {
	# Read the file into a variable
	file_content=$(<$MD_FILE)
	start_line=$(grep -n "$MD_START" $MD_FILE | cut -d: -f1)
	end_line=$(grep -n "$MD_END" $MD_FILE | cut -d: -f1)
	content_to_replace=$(sed -n "${start_line},${end_line}p" $MD_FILE)
	echo "${file_content/$content_to_replace/$(<$TMP)}" >$MD_FILE
}

update_toc() {
	git pull
	MD_START="<!-- BEGIN_TOC -->"
	MD_END="<!-- END_TOC -->"
	check_markers
	TMP="$TMPDIR/toc.md"
	echo "$MD_START" >$TMP
	$SCRIPT_DIRECTORY/markdown-toc.sh $MD_FILE >>$TMP
	echo "$MD_END" >>$TMP
	replace
	if [[ $TF_ACTION == "update_toc" ]]; then
		echo -e "## $TF_ACTION ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
	fi
	echo -e "${OK}update_toc${NC}: Updated toc in $MD_FILE."
	echo -e "✓ update_toc: Updated toc in $MD_FILE." >>$STEP_SUM_MD
	PUSH="true"
}

tf_docs() {
	if [[ $TF_ACTION == "tf_docs" ]]; then
		echo -e "## $TF_ACTION ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
	fi
	MD_START="<!-- BEGIN_TF_DOCS -->"
	MD_END="<!-- END_TF_DOCS -->"
	check_markers
	TMP="$TMPDIR/tfdocs.md"
	echo "$MD_START" >$TMP
	echo "## terraform-docs" >>$TMP
	terraform-docs markdown $TF_ROOT_DIR | sed 's/##/###/g' >>$TMP
	echo "$MD_END" >>$TMP
	replace
	echo -e "${OK}tf_docs${NC}: Updated docs in $MD_FILE."
	echo -e "✓ tf_docs: Updated docs in $MD_FILE." >>$STEP_SUM_MD
	PUSH="true"
}

checkov_docs() {
	MD_START="<!-- BEGIN_CHECKOV -->"
	MD_END="<!-- END_CHECKOV -->"
	echo -e "${OK}checkov_scan${NC}: Using file $MD_FILE."
	check_markers
	TMP="$TMPDIR/checkov.md"
	echo "$MD_START" >$TMP

	if grep -n "check_id" $TMPDIR/results_github_failed_only.md; then
		echo -e "  ${INF}checkov_scan${NC}: Checkov issues found."
		echo "## Checkov findings" >>$TMP
		# Get only the table
		cat $TMPDIR/results_github_failed_only.md | grep --color=never "|" >>$TMP
	else
		echo -e "${OK}$TF_ACTION${NC}: No Checkov issues found."
		echo "## Checkov findings (none)" >>$TMP
		echo -e "> 🎉 CONGRATS! No findings found in Code.\n" >>$TMP
	fi
	# shellcheck disable=SC1068
	echo "**Skipped checks**:" >>$TMP
	grep -A100 "skip-check:" $CONFIG_FILE | tail -n +2 >>$TMP
	echo "<!-- END_CHECKOV -->" >>$TMP
	replace
	echo -e "${OK}checkov_docs${NC}: Updated docs in $MD_FILE."
	echo -e "✓ checkov_scan: Updated docs in $MD_FILE." >>$STEP_SUM_MD
	PUSH="true"
}

pike_docs() {
	if [[ $TF_ACTION == "pike_docs" ]]; then
		echo -e "## $TF_ACTION ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
	fi
	MD_START="<!-- BEGIN_PIKE_DOCS -->"
	MD_END="<!-- END_PIKE_DOCS -->"
	check_markers
	TMP="$TMPDIR/pike.md"
	echo "$MD_START" >$TMP
	echo "## Permissions (Pike)" >>$TMP
	echo "\`\`\`hcl" >>$TMP
	pike scan -o terraform -d $TF_ROOT_DIR 1>>$TMP 2>$ERRLOG
	echo "\`\`\`" >>$TMP
	cat $ERRLOG | sed -r 's/\x1B\[(;?[0-9]{1,3})+[mGK]//g' >>$STEP_SUM_MD
	if grep -n "DBG" $ERRLOG; then
		echo -e "__**Pike Debug**__:\n" >>$TMP
		echo "\`\`\`console" >>$TMP
		cat $ERRLOG | grep --color=never "DBG" | sed -r 's/\x1B\[(;?[0-9]{1,3})+[mGK]//g' >>$TMP
		echo "\`\`\`" >>$TMP
	fi
	echo "$MD_END" >>$TMP
	replace
	echo -e "${OK}pike_docs${NC}: Updated docs in $MD_FILE."
	echo -e "✓ pike_docs: Updated docs in $MD_FILE." >>$STEP_SUM_MD
	PUSH="true"
}

kics_docs() {
	if [[ $TF_ACTION == "kics_docs" ]]; then
		echo -e "## $TF_ACTION ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
	fi
	MD_START="<!-- BEGIN_KICS -->"
	MD_END="<!-- END_KICS -->"
	check_markers
	TMP="$TMPDIR/kics.md"
	echo "$MD_START" >$TMP
	echo "## KICS findings" >>$TMP
	echo "not implemented" >>$TMP
	echo "$MD_END" >>$TMP
	replace
	echo -e "${OK}kics_docs${NC}: Updated docs in $MD_FILE."
	echo -e "✓ kics_docs: Updated docs in $MD_FILE." >>$STEP_SUM_MD
	PUSH="true"
}
