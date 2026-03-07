import boto3
import sys

def get_sub():
    client = boto3.client('cognito-idp', region_name='us-east-1')
    res = client.admin_get_user(UserPoolId='us-east-1_MpuZqIijb', Username='johnchristojcr@gmail.com')
    for attr in res['UserAttributes']:
        if attr['Name'] == 'sub':
            print(attr['Value'])
            return
    print("No sub found")

if __name__ == '__main__':
    get_sub()
