//
//  LogoutRequest.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 4/24/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation


struct LogoutRequest: Encodable, ClientRequest {
    var version: Int? // ignore for now
    var username: String
    var challenge: String? //ignore for now
    var response: String?  // ignore for now
}

