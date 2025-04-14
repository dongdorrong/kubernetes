#!/bin/bash
cp -af ~/.aws/credentials_cleanAssumeRoleCredential ~/.aws/credentials

TOKEN=`aws sts assume-role --profile private --role-arn arn:aws:iam::252462902626:role/terraform-assume-role --role-session-name terraform --duration-seconds 43200`

ACCESS_KEY=`echo $TOKEN | jq -r ".Credentials.AccessKeyId"`
SECRET_KEY=`echo $TOKEN | jq -r ".Credentials.SecretAccessKey"`
SESSION_TOKEN=`echo $TOKEN | jq -r ".Credentials.SessionToken"`

aws configure set aws_access_key_id $ACCESS_KEY --profile private
aws configure set aws_secret_access_key $SECRET_KEY --profile private
aws configure set aws_session_token $SESSION_TOKEN --profile private
