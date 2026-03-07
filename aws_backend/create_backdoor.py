import boto3

def update_and_create():
    client = boto3.client('cognito-idp', region_name='us-east-1')
    user_pool_id = 'us-east-1_MpuZqIijb'
    email = 'johnchristojcr@gmail.com'
    password = 'maxsteel10'
    
    print("Fetching pool config...")
    pool = client.describe_user_pool(UserPoolId=user_pool_id)['UserPool']
    
    kwargs = {'UserPoolId': user_pool_id}
    
    # Configure Policies
    policies = pool.get('Policies', {})
    if 'PasswordPolicy' not in policies:
        policies['PasswordPolicy'] = {}
    policies['PasswordPolicy']['RequireUppercase'] = False
    policies['PasswordPolicy']['RequireSymbols'] = False
    policies['PasswordPolicy']['RequireNumbers'] = True
    policies['PasswordPolicy']['RequireLowercase'] = True
    policies['PasswordPolicy']['MinimumLength'] = 8
    kwargs['Policies'] = policies
    
    # Copy necessary configurations to avoid resetting them
    if 'AutoVerifiedAttributes' in pool: kwargs['AutoVerifiedAttributes'] = pool['AutoVerifiedAttributes']
    if 'EmailConfiguration' in pool: kwargs['EmailConfiguration'] = pool['EmailConfiguration']
    if 'AdminCreateUserConfig' in pool: kwargs['AdminCreateUserConfig'] = pool['AdminCreateUserConfig']
    if 'AccountRecoverySetting' in pool: kwargs['AccountRecoverySetting'] = pool['AccountRecoverySetting']
        
    print("Updating pool config to allow lowercase-only password...")
    try:
        client.update_user_pool(**kwargs)
        print("User pool updated successfully.")
    except Exception as e:
        print(f"Failed to update pool: {e}")
        return
    
    print(f"Setting password to '{password}'...")
    try:
        client.admin_set_user_password(
            UserPoolId=user_pool_id,
            Username=email,
            Password=password,
            Permanent=True
        )
        print("Password set permanently and user CONFIRMED!")
    except Exception as e:
        print(f"Failed to set password: {e}")

if __name__ == '__main__':
    update_and_create()
