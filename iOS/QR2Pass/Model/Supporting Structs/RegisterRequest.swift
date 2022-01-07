//
//  RegisterRequest.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/23/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation


struct RegisterRequest:Encodable, ClientRequest {
    var version: Int?
    var email: String
    var publicKey: String
    var nonce: String
}






	
