#!/usr/bin/env bash

# Bio-Clock Automated Config Sync for Us-East-1 Serverless Stack
# This script retrieves stack outputs and automatically injects them into the Flutter config.

set -e

STACK_NAME="bioclock-stack"
REGION="us-east-1"
CONFIG_FILE="../bio-clock-flutter-repo/lib/shared/core/aws_config.dart"

echo "🔄 Fetching outputs from $STACK_NAME in $REGION..."

USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='CognitoUserPoolId'].OutputValue" --output text || echo "")
CLIENT_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='CognitoClientId'].OutputValue" --output text || echo "")
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text || echo "")
API_GW_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" --output text || echo "")

if [ -z "$USER_POOL_ID" ] || [ "$USER_POOL_ID" == "None" ]; then
  echo "❌ Error: Could not pull outputs. Is '$STACK_NAME' deployed?"
  exit 1
fi

echo "📝 Injecting IDs into $CONFIG_FILE..."

# Backup created automatically by sed -i.bak (macOS compatible format)
sed -i.bak "s|'<CognitoUserPoolId_FROM_CLOUDFORMATION>'|'$USER_POOL_ID'|g" "$CONFIG_FILE"
sed -i.bak "s|'<CognitoClientId_FROM_CLOUDFORMATION>'|'$CLIENT_ID'|g" "$CONFIG_FILE"
sed -i.bak "s|'<S3BucketName_FROM_CLOUDFORMATION>'|'$S3_BUCKET'|g" "$CONFIG_FILE"

if [ -n "$API_GW_URL" ] && [ "$API_GW_URL" != "None" ]; then
  sed -i.bak "s|'https://<ApiGatewayId_FROM_CLOUDFORMATION>.execute-api.us-east-1.amazonaws.com/prod'|'$API_GW_URL'|g" "$CONFIG_FILE"
fi

# Enable the Cloud Backend flag for the Flutter app
echo "🔌 Enabling Cloud Backend in Flutter config..."
sed -i.bak "s|static const bool useCloudBackend = false;|static const bool useCloudBackend = true;|g" "$CONFIG_FILE"

rm -f "${CONFIG_FILE}.bak"

echo "✅ One-Click Sync Complete! Mocks disabled, pointing to live $REGION endpoints."
