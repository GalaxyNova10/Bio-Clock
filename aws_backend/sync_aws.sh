#!/usr/bin/env bash

# Bio-Clock Automated Config Sync for Android/Web
# Target Region: us-east-1

set -e

STACK_NAME="bioclock-stack"
REGION="us-east-1"
CONFIG_FILE="../bio-clock-flutter-repo/lib/shared/core/aws_config.dart"

echo "🔄 Pulling CloudFormation outputs from $STACK_NAME..."

USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='CognitoUserPoolId'].OutputValue" --output text || echo "")
CLIENT_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='CognitoClientId'].OutputValue" --output text || echo "")
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text || echo "")
API_GW_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" --output text || echo "")

if [ -z "$USER_POOL_ID" ] || [ "$USER_POOL_ID" == "None" ]; then
  echo "❌ Error: Could not pull outputs. Is '$STACK_NAME' deployed in $REGION?"
  exit 1
fi

echo "📝 Updating lib/shared/core/aws_config.dart..."

# Safe string replacement using sed with | as the delimiter
sed -i.bak "s|'<CognitoUserPoolId_FROM_CLOUDFORMATION>'|'$USER_POOL_ID'|g" "$CONFIG_FILE"
sed -i.bak "s|'<CognitoClientId_FROM_CLOUDFORMATION>'|'$CLIENT_ID'|g" "$CONFIG_FILE"
sed -i.bak "s|'<S3BucketName_FROM_CLOUDFORMATION>'|'$S3_BUCKET'|g" "$CONFIG_FILE"

if [ -n "$API_GW_URL" ] && [ "$API_GW_URL" != "None" ]; then
  sed -i.bak "s|'https://<ApiGatewayId_FROM_CLOUDFORMATION>.execute-api.us-east-1.amazonaws.com/prod'|'$API_GW_URL'|g" "$CONFIG_FILE"
fi

# Flip the switch to use real backend
sed -i.bak "s|static const bool useCloudBackend = false;|static const bool useCloudBackend = true;|g" "$CONFIG_FILE"

# Clean up
rm -f "${CONFIG_FILE}.bak"

echo "✅ AWS Config Sync Complete! 'useCloudBackend' is now true. Mocks are disabled."
