//
//  ServerResponse.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/24/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

/*
 SCHEMA
//inband repsponse from server
{
    "version": Int //ignored for now
    "username": String,
    "status": status, // enum (ok/nok)
    "response_text": String // (optional) -> more info if the register/login failed.
}
*/

struct ServerResponse:Codable {
    
    var version: Int? //ignore for now
    var email: String
    var status: Status
    var responseText: String
    
    
    enum Status:String, Codable {
        case ok
        case nok
        
    }
    
    
    
}
