import json
import boto3

sqs = boto3.client('sqs')

def lambda_handler(event, context):
    order = json.loads(event['body'])
    sqs.send_message(
        QueueUrl='SQS_QUEUE_URL',  
        MessageBody=json.dumps(order)
    )
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Order has been created successfully'})
    }
