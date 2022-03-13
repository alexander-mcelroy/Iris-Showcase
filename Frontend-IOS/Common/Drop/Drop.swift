//
//  Drop.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/6/21.
//

import Foundation
import SwiftUI

protocol Dropped {
    var id: String { get }
    var location: Location3D { get }
}

struct DroppedEntity: Dropped {
    let id: String
    let location: Location3D
    let entity: Entity
    
    init?(apiDrop: APIDrop) {
        guard
            let node = apiDrop.api_geo_node,
            let location = Location3D(apiDrop.canvas_location)
        else { return nil }
        self.id = apiDrop.id
        self.location = location
        self.entity = Entity(apiGeoNode: node)
    }
}

struct DroppedPortal: Dropped {
    let id: String
    let location: Location3D
    let url: URL
    
    init?(apiDrop: APIDrop) {
        guard
            let portal = apiDrop.portal_url,
            let url = URL(string: portal),
            let location = Location3D(apiDrop.canvas_location)
        else { return nil }
        self.id = apiDrop.id
        self.location = location
        self.url = url
    }
}

struct DroppedAbstraction: Dropped {
    let id: String
    let location: Location3D
    let imageURL: URL
    
    init?(apiDrop: APIDrop) {
        guard
            let image_id = apiDrop.image_id,
            let image_url = URL(string: image_id),
            let location = Location3D(apiDrop.canvas_location)
        else { return nil }
        self.id = apiDrop.id
        self.location = location
        self.imageURL = image_url
    }
}
struct Location3D: Codable, Comparable {
    static func < (lhs: Location3D, rhs: Location3D) -> Bool {
        if lhs.z == rhs.z {
            if lhs.y == rhs.y {
                if lhs.x == rhs.x {
                    return true
                }
                return lhs.x > rhs.x
            }
            return lhs.y > rhs.y
        }
        return lhs.z < rhs.z
    }
    
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
    
    init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init?(_ values: [Double]) {
        guard
            let x = values[safe: 0],
            let y = values[safe: 1],
            let z = values[safe: 2]
        else { return nil }
        self.x = CGFloat(x)
        self.y = CGFloat(y)
        self.z = CGFloat(z)
    }
    
    var asStrings: [String] {
        [x.description, y.description, z.description]
    }
    
    func isIntersecting2D(_ location: Location3D, radius: CGFloat) -> Bool {
        let dx = abs(location.x - x)
        let dy = abs(location.y - y)
        let distance_squared = (dx * dx) + (dy * dy)
        return distance_squared <= (radius * radius) 
    }
}

extension Array where Element == Dropped {
    func sortedByLayoutPriority(decreasing: Bool = false) -> [Dropped] {
        if decreasing {
            return sorted { $0.location > $1.location }
        } else {
            return sorted { $0.location < $1.location }
        }
    }
}




//TODO: Move
extension View {
    var uiView: UIView {
        UIHostingController(rootView: self.ignoresSafeArea()).view
    }
}

let DEBUG_DROPPED_ENTITIES: [DroppedEntity] = [
    DroppedEntity(apiDrop: APIDrop(id: "1", canvas_location: [560, 525, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!,
    DroppedEntity(apiDrop: APIDrop(id: "2", canvas_location: [550, 395, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!,
    DroppedEntity(apiDrop: APIDrop(id: "3", canvas_location: [360, 495, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!,
    DroppedEntity(apiDrop: APIDrop(id: "4", canvas_location: [400, 575, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!,
    DroppedEntity(apiDrop: APIDrop(id: "5", canvas_location: [500, 575, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!,
    DroppedEntity(apiDrop: APIDrop(id: "6", canvas_location: [500, 475, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!,
    DroppedEntity(apiDrop: APIDrop(id: "7", canvas_location: [450, 425, 12], image_id: nil, portal_url: nil, api_geo_node: DEBUG_API_GEO_NODE))!
]
let DEBUG_DROPPED_PORTALS: [DroppedPortal] = [
    DroppedPortal(apiDrop: APIDrop(id: "12", canvas_location: [550, 525, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!,
    DroppedPortal(apiDrop: APIDrop(id: "13", canvas_location: [530, 395, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!,
    DroppedPortal(apiDrop: APIDrop(id: "14", canvas_location: [370, 495, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!,
    DroppedPortal(apiDrop: APIDrop(id: "15", canvas_location: [390, 575, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!,
    DroppedPortal(apiDrop: APIDrop(id: "16", canvas_location: [490, 575, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!,
    DroppedPortal(apiDrop: APIDrop(id: "17", canvas_location: [490, 475, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!,
    DroppedPortal(apiDrop: APIDrop(id: "18", canvas_location: [440, 425, 12], image_id: nil, portal_url: "https://www.nasa.gov/", api_geo_node: nil))!
]
let DEBUG_DROPPED_ABSTRACTIONS: [DroppedAbstraction] = [
    DroppedAbstraction(apiDrop: APIDrop(id: "81", canvas_location: [535, 500, 6], image_id: "8", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "72", canvas_location: [525, 370, 6], image_id: "7", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "63", canvas_location: [355, 470, 6], image_id: "6", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "54", canvas_location: [375, 550, 6], image_id: "5", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "45", canvas_location: [475, 550, 6], image_id: "4", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "36", canvas_location: [475, 450, 6], image_id: "3", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "27", canvas_location: [425, 400, 6], image_id: "2", portal_url: nil, api_geo_node: nil))!,
    DroppedAbstraction(apiDrop: APIDrop(id: "18", canvas_location: [465, 465, 1], image_id: "1", portal_url: nil, api_geo_node: nil))!
]

let DEBUG_DROPPED_ENTITY = DEBUG_DROPPED_ENTITIES[1]
let DEBUG_DROPPED_PORTAL = DEBUG_DROPPED_PORTALS[1]
let DEBUG_DROPPED_ABSTRACTION = DEBUG_DROPPED_ABSTRACTIONS[1]

