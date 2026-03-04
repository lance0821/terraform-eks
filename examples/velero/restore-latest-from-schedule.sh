#!/usr/bin/env bash
set -euo pipefail

SCHEDULE_NAME="${1:-daily}"
NAMESPACE="${2:-velero}"

LATEST_BACKUP="$(kubectl get backups -n "${NAMESPACE}" -o jsonpath='{range .items[?(@.spec.scheduleName=="'"${SCHEDULE_NAME}"'")]}{.metadata.name}{"\n"}{end}' | sort | tail -n1)"

if [[ -z "${LATEST_BACKUP}" ]]; then
  echo "No backups found for schedule '${SCHEDULE_NAME}' in namespace '${NAMESPACE}'." >&2
  exit 1
fi

RESTORE_NAME="restore-${LATEST_BACKUP}-$(date +%Y%m%d%H%M%S)"

kubectl create -n "${NAMESPACE}" -f - <<EOF
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: ${RESTORE_NAME}
spec:
  backupName: ${LATEST_BACKUP}
EOF

echo "Created restore '${RESTORE_NAME}' from backup '${LATEST_BACKUP}'."
kubectl get restore -n "${NAMESPACE}" "${RESTORE_NAME}"
