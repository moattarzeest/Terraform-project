import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('CustomerOrders')

def lambda_handler(event, context):
    for record in event['Records']:
        order = json.loads(record['body'])
        table.put_item(Item=order)
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Order processed successfully'})
    }
