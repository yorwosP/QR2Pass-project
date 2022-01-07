//
//  QRData.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/19/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//


/*
SCHEMA



Register (QR)

{
    "version": Int, //ignored for now
    "username": String,
    "provider": String, (this is the identifier for the site e.g "Amazon US"
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
    "respondTo": URL
}
 */

import Foundation

/*
 version": "1", "email": "jjj@hh.com", "nonce": "bkv1v4cSQas=", "respond_to": "https://qr2pass.herokuapp.com/api/register/", "provider": "test QR2Pass server", "action": "register" 
 */


//    MARK: - supporting structrures
struct QRData:Decodable{

    enum Action:String, Decodable{
        case register
        case login
    }
    
    
    enum Request{

        
        case login(LoginRequest)
        case register(RegisterRequest)
    }
    
    
    struct RegisterRequest:Decodable {
        var version: Int?
        var email: String
        var provider: String
        //            private var _respondTo: String
        var respondTo: URL
        var nonce: String
        //        var action: Action
        
        
        
        
        //            var respondToURL:URL?{
        //                get{
        //
        //                    return URL(string:_respondTo)
        //
        //                }
        //            }
        //            enum CodingKeys:String, CodingKey{
        //                case version, username, provider
        //                case _respondTo =  "respondTo"
        //            }
    }


    struct LoginRequest: Decodable {
        var version: Int? // ignore for now
        var challenge: String
        var validTill: Date //ignore for now
        var provider: String
        var respondTo: URL
        
        
        
        
        
    }
    
    enum CodingKeys: String, CodingKey {
        case action
    }
    

    

    
//    MARK: - properties of the struct
    var request:Request?
    var action:Action
    
//    MARK: - init
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decode(Action.self, forKey: .action)

        switch action {
        case .login:

            let loginRequestData = try LoginRequest(from: decoder)
            self.request = .login(loginRequestData)
        case .register:
            let registerRequestData = try RegisterRequest(from: decoder)
            self.request = .register(registerRequestData)

        }

     self.action = action

        


    }
}
