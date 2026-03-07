import boto3
import requests
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: python verify_production.py <password>")
        sys.exit(1)
        
    password = sys.argv[1]
    email = "johnchristojcr@gmail.com"
    client_id = "2m7q5tumcid5q13qvqdkm6tip5"
    api_url = "https://dqt4avjib8.execute-api.us-east-1.amazonaws.com/Prod/inventory"

    print(f"Authenticating '{email}' with Cognito...")
    client = boto3.client('cognito-idp', region_name='us-east-1')
    
    try:
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': email,
                'PASSWORD': password
            }
        )
        token = response['AuthenticationResult']['IdToken']
        print("JWT IdToken acquired successfully.")
    except Exception as e:
        print(f"Authentication failed: {e}")
        sys.exit(1)

    print(f"Testing API Handshake: GET {api_url}")
    try:
        res = requests.get(api_url, headers={"Authorization": f"Bearer {token}"})
        print(f"Response Status: {res.status_code}")
        if res.status_code == 200:
            print("SUCCESS! 401 Unauthorized error is officially fixed.")
            print("Payload:", res.json())
        else:
            print("API failed.")
            print(res.text)
    except Exception as e:
        print(f"Request failed: {e}")

if __name__ == "__main__":
    main()
