import boto3
import uuid
import datetime
import os

REGION = 'us-east-1'
TABLE_NAME = 'bio-clock-inventory'
USER_ID = 'USER#54786458-e041-70b4-a94f-821d2d9010cf'

def seed_demo_data():
    try:
        cf = boto3.client('cloudformation', region_name=REGION)
        res = cf.describe_stacks(StackName='bioclock-stack')
        for out in res['Stacks'][0]['Outputs']:
            if out['OutputKey'] == 'DynamoDBTableName':
                global TABLE_NAME
                TABLE_NAME = out['OutputValue']
    except Exception:
        pass

    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(TABLE_NAME)

    now = datetime.datetime.utcnow()
    
    # 7 Items showcasing different RULs and states for the color-coded UI demo
    demo_items = [
        {
            "name": "Fresh Spinach",
            "rul": 48 * 60, # 48 hours
            "status": "fresh",
            "storage": "fridge",
            "addedAt": now - datetime.timedelta(hours=4)
        },
        {
            "name": "Tomatoes",
            "rul": 18 * 60, # 18 hours
            "status": "ripening",
            "storage": "room",
            "addedAt": now - datetime.timedelta(hours=8)
        },
        {
            "name": "Bananas",
            "rul": 24 * 60, # 24 hours
            "status": "ripening",
            "storage": "room",
            "addedAt": now - datetime.timedelta(hours=6)
        },
        {
            "name": "Avocado",
            "rul": 6 * 60, # 6 hours (soon rotten warning)
            "status": "soon_rotten",
            "storage": "room",
            "addedAt": now - datetime.timedelta(days=2)
        },
        {
            "name": "Carrots",
            "rul": 80 * 60,
            "status": "fresh",
            "storage": "fridge",
            "addedAt": now - datetime.timedelta(hours=12)
        },
        {
            "name": "Strawberries",
            "rul": 0, # Expired
            "status": "rotten",
            "storage": "fridge",
            "addedAt": now - datetime.timedelta(days=5)
        },
        {
            "name": "Bell Pepper",
            "rul": 60 * 60,
            "status": "fresh",
            "storage": "fridge",
            "addedAt": now - datetime.timedelta(hours=3)
        }
    ]

    print(f"Seeding 7 demo items to {TABLE_NAME} for {USER_ID}...")

    for item in demo_items:
        item_id = f"ITEM#{uuid.uuid4()}"
        try:
            table.put_item(
                Item={
                    'PK': USER_ID,
                    'SK': item_id,
                    'name': item['name'],
                    'rul': item['rul'],
                    'status': item['status'],
                    'storage_advice': 'Demo automatically generated storage advice.',
                    'storage': item['storage'],
                    'created_at': item['addedAt'].isoformat()
                }
            )
            print(f"  Added {item['name']} ({item['status']})")
        except Exception as e:
            print(f"  Failed to add {item['name']}: {e}")

    # Seed the stats row for realism
    print("Seeding user stats row...")
    try:
        table.put_item(
            Item={
                'PK': USER_ID,
                'SK': "STATS",
                'ImpactPoints': 25,
                'ItemsDonated': 2
            }
        )
        print("  Added STATS row.")
    except Exception as e:
        print(f"  Failed to add STATS: {e}")

    print("\nSeeding Complete! View them by logging in as DEMO_SEED_01 or modifying the USER_ID.")

if __name__ == "__main__":
    seed_demo_data()
