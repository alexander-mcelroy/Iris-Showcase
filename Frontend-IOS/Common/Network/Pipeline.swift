//
//  Pipeline.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/13/21.
//

import Foundation
import Combine
import MapKit
import CoreLocation
import Amplify
import AWSPluginsCore


//Pipeline
class Pipeline: NSObject, ObservableObject {
    static var state: Pipeline = Pipeline()
    @Published var deviceLocationStatus: DeviceLocationStatus
    fileprivate let cll_manager: CLLocationManager = CLLocationManager()
    
    override init() {
        deviceLocationStatus = Pipeline.fetch_location_status(cll_manager)
        super.init()
        cll_manager.delegate = self
    }
}

//Media
extension Pipeline {
    static func tap_UIImage(url: URL) -> AnyPublisher<UIImage, Error> {
        let request = URLRequest(url: url)
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw AppError(title: "Tap UIImage", reason: "Not a 200 response from provider")
                    }
                return element.data
            }
            .tryMap { data in
                guard let image = UIImage(data: data) else {
                    throw AppError(title: "Tap UIImage", reason: "Failed to decode raw image data")
                }
                return image
            }
            .eraseToAnyPublisher()
    }
    
    fileprivate static func tap_NewS3Key(ext: MediaExtension) -> AnyPublisher<String, Error> {
        Auth0Manager.fetchUserId()
            .tryMap { user_id -> String in
                guard let user_id = user_id else {
                    throw AppError(title: "Tap New S3 Key", reason: "Failed to fetch user id from Auth0")
                }
                return user_id
            }
            .flatMap { user_id in
                Pipeline.tap_IdentityId()
                    .map { ($0, user_id) }
            }
            .map { (identity_id, user_id) in
                "\(identity_id)" + "/\(user_id)" + "/\(UUID().uuidString)" + ".\(ext)"
            }
            .eraseToAnyPublisher()
    }
    
    static func pump_ImageS3(image: UIImage) -> AnyPublisher<String, Error> {
        Just(image.jpegData(compressionQuality: 0.25))
            .tryMap {
                guard let jpg_data = $0 else {
                    throw AppError(
                        title: "Pump Movie S3",
                        reason: "Failed to extract jpg data from UIImage",
                        userFriendlyTitle: "Unable to upload image")
                }
                return jpg_data
            }
            .flatMap { jpg_data in
                Pipeline.tap_NewS3Key(ext: .jpg)
                    .map { ($0, jpg_data) }
            }
            .flatMap { (key, jpg_data) in
                Amplify.Storage
                    .uploadData(key: key, data: jpg_data, options: StorageUploadDataRequest.Options(accessLevel: .guest))
                    .resultPublisher
                    .map { "public/\($0)" }
                    .mapError {
                        AppError(
                            title: "Pump Image S3",
                            reason: $0.debugDescription,
                            userFriendlyTitle: "Unable to upload image")
                    }
            }
            .eraseToAnyPublisher()
    }
    
    static func pump_MovieS3(movie: URL) -> AnyPublisher<String, Error> {
        Just(movie.mediaExtension)
            .tryMap {
                guard let ext = $0, (ext == .mov || ext == .mp4) else {
                    throw AppError(
                        title: "Pump Movie S3",
                        reason: "Invalid movie URL extension",
                        userFriendlyTitle: "Unable to upload movie")
                }
                return ext
            }
            .flatMap {
                Pipeline.tap_NewS3Key(ext: $0)
            }
            .flatMap {
                Amplify.Storage
                    .uploadFile(key: $0, local: movie, options: StorageUploadFileRequest.Options(accessLevel: .guest))
                    .resultPublisher
                    .map { "public/\($0)" }
                    .mapError {
                        AppError(
                            title: "Pump Movie S3",
                            reason: $0.debugDescription,
                            userFriendlyTitle: "Unable to upload movie")
                    }
            }
            .eraseToAnyPublisher()
    }
}

//Cognito
extension Pipeline {
    fileprivate static func tap_IdentityId() -> AnyPublisher<String, Error> {
        Amplify.Auth.fetchAuthSession()
            .resultPublisher
            .tryMap { session -> AuthCognitoIdentityProvider in
                guard let provider = session as? AuthCognitoIdentityProvider else {
                    throw AppError(title: "Tap Identity Id", reason: "Auth session is not an AuthCognitoIdentityProvider")
                }
                return provider
            }
            .tryMap {
                do { return try $0.getIdentityId().get() }
                catch { throw AppError(title: "Tap Identity Id", reason: error.localizedDescription) }
            }
            .eraseToAnyPublisher()
    }
}

//API
extension Pipeline {
    static func pump_APIRequest(_ request: URLRequest) -> AnyPublisher<Data, Error> {
        Auth0Manager.fetchAccessToken()
            .tryMap { access_token -> String in
                guard let access_token = access_token else {
                    throw AppError(title: "API Request", reason: "Failed to fetch access token from Auth0")
                }
                return access_token
            }
            .flatMap { access_token -> AnyPublisher<Data, Error> in
                var auth_request = request
                auth_request.addValue(access_token, forHTTPHeaderField: "Authorization")
                return URLSession.shared.dataTaskPublisher(for: auth_request)
                    .tryMap { element -> Data in
                        guard let httpResponse = element.response as? HTTPURLResponse,
                            httpResponse.statusCode == 200 else {
                                throw AppError(title: "API Request", reason: "Recieved non-200 response code")
                            }
                        return element.data
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

//Device Location
extension Pipeline: CLLocationManagerDelegate {
    static func pump_RequestDeviceLocation() {
        state.cll_manager.requestWhenInUseAuthorization()
    }
    
    var deviceLocation: CLLocationCoordinate2D? {
        if case let .Available(location: location) = deviceLocationStatus {
            return location
        }
        return nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        deviceLocationStatus = Pipeline.fetch_location_status(cll_manager)
    }
    
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        deviceLocationStatus = Pipeline.fetch_location_status(cll_manager)
    }
    
    static fileprivate func fetch_location_status(_ manager: CLLocationManager) -> DeviceLocationStatus {
        if let location = manager.location {
            return .Available(location: location.coordinate)
        
        } else if manager.authorizationStatus == .notDetermined {
            return .Undecided
            
        } else  {
            return .Unavailable
        }
    }
    
    enum DeviceLocationStatus {
        case Available(location: CLLocationCoordinate2D)
        case Undecided
        case Unavailable
        
        var isUnavailable: Bool {
            switch self {
            case .Unavailable:
                return true
            case .Available(location: _), .Undecided:
                return false
            }
        }
        
        var isUndecided: Bool {
            switch self {
            case .Undecided:
                return true
            case .Available(location: _), .Unavailable:
                return false
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .Available(location: _):
                return true
            case .Undecided, .Unavailable:
                return false
            }
        }
    }
}

//URL
extension URL {
    var mediaExtension: MediaExtension? {
        MediaExtension(rawValue: pathExtension)
    }
}





//MARK: Constants
fileprivate let GALAXY_MOVIE_URL = URL(string: "https://static.videezy.com/system/resources/previews/000/045/557/original/Uluru_Milkyway_2.mp4")!
