//
//  AmazonIdentityProvider.swift
//  s3Upload-Cognito
//
//  Created by EVENTORG CATHERINE on 04/07/19.
//  Copyright © 2019 Catherine. All rights reserved.
//

import AWSCore

final class AmazonIdentityProvider: AWSCognitoCredentialsProviderHelper {
    
    let poolId = "pool-id"
    
    var cachedLogin: NSDictionary?
    var credential: AmazonCognitoCredential?

    init(credential: AmazonCognitoCredential) {
        self.credential = credential
        super.init(regionType: .APSouth1, identityPoolId: poolId, useEnhancedFlow: true, identityProviderManager: nil)
    }
    
    // Handles getting the login
    override func logins() -> AWSTask<NSDictionary> {
        guard let cachedLogin = cachedLogin else {
            return getCredentials().continueWith(block: { credentialTask -> AWSTask<NSDictionary> in
                guard let credential = credentialTask.result else {
                    return AWSTask(result: nil)
                }
                let login: NSDictionary = ["cognito-identity.amazonaws.com": credential.token]
                self.cachedLogin = login
                return AWSTask(result: login)
            }) as! AWSTask<NSDictionary>
        }
        return AWSTask(result: cachedLogin)
    }
    
    // Handles getting a token from the server
    override func token() -> AWSTask<NSString> {
        return getCredentials().continueWith(block: { credentialTask -> AWSTask<NSString> in
            guard let credential = credentialTask.result else {
                return AWSTask(result: nil)
            }
            return AWSTask(result: credential.token as NSString)
        }) as! AWSTask<NSString>
    }
    
    
    
    // Handles getting the identity id
    override func getIdentityId() -> AWSTask<NSString> {
        return getCredentials().continueWith(block: { credentialTask -> AWSTask<NSString> in
            guard let credential = credentialTask.result else {
                return AWSTask(result: nil)
            }
            return AWSTask(result: credential.identityId as NSString)
        }) as! AWSTask<NSString>
    }
    
    // Gets credentials from server
    func getCredentials() -> AWSTask<AmazonCognitoCredential> { // AmazonCognitoCredential is a class I created to store credentials from my server
        let tokenRequest = AWSTaskCompletionSource<AmazonCognitoCredential>()
        
        guard let credential = credential else { return tokenRequest.task }
        
        tokenRequest.set(result: credential)
        
        return tokenRequest.task
    }
}


final class AmazonCognitoCredential {
    let token: String
    let identityId: String
    
    init(token: String, identityId: String) {
        self.token = token
        self.identityId = identityId
    }
}
