#!/usr/bin/env bash
# Ejecuta athena_tables.sql sentencia por sentencia (workgroup primary).
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""
B=airline-system-$(aws sts get-caller-identity --query Account --output text)
OUT=s3://$B/athena-results/
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 - "$DIR/athena_tables.sql" "$B" <<'PY' | while IFS= read -r -d '' SQL; do
import sys
txt = "\n".join(l for l in open(sys.argv[1]).read().splitlines() if not l.startswith("--"))
for s in txt.split("\n;;\n"):
    s = s.strip().rstrip(";")
    if s:
        sys.stdout.write(s.replace("__BUCKET__", sys.argv[2]) + "\0")
PY
  QID=$(aws athena start-query-execution --work-group primary --result-configuration OutputLocation=$OUT --query-string "$SQL" --query QueryExecutionId --output text)
  while :; do
    ST=$(aws athena get-query-execution --query-execution-id "$QID" --query QueryExecution.Status.State --output text)
    case "$ST" in SUCCEEDED) break;; FAILED|CANCELLED) aws athena get-query-execution --query-execution-id "$QID" --query QueryExecution.Status.StateChangeReason --output text; exit 1;; esac
    sleep 1
  done
  echo "OK: ${SQL%%$'\n'*}"
done
