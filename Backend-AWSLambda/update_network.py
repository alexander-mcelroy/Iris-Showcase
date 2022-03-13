"""
Update Network

Enforced Preconditions:
1) 'weight' is one of the following: Distant, Aquainted, or Peer
2) 'entity_id' does not equal 'host_id'
3) There exists a node with an id equal to 'entity_id'
4) There exists a node with an id equal to 'host_id' whose creator is 'user_id'

"""

from api_contract import make_APIData, make_APIGeoNode, DISTANT, AQUAINTED, PEER
from common import valid_host_id, put_edge, get_node, get_weight, delete_edge
from constants import OFFICER_IDS

def _verify_body_composition(body):
    weight = body["weight"]
    if weight != DISTANT and weight != AQUAINTED and weight != PEER:
        raise Exception("Update Network: 'weight' is invalid")

def _verify_entity_id(host_id, entity_id):
    if host_id == entity_id:
        raise Exception("Update Network: 'entity_id' equals 'host_id'")

    if get_node(entity_id) is None:
        raise Exception("Update Network: Node 'entity_id' does not exist") 

def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Update Network: User is not the host's creator")

def _verify(user_id, host_id, entity_id, body):
    _verify_body_composition(body)
    _verify_entity_id(host_id, entity_id)
    _verify_user_is_creator(user_id, host_id)

def _execute_edge_update(head_id, tail_id, weight):
    if weight == DISTANT:
        delete_edge(head_id, tail_id)
    else:
        put_edge(head_id, tail_id, weight)

def execute(user_id, host_id, entity_id, body):
    _verify(user_id, host_id, entity_id, body)
    
    if entity_id not in OFFICER_IDS:
        _execute_edge_update(host_id, entity_id, body["weight"]) 
        
        if host_id in OFFICER_IDS:
            _execute_edge_update(entity_id, host_id, body["weight"])

    entity = get_node(entity_id)
    from_host_weight = get_weight(host_id, entity_id)
    to_host_weight = get_weight(entity_id, host_id)

    api_geo_node = make_APIGeoNode(entity, from_host_weight, to_host_weight)
    return make_APIData(api_geo_node)

