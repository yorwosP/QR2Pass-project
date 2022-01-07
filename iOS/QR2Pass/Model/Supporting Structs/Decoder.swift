//
//  Decoder.swift
//  structs for decoding json responses
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/16/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation


/*
 SCHEMA
 
 
 
 Register (QR)
 
 {
     "version": Int, //ignored for now
     "username": String,
     "provider": URL, //base url for the site (this is the identifier for the site),
     "respondTo": URL,
     "action": action enum //action.register ("register")
 }
 
 login (QR)
 {
     "version": Int, //ignored for now
     "challenge": String,
     "validTill": Date, // till when the nonce is valid for
     "provider": URL, //base url for the site (this is the identifier for the site),
     "action": action.login //action.login ("login")
 }
 

 //inband repsponse from server
 {
     "version": Int //ignored for now
     "username": String,
     "status": status, // enum (ok/nok)
     "response_text": String // (optional) -> more info if the register/login failed.
 }
 
 
 
 
 
 */

//
//enum Action:String, Codable{
//    case register
//    case login
//
//}
//
//private struct GenericQRResponse:Codable {
//    var version: Int?
//    var action: Action
//}
//
//struct RegisterResponse:Codable {
//    var version: Int?
//    var username: String
//    var provider: String
//    var _respondTo: String
//    var action: Action
//
//
////    !!CHECK!! do we need this? - URL is codable
//    var respondToURL:URL?{
//        get{
//
//            return URL(string:_respondTo)
//
//        }
//    }
//    enum CodingKeys:String, CodingKey{
//        case version, username, provider, action
//        case _respondTo =  "respondTo"
//    }
//}
//
//
//struct LoginResponse: Codable {
//    var version: Int? // ignore for now
//    var challenge: String
//    private var _validTill: String? //ignore for now
//    var provider: String
//    var action: Action
//
////    TODO: decide for a date format and implement a corresponding date formatter
//    /*
//
//
//    var validTill:Date{
//        get {
//
//        }
//    }
//    */
//
//
//
//}


//struct Response:Codable {
//
//    var version: Int? //ignore for now
//    var username: String
//    var status: Status
//    var responseText: String?
//
//
//    enum Status:String, Codable {
//        case ok
//        case nok
//
//    }
//
//
//
//}


    
