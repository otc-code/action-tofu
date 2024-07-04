#!/bin/bash
#shellcheck disable=SC1091,SC2086,SC2129,SC2153
kics_scan() {
	if [[ $TF_ACTION == "kics_scan" ]]; then
		echo -e "## Kics scan ($(basename $TF_ROOT_DIR))\n" >>$STEP_SUM_MD
		echo -e "Parameter: $TF_PARAMETER\n" >>$STEP_SUM_MD
	fi
	docker pull docker.io/checkmarx/kics:latest
	echo -e "${OK}TF_ACTION${NC}: Scan directory $TF_ROOT_DIR"
	echo -e "✓ $TF_ACTION: Scan directory $TF_ROOT_DIR" >>$STEP_SUM_MD
	docker run -t -v "$TF_ROOT_DIR":/scan checkmarx/kics scan -p /scan -o "/scan/" --report-formats sarif --no-progress
	cat $TF_ROOT_DIR/results.sarif | reviewdog -f=sarif -filter-mode nofilter -reporter $REVIEWDOG_REPORTER -name "Kics ($(basename $TF_ROOT_DIR))"
	kics_docs
	rm $TF_ROOT_DIR/results.json $TF_ROOT_DIR/results.sarif
}
