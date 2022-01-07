//
//  WebSite.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/14/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

struct WebSite:Codable {
    var url: URL
    var siteName: String
    var user: User
    var isRegistrationComplete: Bool
    var lastLoginAt: Date?
    var registeredAt: Date

}

