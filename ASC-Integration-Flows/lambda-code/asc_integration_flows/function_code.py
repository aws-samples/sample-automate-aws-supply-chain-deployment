from datetime import datetime
import json
import boto3
import time
import os

# Constants
LOG_GROUP_NAME = f"/aws/lambda/{os.environ['AWS_LAMBDA_FUNCTION_NAME']}"

logs_client = boto3.client('logs')

def generate_stream_name(flow_name, operation):
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    return f"{flow_name}-{operation}-{timestamp}"

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
    flow_name = event.get('name', 'unknown')

    # Setup custom log stream
    stream_name = generate_stream_name(flow_name, action)
    sequence_token = None

    def log(msg):
        nonlocal sequence_token
        sequence_token = put_log(msg, stream_name, sequence_token)

    if action in ["create", "update"]:
        required_fields = ['name', 'instanceId', 'sources', 'transformation', 'target']
        fields_to_check = ['name', 'tags']

        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        tags = event.get("tags", {})
        client = boto3.client('supplychain')
        update_flow = False
        response = None

        try:
            prev_input = event["tf"].get("prev_input")
            if prev_input:
                diff_detected = False
                for field in fields_to_check:
                    if field == "tags":
                        if event.get("tags", "{}") != prev_input.get("tags", "{}"):
                            diff_detected = True
                            log("Atleast TAGS field changed. Deleting integration flow to make the update.")
                            break
                    else:
                        if event.get(field) != prev_input.get(field):
                            diff_detected = True
                            log(f"Atleast {field} field changed. Deleting integration flow to make the update.")
                            break

                if diff_detected:
                    #Check if the previous input's Instance ID is NULL or empty. If so then skip deletion.
                    instance_id = prev_input.get('instanceId')
                    name = prev_input.get('name')
                    if instance_id and instance_id != {} and name and name != {}:
                        #Check if integration flow exists
                        paginator = client.get_paginator('list_data_integration_flows')
                        pages = paginator.paginate(instanceId=instance_id)

                        flow_exists = False
                        for page in pages:
                            for flow in page['flows']:
                                if flow['name'] == name:
                                    flow_exists = True
                                    break
                            if flow_exists:
                                break

                        if not flow_exists:
                            log("Old integration flow doesn't exist. Skipping deletion.")
                        else:
                            response = client.delete_data_integration_flow(
                                instanceId=instance_id,
                                name=name
                            )
                            log("Old integration flow deleted.")
                            log(json.dumps(response, default=convert_datetime, indent=2))
                    else:
                        log("Old Instance ID was null or empty. Skipping deletion of old integration flow.")

            paginator = client.get_paginator("list_data_integration_flows")
            pages = paginator.paginate(instanceId=event['instanceId'])

            for page in pages:
                for flow in page['flows']:
                    if flow['name'] == event['name']:
                        log(f"Integration flow '{event['name']}' already exists.")
                        update_flow = True
                        break
                if update_flow:
                    break

            if not update_flow:
                response = client.create_data_integration_flow(
                    instanceId=event['instanceId'],
                    name=event['name'],
                    sources=event['sources'],
                    transformation=event['transformation'],
                    target=event['target'],
                    tags=tags
                )
                log(f"{str(event['name'])} Integration flow created.")
                log(json.dumps(response, default=convert_datetime, indent=2))
                return {
                    'statusCode': 200,
                    'body': json.dumps('Data Lake integration flow created successfully'),
                    'name': response['name']
                }
            else:
                response = client.update_data_integration_flow(
                    instanceId=event['instanceId'],
                    name=event['name'],
                    sources=event['sources'],
                    transformation=event['transformation'],
                    target=event['target'],
                )
                log(f"{str(event['name'])} Integration flow updated.")
                log(json.dumps(response, default=convert_datetime, indent=2))
                return {
                    'statusCode': 200,
                    'body': json.dumps('Data Lake integration flow updated successfully'),
                    'name': response['flow']['name']
                }

        except Exception as e:
            log(f"Error creating/updating integration flow: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error creating/updating Data Lake integration flow: {str(e)}")
            }

    elif action == "delete":
        required_fields = ['name', 'instanceId']
        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        client = boto3.client('supplychain')

        try:
            paginator = client.get_paginator("list_data_integration_flows")
            pages = paginator.paginate(instanceId=event['instanceId'])

            flow_exists = False
            for page in pages:
                for flow in page['flows']:
                    if flow['name'] == event['name']:
                        flow_exists = True
                        break
                if flow_exists:
                    break

            if not flow_exists:
                return {
                    'statusCode': 404,
                    'body': json.dumps(f"Integration flow '{event['name']}' does not exist in instance '{event['instanceId']}'")
                }

            response = client.delete_data_integration_flow(
                instanceId=event['instanceId'],
                name=event['name']
            )

            log(f"Integration flow {event['name']} deleted.")
            log(json.dumps(response, default=convert_datetime, indent=2))
            return {
                'statusCode': 200,
                'body': json.dumps(f"Integration flow '{event['name']}' deleted successfully")
            }

        except Exception as e:
            log(f"Error deleting integration flow: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error deleting Data Lake integration flow: {str(e)}")
            }