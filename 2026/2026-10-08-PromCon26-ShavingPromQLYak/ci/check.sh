#!/usr/bin/env bash
# CI an exporter with PromQL: scrape it twice, then require every contract
# expression to return a non-empty result. Exits non-zero on any failure.
#
# usage: ci/check.sh <metrics-url> <contract.promql>
#
# NOTE: promql-cli's -f mode always exits 0, so each expression runs with
# -q (which does fail on errors) and `jq -e` turns "empty result" into a failure.
set -euo pipefail

url=${1:?metrics url}
contract=${2:?contract file}
promql_cli=${PROMQL_CLI:-promql-cli}
snap=$(mktemp --suffix=.prom)
trap 'rm -f "$snap"' EXIT

"$promql_cli" query -s -c ".scrape $url 2 5s; .save $snap" -q 'vector(1)' >/dev/null

fail=0
while IFS= read -r expr; do
	[[ -z $expr || $expr == \#* ]] && continue
	if "$promql_cli" query -s -o json -q "$expr" "$snap" 2>/dev/null |
		jq -e '.data.result | length > 0' >/dev/null; then
		printf '\e[32mPASS\e[0m  %s\n' "$expr"
	else
		printf '\e[31mFAIL\e[0m  %s\n' "$expr"
		fail=1
	fi
done <"$contract"
exit "$fail"
