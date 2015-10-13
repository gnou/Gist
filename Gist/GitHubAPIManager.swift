//
//  GitHubAPIManager.swift
//  Gist
//
//  Created by CuiMingyu on 10/12/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class GitHubAPIManager {
    
    private static let sharedInstance = GitHubAPIManager()
    class var sharedManager: GitHubAPIManager {
        return sharedInstance
    }
    
    var alamofireManager: Alamofire.Manager
    init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        alamofireManager = Alamofire.Manager(configuration: configuration)
        addSessionHeader("Accept", value: "application/vnd.github.v3+json")
    }
    
    func addSessionHeader(key: String, value: String) {
        var headers: [NSObject: AnyObject]
        if let existingHeaders = alamofireManager.session.configuration.HTTPAdditionalHeaders as? [String: String] {
            headers = existingHeaders
        } else {
            headers = Manager.defaultHTTPHeaders
        }
        headers[key] = value
        let config = alamofireManager.session.configuration
        config.HTTPAdditionalHeaders = headers
        print(config.HTTPAdditionalHeaders)
        alamofireManager = Alamofire.Manager(configuration: config)
    }
    
    func removeSessionHeaderIfExists(key: String) {
        let config = alamofireManager.session.configuration
        if var headers = config.HTTPAdditionalHeaders {
            headers.removeValueForKey(key)
            alamofireManager = Alamofire.Manager(configuration: config)
        }
    }
}
