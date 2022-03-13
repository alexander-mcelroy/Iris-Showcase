"""
Update Host

Enforced Preconditions:
1) 'description' is a valid string if provided
2) 'live_location' is a valid location if provided
3) 'portrait_id' is a valid string if provided
4) 'supplement_id' is a valid string if provided
5) There exists a node with an id equal to 'host_id' whose creator is 'user_id' 

"""

from common import valid_string, valid_location, valid_host_id, make_node_pkey, get_node
from api_contract import make_APIData, make_APIGeoNode, ADMIN
from constants import NODE_TABLE
import s3_access

def _verify_body_composition(body):
    if 'description' in body and not valid_string(body["description"]):
        raise Exception("Update Host: 'description' is invalid")
    
    if 'live_location' in body and not valid_location(body["live_location"]):
        raise Exception("Update Host: 'live_location' is invalid")

    if 'portrait_id' in body and not valid_string(body["portrait_id"]):
        raise Exception("Update Host: 'portrait_id' is invalid")

    if 'supplement_id' in body and not valid_string(body["supplement_id"]):
        raise Exception("Update Host: 'supplement_id' is invalid")

def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Update Host: User is not the host's creator")

def _verify(user_id, host_id, body):
    _verify_body_composition(body)
    _verify_user_is_creator(user_id, host_id)

def execute(user_id, host_id, body):
    _verify(user_id, host_id, body)

    host = get_node(host_id)

    if 'portrait_id' in body and body["portrait_id"] != host["media"]["portrait_id"]:
        s3_access.delete_object(host["media"]["portrait_id"])

    if 'supplement_id' in body and body["supplement_id"] != host["media"]["supplement_id"]:
        s3_access.delete_object(host["media"]["supplement_id"])
    
    NODE_TABLE.update_item(
        Key=make_node_pkey(host_id),
        UpdateExpression='SET description=:a, #L.live_location=:b, media.portrait_id=:c, media.supplement_id=:d',
        ExpressionAttributeValues={
            ':a': body["description"] if 'description' in body else host["description"],
            ':b': body["live_location"] if 'live_location' in body else None,
            ':c': body["portrait_id"] if 'portrait_id' in body else host["media"]["portrait_id"],
            ':d': body["supplement_id"] if 'supplement_id' in body else host["media"]["supplement_id"],
        },
        ExpressionAttributeNames={
            "#L": "location"
        }
    )

    updated_host = get_node(host_id)
    api_geo_node = make_APIGeoNode(updated_host, ADMIN, ADMIN)
    return make_APIData(api_geo_node)
