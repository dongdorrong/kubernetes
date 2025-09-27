#!/usr/bin/env bash
set -euo pipefail

PROFILE="private"
DRY_RUN=false   # 실제 실행: false

say()  { echo "[$(date '+%H:%M:%S')] $*"; }
run()  { if $DRY_RUN; then echo "DRYRUN> $*"; else eval "$@"; fi; }

# 현재 계정의 모든 인스턴스 프로파일 이름 목록
mapfile -t PROFILES < <(aws iam list-instance-profiles \
  --profile "$PROFILE" \
  --query 'InstanceProfiles[].InstanceProfileName' \
  --output text | tr '\t' '\n' | sed '/^$/d')

if [ ${#PROFILES[@]} -eq 0 ]; then
  say "삭제할 인스턴스 프로파일이 없습니다."
  exit 0
fi

say "대상 인스턴스 프로파일:"
printf ' - %s\n' "${PROFILES[@]}"

for NAME in "${PROFILES[@]}"; do
  say "처리 시작: ${NAME}"

  # ARN 조회
  ARN="$(aws iam get-instance-profile \
    --instance-profile-name "$NAME" \
    --profile "$PROFILE" \
    --query 'InstanceProfile.Arn' --output text 2>/dev/null || true)"

  # 1) Role 제거
  mapfile -t ROLES < <(aws iam get-instance-profile \
    --instance-profile-name "$NAME" \
    --profile "$PROFILE" \
    --query 'InstanceProfile.Roles[].RoleName' \
    --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d' || true)

  if [ ${#ROLES[@]} -gt 0 ]; then
    for ROLE in "${ROLES[@]}"; do
      say " - Role 제거: ${ROLE} from ${NAME}"
      run aws iam remove-role-from-instance-profile \
        --instance-profile-name "$NAME" \
        --role-name "$ROLE" \
        --profile "$PROFILE"
    done
  else
    say " - 연결된 Role 없음"
  fi

  # 2) EC2 연결 해제(있으면)
  if [ -n "${ARN:-}" ] && [ "$ARN" != "None" ]; then
    mapfile -t ASSOCS < <(aws ec2 describe-iam-instance-profile-associations \
      --filters "Name=iam-instance-profile.arn,Values=${ARN}" \
      --profile "$PROFILE" \
      --query 'IamInstanceProfileAssociations[].AssociationId' \
      --output text 2>/dev/null | tr '\t' '\n' | sed '/^$/d' || true)

    if [ ${#ASSOCS[@]} -gt 0 ]; then
      for AID in "${ASSOCS[@]}"; do
        say " - EC2 연결 해제: AssociationId=${AID}"
        run aws ec2 disassociate-iam-instance-profile \
          --association-id "$AID" \
          --profile "$PROFILE"
      done
    else
      say " - EC2 연결 없음"
    fi
  fi

  # 3) 인스턴스 프로파일 삭제
  say " - 인스턴스 프로파일 삭제: ${NAME}"
  run aws iam delete-instance-profile \
    --instance-profile-name "$NAME" \
    --profile "$PROFILE"

  say "완료: ${NAME}"
done

say "DRY_RUN=${DRY_RUN}. 실제 삭제를 원하면 스크립트에서 DRY_RUN=false 로 설정하세요."

