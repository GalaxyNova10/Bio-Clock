#!/usr/bin/env bash

# Bio-Clock AWS Serverless Deployment Script
# Target Region: us-east-1

set -e

echo "🚀 Starting deployment for Bio-Clock Backend..."

# 1. Build the SAM application
echo "🔨 Building SAM application..."
python -m samcli build

# 2. Deploy the SAM application
echo "☁️ Deploying to AWS us-east-1..."
python -m samcli deploy \
  --stack-name bio-clock-backend \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --resolve-s3 \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset

echo "✅ Deployment completed successfully!"
echo "--------------------------------------------------------"
echo "🔑 CLOUDFORMATION OUTPUTS (Update aws_config.dart with these):"
echo "--------------------------------------------------------"

# 3. Retrieve and display the stack outputs
aws cloudformation describe-stacks \
  --stack-name bio-clock-backend \
  --region us-east-1 \
  --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
  --output table

echo "--------------------------------------------------------"
echo "📝 NEXT STEPS:"
echo "1. Copy the Outputs above into lib/shared/core/aws_config.dart"
echo "2. Run 'flutter clean' and 'flutter pub get'"
echo "3. Run 'pod install' in the ios/ directory"
echo "4. Build the iOS app!"
echo "--------------------------------------------------------"
