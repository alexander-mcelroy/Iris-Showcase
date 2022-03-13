"""
Delete Drop

Enforced Preconditions:
1) There exists a node with an id equal to 'host_id' whose creator is 'user_id' 

"""

from api_contract import make_APIData, make_APIServerMessage
from common import valid_host_id, make_node_pkey, make_edge_pkey, get_edge, get_local_drops
import s3_access
from constants import NODE_TABLE, EDGE_TABLE


def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Delete Drop: User is not the host's creator")

def _verify(user_id, host_id):
    _verify_user_is_creator(user_id, host_id)

def _execute_local_lift(node_id, drop_id):
    filtered_drops = []
    for drop in get_local_drops(node_id):
        if drop["id"] != drop_id:
            filtered_drops.append(drop)
        elif "image_id" in drop:
            s3_access.delete_object(drop["image_id"])
    
    NODE_TABLE.update_item(
        Key=make_node_pkey(node_id),
        UpdateExpression='SET drops = :a',
        ExpressionAttributeValues={
            ':a': filtered_drops
        }
    )

def _execute_network_lift(head_id, tail_id):
    EDGE_TABLE.update_item(
        Key=make_edge_pkey(head_id, tail_id),
        UpdateExpression='SET #D=:a',
        ExpressionAttributeValues={
            ':a': None
        },
        ExpressionAttributeNames={
            "#D": "drop"
        }
    )

def execute(user_id, host_id, drop_id):
    _verify(user_id, host_id)

    if get_edge(drop_id, host_id) is not None:
        _execute_network_lift(drop_id, host_id)
    else:
        _execute_local_lift(host_id, drop_id)

    return make_APIData(make_APIServerMessage("Successfully Deleted Drop"))

