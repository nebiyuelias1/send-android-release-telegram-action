#!/bin/bash
set -e

echo "📦 Starting Android build and Telegram send..."

TOKEN="$INPUT_BOT_TOKEN"
CHAT_ID="$INPUT_CHAT_ID"
MESSAGE="$INPUT_MESSAGE"
KEYSTORE_BASE64="$INPUT_KEYSTORE_BASE64"
KEYSTORE_PASSWORD="$INPUT_KEYSTORE_PASSWORD"
KEY_ALIAS="$INPUT_KEY_ALIAS"
KEY_PASSWORD="$INPUT_KEY_PASSWORD"
BUILD_TYPE="${INPUT_BUILD_TYPE:-apk}" # Default to APK if not specified

# Print inputs
echo "Telegram Chat: $CHAT_ID"
echo "Build message: $MESSAGE"
echo "Build type: $BUILD_TYPE"

# Write and decode the keystore
echo "$KEYSTORE_BASE64" | base64 -d > ./app/keystore.jks

# Export environment variables for Gradle signing config
export KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"
export KEY_ALIAS="$KEY_ALIAS"
export KEY_PASSWORD="$KEY_PASSWORD"

# Make gradlew executable
chmod +x ./gradlew

# Clone repo source into the container's workspace (mounted automatically)
echo "🔧 Running Gradle assembleRelease..."
if [ "$BUILD_TYPE" == "aab" ]; then
  ./gradlew bundleRelease
  ARTIFACT_PATH=$(find ./app/build/outputs/bundle/release -name "*.aab" | head -n 1) # changed APKPATH to ARTIFACT_PATH for a more generic variable naming it could mean .apk or .aab file.
else
  ./gradlew assembleRelease
  ARTIFACT_PATH=$(find ./app/build/outputs/apk/release -name "*.apk" | head -n 1)
fi

if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "❌ APK not found at $ARTIFACT_PATH"
  exit 1
fi

echo "✅ Build complete: $ARTIFACT_PATH"
echo "📤 Sending to Telegram..."

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" \
  -F chat_id="$CHAT_ID" \
  -F caption="$MESSAGE" \
  -F document=@"$ARTIFACT_PATH" \
  -F parse_mode="Markdown"

echo "✅ APK sent successfully."
