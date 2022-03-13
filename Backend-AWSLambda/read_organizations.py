"""
Read Organizations

Enforced Preconditions:
(none)

"""

from api_contract import make_APIGeoJSON, make_APIGeoNode

CORNELL = {
    'id': "CORNELL_UNIVERSITY",
    'name': "Cornell University",
    'description': "",
    'location': {
        'default_location': ["-76.4735", "42.4534"],
        'live_location': None,
    },
    'zoom': "3",
    'drops': [],
    'creator': "com.rhizomenetworking.iris",
    'media': {
        'portrait_id': "static/cornell-university/portrait.jpg",
        'supplement_id': "static/cornell-university/supplement.png"
    }
}

ORGANIZATIONS = [CORNELL]

def execute():
    api_geo_nodes = []
    for org in ORGANIZATIONS:
        geo = make_APIGeoNode(org)
        api_geo_nodes.append(geo)

    return make_APIGeoJSON(api_geo_nodes)