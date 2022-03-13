"""
Create Drop

Enforced Preconditions:
1) 'id' is a valid string
2) 'canvas_location' is a valid canvas location
3) 'image_id' is a valid string if provided
4) 'portal_url' is a valid string if provided
5) There exists a node with an id equal to 'host_id' whose creator is 'user_id' 
6) If no 'image_id' or 'portal_url' provided, the required 'id' is to be 
   interpreted as an entity id. This entity to host edge must be of weight Peer 
7) The host has less than 10 drops

"""

from api_contract import make_APIData, make_APIServerMessage, PEER
from common import valid_string, valid_canvas_location, valid_host_id, make_node_pkey, make_edge_pkey, get_weight, get_local_drops, query_network_drops
from constants import NODE_TABLE, EDGE_TABLE


def _verify_body_composition(body):
    drop_id = body["id"]
    if not valid_string(drop_id):
        raise Exception("Create Drop: 'id' is invalid")

    location = body["canvas_location"]
    if not valid_canvas_location(location):
        raise Exception("Create Drop: 'canvas_location' is invalid")

    if 'image_id' in body and not valid_string(body["image_id"]):
        raise Exception("Create Drop: 'image_id' is invalid")

    if 'portal_url' in body and not valid_string(body["portal_url"]):
        raise Exception("Create Drop: 'portal_url' is invalid")

def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Create Drop: User is not the host's creator")

def _verify_id(host_id, body):
    if 'image_id' in body or 'portal_url' in body:
        return 
    else:
        if get_weight(body["id"], host_id) != PEER:
            raise Exception("Create Drop: 'id' is invalid")

def _verify_host_within_capacity(host_id):
    local_drops = get_local_drops(host_id)
    network_drops = query_network_drops(host_id)
    if len(local_drops + network_drops) >= 10:
        raise Exception("Create Drop: Host has already reached drop capacity")

def _verify(user_id, host_id, body):
    _verify_body_composition(body)
    _verify_user_is_creator(user_id, host_id)
    _verify_id(host_id, body)
    _verify_host_within_capacity(host_id)

def _execute_local_drop(node_id, drop):
    NODE_TABLE.update_item(
        Key=make_node_pkey(node_id),
        UpdateExpression='SET drops = list_append(drops, :a)',
        ExpressionAttributeValues={
            ':a': [drop]
        }
    )

def _execute_network_drop(head_id, tail_id, drop):
    EDGE_TABLE.update_item(
        Key=make_edge_pkey(head_id, tail_id),
        UpdateExpression='SET #D=:a',
        ExpressionAttributeValues={
            ':a': drop
        },
        ExpressionAttributeNames={
            "#D": "drop"
        }
    )

def execute(user_id, host_id, body):
    _verify(user_id, host_id, body)

    drop = {
        'id': body["id"],
        'canvas_location': body["canvas_location"]
    }

    if 'image_id' in body:
        drop["image_id"] = body["image_id"]
        _execute_local_drop(host_id, drop)
    elif 'portal_url' in body:
        drop["portal_url"] = body["portal_url"]
        _execute_local_drop(host_id, drop)
    else:
        _execute_network_drop(body["id"], host_id, drop)

    return make_APIData(make_APIServerMessage("Successfully Created Drop"))




