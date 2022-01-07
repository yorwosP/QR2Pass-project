//
//  CryptoManager.swift
//  QR2Pass
//
//  Handles all cryptographic actions like creating private key the public key, signing data (crypto hash),
//  these may be refactored to use new (ios 13 and later) CryptoKit
//
//
//  Created by Yorwos Pallikaropoulos on 1/23/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation


// TODO: update this for iOS 13 and up (CryptoKit)
/// Manager of the cryptographic functions (sign, export public key)
/// implementation based on iOS 12 api. 13's CryptoKit may be better and easier
class CryptoManager{
    
    var tag: Data // used to identify the key
    var keyType:CFString
    var keySize: Int
   
    
    
    /// sign a mesage (string) with private key,
    /// - Parameter message: the message (string)
    /// - Returns: the signed message (base64 encoding), nil  if cannot get the private key
    func sign(_ message:String) throws -> String?{
        guard let data = message.data(using: .utf8) else{
        
            return nil
        }
        if let privateKey = searchForKey(){
            let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
            var error: Unmanaged<CFError>?
            guard let signature = SecKeyCreateSignature(privateKey,
                                                        algorithm,
                                                        data as CFData,
                                                        &error) as Data? else {
                                                            throw error!.takeRetainedValue() as Error
            }
            
/*            alternative method for a cryptorgraphic hash (ios >=13)
            
                        if #available(iOS 13.0, *) {
            
                            let hash512 = SHA512.hash(data: data)
                            print("hash:\n\(hash512.description)")
                        } else {
                            // Fallback on earlier versions
                        }
 */
            
            return signature.base64EncodedString()
            
            
        }else{
            
            // TODO: - maybe throw an error for better handling by the caller
            return nil
        }
    }
    

    
    /// export the public key in base 64 encoding (or nil)
    /// - Returns: the public key (base 64) or nil if cannot  export public key
    func exportPublicKey() -> String?{
        if let key = searchForKey(){
            if let publicKey = SecKeyCopyPublicKey(key){
                
                var exportError: Unmanaged<CFError>?
                if let data = SecKeyCopyExternalRepresentation(publicKey, &exportError){
                    let exportKey = (data as Data).base64EncodedString()
                    // let str = String(decoding: (data as Data), as: UTF8.self)
                    // print(str)
                    return exportKey
                }
            }
            
        }
        // TODO: - maybe throw an error for better handling by the caller
        return nil
        
    }
    
    
    //    MARK: - helper functions
        

    
    /// searhes keychain for a key marching the tag and the key type
    /// - Returns: a reference to the private key (SecKey) or nil
    private func searchForKey() -> SecKey? {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: self.tag,
            kSecAttrKeyType as String: keyType,
            kSecReturnRef as String: true
        ]
        
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if  status == errSecSuccess{
           // already have this key
            return (item as! SecKey)
          
        }else{
            return nil
            
        }
        
        
    }
    

    //  TODO: maybe implement a way to delete a key (unregister from a site etc)
    /// Debug function to delete all keys
    private func deleteAllKeys(){
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            //            kSecAttrApplicationTag as String: self.tag,
            kSecAttrKeyType as String: keyType,
            kSecReturnRef as String: true
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("got error while deleting")
            return
        }
        
        
        
    }
    
    
    /// create a key and  store it in the keychain
    /// the key itself is never stored in the object
    /// instead, whenever is needed is retrieved from the keychain
    private func createKey() throws{
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String:            keyType,
            kSecAttrKeySizeInBits as String:      keySize,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String:      true,
                kSecAttrApplicationTag as String:   tag,
                //            kSecAttrAccessControl as String:    access
            ]
        ]
        
        
        
        var error: Unmanaged<CFError>?
        guard let _ = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        
    }
    
    //    MARK: - init
    /// failable initializer
    /// - Parameters:
    ///   - tagString: a tag to identify the key
    ///   - keyType: key algorithmm (RSA by default)
    ///   - keySize: key size in bits
    init?(tag tagString: String, keyType:CFString = kSecAttrKeyTypeRSA, keySize: Int = 2048){
        
        self.tag = tagString.data(using: .utf8)!
        self.keyType = keyType
        self.keySize = keySize
        let key = searchForKey()
        if key == nil{
            do {
                
                try createKey()
            } catch {
                return nil
            }
        }
        
    }
}


