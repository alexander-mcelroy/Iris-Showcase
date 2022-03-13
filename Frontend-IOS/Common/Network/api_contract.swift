//
//  APIContract.swift
//  Owl (iOS)
//
//  Created by Developer on 7/3/21.
//

import Foundation
import SwiftUI

let API_DOMAIN: URL = URL(string: "https://4s9pe4gqvc.execute-api.us-east-2.amazonaws.com/dev/private")!
let PUBLIC_API_DOMIAN: URL = URL(string: "https://4s9pe4gqvc.execute-api.us-east-2.amazonaws.com/dev/public")!


//MARK: Read
struct APIData<T: Codable>: Codable {
    let data: T
}

struct APIGeoJSON: Codable {
    let type: String
    let crs: CRS
    let features: [APIGeoNode] 
    
    struct CRS: Codable {
        let type: String
        let properties: Properties
        
        struct Properties: Codable {
            let name: String
        }
    }
}

struct APIGeoTrigger: Codable {
    let type: String
    let properties: Properties
    let geometry: APIGeoNode.Geometry
    
    struct Properties: Codable {
        let trigger_id: String
        let zoom: Double
    }
}

struct APIGeoNode: Codable {
    let type: String
    let properties: Properties
    let geometry: Geometry

    struct Properties: Codable {
        let id: String
        let name: String
        let description: String
        let live_location_enabled: Bool?
        let zoom: Double
        let media: Media
        let weight: Weight
        let counter_weight: CounterWeight
        
        struct Media: Codable {
            let portrait_id: String
            let supplement_id: String
        }
        
        enum Weight: String, Codable {
            case Admin
            case Peer
            case Aquainted
            case Distant
        }
        
        enum CounterWeight: String, Codable {
            case Close
            case Distant
        }
    }
    
    struct Geometry: Codable {
        let type: String
        let coordinates: [Double]
    }
}

struct APIDrop: Codable {
    let id: String
    let canvas_location: [Double]
    let image_id: String?
    let portal_url: String?
    let api_geo_node: APIGeoNode?
}

struct APIServerMessage: Codable {
    let message: String
}

enum APIMediaExtension: String, Codable {
    case png
    case jpg
    case mp4
    case mov
}




//MARK: Write
struct APICreateHost: Codable {
    let id: String
    let name: String
    let description: String
    let default_location: [String]
    let live_location: [String]?
    let portrait_id: String
    let supplement_id: String
}

struct APIUpdateHost: Codable {
    let description: String?
    let live_location: [String]?
    let portrait_id: String?
    let supplement_id: String?
}

struct APIUpdateNetwork: Codable {
    let weight: APIGeoNode.Properties.Weight
}

struct APIPullTriggers: Codable {
    let trigger_ids: [String]
}

struct APICreateDrop: Codable {
    let id: String
    let canvas_location: [String]
    let image_id: String?
    let portal_url: String?
}

