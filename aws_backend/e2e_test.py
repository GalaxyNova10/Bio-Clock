import boto3
import time
import os
import sys

# Target Configuration
REGION = 'us-east-1'
STACK_NAME = 'bioclock-stack'

s3_client = boto3.client('s3', region_name=REGION)
dynamodb = boto3.resource('dynamodb', region_name=REGION)

def get_cf_output(key):
    try:
        cf = boto3.client('cloudformation', region_name=REGION)
        res = cf.describe_stacks(StackName=STACK_NAME)
        for out in res['Stacks'][0]['Outputs']:
            if out['OutputKey'] == key:
                return out['OutputValue']
        return None
    except Exception as e:
        print(f"Error fetching CloudFormation Stack: {e}")
        return None

def run_e2e_verification():
    print("🚀 Running End-to-End Verification to Claude 4.5...")
    
    bucket_name = get_cf_output('S3BucketName')
    table_name = get_cf_output('DynamoDBTableName')

    if not bucket_name or not table_name:
        table_name = 'bio-clock-inventory'
        # Fallback if stack name differs
        bucket_name = input("Bucket name not found. Enter your S3 bucket name manually: ")

    user_id = 'USER#E2E_CLAUDE_TEST'
    test_image_path = 'local_e2e_image.jpg'
    
    # 1. Create a dummy test image if needed
    if not os.path.exists(test_image_path):
        with open(test_image_path, 'wb') as f:
            f.write(b"simulating an image upload")
            
    object_key = f"{user_id}/scan_e2e.jpg"
    
    # 2. Upload file to S3
    print(f"📤 Uploading test scan to s3://{bucket_name}/{object_key}...")
    try:
        s3_client.upload_file(test_image_path, bucket_name, object_key)
    except Exception as e:
        print(f"❌ Upload failed: {e}")
        sys.exit(1)
        
    # 3. Wait 5 seconds
    print("⏳ Waiting 5 seconds for Lambda -> Rekognition -> Claude 4.5 invocation...")
    time.sleep(5)
    
    # 4. Query DynamoDB
    print(f"🔍 Searching DynamoDB table '{table_name}'...")
    try:
        table = dynamodb.Table(table_name)
        response = table.query(
            KeyConditionExpression="PK = :pk",
            ExpressionAttributeValues={":pk": user_id}
        )
        
        items = response.get('Items', [])
        if not items:
            print("❌ Processing failed. No items found. Check Lambda CloudWatch logs.")
        else:
            # Sort to get the most recent processed item
            items.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            latest_item = items[0]
            
            print("\n✅ End-to-End Success! Claude 4.5 Result:")
            print("==================================================")
            print(f"Item Name: {latest_item.get('name', 'N/A')}")
            print(f"RUL: {latest_item.get('rul', 0)} minutes")
            print(f"Storage Advice: {latest_item.get('storage_advice', 'No advice found.')}")
            print("==================================================")
            
    except Exception as e:
        print(f"❌ DynamoDB query failed: {e}")

if __name__ == "__main__":
    run_e2e_verification()
