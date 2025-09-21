from datetime import datetime
import botocore.exceptions
import json
import time
import boto3
import logging

def convert_datetime(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError("Type not serializable")

def is_empty(val):
    return val is None or val == "" or val == {} or val == []

def lambda_handler(event, context):
    action = event["tf"]["action"]
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    client = boto3.client('supplychain')
    instance_active = False
    instanceId = None
    response = None

    #Delete failed instances
    paginator = client.get_paginator('list_instances')
    pages = paginator.paginate(
        instanceStateFilter = ["CreateFailed", "DeleteFailed"]
    )
    for page in pages:
        for inst in page['instances']:
            response = client.delete_instance(
                instanceId = inst['instanceId']
            )
            # Wait until the ASC instance has been deleted
            instance_deleted = False
            while (True):
                try:
                    response = client.get_instance(
                        instanceId = inst['instanceId']
                    )
                    if response['instance']['state'] == "Deleted":
                        instance_deleted = True
                        logger.info(f"Failed ASC instance {inst['instanceId']} has been deleted")
                    elif response['instance']['state'] == "DeleteFailed":
                        logger.error(f"Failed ASC instance deletion failed - {response['instance']['errorMessage']}")
                        return {
                            'statusCode': 500,
                            'body': json.dumps(f"Failed ASC Instance's deletion failed : {response['instance']['errorMessage']}")
                        }
                    
                except botocore.exceptions.ClientError as e:
                    if e.response['Error']['Code'] == "ResourceNotFoundException":
                        logger.info(f"Failed ASC instance {inst['instanceId']} has been deleted and doesn't exist anymore")
                        instance_deleted = True
                    else:
                        logger.exception(f"Unexpected error for failed ASC instance from get_instance: {e}")
                        raise
                if instance_deleted == True:
                    break
                time.sleep(5)

    if action in ["create","update"]:
    
        required_fields = ['instanceName', 'instanceDescription']
        fields_to_check = ['instanceName']

        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }
        tags = event.get("tags", {})

        try:
            #Delete previous input's Instance
            instance_active = False
            prev_input = event["tf"].get("prev_input")
            if prev_input:
                diff_detected = False
                for field in fields_to_check:
                    if field == "instanceName":
                        if event.get("instanceName", "") != prev_input.get("instanceName", ""):
                            diff_detected = True
                            logger.info("Atleast INSTANCE NAME field changed. Deleting instance to make the update.")
                            break
                    else:
                        if event.get(field) != prev_input.get(field):
                            diff_detected = True
                            logger.info(f"Atleast {field} field changed. Deleting instance to make the update.")
                            break
                        
                if diff_detected:
                    #Check if the previous input's Instance Name is NULL or empty. If so then skip deletion.
                    instanceName = prev_input.get('instanceName')
                    if instanceName and instanceName != {}:
                        #Check if previous instance exists
                        paginator = client.get_paginator('list_instances')
                        pages = paginator.paginate(
                            instanceStateFilter = ["Active"]
                        )
                        for page in pages:
                            for inst in page['instances']:
                                if inst['instanceName'] == instanceName:
                                    instance_active = True
                                    instanceId = inst['instanceId']
                                    break
                            if instance_active == True:
                                break

                        if not instance_active:
                            logger.info("Old Instance doesn't exist. Skipping deletion.")
                        else:
                            response = client.delete_instance(
                                instanceId = instanceId
                            )
                            # Wait until the old ASC instance has been deleted
                            instance_deleted = False
                            while (True):
                                try:
                                    response =client.get_instance(
                                        instanceId = instanceId
                                    )
                                    if response['instance']['state'] == "Deleted":
                                        instance_deleted = True
                                        logger.info(f"Old ASC instance {instanceId} has been deleted")
                                    elif response['instance']['state'] == "DeleteFailed":
                                        logger.error(f"Old ASC instance deletion failed - {response['instance']['errorMessage']}")
                                        return {
                                            'statusCode': 500,
                                            'body': json.dumps(f"Old ASC Instance's deletion failed : {response['instance']['errorMessage']}")
                                        }
                                    
                                except botocore.exceptions.ClientError as e:
                                    if e.response['Error']['Code'] == "ResourceNotFoundException":
                                        logger.info(f"Old ASC instance {instanceId} has been deleted and doesn't exist anymore")
                                        instance_deleted = True
                                    else:
                                        logger.exception(f"Unexpected error when deleting old ASC instance from get_instance: {e}")
                                        raise
                                if instance_deleted == True:
                                    break
                                time.sleep(5)
                    else:
                        logger.info("Old Instance Name was null or empty. Skipping deletion of old instance.")

            instance_active = False
            paginator = client.get_paginator('list_instances')
            pages = paginator.paginate(
                instanceStateFilter = ["Active"]
            )
            for page in pages:
                for inst in page['instances']:
                    if inst['instanceName'] == event["instanceName"]:
                        instance_active = True
                        instanceId = inst['instanceId']
                        break
                if instance_active == True:
                    break
            
            if instance_active:
                logger.info("ASC instance already exists. Updating its description")
                response = client.update_instance(
                    instanceId = instanceId,
                    instanceName = event["instanceName"],
                    instanceDescription = event["instanceDescription"]
                )
                logger.info(f"The ASC instance {instanceId} has been updated")
                logger.info("KMS key policy will be updated with ASC and Secrets Manager statements from the pipeline, if not done already")
                return {
                    'statusCode': 200,
                    'body': "ASC Instance updated successfully",
                    'instanceId': response['instance']['instanceId']
                }
            
            if not instance_active:
                logger.info("ASC instance does not exist. Creating it")
                # Create parameters dynamically
                params = {
                    "instanceName": event["instanceName"],
                    "instanceDescription": event["instanceDescription"],
                    "tags": tags
                }

                if "kmsKeyArn" in event:
                    params["kmsKeyArn"] = event["kmsKeyArn"]
                if "webAppDnsDomain" in event:
                    params["webAppDnsDomain"] = event["webAppDnsDomain"]
                if "clientToken" in event:
                    params["clientToken"] = event["clientToken"]
            
                response = client.create_instance(**params)
                instance_id = response['instance']['instanceId']

                logging.info(json.dumps(response, default=convert_datetime, indent=2))
                logger.info("ASC instance successfully created and is in Initializing state")

                # Wait until the ASC instance becomes active
                instance_active = False
                while (True):
                    response = client.get_instance(
                        instanceId = instance_id
                    )
                    if response['instance']['state'] == "Active":
                        instance_active = True
                        logger.info(f"ASC instance {str(instance_id)} is in Active state")
                    elif response['instance']['state'] == "CreateFailed":
                        logger.error(f"ASC instance creation failed - {response['instance']['errorMessage']}")
                        return {
                            'statusCode': 500,
                            'body': json.dumps(f"ASC Instance creation failed : {response['instance']['errorMessage']}")
                        }
                    if instance_active == True:
                        break
                    time.sleep(5)

                logger.info("KMS key policy will be updated with ASC and Secrets Manager statements from the pipeline, if not done already")
                return {
                    'statusCode': 200,
                    'body': "ASC Instance has been created successfully",
                    'instanceId': instance_id
                }

        except Exception as e:
            logger.error(f"Error creating/updating the ASC Instance: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error creating/updating the ASC Instance: {str(e)}")
            }
        
    elif action == "delete":

        required_fields = ['instanceName', 'instanceDescription']
        missing = [f for f in required_fields if is_empty(event.get(f))]
        if missing:
            return {
                'statusCode': 400,
                'body': json.dumps(f"Missing fields: {', '.join(missing)}")
            }

        try:
            instance_active = False
            instanceId = None
            paginator = client.get_paginator('list_instances')
            pages = paginator.paginate(
                instanceStateFilter = ["Active"]
            )
            for page in pages:
                for inst in page['instances']:
                    if inst['instanceName'] == event["instanceName"]:
                        instance_active = True
                        instanceId = inst['instanceId']
                        break
                if instance_active == True:
                    break

            if not instance_active:
                logger.info("ASC Instance doesn't exist. Skipping deletion.")
            else:
                response = client.delete_instance(
                    instanceId = instanceId
                )
                # Wait until the old ASC instance has been deleted
                instance_deleted = False
                while (True):
                    try:
                        response = client.get_instance(
                            instanceId = instanceId
                        )
                        if response['instance']['state'] == "Deleted":
                            instance_deleted = True
                            logger.info(f"Current ASC instance {instanceId} has been deleted")
                        elif response['instance']['state'] == "DeleteFailed":
                            logger.error(f"Current ASC instance deletion failed - {response['instance']['errorMessage']}")
                            return {
                                'statusCode': 500,
                                'body': json.dumps(f"Current ASC Instance's deletion failed : {response['instance']['errorMessage']}")
                            }
                        
                    except botocore.exceptions.ClientError as e:
                        if e.response['Error']['Code'] == "ResourceNotFoundException":
                            logger.info(f"Current ASC instance {instanceId} has been deleted and doesn't exist anymore")
                            instance_deleted = True
                        else:
                            logger.exception(f"Unexpected error when deleting the current ASC instance from get_instance: {e}")
                            raise
                    if instance_deleted == True:
                        break
                    time.sleep(5)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps(f"Successfully deleted the current ASC Instance - {instanceId}")
                }

        except Exception as e:
            logger.error(f"Error deleting the current ASC Instance: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f"Error deleting the current ASC Instance: {str(e)}")
            }
