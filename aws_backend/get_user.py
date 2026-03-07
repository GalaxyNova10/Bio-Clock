import boto3
import sys

def create_and_get_demo_user():
    client = boto3.client('cognito-idp', region_name='us-east-1')
    pool_id = 'us-east-1_MpuZqIijb'
    email = 'demo@bioclock.app'
    
    try:
        response = client.admin_create_user(
            UserPoolId=pool_id,
            Username=email,
            UserAttributes=[{'Name': 'email', 'Value': email}, {'Name': 'email_verified', 'Value': 'true'}],
            MessageAction='SUPPRESS'
        )
        sub = next((attr['Value'] for attr in response['User']['Attributes'] if attr['Name'] == 'sub'), None)
        print(f"Created user with sub: {sub}")
        
        client.admin_set_user_password(
            UserPoolId=pool_id,
            Username=email,
            Password='Password123!',
            Permanent=True
        )
        print("Set password successfully.")
        
        # Output sub to file so we can read it easily
        with open('demo_sub.txt', 'w') as f:
            f.write(sub)
            
    except client.exceptions.UsernameExistsException:
        print("User already exists. Fetching sub...")
        res = client.admin_get_user(UserPoolId=pool_id, Username=email)
        sub = next((attr['Value'] for attr in res['UserAttributes'] if attr['Name'] == 'sub'), None)
        print(f"Existing sub: {sub}")
        with open('demo_sub.txt', 'w') as f:
            f.write(sub)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_and_get_demo_user()
