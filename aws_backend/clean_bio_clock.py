import boto3

def clean_resources():
    cognito = boto3.client('cognito-idp', region_name='us-east-1')
    ddb = boto3.client('dynamodb', region_name='us-east-1')

    # Check for User Pools
    print("Cleaning User Pools...")
    pools = cognito.list_user_pools(MaxResults=10)
    for pool in pools['UserPools']:
        if 'bio-clock' in pool['Name'].lower():
            print(f"Deleting User Pool: {pool['Name']} ({pool['Id']})...")
            try:
                cognito.delete_user_pool(UserPoolId=pool['Id'])
                print("Deleted.")
            except Exception as e:
                print(f"Error deleting user pool: {e}")

    # Check for Tables
    print("\nCleaning Tables...")
    tables = ddb.list_tables()
    for table in tables['TableNames']:
        if 'bio-clock' in table.lower():
            print(f"Deleting Table: {table}...")
            try:
                ddb.delete_table(TableName=table)
                print("Deleted.")
            except Exception as e:
                print(f"Error deleting table: {e}")

if __name__ == "__main__":
    clean_resources()
