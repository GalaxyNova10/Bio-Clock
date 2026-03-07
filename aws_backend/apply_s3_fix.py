import boto3
import json

REGION = 'us-east-1'
BUCKET_NAME = 'bioclock-scans-882574059997-us-east-1'

def apply_s3_policy():
    s3 = boto3.client('s3', region_name=REGION)
    
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowAuthenticatedUploads",
                "Effect": "Allow",
                "Principal": "*",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject"
                ],
                "Resource": f"arn:aws:s3:::{BUCKET_NAME}/public/*"
            }
        ]
    }
    
    # Adding CORS as well just in case
    cors_configuration = {
        'CORSRules': [
            {
                'AllowedHeaders': ['*'],
                'AllowedMethods': ['PUT', 'POST', 'GET'],
                'AllowedOrigins': ['*'],
                'MaxAgeSeconds': 3000
            }
        ]
    }

    try:
        print(f"Applying Policy to {BUCKET_NAME}...")
        s3.put_bucket_policy(Bucket=BUCKET_NAME, Policy=json.dumps(policy))
        print("Policy applied successfully.")
        
        print("Applying CORS configuration...")
        s3.put_bucket_cors(Bucket=BUCKET_NAME, CORSConfiguration=cors_configuration)
        print("CORS configuration applied successfully.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    apply_s3_policy()
