//
//  ViewController.swift
//  s3Upload-Cognito
//
//  Created by EVENTORG CATHERINE on 04/07/19.
//  Copyright © 2019 Catherine. All rights reserved.
//

import UIKit
import AWSCore
import AWSS3

enum AWSS3Bucket {
    case image
    case file
    
    var path: String {
        switch self {
        case .image:
            return "images/"
        case .file:
            return "files/"
        }
    }
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let credential = AmazonCognitoCredential(token: "token", identityId: "identity-id")
        
        let configuration = AWSCogintoConfiguration(credential: credential)
        let s3 = S3ImageUploader(serviceConfiguration: configuration)
        let image = UIImage(named: "image")!

        s3.uploadImage(image)
        
    }
    
}

struct AWSCogintoConfiguration {
    
    var identityProvider: AmazonIdentityProvider
    var credentialsProvider: AWSCognitoCredentialsProvider
    var serviceConfiguration: AWSServiceConfiguration
    
    init(credential: AmazonCognitoCredential) {
        
        self.identityProvider = AmazonIdentityProvider(credential: credential)
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APSouth1, identityProvider: identityProvider)
        self.serviceConfiguration = AWSServiceConfiguration(region: .APSouth1, credentialsProvider: credentialsProvider)
    }
    
}

struct S3ImageUploader {
    
    //    static let main = S3ImageUploader()
    var configuration: AWSCogintoConfiguration
    
    init(serviceConfiguration: AWSCogintoConfiguration) {
        
        self.configuration = serviceConfiguration
        AWSServiceManager.default().defaultServiceConfiguration = configuration.serviceConfiguration
    }
    
    func uploadImage(_ image: UIImage, bucket: String = "bucket-name") {
        
        getIdentityId { (status, error) in
            if let error = error {
                NSLog("Error: %@",error.localizedDescription)
            }
            if status {
                self.upload(image: image)
               
            }
        }
        
    }
    
    func upload(image: UIImage, bucket: String = APIEnvironment.environment.awsBucket){
        let progressBlock: AWSS3TransferUtilityProgressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                // Do something e.g. Update a progress bar.
            })
        }
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progressBlock
        let transferUtility = AWSS3TransferUtility.default()
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if ((error) != nil){
                    print("Failed with error", error?.localizedDescription ?? "")
                } else{
                    NSLog("success")
                }
            })
        }
        
        guard let data = image.jpegData(compressionQuality: 1.0) else { return }
        
        transferUtility.uploadData(data, bucket: bucket, key: String(format: "%@%@", AWSS3Bucket.image.path, "test.jpg"), contentType: "image/jpeg", expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                NSLog("Error: %@",error.localizedDescription);
            }
            
            
            if let _ = task.result {
                NSLog("Upload Starting!")
                // Do something with uploadTask.
            }
            return nil
        }
        
        
    }
    
    
    fileprivate func getIdentityId(completion: @escaping (_ success: Bool, _ error: Error? ) -> ()) {
        self.configuration.credentialsProvider.getIdentityId().continueOnSuccessWith(block: { (task) -> Any? in
            if let error = task.error {
                NSLog("Error: %@",error.localizedDescription)
                completion(false, error)
            }
            
            if let _ = task.result {
                //                    print(task.result)
                completion(true, nil)
            }
            return nil
            
        })
    }
}

