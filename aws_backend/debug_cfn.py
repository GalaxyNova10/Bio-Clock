import boto3

def get_cfn_errors():
    client = boto3.client('cloudformation', region_name='us-east-1')
    try:
        res = client.list_change_sets(StackName='bio-clock-backend')
        for c in res.get('Summaries', []):
            if c['Status'] == 'FAILED':
                print(f"ChangeSet: {c['ChangeSetName']}")
                print(f"Reason: {c.get('StatusReason')}")
                print("-" * 40)
    except Exception as e:
        print(f"Error querying stack events: {e}")

if __name__ == "__main__":
    get_cfn_errors()
