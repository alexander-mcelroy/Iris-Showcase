//
//  Authenticator.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/4/21.
//

import SwiftUI
import Auth0
import Combine


//MARK: Leaf
struct Authenticator: View {
    @ObservedObject var xylem: Xylem
    let phloem: AuthenticatorPhloem?
    var body: some View {
        ZStack {
            MediaLayer(phloem: phloem)
                .ignoresSafeArea()
                .opacity(xylem.inCandidacy ? 1 : 0)
            
            VStack {
                Text("Welcome")
                    .font(.system(size: 55, weight: .thin, design: .default))
                    .foregroundColor(.white)
                    .padding(.top, 55)
                    .opacity(xylem.inCandidacy ? 0 : 1)
                    .animation(.easeIn)
                
                Spacer()
                
                if xylem.inCandidacy {
                    SignInLayer(phloem: phloem)
                        .transition(.move(edge: .bottom))
                        .animation(.easeIn(duration: 0.2))
                }
            }
        }
        .opacity(xylem.authenticated ? 0 : 1)
        .environmentObject(xylem)
    }
}

struct Authenticator_Previews: PreviewProvider {
    static var previews: some View {
        Authenticator(xylem: DEBUG_DATA().xylem, phloem: nil)
            .previewLayout(.fixed(width: 390, height: 700))
            .frame(width: 390, height: 700, alignment: .center)
            .previewDisplayName("Authenticator")
            .background(Color.gray)
    }
}

fileprivate struct MediaLayer: View {
    @EnvironmentObject var xylem: Authenticator.Xylem
    let phloem: AuthenticatorPhloem?
    var body: some View {
        ZStack {
            BACKDROP_COLOR
                .animation(.easeIn)
                
            if let organization = xylem.organization {
                EntityBackdrop(entity: organization)
                    .transition(.opacity)
            }
        }
        .animation(.linear(duration: 1).delay(1))
        .onTapGesture {
            phloem?.didCancelSignIn()
        }
    }
}

fileprivate struct SignInLayer: View {
    @EnvironmentObject var xylem: Authenticator.Xylem
    let phloem: AuthenticatorPhloem?
    var body: some View {
        VStack {
            VStack {
                Text("By tapping Accept & Sign In, you acknowledge that you have read and agree to the following:")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(.white)
                
                HStack {
                    
                    Link(destination: PRIVACY_POLICY_URL, label: {
                        Text("Privacy Policy")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white))
                    })
                    .padding(.trailing)
                    
                    Link(destination: TERMS_URL, label: {
                        Text("Terms and Conditions")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white))
                    })
                    .padding(.trailing)
                    
                    Link(destination: EULA_URL, label: {
                        Text("End-User License Agreement")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white))
                    })
                }
            }
            .padding()
            .background(BlurView())
            .clipShape(RoundedRectangle(cornerRadius: 25.0))
                
            
            Button {
                xylem.attemptSignIn {
                    phloem?.didSignIn()
                }
            }
            label: {
                Text("Accept & Sign In")
                    .font(.system(size: 25, weight: .thin, design: .default))
                    .foregroundColor(.orange)
            }
            .padding()
            .background(BlurView())
            .clipShape(RoundedRectangle(cornerRadius: 20.0))
        }
        .frame(width: 310, height: 250, alignment: .center)
    }
}




//MARK: Xylem
extension Authenticator {
    class Xylem: ObservableObject {
        @Published var position: Position = .Unauthenticated
        enum Position {
            case Authenticated
            case Unauthenticated
            case Candidate(organization: Entity)
        }
        
        private var sign_in_loader: AnyCancellable?
        
        fileprivate func attemptSignIn(onSuccess: @escaping () -> Void) {
            sign_in_loader = Pipeline.pump_SignIn().sink { signed_in in
                if signed_in {
                    onSuccess()
                } else {
                    Staging.global.alert(title: "Unable to Sign In", "")
                }
            }
        }
    }
}

extension Authenticator.Xylem {
    var organization: Entity? {
        switch position {
        case .Candidate(organization: let org):
            return org
        case .Authenticated, .Unauthenticated:
            return nil
        }
    }
    
    var authenticated: Bool {
        switch position {
        case .Authenticated:
            return true
        case .Unauthenticated, .Candidate(organization: _):
            return false
        }
    }
    
    var inCandidacy: Bool {
        switch position {
        case .Candidate(organization: _):
            return true
        case .Authenticated, .Unauthenticated:
            return false
        }
    }
}




//MARK: Phloem
protocol AuthenticatorPhloem {
    func didCancelSignIn()
    func didSignIn()
    func didSignOut()
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func pump_SignIn() -> AnyPublisher<Bool, Never> {
        Auth0Manager.signIn()
    }
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem: Authenticator.Xylem = Authenticator.Xylem()
    init() {
        xylem.position = .Candidate(organization: DEBUG_ENTITY)
    }
}

fileprivate let BACKDROP_COLOR: Color = Color("Base")
let PRIVACY_POLICY_URL: URL = URL(string: "https://www.termsfeed.com/live/4f9befee-ec28-4aae-8e5a-e00ebf897bee")!
let TERMS_URL: URL = URL(string: "https://www.termsfeed.com/live/4f2f532a-ce17-4151-a801-c8e88de686ed")!
let EULA_URL: URL = URL(string: "https://www.termsfeed.com/live/29b20b50-4046-440e-97b1-8e754c67605a")!
