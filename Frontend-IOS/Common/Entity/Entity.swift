//
//  Entity.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/5/21.
//

import Foundation
import Mapbox


struct Entity {
    let id: String
    let name: String
    let location: CLLocationCoordinate2D
    let liveLocationEnabled: Bool?
    let description: String
    let portraitImageURL: URL
    let supplementalImageURL: URL?
    let supplementalMovieURL: URL?
    let relationship: Relationship
    let counterRelationship: CounterRelationship
    let zoom: Double
    
    typealias Relationship = APIGeoNode.Properties.Weight
    typealias CounterRelationship = APIGeoNode.Properties.CounterWeight
}

extension Entity {
    init(apiGeoNode: APIGeoNode) {
        self.id = apiGeoNode.properties.id
        self.name = apiGeoNode.properties.name
        self.location = .init(
            latitude: apiGeoNode.geometry.coordinates[safe: 1] ?? 0,
            longitude: apiGeoNode.geometry.coordinates.first ?? 0)
        self.liveLocationEnabled = apiGeoNode.properties.live_location_enabled
        self.description = apiGeoNode.properties.description
        self.relationship = apiGeoNode.properties.weight
        self.counterRelationship = apiGeoNode.properties.counter_weight
        self.zoom = apiGeoNode.properties.zoom
        
        guard
            let portrait_url = URL(string: apiGeoNode.properties.media.portrait_id),
            let supplement_url = URL(string: apiGeoNode.properties.media.supplement_id),
            let supplement_extension = MediaExtension(rawValue: supplement_url.pathExtension)
        else {
            preconditionFailure("Invalid ApiGeoNode provided")
        }

        self.portraitImageURL = portrait_url
        switch supplement_extension {
        case .jpg, .png:
            self.supplementalImageURL = supplement_url
            self.supplementalMovieURL = nil
        case .mov, .mp4:
            self.supplementalImageURL = nil
            self.supplementalMovieURL = supplement_url
        }
    }
}

extension Array where Element == Entity {
    func contains(_ entity: Entity) -> Bool {
        contains { val in
            entity.id == val.id
        }
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

typealias MediaExtension = APIMediaExtension

let DEBUG_ENTITY = Entity(
    id: "debug_entity_id",
    name: "Debug Entity Name",
    location: .init(latitude: 42.4534, longitude: -76.4735),
    liveLocationEnabled: nil,
    description: "Debug entity destcription",
    portraitImageURL: URL(string: "d1")!,
    supplementalImageURL: URL(string: "d2")!,
    supplementalMovieURL: nil,
    relationship: .Peer,
    counterRelationship: .Close,
    zoom: 2)
let DEBUG_HOST = Entity(
    id: "debug_host_id",
    name: "Debug Host Name",
    location: .init(latitude: 42.4534, longitude: -76.4735),
    liveLocationEnabled: true,
    description: "Debug host destcription",
    portraitImageURL: URL(string: "d3")!,
    supplementalImageURL: URL(string: "d4")!,
    supplementalMovieURL: nil,
    relationship: .Admin,
    counterRelationship: .Close,
    zoom: 2)

let DEBUG_API_GEO_NODE = APIGeoNode(
    type: "Feature",
    properties: APIGeoNode.Properties(
        id: "1",
        name: "Debug Api GeoNode",
        description: "",
        live_location_enabled: nil,
        zoom: 2,
        media: APIGeoNode.Properties.Media(
            portrait_id: "https://www.nasa.gov/sites/default/files/thumbnails/image/potw2126a.jpg",
            supplement_id: "https://www.nasa.gov/sites/default/files/thumbnails/image/potw2126a.jpg"),
        weight: .Peer,
        counter_weight: .Close),
    geometry: APIGeoNode.Geometry())

fileprivate extension APIGeoNode.Geometry {
    init() {
        self.type = "Point"
        self.coordinates = [-76.4735, 42.4534]
    }
}
