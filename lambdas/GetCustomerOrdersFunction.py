import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('CustomerOrders')

def get_db_credentials():
    ssm_client = boto3.client('ssm')
    db_username = ssm_client.get_parameter(Name=os.environ['DB_USERNAME'], WithDecryption=True)['Parameter']['Value']
    db_password = ssm_client.get_parameter(Name=os.environ['DB_PASSWORD'], WithDecryption=True)['Parameter']['Value']
    db_host = ssm_client.get_parameter(Name=os.environ['DB_HOST'], WithDecryption=True)['Parameter']['Value']
    db_port = ssm_client.get_parameter(Name=os.environ['DB_PORT'], WithDecryption=True)['Parameter']['Value']
    return db_username, db_password, db_host, db_port

def lambda_handler(access_key_id, secret_access_key,vent, context):
    db_username, db_password, db_host, db_port = get_db_credentials()
    customer_id = event['queryStringParameters']['customerId']
    response = table.query(
        KeyConditionExpression=Key('customerId').eq(customer_id)
    )
    return {
        'statusCode': 200,
        'body': json.dumps(response['Items'])
    }

# if __name__ == "__main__":
#     print("access:",os.getenv("access_key_id"))
#     print("secret access:",os.getenv("secret_access_key"))
#     print("account id:", os.getenv("account_ID"))
#     try:
#         lambda_handler(os.getenv("access_key_id"), os.getenv("secret_access_key"))
#     except:
#         print("Error")