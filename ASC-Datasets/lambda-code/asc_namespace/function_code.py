from datetime import datetime
import json
import boto3
import time
import os

# Constants
LOG_GROUP_NAME = f"/aws/lambda/{os.environ['AWS_LAMBDA_FUNCTION_NAME']}"

# Create boto3 logs client once
logs_client = boto3.client('logs')

def generate_stream_name(namespace, operation):
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    return f"{namespace}-{operation}-{timestamp}"

def put_log(message, stream_name, sequence_token=None):
    try:
        logs_client.create_log_stream(
            logGroupName=LOG_GROUP_NAME,
            logStreamName=stream_name
        )
    except logs_client.exceptions.ResourceAlreadyExistsException:
        if sequence_token is None:
            response = logs_client.describe_log_streams(
                logGroupName=LOG_GROUP_NAME,
                logStreamNamePrefix=stream_name
            )
            streams = response.get("logStreams", [])
            if not streams:
                raise Exception(f"Log stream {stream_name} not found.")
            sequence_token = streams[0].get("uploadSequenceToken")

    log_event = {
        'logGroupName': LOG_GROUP_NAME,
        'logStreamName': stream_name,
        'logEvents': [{
            'timestamp': int(time.time() * 1000),
            'message': message
        }]
    }

    if sequence_token:
        log_event['sequenceToken'] = sequence_token

    response = logs_client.put_log_events(**log_event)
    return response.get('nextSequenceToken')

def convert_datetime(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError("Type not serializable")

def is_empty(val):
    return val is None or val == "" or val == {} or val == []

def lambda_handler(event, context):
    action = event["tf"]["action"]
    namespace = event.get('namespace', 'unknown')

    # Setup custom stream name
    stream_name = generate_stream_name(namespace, action)
    sequence_token = None

    def log(msg):
        nonlocal sequence_token
        sequence_token = put_log(msg, stream_name, sequence_token)

    if action in ["create", "update"]:
        required_fields = ['instanceId', 'namespace', 'description']
        fields_to_check = ['namespace', 'instanceId', 'tags']

        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        tags = event.get("tags", {})
        client = boto3.client('supplychain')
        update_namespace = False

        try:
            prev_input = event["tf"].get("prev_input")
            if prev_input:
                diff_detected = False
                for field in fields_to_check:
                    if field == "tags":
                        if event.get("tags", "{}") != prev_input.get("tags", "{}"):
                            diff_detected = True
                            log("Atleast TAGS field changed. Deleting namespace to make the update.")
                            break
                    else:
                        if event.get(field) != prev_input.get(field):
                            diff_detected = True
                            log(f"Atleast {field} field changed. Deleting namespace to make the update.")
                            break

                if diff_detected:
                    #Check if the previous input's Instance ID is NULL or empty. If so then skip deletion.
                    instance_id = prev_input.get('instanceId')
                    namespace = prev_input.get('namespace')
                    if instance_id and instance_id != {} and namespace and namespace != {}:
                        #Check if dataset exists
                        paginator = client.get_paginator('list_data_lake_namespaces')
                        pages = paginator.paginate(instanceId=instance_id)

                        namespace_exists = False
                        for page in pages:
                            for ns in page['namespaces']:
                                if ns['name'] == namespace:
                                    namespace_exists = True
                                    break
                            if namespace_exists:
                                break

                        if not namespace_exists:
                            log("Old namespace doesn't exist. Skipping deletion.")
                        else:
                            response = client.delete_data_lake_namespace(
                                instanceId=instance_id,
                                name=namespace
                            )
                            log("Old namespace deleted.")
                            log(json.dumps(response, default=convert_datetime, indent=2))
                    else:
                        log("Old Instance ID was null or empty. Skipping deletion of old namespace.")
                    
            paginator = client.get_paginator('list_data_lake_namespaces')
            pages = paginator.paginate(instanceId=event['instanceId'])

            for page in pages:
                for ns in page['namespaces']:
                    if ns['name'] == event['namespace']:
                        log(f"{event['namespace']} namespace already exists.")
                        update_namespace = True
                        break
                if update_namespace:
                    break

            if not update_namespace:
                response = client.create_data_lake_namespace(
                    instanceId=event['instanceId'],
                    name=event['namespace'],
                    description=event['description'],
                    tags=tags
                )
                log(f"{event['namespace']} namespace created.")
                log(json.dumps(response, default=convert_datetime, indent=2))
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Namespace Created')
                }
            else:
                response = client.update_data_lake_namespace(
                    instanceId=event['instanceId'],
                    name=event['namespace'],
                    description=event['description']
                )
                log(f"{event['namespace']} namespace updated.")
                log(json.dumps(response, default=convert_datetime, indent=2))
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Namespace Updated')
                }

        except Exception as e:
            log(f"Error creating/updating namespace: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error creating/updating namespace: {str(e)}")
            }

    elif action == "delete":
        required_fields = ['instanceId', 'namespace']
        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        client = boto3.client('supplychain')

        try:
            paginator = client.get_paginator('list_data_lake_namespaces')
            pages = paginator.paginate(instanceId=event['instanceId'])

            namespace_exists = False
            for page in pages:
                for ns in page['namespaces']:
                    if ns['name'] == event['namespace']:
                        namespace_exists = True
                        break
                if namespace_exists:
                    break

            if not namespace_exists:
                return {
                    'statusCode': 404,
                    'body': json.dumps(f"Namespace {event['namespace']} not found.")
                }

            response = client.delete_data_lake_namespace(
                instanceId=event['instanceId'],
                name=event['namespace']
            )
            log(f"Namespace {event['namespace']} deleted.")
            log(json.dumps(response, default=convert_datetime, indent=2))
            return {
                'statusCode': 200,
                'body': json.dumps(f"Namespace {event['namespace']} deleted successfully.")
            }

        except Exception as e:
            log(f"Error deleting namespace: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error deleting namespace: {str(e)}")
            }