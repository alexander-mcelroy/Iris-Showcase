import s3_access

ADMIN = "Admin"
PEER = "Peer"
AQUAINTED = "Aquainted"
DISTANT = "Distant"

PNG = "png"
JPG = "jpg"
MP4 = "mp4"
MOV = "mov"

def make_APILocation(node, to_host_weight=DISTANT):
    longitude = node["location"]["default_location"][0]
    latitude = node["location"]["default_location"][1]
    authorized = (to_host_weight == PEER or to_host_weight == ADMIN)
    if authorized and node["location"]["live_location"] is not None:
        longitude = node["location"]["live_location"][0]
        latitude = node["location"]["live_location"][1]
    return [float(longitude), float(latitude)]

def make_APIGeoPoint(api_location):
    return {
        'type': "Feature",
        'properties': None,
        'geometry': {
            'type': "Point",
            'coordinates': api_location
        }
    }

def make_APIGeoTrigger(trigger_id, zoom, api_location):
    return {
        'type': "Feature",
        'properties': {
            'trigger_id': trigger_id,
            'zoom': float(zoom)
        },
        'geometry': {
            'type': "Point",
            'coordinates': api_location
        }
    }

def make_APIGeoNode(node, from_host_weight=DISTANT, to_host_weight=DISTANT):
    live_location_enabled = None
    if from_host_weight == ADMIN and to_host_weight == ADMIN:
        live_location_enabled = node["location"]["live_location"] is not None
    portrait_id = s3_access.presigned_url(node["media"]["portrait_id"])
    supplement_id = s3_access.presigned_url(node["media"]["supplement_id"])
    counter_weight = "Distant" if to_host_weight == DISTANT else "Close"

    return {
        'type': "Feature",
        'properties': {
            'id': node["id"],
            'name': node["name"],
            'description': node["description"],
            'live_location_enabled': live_location_enabled,
            'zoom': float(node["zoom"]),
            'media': {
                'portrait_id': portrait_id,
                'supplement_id': supplement_id
            },
            'weight': from_host_weight,
            'counter_weight': counter_weight
        },
        'geometry': {
            'type': "Point",
            'coordinates': make_APILocation(node, to_host_weight)
        }
    }

def make_APIGeoJSON(api_geos):
    return {
        "type": "FeatureCollection",
        "crs": {
            "type": "name",
            "properties": {
                "name": "urn:ogc:def:crs:OGC:1.3:CRS84"
            }
        },
        "features": api_geos
    }

def make_APICanvasDrop(drop, api_geo_node=None):
    x = drop['canvas_location'][0]
    y = drop['canvas_location'][1]
    z = drop['canvas_location'][2]
    
    image_id = None
    if 'image_id' in drop: 
        image_id = s3_access.presigned_url(drop["image_id"])

    return {
        'id': drop["id"],
        'canvas_location': [float(x), float(y), float(z)],
        'image_id': image_id,
        'portal_url': drop["portal_url"] if 'portal_url' in drop else None,
        'api_geo_node': api_geo_node
    }

def make_APIServerMessage(message):
    return {
        'message': message
    }

def make_APIData(api_obj):
    return {
        'data': api_obj
    }    


