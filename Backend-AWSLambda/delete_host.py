"""
Delete Host

Enforced Preconditions:
1) There exists a node with an id equal to 'host_id' whose creator is 'user_id' 

"""

from api_contract import make_APIData, make_APIServerMessage
from common import valid_host_id, make_node_pkey, get_node, delete_edge, query_edges_by_head, query_edges_by_tail
import s3_access
from constants import NODE_TABLE


def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Delete Host: User is not the host's creator")

def _verify(user_id, host_id):
    _verify_user_is_creator(user_id, host_id)

def execute(user_id, host_id):
    _verify(user_id, host_id)

    host = get_node(host_id)
    s3_access.delete_object(host["media"]["portrait_id"])
    s3_access.delete_object(host["media"]["supplement_id"])

    NODE_TABLE.delete_item(
        Key=make_node_pkey(host_id)
    )

    to_host_edges = query_edges_by_head(host_id)
    from_host_edges = query_edges_by_tail(host_id)

    for edge in (to_host_edges + from_host_edges):
        delete_edge(edge["head"], edge["tail"])

    return make_APIData(make_APIServerMessage("Successfully deleted host"))

    
