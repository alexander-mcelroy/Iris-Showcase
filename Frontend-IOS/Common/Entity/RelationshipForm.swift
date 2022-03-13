//
//  RelationshipForm.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/20/21.
//

import SwiftUI
import Combine

//MARK: Leaf
struct RelationshipForm: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var xylem: Xylem
    let phloem: RelationshipFormPhloem?
    var body: some View {
        ZStack {
            if let host = xylem.host, let entity = xylem.entity {
                Backdrop(entity: entity)
                
                VStack {
                    RelationshipSlider(relationship: $xylem.proposedRelationship)
                        .padding(.top, 55)
                    
                    PermissionsLabel(host: host, entity: entity, proposedRelationship: xylem.proposedRelationship)
                        .padding(.top)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    ZStack {
                        ReportButton {
                            xylem.sendReport()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .opacity(
                            xylem.proposedRelationship == entity.relationship &&
                            xylem.proposedRelationship != .Admin ? 1 : 0)


                        ConfirmationButton {
                            xylem.send {
                                phloem?.didUpdateRelationship(of: $0)
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                        .opacity(
                            xylem.proposedRelationship != entity.relationship &&
                            xylem.proposedRelationship != .Admin ? 1 : 0)
                    }
                    .padding(.bottom, 60)
                    .animation(.easeIn)
                }
            }
        }
        .onDisappear {
            xylem.revertChangesIfNeccessary()
        }
    }
}

struct RelationshipForm_Previews: PreviewProvider {
    static var previews: some View {
        RelationshipForm(xylem: DEBUG_DATA().xylem, phloem: nil)
    }
}

fileprivate struct Backdrop: View {
    let entity: Entity
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BACKDROP_COLOR
                RemoteImage(url: entity.portraitImageURL)
                    .scaledToFill()
                    .clipped()
                BlurView()
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

fileprivate struct PermissionsLabel: View {
    let host: Entity
    let entity: Entity
    let proposedRelationship: Entity.Relationship
    var body: some View {
        GeometryReader { geometry in
            HStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        Text("Visibility")
                            .font(.system(size: 40, weight: .thin, design: .default))
                            .foregroundColor(proposedRelationship == .Distant ? Color.white : Color.orange)
                        
                        Text(visibility_condition)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.leading, 30)
                            .padding(.bottom)
                            

                        Text("Reachability")
                            .font(.system(size: 40, weight: .thin, design: .default))
                            .foregroundColor(
                                proposedRelationship == .Distant ||
                                proposedRelationship == .Aquainted ? Color.white : Color.orange)
                        
                        Text(reachability_condition)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.leading, 30)
                            .padding(.bottom)

                        Text("Modification")
                            .font(.system(size: 40, weight: .thin, design: .default))
                            .foregroundColor(proposedRelationship == .Admin ? Color.orange : Color.white)
                        
                        Text(modification_condition)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.leading, 30)
                            .padding(.bottom)
                        
                        Spacer()
                    }
                }
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .foregroundColor(.white)
        }
    }
    
    var visibility_condition: String {
        switch proposedRelationship {
        case .Peer, .Admin:
            return "\(entity.name) can see full profile of \(host.name), including live location (if available)"
        case .Aquainted:
            return "\(entity.name) can see full profile of \(host.name), not including live location"
        case .Distant:
            return "\(entity.name) can only see basic \(host.name) information"
        }
    }
    
    var reachability_condition: String {
        switch proposedRelationship {
        case .Peer, .Admin:
            return "\(host.name) can be directly reached from from \(entity.name)"
        case .Distant, .Aquainted:
            return "\(host.name) is not directly reachable from \(entity.name)"
        }
    }
    
    var modification_condition: String {
        switch proposedRelationship {
        case .Admin:
            return "\(entity.name) can edit and delete the \(host.name)"

        case .Distant, .Aquainted, .Peer:
            return "\(entity.name) cannot edit any components of the \(host.name)"
        }
    }
}

fileprivate extension RelationshipForm {
    class RelationshipWrapper: ObservableObject {
        @Published var relationship: Entity.Relationship
        init(relationship: Entity.Relationship) {
            self.relationship = relationship
        }
    }
}




//MARK: Xylem
extension RelationshipForm {
    class Xylem: ObservableObject {
        @Published var position: Position = .Blind
        enum Position {
            case Blind
            case Update(entity: Entity, host: Entity)
        }
        @Published fileprivate var proposedRelationship: Entity.Relationship = .Distant
        private var position_listener: AnyCancellable?
        private var sender: AnyCancellable?
        private var report_sender: AnyCancellable?
        
        init() {
            position_listener = $position.sink {
                switch $0 {
                case .Blind:
                    return
                case .Update(entity: let entity, host: _):
                    //BEGIN EXCEPTION to the rule
                    self.proposedRelationship = entity.relationship
                    //END EXCEPTION
                }
            }
        }
    }
}

fileprivate extension RelationshipForm.Xylem {
    var entity: Entity? {
        if case .Update(entity: let entity, host: _) = position {
            return entity
        }
        return nil
    }
    
    var host: Entity? {
        if case .Update(entity: _, host: let host) = position {
            return host
        }
        return nil
    }
    
    func revertChangesIfNeccessary() {
        proposedRelationship = entity?.relationship ?? .Distant
    }
}

fileprivate extension RelationshipForm.Xylem {
    func send(_ onSuccess: @escaping (Entity) -> Void) {
        guard let entity = entity, let host = host else { return }

        Staging.global.lock()
        sender = Pipeline.pump_UpdateRelationship(host: host, entity: entity, relationship: proposedRelationship)
            .receive(on: RunLoop.main)
            .sink {
                if case .failure = $0 {
                    Staging.global.alert(title: "Unable to Update Relationship", "Please try again in a few moments")
                }
                Staging.global.unlock()
            }
            receiveValue: {
                onSuccess($0)
                Staging.global.unlock()
            }
    }
    
    func sendReport() {
        guard let entity = entity, let host = host else { return }

        Staging.global.lock()
        report_sender = Pipeline.pump_CreateReport(host: host, entity: entity)
            .receive(on: RunLoop.main)
            .sink {
                if case .failure = $0 {
                    Staging.global.alert(title: "Unable to File Report", "Please try again in a few moments")
                }
                Staging.global.unlock()
            }
            receiveValue: { _ in
                Staging.global.unlock()
            }
    }
}




//MARK: Phloem
protocol RelationshipFormPhloem {
    func didUpdateRelationship(of entity: Entity)
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func pump_UpdateRelationship(host: Entity, entity: Entity, relationship: Entity.Relationship) -> AnyPublisher<Entity, Error> {
        Just([URLQueryItem(name: "filter", value: entity.id)])
            //Craft URL
            .tryMap { query_items -> URL in
                guard let url =
                    API_DOMAIN
                        .appendingPathComponent("hosts/\(host.id)/network", isDirectory: false)
                        .appendingQueryItems(query_items)
                else {
                    throw AppError(title: "Update Relationship", reason: "Failed to craft URL")
                }
                return url
            }
            
            //Encode Body
            .tryMap { url -> (URL, Data) in
                let body = APIUpdateNetwork(weight: relationship)
                let data = try JSONEncoder().encode(body)
                return (url, data)
            }
            .mapError { _ in
                AppError(title: "Update Relationship", reason: "Failed to encode http body")
            }
            
            //Upload to Server
            .flatMap { (url, data) -> AnyPublisher<Entity, Error> in
                var request = URLRequest(url: url)
                request.httpMethod = "PATCH"
                request.httpBody = data
                
                return Pipeline.pump_APIRequest(request)
                    .decode(type: APIData<APIGeoNode>.self, decoder: JSONDecoder())
                    .map { Entity(apiGeoNode: $0.data) }
                    .mapError { _ in
                        AppError(title: "Update Relationship", reason: "Failed to decode API response")
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    static func pump_CreateReport(host: Entity, entity: Entity) -> AnyPublisher<String, Error> {
        let url = API_DOMAIN.appendingPathComponent("/hosts/\(host.id)/reports/\(entity.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        return Pipeline.pump_APIRequest(request)
            .decode(type: APIData<APIServerMessage>.self, decoder: JSONDecoder())
            .map { $0.data.message }
            .mapError { _ in
                AppError(title: "Create Report", reason: "Failed to decode API response")
            }
            .eraseToAnyPublisher()
    }
}




//MARK: To Move
extension URL {
    func appendingQueryItems(_ items: [URLQueryItem]) -> URL? {
        var url_components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        url_components?.queryItems = items
        return url_components?.url
    }
}




//MARK: Constants
fileprivate class DEBUG_DATA {
    let xylem: RelationshipForm.Xylem
    init() {
        xylem = RelationshipForm.Xylem()
        xylem.position = .Update(entity: DEBUG_ENTITY, host: DEBUG_HOST)
    }
}
fileprivate let BACKDROP_COLOR: Color = Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255)
