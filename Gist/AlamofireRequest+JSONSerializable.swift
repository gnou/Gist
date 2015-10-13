//
//  AlamofireRequest+JSONSerializable.swift
//  Gist
//
//  Created by CuiMingyu on 10/13/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension Alamofire.Request {
    public func responseObject<T: ResponseJSONObjectSerializable>(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<T>) -> Void) -> Self {
        let responseSerializer = GenericResponseSerializer<T> { (request, response, data) -> Result<T> in
            guard let responseData = data else {
                let failureReason = "Object could not be serialized because input data was nil"
                let error = Error.errorWithCode(Error.Code.DataSerializationFailed, failureReason: failureReason)
                return Result.Failure(data, error)
            }
            let json = SwiftyJSON.JSON(data: responseData)
            if let newObject = T(json: json) {
                return Result.Success(newObject)
            }
            let error = Error.errorWithCode(Error.Code.JSONSerializationFailed, failureReason: "JSON could not be converted to object")
            return Result.Failure(responseData, error)
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
    public func responseArray<T: ResponseJSONObjectSerializable>(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<[T]>) -> Void) -> Self {
        let responseSerializer = GenericResponseSerializer<[T]> { (request, response, data) -> Result<[T]> in
            guard let responseData = data else {
                let failureReason = "Array could not be serialized because input data was nil"
                let error = Error.errorWithCode(Error.Code.DataSerializationFailed, failureReason: failureReason)
                return Result.Failure(data, error)
            }
            if let jsonArray = SwiftyJSON.JSON(data: responseData).array {
                let objects = jsonArray.map { T(json: $0) }.filter { $0 != nil }.map { $0! }
                return Result.Success(objects)
            }
            let error = Error.errorWithCode(Error.Code.JSONSerializationFailed, failureReason: "JSON could not be converted to object")
            return Result.Failure(responseData, error)
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}
