//
//  EntryIOS.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 5/27/21.
//

import SwiftUI
import CoreLocation
import Combine
import Amplify
import AWSPluginsCore


//MARK: Leaf
struct MainIOS: View {
    @EnvironmentObject var xylem: Xylem
    @EnvironmentObject var staging: Staging

    var body: some View {
        ZStack {
            Map(xylem: xylem.mapXylem, phloem: xylem)
            
            Header(xylem: xylem.headerXylem, phloem: xylem)
            
            Authenticator(xylem: xylem.authenticatorXylem, phloem: xylem)
                .opacity(xylem.booting ? 0 : 1)
            
            if staging.locked {
                ZoomingEarthImage()
                    .transition(.opacity)
                    .animation(.linear)
                    .ignoresSafeArea()
            }
            
            Color("Base")
                .allowsHitTesting(xylem.booting)
                .opacity(xylem.booting ? 1 : 0)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 1))
            
        }
        .alert(isPresented: $staging.alertVisible) {
            Alert(
                title: Text(staging.alert?.title ?? "Unable to complete"),
                message: Text(staging.alert?.message ?? "Please try again in a few minutes"),
                dismissButton: .default(Text("dismiss")))
        }
    }
}

struct MainIOS_Previews: PreviewProvider {
    static var previews: some View {
        MainIOS()
            .environmentObject(MainIOS.Xylem())
    }
}




//MARK: Xylem
extension MainIOS {
    class Xylem: ObservableObject {
        let mapXylem: Map.Xylem = Map.Xylem()
        let headerXylem: Header.Xylem = Header.Xylem()
        let authenticatorXylem: Authenticator.Xylem = Authenticator.Xylem()
        
        @Published fileprivate var booting = true
        private var booter: AnyCancellable?
        
        init() {
            booter = Pipeline.tap_IsSignedIn().delay(for: .seconds(1), scheduler: RunLoop.main).sink {
                if $0 {
                    self.didSignIn() 
                } else {
                    self.didSignOut()
                }
                self.booting = false
            }
        }
    }
}

extension MainIOS.Xylem {
    private func updated_entity_path(adding entity: Entity) -> [Entity] {
        guard let host = headerXylem.host else {
            preconditionFailure("Selecting entity requires a host")
        }

        if host.id == entity.id {
            return [entity]
        }
        else if let current_path = headerXylem.path, let i = current_path.firstIndex(where: { $0.id == entity.id }) {
            return Array(current_path[...(i - 1)] + [entity])
        }
        else if let current_path = headerXylem.path {
            return current_path + [entity]
        }
        else {
            return [entity]
        }
    }
}




//MARK: Phloem
fileprivate typealias Phloem = MapPhloem & AuthenticatorPhloem & HeaderPhloem
extension MainIOS.Xylem: Phloem {
    func didSelect(organization: Entity) {
        //DOWNSTREAM
        precondition(mapXylem.isInOrganizationSelection)
        precondition(headerXylem.isBlind)
        precondition(!authenticatorXylem.authenticated && !authenticatorXylem.inCandidacy)
        
        authenticatorXylem.position = .Candidate(organization: organization)
    }
    
    func didCancelSignIn() {
        //DOWNSTREAM
        precondition(mapXylem.isInOrganizationSelection)
        precondition(headerXylem.isBlind)
        precondition(!authenticatorXylem.authenticated)
        
        authenticatorXylem.position = .Unauthenticated
    }
    
    func didSignIn() {
        //DOWNSTREAM
        precondition(mapXylem.isInOrganizationSelection)
        precondition(headerXylem.isBlind)
        precondition(!authenticatorXylem.authenticated)
        
        mapXylem.position = .Hosts
        authenticatorXylem.position = .Authenticated
    }
    
    func didSelect(host: Entity) {
        //DOWNSTREAM
        precondition(mapXylem.isInHostSelection || mapXylem.isInLinks)
        precondition(headerXylem.centeredEntityIsHost || headerXylem.isBlind)
        precondition(authenticatorXylem.authenticated)
        
        mapXylem.position = .Network(host: host)
        headerXylem.position = .Hosted(host: host)
    }
    
    func didSelect(_ entity: Entity) {
        //DOWNSTREAM
        precondition(!mapXylem.isInHostSelection && !mapXylem.isInOrganizationSelection)
        precondition(!headerXylem.isBlind)
        precondition(authenticatorXylem.authenticated)
        
        guard let host = headerXylem.host else {
            preconditionFailure("Cannot select entity without host")
        }
        
        mapXylem.position = .Links(ofEntity: entity, host: host)
        headerXylem.position = .Explored(host: host, path: updated_entity_path(adding: entity))
    }
    
    
    func didSignOut() {
        //DOWNSTREAM
        mapXylem.position = .Organizations
        headerXylem.position = .Blind
        authenticatorXylem.position = .Unauthenticated
    }
    
    func didExitHost() {
        //DOWNSTREAM
        precondition(authenticatorXylem.authenticated)
        mapXylem.position = .Hosts
        headerXylem.position = .Blind
    }
    
    func didSelectGlobe() {
        //DOWNSTREAM
        precondition(!mapXylem.isInHostSelection && !mapXylem.isInOrganizationSelection)
        precondition(headerXylem.centeredEntity != nil)
        precondition(authenticatorXylem.authenticated)
        guard let host = headerXylem.host else {
            preconditionFailure("Cannot select globe without host")
        }
        mapXylem.position = .Network(host: host)
        headerXylem.position = .Hosted(host: host)
    }
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func tap_IsSignedIn() -> AnyPublisher<Bool, Never> {
        Auth0Manager.isSignedIn()
    }
}
