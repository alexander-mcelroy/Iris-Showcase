//
//  AppError.swift
//  Iris (iOS)
//
//  Created by Rhizome Networking LLC on 9/24/21.
//

import Foundation

struct AppError: Error {
    private let title: String
    private let reason: String
    private let user_friendly_title: String
    private let user_friendly_message: String
    
    init(title: String, reason: String, userFriendlyTitle: String?, userFriendlyMessage: String?) {
        self.title = title
        self.reason = reason
        self.user_friendly_title = userFriendlyTitle ?? AppError.DEFAULT_FRIENDLY_TITLE
        self.user_friendly_message = userFriendlyMessage ?? AppError.DEFAULT_FRIENDLY_MESSAGE
        log()
    }
    
    init(title: String, reason: String, userFriendlyTitle: String?) {
        self.title = title
        self.reason = reason
        self.user_friendly_title = userFriendlyTitle ?? AppError.DEFAULT_FRIENDLY_TITLE
        self.user_friendly_message = AppError.DEFAULT_FRIENDLY_MESSAGE
        log()
    }
    
    init(title: String, reason: String) {
        self.title = title
        self.reason = reason
        self.user_friendly_title = AppError.DEFAULT_FRIENDLY_TITLE
        self.user_friendly_message = AppError.DEFAULT_FRIENDLY_MESSAGE
        log()
    }
    
    func presentToUser() {
        Staging.global.alert(title: user_friendly_title, user_friendly_message)
    }
    
    private func log() {
        print("\n\nAPP ERROR - \(title)\nReason: \(reason)\n\n")
    }
    
    private static let DEFAULT_FRIENDLY_TITLE: String = "Unable to fullfill your request"
    private static let DEFAULT_FRIENDLY_MESSAGE: String = "Please try again in a few moments. If persistent, don't hesitate to reach us at support@rhizomnetworking.com"
}

extension Error {
    func presentToUser() {
        if let app_error = self as? AppError {
            app_error.presentToUser()
        } else {
            let app_error = AppError(title: "Present Generic Error to User", reason: "This App Error is created to present a generic error to the user")
            app_error.presentToUser()
        }
    }
}
