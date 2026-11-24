#!/usr/bin/env bash
# Variables de la cuenta actual (sirve en cualquier Learner Lab). Uso: source infra/env.sh
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""
ACCT=$(aws sts get-caller-identity --query Account --output text)
BUCKET=airline-system-$ACCT
VPC=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
# subnets por defecto de us-east-1a/b/c (t3 no existe en todas las AZ)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC Name=default-for-az,Values=true \
  --query 'Subnets[?contains([`us-east-1a`,`us-east-1b`,`us-east-1c`],AvailabilityZone)].SubnetId' --output text)
MYIP=$(curl -s https://checkip.amazonaws.com)/32
