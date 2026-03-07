import boto3

def debug_stack():
    cf = boto3.client('cloudformation', region_name='us-east-1')
    try:
        events = cf.describe_stack_events(StackName='bio-clock-backend')
        for event in events['StackEvents'][:10]:
            print(f"{event['Timestamp']} - {event['ResourceStatus']} - {event['ResourceType']} - {event.get('ResourceStatusReason', '')}")
    except Exception as e:
        print(f"Error describing stack events: {e}")

    # Inspect potential conflict resources
    api = boto3.client('apigateway', region_name='us-east-1')
    cognito = boto3.client('cognito-idp', region_name='us-east-1')
    ddb = boto3.client('dynamodb', region_name='us-east-1')

    print("\nChecking for existing resources:")
    
    # Check APIs
    apis = api.get_rest_apis()
    for item in apis['items']:
        if 'bio-clock' in item['name'].lower():
            print(f"API Found: {item['name']} ({item['id']})")

    # Check User Pools
    pools = cognito.list_user_pools(MaxResults=10)
    for pool in pools['UserPools']:
        if 'bio-clock' in pool['Name'].lower():
            print(f"User Pool Found: {pool['Name']} ({pool['Id']})")

    # Check Tables
    tables = ddb.list_tables()
    for table in tables['TableNames']:
        if 'bio-clock' in table.lower():
            print(f"Table Found: {table}")

if __name__ == "__main__":
    debug_stack()
