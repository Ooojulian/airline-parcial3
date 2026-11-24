#!/usr/bin/env bash
# Sube backend/ y frontend/ (último commit) a S3 y los despliega en la EC2: reconstruye las imágenes y relanza API y web.
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""
cd "$(dirname "$0")/../.."
B=airline-system-$(aws sts get-caller-identity --query Account --output text)
git archive --format=tar.gz -o /tmp/backend.tgz HEAD backend frontend infra/restaurar_db.sh
aws s3 cp /tmp/backend.tgz s3://$B/code/backend.tgz --quiet
bash infra/ssm_run.sh "set -e; mkdir -p /opt/airline-system && cd /opt/airline-system && aws s3 cp s3://$B/code/backend.tgz /tmp/backend.tgz --quiet && tar xzf /tmp/backend.tgz && bash backend/run_api.sh --build 2>&1 | tail -3 && bash frontend/run_web.sh 2>&1 | tail -1"
