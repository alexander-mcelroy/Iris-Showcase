//
//  Map.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/4/21.
//

import SwiftUI
import Combine
import Mapbox
import Amplify
import AWSPluginsCore


//MARK: Leaf
struct Map: View {
    @ObservedObject var xylem: Map.Xylem
    let phloem: MapPhloem?
    @State private var presenting_write: Bool = false
    var body: some View {
        ZStack {
            MapboxView(xylem: xylem.mapboxViewXylem, phloem: self)
                .ignoresSafeArea()
            
            HostSelectionLabelLayer()
                .environmentObject(xylem)
        }
        .sheet(isPresented: $presenting_write) {
            EntityForm(xylem: xylem.entityFormXylem, phloem: self)
                .ignoresSafeArea()
        }
    }
}

struct Map_Previews: PreviewProvider {
    static var previews: some View {
        Map(xylem: DEBUG_DATA().xylem, phloem: nil)
    }
}

fileprivate struct HostSelectionLabelLayer: View {
    @EnvironmentObject var xylem: Map.Xylem
    var body: some View {
        VStack {
            if xylem.isInHostSelection {
                Text("Select an Iris")
                    .font(.system(size: 50, weight: .thin, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.top, 35)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .top)))
            }
            
            Spacer()
            
            if xylem.isInHostSelection {
                Text("or press a new location \nto create")
                    .font(.system(size: 25, weight: .thin, design: .default))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 35)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
            }
        }
        .animation(.easeIn)
    }
}




//MARK: Xylem
extension Map {
    class Xylem: ObservableObject {
        @Published var position: Position = .Organizations
        enum Position {
            case Organizations
            case Hosts
            case Network(host: Entity)
            case Links(ofEntity: Entity, host: Entity)
        }
        
        let mapboxViewXylem: MapboxView.Xylem = MapboxView.Xylem()
        let entityFormXylem: EntityForm.Xylem = EntityForm.Xylem()
        
        private var position_listener: AnyCancellable?
        private var organizations_loader: AnyCancellable?
        private var hosts_loader: AnyCancellable?
        private var network_loader: AnyCancellable?
        private var links_loader: AnyCancellable?
        
        private var trigger_pullers: [String: AnyCancellable] = [:]
        private var queued_triggers: [String] = []
        private var pulled_triggers: [String] = []
        
        init() {
            load_organizations()
            Staging.global.fly()
            
            position_listener = $position.sink { new_position in
                self.organizations_loader?.cancel()
                self.hosts_loader?.cancel()
                self.network_loader?.cancel()
                self.links_loader?.cancel()
                self.trigger_pullers.forEach { $0.1.cancel() }
                self.trigger_pullers = [:]
                
                self.queued_triggers = []
                self.pulled_triggers = []
                
                self.mapboxViewXylem.hostsmap = []
                
                var location: CLLocationCoordinate2D?
                let altitude: Double?
                switch new_position {
                case .Organizations:
                    altitude = HIGH_ALTITUDE
                    self.load_organizations()
                    
                case .Hosts:
                    altitude = HIGH_ALTITUDE
                    self.load_hosts()
                    
                case .Network(host: let host):
                    location = host.location
                    altitude = MEDIUM_ALTITUDE
                    self.load_network(host: host)
                    
                case .Links(ofEntity: let entity, host: let host):
                    location = entity.location
                    altitude = LOW_ALTITUDE
                    self.load_links(of: entity, host: host)
                }
                Staging.global.fly(location: location, altitude: altitude)
            }
        }
    }
}

extension Map.Xylem {
    var isInHostSelection: Bool {
        switch position {
        case .Hosts:
            return true
        case .Organizations, .Network, .Links:
            return false
        }
    }
    
    var isInOrganizationSelection: Bool {
        switch position {
        case .Organizations:
            return true
        case .Hosts, .Network, .Links:
            return false
        }
    }
    
    var isInLinks: Bool {
        switch position {
        case .Links:
            return true
        case .Organizations, .Hosts, .Network:
            return false
        }
    }
    
    var host: Entity? {
        if case .Network(host: let host) = position {
            return host
        } else if case .Links(ofEntity: _, host: let host) = position {
            return host
        } else {
            return nil
        }
    }
}

extension Map.Xylem {
    private func load_organizations() {
        self.mapboxViewXylem.mapboxStyle = .Dark
        self.mapboxViewXylem.hostsmap = []
        self.mapboxViewXylem.queryStyle = .Light
        self.mapboxViewXylem.queryMapURL = Pipeline.tap_ReadOrganizations
        self.mapboxViewXylem.annotationsMapURL = Pipeline.tap_ReadOrganizations
    }
    
    private func load_hosts() {
        self.mapboxViewXylem.mapboxStyle = .Dark
        self.mapboxViewXylem.hostsmap = []
        self.mapboxViewXylem.queryStyle = .None
        self.mapboxViewXylem.queryMapURL = nil
        self.mapboxViewXylem.annotationsMapURL = nil
        
        hosts_loader = Pipeline.tap_ReadHosts
            .receive(on: RunLoop.main)
            .sink {
                if case .failure = $0 {
                    Staging.global.alert(title: "Unable to load your irises", "Please try again in a few moments")
                }
            }
            receiveValue: {
                self.mapboxViewXylem.hostsmap = $0
            }
    }
    
    private func load_network(host: Entity) {
        self.mapboxViewXylem.mapboxStyle = .Satellite
        self.mapboxViewXylem.hostsmap = [host]
        self.mapboxViewXylem.queryStyle = .Rich
        self.mapboxViewXylem.queryMapURL = nil
        self.mapboxViewXylem.annotationsMapURL = nil
        
        network_loader = Pipeline.tap_ReadNetwork(host: host)
            .receive(on: RunLoop.main)
            .sink {
                if case .failure = $0 {
                    Staging.global.alert(title: "Unable to load network", "Please try again in a few moments")
                }
            }
            receiveValue: { (query_url, annotations_url) in
                self.mapboxViewXylem.queryMapURL = query_url
                self.mapboxViewXylem.annotationsMapURL = annotations_url
            }
    }
    
    private func load_links(of entity: Entity, host: Entity) {
        self.mapboxViewXylem.mapboxStyle = .Light
        self.mapboxViewXylem.hostsmap = []
        self.mapboxViewXylem.queryStyle = .Dark
        self.mapboxViewXylem.queryMapURL = nil
        self.mapboxViewXylem.annotationsMapURL = nil
        
        links_loader = Pipeline.tap_ReadLinks(of: entity, host: host)
            .receive(on: RunLoop.main)
            .sink {
                if case .failure = $0 {
                    Staging.global.alert(title: "Unable to load heatmap", "Please try again in a few moments")
                }
            }
            receiveValue: { (query_url, annotations_url) in
                self.mapboxViewXylem.queryMapURL = query_url
                self.mapboxViewXylem.annotationsMapURL = annotations_url
            }
    }
    
    func pullTriggers(triggerIds: [String], host: Entity) {
        var new: [String] = []
        triggerIds.forEach {
            if !new.contains($0) && !queued_triggers.contains($0) && !pulled_triggers.contains($0) {
                new.append($0)
            }
        }
        if new.isEmpty { return }
        
        if trigger_pullers.count < 10 {
            let key = UUID().uuidString
            trigger_pullers[key] =
                Pipeline.pump_PullTriggers(triggerIds: new + queued_triggers, host: host)
                    .receive(on: RunLoop.main)
                    .sink {
                        if case .failure = $0 {
                            Staging.global.alert(title: "Unable to load all irises", "Please try again in a few moments")
                        }
                    }
                    receiveValue: { _ in
                        self.mapboxViewXylem.objectWillChange.send()
                        self.trigger_pullers[key] = nil
                    }
            
            pulled_triggers += (new + queued_triggers)
            queued_triggers = []
            
        } else {
            queued_triggers += new
        }
    }
}




//MARK: Phloem
protocol MapPhloem {
    func didSelect(_ entity: Entity)
    func didSelect(organization: Entity)
    func didSelect(host: Entity)
}

extension MapPhloem {
    func didSelect(_ entity: Entity) {}
    func didSelect(organization: Entity) {}
    func didSelect(host: Entity) {}
}

extension Map: MapboxViewPhloem {
    func didPull(_ triggers: [String]) {
        if let host = xylem.host {
            xylem.pullTriggers(triggerIds: triggers, host: host)
        }
    }
    
    func didSelect(_ entity: Entity) {
        switch xylem.position {
        case .Organizations:
            phloem?.didSelect(organization: entity)
        case .Hosts:
            phloem?.didSelect(host: entity)
        case .Network, .Links:
            phloem?.didSelect(entity)
        }
    }
    
    func didLongPress(_ press: UILongPressGestureRecognizer, at location: CLLocationCoordinate2D) {
        switch xylem.position {
        case .Hosts:
            //BEGIN EXCEPTION to the rule
            xylem.entityFormXylem.position = .Create(defaultLocation: location)
            //END EXCEPTION
            presenting_write = true
        case .Organizations, .Network, .Links:
            return
        }
    }
}

extension Map: EntityFormPhloem {
    func didCreateHost(host: Entity) {
        phloem?.didSelect(host: host)
    }
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static var tap_ReadOrganizations: URL {
        PUBLIC_API_DOMIAN.appendingPathComponent("/organizations", isDirectory: false)
    }

    static var tap_ReadHosts: AnyPublisher<[Entity], Error> {
        let url = API_DOMAIN.appendingPathComponent("hosts", isDirectory: false)
        let request = URLRequest(url: url)
        
        return Pipeline.pump_APIRequest(request)
            .decode(type: APIData<[APIGeoNode]>.self, decoder: JSONDecoder())
            .map {
                $0.data.map { geo_node in
                    Entity(apiGeoNode: geo_node)
                }
            }
            .mapError { _ in
                AppError(title: "Read Hosts", reason: "Failed to decode API response")
            }
            .eraseToAnyPublisher()
    }
    
    static func tap_ReadNetwork(host: Entity) -> AnyPublisher<(URL,URL), Error> {
        let url = API_DOMAIN.appendingPathComponent("hosts/\(host.id)/network", isDirectory: false)
        let request = URLRequest(url: url)
        
        return Pipeline.pump_APIRequest(request)
            .tryMap {
                guard
                    let query_url = FileManager.overwrite(QUERY_GEOJSON, with: $0),
                    let annotations_url = FileManager.overwrite(ANNOTATIONS_GEOJSON, with: nil)
                else {
                    throw AppError(title: "Read Network", reason: "Failed to generate query url and annotations url")
                }
                return (query_url, annotations_url)
            }
            .eraseToAnyPublisher()
    }
    
    static func tap_ReadLinks(of entity: Entity, host: Entity) -> AnyPublisher<(URL, URL), Error> {
        let url = API_DOMAIN
            .appendingPathComponent("hosts/\(host.id)/network", isDirectory: false)
            .appending("filter", value: entity.id)
        let request = URLRequest(url: url)
        
        return Pipeline.pump_APIRequest(request)
            .tryMap {
                guard
                    let query_url = FileManager.overwrite(QUERY_GEOJSON, with: $0),
                    let annotations_url = FileManager.overwrite(ANNOTATIONS_GEOJSON, with: nil)
                else {
                    throw AppError(title: "Read Links", reason: "Failed to generate query url and annotations url")
                }
                return (query_url, annotations_url)
            }
            .eraseToAnyPublisher()
    }
    
    static func pump_PullTriggers(triggerIds: [String], host: Entity) -> AnyPublisher<Void, Error> {
        let url = API_DOMAIN.appendingPathComponent("hosts/\(host.id)/network/triggers", isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        return Just(())
            .tryMap { _ -> URLRequest in
                let body = APIPullTriggers(trigger_ids: triggerIds)
                let encoded = try JSONEncoder().encode(body)
                request.httpBody = encoded
                return request
            }
            .flatMap {
                Pipeline.pump_APIRequest($0)
                    .tryMap {
                        try FileManager.merge(geojson: ANNOTATIONS_GEOJSON, with: $0)
                    }
                    .eraseToAnyPublisher()
            }
            .mapError { _ in
                AppError(title: "Pull Triggers", reason: "Failed to complete")
            }
            .eraseToAnyPublisher()
    }
}

fileprivate extension FileManager {
    static func overwrite(_ filename: String, with data: Data?) -> URL? {
        let url = localURL(filename)
        if FileManager.default.fileExists(atPath: url.path) {
            do { try FileManager.default.removeItem(at: url) }
            catch { return nil }
        }
        FileManager.default.createFile(atPath: url.path, contents: data)
        return url
    }
    
    static func merge(geojson: String, with geojsonData: Data) throws {
        let data = try Data(contentsOf: localURL(geojson), options: .mappedIfSafe)
        if data.isEmpty {
            let _ = overwrite(geojson, with: geojsonData)
            return
        }
        
        let new = try JSONDecoder().decode(APIGeoJSON.self, from: geojsonData)
        let current = try JSONDecoder().decode(APIGeoJSON.self, from: data)
        let combined = APIGeoJSON(
            type: current.type,
            crs: current.crs,
            features: current.features + new.features)
        
        let combined_data = try JSONEncoder().encode(combined)
        let _ = overwrite(geojson, with: combined_data)
    }
    
    static func localURL(_ filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }
}




//MARK: To Move
extension URL {
    func appending(_ queryItem: String, value: String?) -> URL {

        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

        // Create query item
        let queryItem = URLQueryItem(name: queryItem, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        return urlComponents.url!
    }
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem: Map.Xylem = Map.Xylem()
    init() {
        xylem.position = .Network(host: DEBUG_HOST)
    }
}
fileprivate let DEBUG_EQ_GEOJSON_URL = URL(string: "https://www.mapbox.com/mapbox-gl-js/assets/earthquakes.geojson")!
fileprivate let QUERY_GEOJSON = "query.geojson"
fileprivate let ANNOTATIONS_GEOJSON = "annotations.geojson"
fileprivate let HIGH_ALTITUDE: Double = 8000000
fileprivate let MEDIUM_ALTITUDE: Double = 6000000
fileprivate let LOW_ALTITUDE: Double = 800000
