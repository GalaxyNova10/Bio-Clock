import boto3
import json

def get_outputs(stack_name):
    cf = boto3.client('cloudformation', region_name='us-east-1')
    try:
        response = cf.describe_stacks(StackName=stack_name)
        outputs = response['Stacks'][0].get('Outputs', [])
        print(json.dumps(outputs, indent=2))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    get_outputs('bio-clock-backend-v3')
