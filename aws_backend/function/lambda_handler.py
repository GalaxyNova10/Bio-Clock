import json
import os
import boto3
import uuid
import datetime
import re
import urllib.parse
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')
bedrock_client = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')

TABLE_NAME = os.environ.get('TABLE_NAME', 'bio-clock-inventory')
table = dynamodb.Table(TABLE_NAME)

def get_best_guess_fallback(labels):
    """
    Fallback algorithm if Bedrock fails/throttles. 
    Estimates shelf life based purely on Rekognition labels.
    """
    # A simple dictionary or heuristic-based mapping
    fallback_map = {
        'Tomato': 7,
        'Banana': 5,
        'Apple': 14,
        'Spinach': 4,
        'Milk': 10,
        'Carrot': 21,
        'Chicken': 3,
        'Bread': 7,
        'Cheese': 14
    }
    
    # Try to find a match in the labels
    item_name = "Unknown Food Item"
    expiry_days = 5  # default baseline
    storage_advice = "Store in a cool, dry place or refrigerate for safety."

    for label in labels:
        if label in fallback_map:
            item_name = label
            expiry_days = fallback_map[label]
            break
        # General categorizations
        if label.lower() in ['fruit', 'vegetable', 'produce']:
            item_name = "Fresh Produce"
            expiry_days = 7
    
    return {
        "item_name": item_name,
        "expiry_days": expiry_days,
        "storage_advice": storage_advice
    }

def lambda_handler(event, context):
    # ── API Gateway Routing ──
    if 'httpMethod' in event:
        method = event['httpMethod']
        path = event['path']
        print(f"Handling {method} request for {path}")

        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,Access-Control-Allow-Private-Network',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE',
            'Access-Control-Allow-Private-Network': 'true'
        }

        if method == 'OPTIONS':
            return {'statusCode': 200, 'headers': headers}

        # GET /inventory?userId=USER#...
        if path == '/inventory' and method == 'GET':
            user_id = (event.get('queryStringParameters') or {}).get('userId', 'USER#UNKNOWN')
            try:
                response = table.query(KeyConditionExpression=boto3.dynamodb.conditions.Key('PK').eq(user_id))
                items = response.get('Items', [])
                # Filter out STATS item
                items = [i for i in items if i.get('SK') != 'STATS']
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(items, default=str)
                }
            except Exception as e:
                return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}

        # GET /profile/stats?userId=USER#...
        if path == '/profile/stats' and method == 'GET':
            user_id = (event.get('queryStringParameters') or {}).get('userId', 'USER#UNKNOWN')
            try:
                response = table.get_item(Key={'PK': user_id, 'SK': 'STATS'})
                stats = response.get('Item', {})
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(stats, default=str)
                }
            except Exception as e:
                return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}

        # POST /auth/signin
        if path == '/auth/signin' and method == 'POST':
            try:
                body = json.loads(event.get('body', '{}'))
                username = body.get('email')
                password = body.get('password')
                
                client = boto3.client('cognito-idp')
                user_pool_id = os.environ.get('USER_POOL_ID', 'us-east-1_MpuZqIijb')
                client_id = os.environ.get('CLIENT_ID', '2m7q5tumcid5q13qvqdkm6tip5')
                
                res = client.admin_initiate_auth(
                    UserPoolId=user_pool_id,
                    ClientId=client_id,
                    AuthFlow='ADMIN_NO_SRP_AUTH',
                    AuthParameters={'USERNAME': username, 'PASSWORD': password}
                )
                auth_res = res.get('AuthenticationResult', {})
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({
                        'idToken': auth_res.get('IdToken'),
                        'accessToken': auth_res.get('AccessToken'),
                        'refreshToken': auth_res.get('RefreshToken')
                    })
                }
            except Exception as e:
                logger.error(f"Auth failed for {username}: {str(e)}")
                return {'statusCode': 401, 'headers': headers, 'body': json.dumps({'error': f"Unauthorized: {str(e)}"})}

        # POST /auth/refresh
        if path == '/auth/refresh' and method == 'POST':
            try:
                body = json.loads(event.get('body', '{}'))
                refresh_token = body.get('refreshToken')
                client = boto3.client('cognito-idp')
                user_pool_id = os.environ.get('USER_POOL_ID')
                client_id = os.environ.get('CLIENT_ID')
                
                res = client.admin_initiate_auth(
                    UserPoolId=user_pool_id,
                    ClientId=client_id,
                    AuthFlow='REFRESH_TOKEN_AUTH',
                    AuthParameters={'REFRESH_TOKEN': refresh_token}
                )
                auth_res = res.get('AuthenticationResult', {})
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({
                        'idToken': auth_res.get('IdToken'),
                        'accessToken': auth_res.get('AccessToken')
                    })
                }
            except Exception as e:
                return {'statusCode': 401, 'headers': headers, 'body': json.dumps({'error': str(e)})}

        # POST /auth/signup
        if path == '/auth/signup' and method == 'POST':
            try:
                body = json.loads(event.get('body', '{}'))
                email = body.get('email')
                password = body.get('password')
                full_name = body.get('fullName') or body.get('full_name') or 'User'
                
                client = boto3.client('cognito-idp')
                user_pool_id = os.environ.get('USER_POOL_ID', 'us-east-1_MpuZqIijb')
                
                # Simple admin creation for demo
                client.admin_create_user(
                    UserPoolId=user_pool_id,
                    Username=email,
                    UserAttributes=[
                        {'Name': 'email', 'Value': email}, 
                        {'Name': 'email_verified', 'Value': 'true'},
                        {'Name': 'name', 'Value': full_name}
                    ],
                    MessageAction='SUPPRESS'
                )
                client.admin_set_user_password(UserPoolId=user_pool_id, Username=email, Password=password, Permanent=True)
                
                return {'statusCode': 201, 'headers': headers, 'body': json.dumps({'message': 'User created'})}
            except Exception as e:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': str(e)})}

        return {'statusCode': 404, 'headers': headers, 'body': json.dumps({'error': 'Not Found'})}

    # ── S3 Event Processing ──
    print("Received S3 event:", json.dumps(event))
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        # URL decode the key (S3 events are url-encoded)
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])
        print(f"Processing object: s3://{bucket}/{key}")
        
        try:
            # 1. Extract labels via Rekognition
            rek_response = rekognition_client.detect_labels(
                Image={'S3Object': {'Bucket': bucket, 'Name': key}},
                MaxLabels=10,
                MinConfidence=70
            )
            
            labels = [label['Name'] for label in rek_response.get('Labels', [])]
            if not labels:
                print("No clear labels detected. Aborting.")
                continue
                
            identified_label = labels[0]
            print(f"Top Rekognition labels: {labels}")
            
            # 2. Prompt Claude 3 Haiku for Structured JSON output
            model_id = 'anthropic.claude-3-haiku-20240307-v1:0'
            prompt = (
                f"You are an expert food scientist. Analyze these image labels: {labels}. "
                "1. Identify the primary food item.\n"
                "2. Estimate its shelf life in days.\n"
                "3. If the item is fresh 'Produce' (fruit/vegetables), provide storage advice specifically focusing on optimal temperature (e.g. Fridge vs Room Temp). "
                "If it is 'Packaged' food, instruct the user to check the 'Best By' or expiration date printed on the packaging.\n"
                "Respond STRICTLY in JSON format with no markdown and exactly these keys: "
                '{"item_name": string, "expiry_days": int, "storage_advice": string}'
            )
            
            bedrock_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 300,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}]
                    }
                ]
            }
            
            result_json = None
            try:
                bedrock_response = bedrock_client.invoke_model(
                    modelId=model_id,
                    contentType='application/json',
                    accept='application/json',
                    body=json.dumps(bedrock_body)
                )
                
                response_body = json.loads(bedrock_response['body'].read())
                reply_text = response_body['content'][0]['text']
                
                # Robustly Extract JSON by stripping markdown and conversational text
                # We use a greedy regex .* to match from the first { to the last }
                match = re.search(r'\{.*\}', reply_text, re.DOTALL)
                if not match:
                    raise ValueError("Failed to locate any JSON braces in Bedrock response.")
                    
                json_str = match.group(0)
                result_json = json.loads(json_str)
                    
            except ClientError as bedrock_err:
                if bedrock_err.response['Error']['Code'] == 'AccessDeniedException':
                    logger.exception("Bedrock invocation failed with AccessDeniedException. Triggering fallback.")
                else:
                    logger.exception(f"Bedrock invocation failed with ClientError: {str(bedrock_err)}")
                result_json = get_best_guess_fallback(labels)
            except Exception as bedrock_err:
                logger.exception(f"Bedrock invocation failed or throttled: {str(bedrock_err)}. Triggering fallback.")
                # Fallback purely dependent on Rekognition
                result_json = get_best_guess_fallback(labels)
            
            # 3. Apply Q10 Thermodynamic Verdict (2.0 ^ (deltaT / 10.0))
            # Optimal temps: Produce (7C), Fridge (4C), Freezer (-18C), Room (25C)
            # Default to 25.0 if not known, but we scale RUL based on storage
            item_name = result_json.get('item_name', identified_label)
            base_expiry_days = float(result_json.get('expiry_days', 5))
            
            # Storage heuristic for Q10
            # If stored at Room (25C) instead of Fridge (4C), deltaT = 21.0
            # RUL = base * 2.0 ^ (-21.0 / 10.0)
            t_env = 25.0 # default
            t_opt = 4.0  # assumed reference for standard AI shelf-life
            
            storage_advice = result_json.get('storage_advice', 'Store appropriately.')
            if 'fridge' in storage_advice.lower() or 'refrigerate' in storage_advice.lower():
                t_env = 4.0
            if 'freezer' in storage_advice.lower():
                t_env = -18.0
            
            delta_t = float(t_env - t_opt)
            q10_factor = 2.0 ** (-delta_t / 10.0)
            final_expiry_days = base_expiry_days * q10_factor
            
            rul_minutes = int(final_expiry_days * 24 * 60)
            print(f"Q10 Breakdown: Base={base_expiry_days}d, dT={delta_t}, Factor={q10_factor:.2f}, Final={final_expiry_days:.2f}d")
            
            # Extract user_id from key (e.g., public/SUB/...)
            path_parts = key.split('/')
            user_id = 'USER#UNKNOWN'
            if len(path_parts) > 1 and path_parts[1] != 'unknown':
                raw_sub = path_parts[1]
                user_id = f"USER#{raw_sub}"
                    
            item_id = f"ITEM#{uuid.uuid4()}"
            timestamp = datetime.datetime.utcnow().isoformat()
            
            db_item = {
                'PK': user_id,
                'SK': item_id,
                'name': item_name,
                'rul': rul_minutes,
                'storage_advice': storage_advice,
                'status': 'fresh',
                'confidence': 90, # derived mostly from Rekognition/LLM certainty
                's3_key': key,
                'created_at': timestamp
            }
            
            try:
                table.put_item(Item=db_item)
                print(f"Successfully processed and saved ITEM {item_name} (RUL: {final_expiry_days:.2f} days) for {user_id}")
            except Exception as e:
                logger.exception(f"DynamoDB put_item failed: {str(e)}")
                raise
            
        except Exception as e:
            logger.exception(f"Critical error processing record {key}: {str(e)}")
            # Do not raise here so batch processing continues for other records

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,Access-Control-Allow-Private-Network',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            'Access-Control-Allow-Private-Network': 'true'
        },
        'body': json.dumps('Event Processing complete')
    }
