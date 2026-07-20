#!/usr/bin/env bash
set -euo pipefail

echo "Starting deploy_release.sh"

RELEASE_CHANNEL="${RELEASE_CHANNEL:-stable}"
CANARY_PERCENT="${CANARY_PERCENT:-0}"
ROLLBACK_TO="${ROLLBACK_TO:-}"

ARTIFACT_DIR="release-artifacts"
AAB_FILE=$(find "$ARTIFACT_DIR" -type f -name "*.aab" | head -n 1 || true)
WEB_DIR="$ARTIFACT_DIR/build/web"

if [[ -z "$AAB_FILE" ]]; then
  echo "No Android AppBundle found in $ARTIFACT_DIR"
  exit 1
fi

if [[ ! -d "$WEB_DIR" ]]; then
  echo "No web build directory found in $WEB_DIR"
  exit 1
fi

echo "Release channel: $RELEASE_CHANNEL"
echo "Canary percent: $CANARY_PERCENT"
echo "Rollback target: ${ROLLBACK_TO:-none}"
echo "Android artifact: $AAB_FILE"

if [[ -n "${FIREBASE_APP_ID_ANDROID:-}" && -n "${FIREBASE_TOKEN:-}" ]]; then
  echo "Deploying Android build through Firebase App Distribution"
  npm install -g firebase-tools
  firebase appdistribution:distribute "$AAB_FILE" \
    --app "$FIREBASE_APP_ID_ANDROID" \
    --token "$FIREBASE_TOKEN" \
    --groups "${FIREBASE_TESTER_GROUPS:-qa}"
else
  echo "Skipping Firebase Android deploy (missing FIREBASE_APP_ID_ANDROID or FIREBASE_TOKEN)"
fi

if [[ -n "${WEB_DEPLOY_TARGET:-}" ]]; then
  echo "Preparing web deploy package for target: $WEB_DEPLOY_TARGET"
  tar -czf web-release.tar.gz -C "$WEB_DIR" .
  echo "Web package created: web-release.tar.gz"
else
  echo "Skipping web deploy target (WEB_DEPLOY_TARGET not set)"
fi

echo "Deploy script completed"
