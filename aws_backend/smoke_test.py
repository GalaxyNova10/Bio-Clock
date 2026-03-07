import boto3
import json
import uuid
import time
import os

# Target configuration
REGION = 'us-east-1'
# Initialize AWS clients
s3_client = boto3.client('s3', region_name=REGION)
lambda_client = boto3.client('lambda', region_name=REGION)
dynamodb = boto3.resource('dynamodb', region_name=REGION)

def get_stack_outputs(stack_name='bio-clock-backend'):
    """Fetch the deployed stack outputs to auto-discover bucket and table names."""
    try:
        cf_client = boto3.client('cloudformation', region_name=REGION)
        response = cf_client.describe_stacks(StackName=stack_name)
        outputs = {out['OutputKey']: out['OutputValue'] for out in response['Stacks'][0]['Outputs']}
        return outputs
    except Exception as e:
        print(f"Error fetching stack outputs (is the stack deployed?): {e}")
        return None

def run_smoke_test():
    print("🚀 Starting Bio-Clock Backend Smoke Test...\n")
    
    outputs = get_stack_outputs()
    if not outputs:
        print("❌ Cannot proceed without stack outputs.")
        return
        
    bucket_name = outputs.get('S3BucketName')
    table_name = outputs.get('DynamoDBTableName')
    
    if not bucket_name or not table_name:
        print("❌ Missing required stack outputs (S3BucketName or DynamoDBTableName).")
        return
        
    print(f"📦 Target S3 Bucket: {bucket_name}")
    print(f"🗄️ Target DynamoDB Table: {table_name}")
    
    # 1. Create a dummy image file (1x1 pixel JPEG or just text pretending to be an image)
    # Ideally, supply a real image path here for Rekognition to actually work!
    # For this smoke test, we'll try to use a local test image if it exists.
    test_image_path = 'test_banana.jpg'
    
    # If the file doesn't exist, we'll create a dummy text file to trigger the Lambda
    # Note: Rekognition will fail on a text file, which is perfect for testing the 'Fallback' logic!
    if not os.path.exists(test_image_path):
        print(f"⚠️ {test_image_path} not found. Creating a dummy file to test the Bedrock/Rekognition fallback mechanism.")
        with open(test_image_path, 'wb') as f:
            f.write(b"Not a real image. Testing fallback logic.")
            
    test_user_id = "USER#SMOKE_TEST_01"
    object_key = f"{test_user_id}/scan_{int(time.time())}.jpg"
    
    # 2. Upload file to S3
    print(f"\n📤 Uploading test file to s3://{bucket_name}/{object_key} ...")
    try:
        s3_client.upload_file(test_image_path, bucket_name, object_key)
        print("✅ Upload successful. S3 ObjectCreated event should now trigger the Lambda.")
    except Exception as e:
        print(f"❌ S3 Upload failed: {e}")
        return
        
    # 3. Wait for Lambda to process
    print("⏳ Waiting 10 seconds for Lambda and Bedrock to process the image...")
    time.sleep(10)
    
    # 4. Verify DynamoDB for the written record
    print(f"🔍 Checking DynamoDB table '{table_name}' for records belonging to {test_user_id}...")
    try:
        table = dynamodb.Table(table_name)
        response = table.query(
            KeyConditionExpression="PK = :pk",
            ExpressionAttributeValues={":pk": test_user_id}
        )
        
        items = response.get('Items', [])
        if not items:
            print("❌ No items found in DynamoDB. The Lambda may have failed or is still processing.")
            print("Action: Check CloudWatch Logs for the ScanProcessorFunction.")
        else:
            print(f"✅ Success! Found {len(items)} item(s) in DynamoDB:")
            for item in items:
                print(json.dumps(item, indent=2, default=str))
                
    except Exception as e:
        print(f"❌ DynamoDB Query failed: {e}")

if __name__ == "__main__":
    run_smoke_test()
