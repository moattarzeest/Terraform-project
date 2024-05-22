import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UpdateProductInfo')

def lambda_handler(event, context):
    order = json.loads(event['body'])
    #Updating Stock here
    table.update_item(
        Key={'productId': order['productId']},
        UpdateExpression="SET stock = stock - :qty",
        ExpressionAttributeValues={':qty': order['quantity']}
    )
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Stock updated successfully'})
    }
