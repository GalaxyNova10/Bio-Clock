import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('TABLE_NAME', 'bio-clock-inventory')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    try:
        body_str = event.get('body')
        if not body_str:
            return {'statusCode': 400, 'headers': {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key', 'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'}, 'body': json.dumps('Missing body')}
            
        body = json.loads(body_str)
        user_id = body.get('userId')
        item_id = body.get('itemId')
        
        if not user_id or not item_id:
            return {'statusCode': 400, 'headers': {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key', 'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'}, 'body': json.dumps('Missing userId or itemId')}
            
        # 1. Update the item's status to isDonated = true
        table.update_item(
            Key={'PK': user_id, 'SK': item_id},
            UpdateExpression="SET isDonated = :val, #status = :status",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={":val": True, ":status": "donated"}
        )
        
        # 2. Increment ImpactPoints in the user stats (same table, SK = STATS)
        stats_sk = "STATS"
        table.update_item(
            Key={'PK': user_id, 'SK': stats_sk},
            UpdateExpression="ADD ImpactPoints :inc, ItemsDonated :inc",
            ExpressionAttributeValues={":inc": 1}
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'message': 'Donation processed successfully'})
        }
    except Exception as e:
        print(f"Error processing donation: {e}")
        return {'statusCode': 500, 'headers': {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key', 'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'}, 'body': json.dumps(f'Internal error: {str(e)}')}
