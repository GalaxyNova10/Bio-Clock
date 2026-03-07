#!/usr/bin/env bash

# Bio-Clock Automated Config Sync
# Target Region: us-east-1

set -e

STACK_NAME="bioclock-stack"
REGION="us-east-1"
CONFIG_FILE="../bio-clock-flutter-repo/lib/shared/core/aws_config.dart"

echo "🔄 Querying CloudFormation outputs for $STACK_NAME..."

# Fetch exact string values from the stack outputs
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='CognitoUserPoolId'].OutputValue" --output text)
CLIENT_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='CognitoClientId'].OutputValue" --output text)
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text)
API_GW_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" --output text)

if [ -z "$USER_POOL_ID" ] || [ "$USER_POOL_ID" == "None" ]; then
  echo "❌ Error: Could not retrieve CloudFormation outputs. Ensure '$STACK_NAME' is deployed."
  exit 1
fi

echo "📝 Overwriting placeholders in lib/shared/core/aws_config.dart..."

# Replace placeholders using | as the sed delimiter to safely parse URLs
sed -i.bak "s|'<CognitoUserPoolId_FROM_CLOUDFORMATION>'|'$USER_POOL_ID'|g" "$CONFIG_FILE"
sed -i.bak "s|'<CognitoClientId_FROM_CLOUDFORMATION>'|'$CLIENT_ID'|g" "$CONFIG_FILE"
sed -i.bak "s|'<S3BucketName_FROM_CLOUDFORMATION>'|'$S3_BUCKET'|g" "$CONFIG_FILE"

if [ -n "$API_GW_URL" ] && [ "$API_GW_URL" != "None" ]; then
  sed -i.bak "s|'https://<ApiGatewayId_FROM_CLOUDFORMATION>.execute-api.us-east-1.amazonaws.com/prod'|'$API_GW_URL'|g" "$CONFIG_FILE"
fi

# Automatically enable the cloud backend boolean
sed -i.bak "s|static const bool useCloudBackend = false;|static const bool useCloudBackend = true;|g" "$CONFIG_FILE"

# Clean up sed backup on mac/linux
rm -f "${CONFIG_FILE}.bak"

echo "✅ Sync complete! 'useCloudBackend' is now TRUE."
