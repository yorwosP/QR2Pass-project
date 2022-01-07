//
//  ApiError.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/24/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation


enum ApiError: Error {

    case networkError(errorCode: Int,  additionalMessage:String = "")
    case genericError(message:String)
    case parsingError
    

}

extension ApiError: LocalizedError{
    var description: String {
        switch self {
        case .genericError(let message):
            return message
        case .networkError(let errorCode, let additionalMessage):
            return "\(errorCode): \(additionalMessage)"
            
        case .parsingError:
            return "Error in parsing"
        }
    }
}
