"""
Read Hosts

Enforced Preconditions
(None)

"""

from boto3.dynamodb.conditions import Key
from api_contract import make_APIData, make_APIGeoNode, ADMIN
from constants import NODE_TABLE

def execute(user_id): 
    hosts = NODE_TABLE.query(
        IndexName="creator-index",
        KeyConditionExpression=Key('creator').eq(user_id))['Items']
    geos = list(map(lambda host: make_APIGeoNode(host, ADMIN, ADMIN), hosts))
    return make_APIData(geos)
