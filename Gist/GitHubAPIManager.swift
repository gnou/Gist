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
        alamofireManager = Alamofire.Manager(configuration: config)
    }
    
    func removeSessionHeaderIfExists(key: String) {
        let config = alamofireManager.session.configuration
        if var headers = config.HTTPAdditionalHeaders {
            headers.removeValueForKey(key)
            alamofireManager = Alamofire.Manager(configuration: config)
        }
    }
    
    func getPublisGists(pageToLoad: String?, completion: (Result<[Gist]>, String?) -> Void) {
        if let urlString = pageToLoad {
            getGists(urlString, completionHandler: completion)
        } else {
            getGists("https://api.github.com/gists/public", completionHandler: completion)
        }
    }
    
    func getGists(urlString: String, completionHandler: (Result<[Gist]>, String?) -> Void) {
        alamofireManager.request(.GET, urlString)
            .validate()
            .responseArray { (req, res, result: Result<[Gist]>) -> Void in
                guard result.error == nil,
                    let gists = result.value else {
                        print(result.error)
                        completionHandler(result, nil)
                        return
                }
                
                let next = self.getNextPageFromHeaders(res)
                completionHandler(.Success(gists), next)
        }
    }
    
    private func getNextPageFromHeaders(response: NSHTTPURLResponse?) -> String? {
        if let linkHeader = response?.allHeaderFields["Link"] as? String {
            let components = linkHeader.characters.split { $0 == "," }.map { String($0) }
            for item in components {
                let rangeOfNext = item.rangeOfString("rel=\"next\"", options: [])
                if rangeOfNext != nil {
                    let rangeOfPaddedURL = item.rangeOfString("<(.*)>", options: .RegularExpressionSearch)
                    if let range = rangeOfPaddedURL {
                        let nextURL = item.substringWithRange(range)
                        let startIndex = nextURL.startIndex.advancedBy(1)
                        let endIndex = nextURL.endIndex.advancedBy(-1)
                        let urlRange = startIndex..<endIndex
                        return nextURL.substringWithRange(urlRange)
                    }
                }
            }
        }
        return nil
    }
    
    
    func printMyStarredGistsWithBasicAuth() {
        let username = "gnou"
        let password = "tpasghbn23GITHUB"
        
        let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        let headers = ["Authorization": "Basic \(base64Credentials)"]
        
        Alamofire.request(.GET, "https://api.github.com/gists/starred", headers: headers)
        .responseString { (_, _, result) -> Void in
            if let receivedString = result.value {
                print(receivedString)
            }
        }
    }
    
    func doGetWithBasicAuth() -> Void {
        let username = "myUsername"
        let password = "myPassword"
        
        let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.ForSession)
        
        Alamofire.request(.GET, "https://httpbin.org/basic-auth/\(username)/\(password)")
            .authenticate(usingCredential: credential)
            .responseString { (_, _, result) -> Void in
                if let receivedString = result.value {
                    print(receivedString)
                }
        }
    }
}
