#!/bin/bash
#shellcheck disable=SC1091,SC2086
validate() {
	if [[ $TF_ACTION == "validate" ]]; then
		echo -e "## validate ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
	fi
	echo -e "  $TF_ACTION - TF_PARAMETER: Root - ${INF}$TF_ROOT_DIR${NC}"
	JSON="$(mktemp --suffix=.tf.validate)" || {
		echo -e "${ERR}Failed to create tf.validate temp file${NC}"
		exit 1
	}
	$TFE -chdir=$TF_ROOT_DIR validate -json >$JSON 2>>$ERRLOG

	# Get Results
	result=$(jq '.valid' $JSON)
	errors=$(jq '.error_count' $JSON)
	warnings=$(jq '.warning_count' $JSON)
	TMPFILE=$(mktemp)
	## TF validate to reviewdog
	cat >$TMPFILE <<EOT
{
  "source": {
    "name": "$TFE validate",
    "url": ""
  },
  "severity": "ERROR",
  "diagnostics":
EOT

	cat $JSON | jq --arg DIR "$TF_ROOT_DIR" '[.diagnostics[] | del(.range.start.byte) | del(.range.end.byte) | .severity|=ascii_upcase | .range.path=$DIR + "/" + .range.filename|{message: .detail, location: { path: .range.path, range: {start: .range.start, end: .range.end} }, severity: .severity}]' >>$TMPFILE
	echo "}" >>$TMPFILE
	# Validate to reviewdog
	cat $TMPFILE | reviewdog -f=rdjson -filter-mode nofilter -reporter $REVIEWDOG_REPORTER -name "TF validate ($(basename $TF_ROOT_DIR))" >$ERRLOG

	rm $TMPFILE $JSON
	if [[ "$result" == "true" ]]; then
		echo -e "${OK}$TFE validate${NC}: $TFE code valid with ${INF}$warnings${NC} warning(s)."
		if [[ ! "$warnings" == 0 ]]; then gh_annotation "warning" "$TFE $TF_ACTION" "$TFE code has $warnings warning(s)!"; fi
		echo -e "✓ $TFE validate: $TFE code valid ($warnings warnings)." >>$STEP_SUM_MD
	else
		echo -e "${ERR}$TFE validate${NC}: $TFE code not valid with ${INF}$errors${NC} error(s)."
		gh_annotation "error" "$TFE $TF_ACTION" "$TFE code not valid with $errors error(s)!"
		echo -e "✗ $TFE validate: $TFE code not valid!" >>$STEP_SUM_MD
		ERROR=true
	fi
}
