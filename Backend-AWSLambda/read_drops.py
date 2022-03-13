"""
Read Drop

Enforced Preconditions:
1) If 'entity_id' is provided, the entity to host weight cannot be distant.
2) There exists a node with an id equal to 'host_id' whose creator is 'user_id' 

"""

from api_contract import make_APIData, make_APICanvasDrop, make_APIGeoNode, DISTANT
from common import valid_host_id, get_node, get_weight, get_local_drops, query_network_drops

def _verify_entity_id(host_id, entity_id):
    if get_weight(entity_id, host_id) == DISTANT:
        raise Exception("Read Drops: No 'entity_id' invalid")

def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Read Drops: User is not the host's creator")

def _verify(user_id, host_id, entity_id):
    _verify_entity_id(host_id, entity_id)
    _verify_user_is_creator(user_id, host_id)

def execute(user_id, host_id, entity_id):
    _verify(user_id, host_id, entity_id)
    
    local_drops = get_local_drops(entity_id)
    network_drops = query_network_drops(entity_id)
    
    canvas_drops = list(map(lambda drop: make_APICanvasDrop(drop), local_drops))
    for drop in network_drops:
        node = get_node(drop["id"])
        from_host_weight = get_weight(host_id, node["id"])
        to_host_weight = get_weight(node["id"], host_id)
        api_geo_node = make_APIGeoNode(node, from_host_weight, to_host_weight)
        canvas_drops.append(make_APICanvasDrop(drop, api_geo_node))

    return make_APIData(canvas_drops)