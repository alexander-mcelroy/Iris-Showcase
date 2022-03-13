"""
Read Network

Enforced Preconditions:
1) If provided, there exists a node with an id equal to 'entity_id' 
2) There exists a node with an id equal to 'host_id' whose creator is 'user_id'

"""

from api_contract import make_APIGeoJSON, make_APIGeoTrigger, make_APIGeoPoint, make_APILocation, PEER
from common import valid_host_id, get_node, get_weight, query_edges_by_tail
from constants import NODE_TABLE

def _verify_entity_id(entity_id):
    if entity_id is None:
        return 
    if get_node(entity_id) is None:
        raise Exception("Read Network: Node 'entity_id' does not exist") 

def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Read Network: User is not the host's creator")

def _verify(user_id, host_id, entity_id):
    _verify_entity_id(entity_id)
    _verify_user_is_creator(user_id, host_id)

def execute(user_id, host_id, entity_id):
    _verify(user_id, host_id, entity_id)

    visible_nodes = []
    invisible_nodes = []
    if entity_id is None:
        visible_nodes = NODE_TABLE.scan()["Items"]
    else: 
        edges = query_edges_by_tail(entity_id)
        for edge in edges:
            node = get_node(edge["head"])
            if edge["weight"] == PEER:
                visible_nodes.append(node)
            else:
                invisible_nodes.append(node)
    
    geo_triggers = []
    for node in visible_nodes:
        to_host_weight = get_weight(node["id"], host_id)
        location = make_APILocation(node, to_host_weight)
        trigger = make_APIGeoTrigger(node["id"], node["zoom"], location)
        geo_triggers.append(trigger)

    geo_points = []
    for node in invisible_nodes:
        location = make_APILocation(node)
        point = make_APIGeoPoint(location)
        geo_points.append(point)

    return make_APIGeoJSON(geo_triggers + geo_points)