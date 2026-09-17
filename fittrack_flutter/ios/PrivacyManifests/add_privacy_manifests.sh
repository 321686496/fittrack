#!/bin/sh
# ---------------------------------------------------------------------------
# ITMS-91061 fix: inject a PrivacyInfo.xcprivacy into each third-party SDK
# framework that ships inside the app bundle but lacks one.
#
# Why this is needed: this project builds with the Flutter 3.7.12 OHOS fork,
# whose bundled Flutter engine plus plugin / Google frameworks predate the
# App Store privacy-manifest requirement. Apple flags every such framework
# with ITMS-91061.
#
# This script runs as the LAST build phase, so every framework has already
# been embedded into <Runner.app>/Frameworks. It copies PrivacyInfo.xcprivacy
# into each flagged framework and re-signs the modified frameworks so their
# code signatures stay valid. It is idempotent: it skips frameworks that
# already carry a manifest and is a no-op on simulator / unsigned builds.
# ---------------------------------------------------------------------------

MANIFEST="${PROJECT_DIR}/PrivacyManifests/PrivacyInfo.xcprivacy"
FW_ROOT="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY}"

# Frameworks Apple flagged as missing a privacy manifest.
FRAMEWORKS="Flutter GTMSessionFetcher GoogleToolboxForMac image_picker_ios share_plus sqflite url_launcher_ios"

for FW in ${FRAMEWORKS}; do
  FW_DIR="${FW_ROOT}/${FW}.framework"
  [ -d "${FW_DIR}" ] || continue
  DEST="${FW_DIR}/PrivacyInfo.xcprivacy"
  [ -f "${DEST}" ] && continue
  cp "${MANIFEST}" "${DEST}"

  # Re-sign the modified framework so adding the resource does not
  # invalidate its existing signature.
  if [ "${CODE_SIGNING_ALLOWED}" != "NO" ] && [ -n "${IDENTITY}" ] && [ "${IDENTITY}" != "-" ]; then
    /usr/bin/codesign --force --sign "${IDENTITY}" --preserve-metadata=identifier,entitlements,runtime "${FW_DIR}" || exit 1
  fi
done