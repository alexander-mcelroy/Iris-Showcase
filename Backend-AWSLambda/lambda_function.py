import json
import logging

import read_organizations

import create_host
import read_hosts
import update_host
import delete_host

import read_network
import pull_trigger
import update_network

import create_drop
import read_drops
import delete_drop

import create_report

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def serve(event):
    print(event["httpMethod"] + " " + event["resource"])
    resource = event['resource']
    method = event['httpMethod']
    path_parameters = event['pathParameters']
    query_parameters = event['queryStringParameters']

    body = None 
    if 'body' in event and event['body'] is not None:
        body = json.loads(event['body'])
    
    statusCode = 200
    response = None

    if resource == "/public/organizations" and method == "GET":
        return {
            'statusCode': statusCode,
            'body': json.dumps(read_organizations.execute())
        }

    auth0_user_id = event['requestContext']['authorizer']['auth0_user_id']
    print("Auth0 User ID: " + auth0_user_id)
    if resource == "/private/hosts" and method == "GET":
        response = read_hosts.execute(auth0_user_id)

    elif resource == "/private/hosts" and method == "POST":
        response = create_host.execute(auth0_user_id, body)
    
    elif resource == "/private/hosts/{host_id}" and method == "PATCH":
        response = update_host.execute(auth0_user_id, path_parameters["host_id"], body)
    
    elif resource == "/private/hosts/{host_id}" and method == "DELETE":
        response = delete_host.execute(auth0_user_id, path_parameters["host_id"])

    elif resource == "/private/hosts/{host_id}/network" and method == "GET":
        entity_id = query_parameters["filter"] if query_parameters is not None and 'filter' in query_parameters else None
        response = read_network.execute(auth0_user_id, path_parameters["host_id"], entity_id)

    elif resource == "/private/hosts/{host_id}/network" and method == "PATCH":
        response = update_network.execute(auth0_user_id, path_parameters["host_id"], query_parameters["filter"], body)

    elif resource == "/private/hosts/{host_id}/network/triggers" and method == "POST":
        response = pull_trigger.execute(auth0_user_id, path_parameters["host_id"], body)

    elif resource == "/private/hosts/{host_id}/drops" and method == "GET":
        entity_id = query_parameters["filter"] if query_parameters is not None and 'filter' in query_parameters else None
        response = read_drops.execute(auth0_user_id, path_parameters["host_id"], entity_id)
    
    elif resource == "/private/hosts/{host_id}/drops" and method == "POST":
        response = create_drop.execute(auth0_user_id, path_parameters["host_id"], body)
    
    elif resource == "/private/hosts/{host_id}/drops/{drop_id}" and method == "DELETE":
        response = delete_drop.execute(auth0_user_id, path_parameters["host_id"], path_parameters["drop_id"])

    elif resource == "/private/hosts/{host_id}/reports/{entity_id}" and method == "POST":
        response = create_report.execute(auth0_user_id, path_parameters["host_id"], path_parameters["entity_id"])

    else:
        statusCode = 404
        response = {
            'message': "Resource not found"
        }

    return {
        'statusCode': statusCode,
        'body': json.dumps(response)
    }

def lambda_handler(event, context):
    try:
        return serve(event)

    except Exception as err:
        logger.exception(err)
        response = {
            'message': "Failed to serve request"
        }
        return {
            'statusCode': 500,
            'body': json.dumps(response)
        }
