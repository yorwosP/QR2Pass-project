//
//  Request.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/23/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation


// TODO: - perhaps move all the request here
/*


struct Request:Encodable{
    
    enum Action:String, Encodable{
        case register
        case login
    }
    

    
    
    enum Request{
        
        
        case login(LoginRequest)
        case resister(RegisterRequest)
        case movedAway
    }
    
    
    struct RegisterRequest:Encodable {
        var version: Int?
        var username: String
        var publicKey: String
        
//  use a encoding strategy (.convertToSnakeCase) instead
        
//        enum CodingKeys:String, CodingKey{
//            case version, username
//            case publicKey =  "public_key"
//        }
    }
    
    
    struct LoginRequest: Encodable {
        var version: Int? // ignore for now
        var username: String
        var challenge: String
        var response: String
        
        


        
        
        
    }
    
    enum CodingKeys: String, CodingKey {
        case action
    }
    
    
    
    
    
    //    MARK: - properties of the struct
    var request:Request?
    var action:Action
    
    
    
    //    MARK: - init
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let action = try container.decode(Action.self, forKey: .action)
//
//        switch action {
//        case .login:
//
//            let loginRequestData = try LoginRequest(from: decoder)
//            self.request = .login(loginRequestData)
//        case .register:
//            let registerRequestData = try RegisterRequest(from: decoder)
//            self.request = .resister(registerRequestData)
//
//        }
//
//        self.action = action
        
        
        
        
//    }
}

*/
