//
//  LoginRequest.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/23/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

struct LoginRequest: Encodable, ClientRequest {
    var version: Int? // ignore for now
    var username: String
    var challenge: String
    var response: String
}
