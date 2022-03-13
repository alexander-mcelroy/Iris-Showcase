"""
Create Host

Enforced Preconditions:
1) 'id' is a valid string
2) 'name' is a valid string and cannot resemble 'Iris by Rhizome Networking'
3) 'description' is a valid string
4) 'default_location' is a valid location
5) 'live_location' is a valid location if provided
6) 'portrait_id' is a valid string
7) 'supplement_id' is a valid string
8) There are not more than 3 nodes whoose creator is 'user_id'
9) No existing node has an id equal to 'id'

"""

from boto3.dynamodb.conditions import Key
from common import valid_string, valid_location, get_node
from api_contract import make_APIData, make_APIGeoNode, ADMIN
from constants import NODE_TABLE

INVALID_NAMES = [
    "Iris by Rhizome Networking",
    "Rhizome Networking",
    "Rhizome Networking, LLC",
    "Rhizome Networking LLC"
]

def _verify_body_compositon(body):
    host_id = body["id"]
    if not valid_string(host_id):
        raise Exception("Create Host: 'id' is invalid")
    
    name = body["name"]
    if not valid_string(name) or name in INVALID_NAMES:
        raise Exception("Create Host: 'name' is invalid")

    description = body["description"]
    if not valid_string(description):
        raise Exception("Create Host: 'description' is invalid")

    default_location = body["default_location"]
    if not valid_location(default_location):
        raise Exception("Create Host: 'default_location' in invalid")
    
    if 'live_location' in body and not valid_location(body["live_location"]):
        raise Exception("Create Host: 'live_location' in invalid")

    portrait_id = body["portrait_id"]
    if not valid_string(portrait_id):
        raise Exception("Create Host: 'portrait_id' is invalid")

    supplement_id = body["supplement_id"]
    if not valid_string(supplement_id):
        raise Exception("Create Host: 'supplement_id' is invalid")

def _verify_user_within_capacity(user_id):
    nodes_of_user = NODE_TABLE.query(
        IndexName="creator-index",
        KeyConditionExpression=Key('creator').eq(user_id))['Items']
    if len(nodes_of_user) >= 3:
        raise Exception("Create Host: User has already reached capacity")

def _verify_unique_node_id(node_id):
    if get_node(node_id) is not None:
        raise Exception("Create Host: A node with the same id already exists") 

def _verify(user_id, body):
    _verify_body_compositon(body)
    _verify_user_within_capacity(user_id)
    _verify_unique_node_id(body["id"])

def execute(user_id, body):
    _verify(user_id, body) 

    live_location = body["live_location"] if 'live_location' in body else None
    NODE_TABLE.put_item(
        Item={
            'id': body["id"],
            'name': body["name"],
            'description': body["description"],
            'location': {
                'default_location': body["default_location"],
                'live_location': live_location,
            },
            'zoom': "16",
            'drops': [],
            'creator': user_id,
            'media': {
                'portrait_id': body["portrait_id"],
                'supplement_id': body["supplement_id"]
            }
        }
    )

    host = get_node(body["id"])
    api_geo_node = make_APIGeoNode(host, ADMIN, ADMIN)
    return make_APIData(api_geo_node)
