"""
Create Report

Enforced Preconditons:
1) There exists a node with an id equal to 'host_id' whose creator is 'user_id' 

"""

from api_contract import make_APIData, make_APIServerMessage, PEER
from common import valid_host_id, put_edge
from constants import OFFICER_IDS

def _verify_user_is_creator(user_id, host_id):
    if not valid_host_id(user_id, host_id):
        raise Exception("Create Report: User is not the host's creator")

def _verify(user_id, host_id, entity_id):
    _verify_user_is_creator(user_id, host_id)

def execute(user_id, host_id, entity_id):
    _verify(user_id, host_id, entity_id)

    if entity_id in OFFICER_IDS:
        return make_APIData(make_APIServerMessage("Successfully Created Report"))

    for officer_id in OFFICER_IDS:
        put_edge(officer_id, entity_id, PEER)
        put_edge(entity_id, officer_id, PEER)

    return make_APIData(make_APIServerMessage("Successfully Created Report"))