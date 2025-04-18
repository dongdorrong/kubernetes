#!/bin/bash
# credentials 파일 초기화
cp -af ~/.aws/credentials_cleanAssumeRoleCredential ~/.aws/credentials

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 메뉴 출력
echo -e "${YELLOW}사용할 역할을 선택하세요:${NC}"
echo "1) terraform-assume-role"
echo "2) eks-assume-role"
read -p "선택 (1 또는 2): " choice

# 선택에 따른 역할 ARN 설정
case $choice in
    1)
        ROLE_ARN="arn:aws:iam::252462902626:role/terraform-assume-role"
        SESSION_NAME="terraform"
        echo -e "${GREEN}terraform-assume-role로 전환합니다.${NC}"
        ;;
    2)
        ROLE_ARN="arn:aws:iam::252462902626:role/eks-assume-role"
        SESSION_NAME="eks"
        echo -e "${GREEN}eks-assume-role로 전환합니다.${NC}"
        ;;
    *)
        echo "잘못된 선택입니다. 1 또는 2를 선택해주세요."
        exit 1
        ;;
esac

# AWS STS assume-role 호출
TOKEN=$(aws sts assume-role \
    --role-arn ${ROLE_ARN} \
    --role-session-name ${SESSION_NAME} \
    --profile private \
    --duration-seconds 43200)

if [ $? -ne 0 ]; then
    echo "역할 전환 중 오류가 발생했습니다."
    exit 1
fi

# credentials 파일 업데이트
ACCESS_KEY=$(echo $TOKEN | jq -r ".Credentials.AccessKeyId")
SECRET_KEY=$(echo $TOKEN | jq -r ".Credentials.SecretAccessKey")
SESSION_TOKEN=$(echo $TOKEN | jq -r ".Credentials.SessionToken")

aws configure set aws_access_key_id $ACCESS_KEY --profile private
aws configure set aws_secret_access_key $SECRET_KEY --profile private
aws configure set aws_session_token $SESSION_TOKEN --profile private

echo -e "${GREEN}역할 전환이 완료되었습니다.${NC}"
echo "다음 명령어로 현재 자격 증명을 확인할 수 있습니다:"
echo "aws sts get-caller-identity --profile private"
