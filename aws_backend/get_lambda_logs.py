import boto3
import time

def get_logs():
    logs = boto3.client('logs', region_name='us-east-1')
    cf = boto3.client('cloudformation', region_name='us-east-1')
    
    # Get physical ID of the Lambda
    resources = cf.list_stack_resources(StackName='bio-clock-backend-v3')
    lambda_name = next(r['PhysicalResourceId'] for r in resources['StackResourceSummaries'] if r['LogicalResourceId'] == 'ScanProcessorFunction')
    
    log_group = f"/aws/lambda/{lambda_name}"
    print(f"Checking logs for: {log_group}")
    
    try:
        streams = logs.describe_log_streams(logGroupName=log_group, orderBy='LastEventTime', descending=True, limit=1)
        if not streams['logStreams']:
            print("No log streams found.")
            return

        stream_name = streams['logStreams'][0]['logStreamName']
        events = logs.get_log_events(logGroupName=log_group, logStreamName=stream_name, limit=20)
        
        for event in events['events']:
            print(f"{time.strftime('%H:%M:%S', time.gmtime(event['timestamp']/1000.0))} - {event['message'].strip()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    get_logs()
