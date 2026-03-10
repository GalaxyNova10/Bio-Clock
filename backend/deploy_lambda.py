import boto3
import os
import zipfile

def deploy():
    session = boto3.Session(
        aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
        region_name=os.environ.get('AWS_REGION', 'us-east-1')
    )
    client = session.client('lambda')
    
    try:
        functions = client.list_functions()['Functions']
        if not functions:
            print("No functions found!")
            return
        
        target = functions[0]['FunctionName']
        print(f"Dynamically Deploying to: {target}")

        zip_path = 'function.zip'
        with zipfile.ZipFile(zip_path, 'w') as zf:
            zf.write('lambda_handler.py')

        print("Updating function code...")
        with open(zip_path, 'rb') as f:
            response = client.update_function_code(
                FunctionName=target,
                ZipFile=f.read()
            )
        
        print(f"Deployment Successful! Last Update: {response.get('LastModified')}")
    except Exception as e:
        print(f"Error during deployment: {e}")

if __name__ == '__main__':
    deploy()
