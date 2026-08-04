#!/usr/bin/env bash
set -euo pipefail

echo "Starting deploy_release.sh"

RELEASE_CHANNEL="${RELEASE_CHANNEL:-stable}"

ARTIFACT_DIR="release-artifacts"
AAB_FILE=$(find "$ARTIFACT_DIR" -type f -name "*.aab" | head -n 1 || true)

if [[ -z "$AAB_FILE" ]]; then
  echo "No Android AppBundle found in $ARTIFACT_DIR"
  exit 1
fi

echo "Release channel: $RELEASE_CHANNEL"
echo "Android artifact: $AAB_FILE"

: "${FIREBASE_APP_ID_ANDROID:?FIREBASE_APP_ID_ANDROID is required for closed-beta distribution}"
: "${FIREBASE_TOKEN:?FIREBASE_TOKEN is required for closed-beta distribution}"
: "${FIREBASE_TESTER_GROUPS:?FIREBASE_TESTER_GROUPS is required for closed-beta distribution}"

echo "Distributing Android build through Firebase App Distribution"
npx --yes firebase-tools@13.31.2 appdistribution:distribute "$AAB_FILE" \
  --app "$FIREBASE_APP_ID_ANDROID" \
  --token "$FIREBASE_TOKEN" \
  --groups "$FIREBASE_TESTER_GROUPS"

echo "Deploy script completed"
