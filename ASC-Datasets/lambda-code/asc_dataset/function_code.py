from datetime import datetime
import json
import boto3
import time
import os

# Constants
LOG_GROUP_NAME = f"/aws/lambda/{os.environ['AWS_LAMBDA_FUNCTION_NAME']}"

# Create boto3 logs client once
logs_client = boto3.client('logs')

def generate_stream_name(dataset_name, operation):
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    return f"{dataset_name}-{operation}-{timestamp}"

def put_log(message, stream_name, sequence_token=None):
    try:
        # Create stream if it doesn't exist
        logs_client.create_log_stream(
            logGroupName=LOG_GROUP_NAME,
            logStreamName=stream_name
        )
    except logs_client.exceptions.ResourceAlreadyExistsException:
        if sequence_token is None:
            # Get latest sequence token
            response = logs_client.describe_log_streams(
                logGroupName=LOG_GROUP_NAME,
                logStreamNamePrefix=stream_name
            )
            streams = response.get("logStreams", [])
            if not streams:
                raise Exception(f"Log stream {stream_name} not found.")
            sequence_token = streams[0].get("uploadSequenceToken")

    # Prepare log event
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
    dataset_name = event.get('name', 'unknown')

    # Setup custom stream name
    stream_name = generate_stream_name(dataset_name, action)
    sequence_token = None  # Will be updated after each log write

    def log(msg):
        nonlocal sequence_token
        sequence_token = put_log(msg, stream_name, sequence_token)

    if action in ["create", "update"]:
        required_fields = ['name', 'schema', 'description', 'namespace', 'instanceId']
        fields_to_check = ['name', 'schema', 'namespace', 'instanceId', 'tags']

        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        schema_str = event['schema']
        try:
            schema = json.loads(schema_str)
        except json.JSONDecodeError as e:
            log(f"Invalid schema JSON: {str(e)}")
            return {
                'statusCode': 400,
                'body': json.dumps(f'Invalid schema JSON: {str(e)}')
            }

        tags = event.get("tags", {})
        client = boto3.client('supplychain')
        update_dataset = False
        response = None

        try:
            prev_input = event["tf"].get("prev_input")

            if prev_input:
                diff_detected = False
                prev_schema = json.loads(prev_input.get("schema", "{}"))
                for field in fields_to_check:
                    if field == "schema":
                        if schema != prev_schema:
                            diff_detected = True
                            log("Atleast SCHEMA field changed. Deleting dataset to make the update.")
                            break
                    elif field == "tags":
                        if event.get("tags", "{}") != prev_input.get("tags", "{}"):
                            diff_detected = True
                            log("Atleast TAGS field changed. Deleting dataset to make the update.")
                            break
                    else:
                        if event.get(field) != prev_input.get(field):
                            diff_detected = True
                            log(f"Atleast {field} field changed. Deleting dataset to make the update.")
                            break

                if diff_detected:
                    #Check if the previous input's Instance ID is NULL or empty. If so then skip deletion.
                    instance_id = prev_input.get('instanceId')
                    namespace = prev_input.get('namespace')
                    name = prev_input.get('name')
                    if instance_id and instance_id != {} and namespace and namespace != {} and name and name != {}:
                        #Check if dataset exists
                        paginator = client.get_paginator('list_data_lake_datasets')
                        pages = paginator.paginate(
                            instanceId=instance_id,
                            namespace=namespace
                        )

                        dataset_exists = False
                        for page in pages:
                            for ds in page['datasets']:
                                if ds['name'] == name:
                                    dataset_exists = True
                                    break
                            if dataset_exists:
                                break

                        if not dataset_exists:
                            log("Old dataset doesn't exist. Skipping deletion.")
                        else:
                            response = client.delete_data_lake_dataset(
                                instanceId=instance_id,
                                namespace=namespace,
                                name=name
                            )
                            log("Old dataset deleted.")
                            log(json.dumps(response, default=convert_datetime, indent=2))
                    else:
                        log("Old Instance ID was null or empty. Skipping deletion of old dataset.")

            # List existing datasets
            paginator = client.get_paginator('list_data_lake_datasets')
            pages = paginator.paginate(
                instanceId=event['instanceId'],
                namespace=event['namespace']
            )

            for page in pages:
                for i in page['datasets']:
                    if i['name'] == event['name']:
                        log(f"{event['name']} dataset already exists.")
                        update_dataset = True
                        break
                if update_dataset:
                    break

            if not update_dataset:
                # Create dataset
                response = client.create_data_lake_dataset(
                    instanceId=event['instanceId'],
                    namespace=event['namespace'],
                    name=event['name'],
                    schema=schema,
                    description=event['description'],
                    tags=tags
                )
                log(f"{str(event['name'])} Dataset created.")
                log(json.dumps(response, default=convert_datetime, indent=2))
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Dataset Created'),
                    'namespace': event['namespace'],
                    'name': event['name'],
                    'arn': response['dataset']['arn']
                }
            else:
                # Update dataset
                response = client.update_data_lake_dataset(
                    instanceId=event['instanceId'],
                    namespace=event['namespace'],
                    name=event['name'],
                    description=event['description']
                )
                log(f"{str(event['name'])} Dataset updated.")
                log(json.dumps(response, default=convert_datetime, indent=2))
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Dataset Updated'),
                    'namespace': event['namespace'],
                    'name': event['name'],
                    'arn': response['dataset']['arn']
                }

        except Exception as e:
            log(f"Error creating/updating dataset: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error creating/updating Data Lake Dataset: {str(e)}")
            }

    elif action == "delete":
        required_fields = ['name', 'namespace', 'instanceId']
        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        client = boto3.client('supplychain')

        try:
            paginator = client.get_paginator('list_data_lake_datasets')
            pages = paginator.paginate(
                instanceId=event['instanceId'],
                namespace=event['namespace']
            )

            dataset_exists = False
            for page in pages:
                for ds in page['datasets']:
                    if ds['name'] == event['name']:
                        dataset_exists = True
                        break
                if dataset_exists:
                    break

            if not dataset_exists:
                return {
                    'statusCode': 404,
                    'body': json.dumps(f"Dataset {event['name']} not found.")
                }

            response = client.delete_data_lake_dataset(
                instanceId=event['instanceId'],
                namespace=event['namespace'],
                name=event['name']
            )
            log(f"Dataset {event['name']} deleted.")
            log(json.dumps(response, default=convert_datetime, indent=2))
            return {
                'statusCode': 200,
                'body': json.dumps(f"Dataset {event['name']} deleted successfully.")
            }

        except Exception as e:
            log(f"Error in delete: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error deleting Data Lake Dataset: {str(e)}")
            }
