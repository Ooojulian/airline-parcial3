#!/usr/bin/env bash
# Se ejecuta EN LA EC2 (vía ssm_run.sh). Restaura airline_oltp y airline_olap desde los dumps en s3://<bucket>/backup/db/.
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1
B=airline-system-$(aws sts get-caller-identity --query Account --output text)
DB_HOST=$(aws ssm get-parameter --name /airline/db/host --query Parameter.Value --output text)
DB_USER=$(aws ssm get-parameter --name /airline/db/user --query Parameter.Value --output text)
export PGPASSWORD=$(aws ssm get-parameter --name /airline/db/password --with-decryption --query Parameter.Value --output text) PGSSLMODE=require
for db in airline_oltp airline_olap; do
  aws s3 cp s3://$B/backup/db/$db.dump /tmp/$db.dump --quiet
  psql -h $DB_HOST -U $DB_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1 \
    || psql -h $DB_HOST -U $DB_USER -d postgres -qc "CREATE DATABASE $db"
  pg_restore -h $DB_HOST -U $DB_USER -d $db --clean --if-exists --no-owner --no-privileges /tmp/$db.dump || true
done
psql -h $DB_HOST -U $DB_USER -d airline_oltp -tAc "SELECT 'vuelos='||(SELECT count(*) FROM flights)||' reservas='||(SELECT count(*) FROM reservations)"
