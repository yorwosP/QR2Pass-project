//
//  ConnectionManager.swift
//  QR2Pass
//
//  handles the connection to the server
//  registration/login request/response
//
//  Created by Yorwos Pallikaropoulos on 1/23/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

class ConnectionManager {
    
    let apiVersion = 1
    
    
    
    
    /// Generic function to send client requests (JSON format)  to server
    /// called by public functions register, login and logout
    /// - Parameters:
    ///   - request: a request that conforms to the ClientRequest protocol
    ///   - url: URL
    ///   - method: HTTP method
    ///   - completionHandler: callback
    private func send<T:ClientRequest>(_ request:T,
                                       to url:URL,
                                       method:String = "POST",
                                       _ completionHandler:@escaping(_ error:ApiError?, _ result:Data?)   -> Void) {
        
        var apiError: ApiError?
        var responseData: Data?
        var urlRequest = URLRequest(url:url)
        // TODO: make the respondToURL mandatory??
        urlRequest.httpMethod = method
        //HTTP Headers
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
       
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonRequest = try! jsonEncoder.encode(request) // this should never fail since we are constructing the data
        urlRequest.httpBody = jsonRequest
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            // handle the result here.
            if let error = error{ //a generic error occured (i.e we have not received any kind (even an erroneous) response from the server)
                apiError = ApiError.genericError(message: error.localizedDescription)
                
            }else{
                if let httpResponse = response as? HTTPURLResponse{
                    //                    we have received some kind of response. check if it is an ok response
                    if (0...299).contains(httpResponse.statusCode){ //2xx response
                        responseData = data
//                        print("received an ok response with data\n\(data)")
                        
                    }else{ //non 2xx response, construct a network error to be passed to the caller
                        apiError = ApiError.networkError(errorCode: httpResponse.statusCode) // the additionalMessage will be added by the caller.
                        
                    }
                    
                }
                
            }
            completionHandler(apiError, responseData)
            
        }.resume()
    }
    

    
    
    /// Send a registration request to the server for an account (email/public key).
    /// Pass the response as a ServerResponse struct and the error (if any) in a completion handler
    /// - Parameters:
    ///   - url: a URL object pointing to the server
    ///   - email: the email for the account to register
    ///   - publicKey: the public key of the account
    ///   - nonce: the nonce provided by the server
    ///   - completionHandler: ServerResponse (or nil) and ApiError (or nil) passed in the completion handler
    func register(to url: URL,
                  for email: String,
                  with publicKey:String,
                  and nonce: String,
                  _ completionHandler:@escaping(_ error:ApiError?, _ response:ServerResponse?)   -> Void){
        
        var apiError: ApiError?
        var serverResponse: ServerResponse?
        
        let registerRequest = RegisterRequest(version: apiVersion, email: email, publicKey: publicKey, nonce: nonce)
        send(registerRequest, to: url) { (error, data) in
            // no error received
            if let data = data, error == nil{
                // decode the response
                // let str = String(decoding: data, as: UTF8.self)
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                if let response = try? jsonDecoder.decode(ServerResponse.self, from: data){
                    serverResponse = response
                }else{
                // cannot parse the (JSON) response
                    apiError = .parsingError
                }
                
                
                
            }else{
                // no data, or an error received
                if let error = error{
                    apiError = error
                    
                }
            }
            
          completionHandler(apiError, serverResponse)
        }
        
    }
    
    
    
    /// Send a login request to the server for a registered account
    /// The server's challenge is signed by the user's private key
    /// - Parameters:
    ///   - url: a URL object pointing to the server
    ///   - username: username
    ///   - challenge: challenge from the server
    ///   - response: challenge response
    ///   - completionHandler: ServerResponse (or nil) and ApiError (or nil) passed in the completion handler
    func login(to url: URL,
               for username: String,
               challenge:String,
               response:String,
               _ completionHandler:@escaping(_ error:ApiError?, _ response:ServerResponse?)   -> Void){
        var apiError: ApiError?
        var serverResponse: ServerResponse?
        
        
        let loginRequest = LoginRequest(version: apiVersion, username: username, challenge: challenge, response: response)
        send(loginRequest, to: url) { (error, data) in
            // no error received
            if let data = data, error == nil{
                // decode the response
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                if let response = try? jsonDecoder.decode(ServerResponse.self, from: data){
                    serverResponse = response
                }else{
                    // cannot parse the (JSON) response
                    apiError = .parsingError
                }

            }else{
                // no data, or an error received
                if let error = error{
                    apiError = error
                }
            }
            completionHandler(apiError, serverResponse)
        }
    }
    
    
    
    // TODO: - implement logout
    
    
    /// Send a logout request to the server
    /// Not currently used in this implementation
    /// - Parameters:
    ///   - url: a URL object pointing to the server
    ///   - username: username
    ///   - challenge: challenge from the server
    ///   - response: challenge response
    ///   - completionHandler: erverResponse (or nil) and ApiError (or nil) passed in the completion handler
    func logout(from url: URL,
               for username: String,
               challenge:String,
               response:String,
               _ completionHandler:@escaping(_ error:ApiError?, _ response:ServerResponse?)   -> Void){
        var apiError: ApiError?
        var serverResponse: ServerResponse?
        
        
        let logoutRequest = LogoutRequest(version: apiVersion, username: username, challenge: challenge, response: response)
        send(logoutRequest, to: url) { (error, data) in
            // no error received
            if let data = data, error == nil{
                // decode the response
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                if let response = try? jsonDecoder.decode(ServerResponse.self, from: data){
                    serverResponse = response
                }else{
                
                    apiError = .parsingError

                }
  
            }else{
                if let error = error{
                    apiError = error
                }
            }
            completionHandler(apiError, serverResponse)
        }
    }
}
