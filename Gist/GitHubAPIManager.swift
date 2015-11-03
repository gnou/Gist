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
import UIKit
import Locksmith

class GitHubAPIManager {
    
    // Error Domain
    static let ErrorDomain = "com.error.GitHubAPIManager"
    
    // Client Info from github.com
    let clientID: String = "0aa2f24d091dad51baa9"
    let clientSecret: String = "767decd12a03db4b461f05b4af7c28668a557add"
    
    var OAuthToken: String? {
        set {
            if let valueToSave = newValue {
                do {
                    try Locksmith.saveData(["token": valueToSave], forUserAccount: "github")
                } catch {
                    let _ = try? Locksmith.deleteDataForUserAccount("github")
                }
                addSessionHeader("Authorization", value: "token \(valueToSave)")
            } else {
                let _ = try? Locksmith.deleteDataForUserAccount("github")
                removeSessionHeaderIfExists("Authorization")
            }
        }
        get {
            let dictionary = Locksmith.loadDataForUserAccount("github")
            if let token = dictionary?["token"] as? String {
                return token
            }
            removeSessionHeaderIfExists("Authorization")
            return nil
        }
    }
    
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
    
    //MARK: - OAuth2
    
    /// Handler for the OAuth process
    /// stored as vars since sometimes it requires a round trip to safari which
    /// make it hard to just keep a refreence to it
    var OAuthTokenCompletionHandler: (NSError? -> Void)?
    
    func hasOAuthToken() -> Bool {
        if let token = self.OAuthToken {
            return !token.isEmpty
        } else {
            return false
        }
    }
    
    func startOAuth2Login() {
        var success = false
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: "loadingOAuthToken")
        
        let params = "client_id=\(clientID)&scope=gist&state=TEST_STATE"
        let baseURLString = "https://github.com/login/oauth/authorize?"
        let authPath: String = baseURLString + params
        if let authURL: NSURL = NSURL(string: authPath) {
            print(authURL.absoluteString)
            success = UIApplication.sharedApplication().openURL(authURL)
        }
        
        if !success {
            // TODO: handle
            defaults.setBool(false, forKey: "loadingOAuthToken")
            if let completionHandler = self.OAuthTokenCompletionHandler {
                let error = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create an OAuth authorization URL",
                    NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
                completionHandler(error)
            }
        }
        
    }
    
    func processOAuthStep1Response(url: NSURL) {
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        var code: String?
        if let queryItems = components?.queryItems {
            for queryItem in queryItems {
                if queryItem.name.lowercaseString == "code" {
                    code = queryItem.value
                    break
                }
            }
        }
        if let receivedCode = code {
            swapAuthCodeForToken(receivedCode)
        } else{
            // no code in URL
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(false, forKey: "loadingOAuthToken")
            
            if let completionHandler = self.OAuthTokenCompletionHandler {
                let noCodeInResponseError = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an OAuth code", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
                completionHandler(noCodeInResponseError)
            }
        }
    }
    
    func swapAuthCodeForToken(receivedCode: String) {
        let getTokenPath: String = "https://github.com/login/oauth/access_token"
        let tokenParams = ["client_id": clientID, "client_secret": clientSecret, "code": receivedCode]
        let jsonHeader = ["Accept": "application/json"]
        Alamofire.request(.POST, getTokenPath, parameters: tokenParams, headers: jsonHeader)
            .responseString { (request, response, result) -> Void in
                if let error = result.error {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setBool(false, forKey: "loadingOAuthToken")
                    
                    if let completionHandler = self.OAuthTokenCompletionHandler {
                        completionHandler(error as NSError)
                    }
                    return
                }
                if let receivedResults = result.value,
                    jsonData = receivedResults.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                        let jsonResults = JSON(data: jsonData)
                        for (key, value) in jsonResults {
                            switch key {
                            case "access_token":
                                self.OAuthToken = value.string
                            case "scope":
                                // TODO: verify scope
                                print("SET SCOPE")
                            case "token_type":
                                // TODO: verify is bearer
                                print("CHECK IF BEARER")
                            default:
                                print("got more than I expected from the OAuth token exchange")
                                print(key)
                            }
                        }
                }
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setBool(false, forKey: "loadingOAuthToken")
                
                if let completionHandler = self.OAuthTokenCompletionHandler {
                    if self.hasOAuthToken() {
                        completionHandler(nil)
                    } else {
                        let noOAuthError = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an OAuth token", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
                        completionHandler(noOAuthError)
                    }
                }
        }
    }
    
    // MARK: - Api Functions
    
    func getPublisGists(pageToLoad: String?, completion: (Result<[GistClass]>, String?) -> Void) {
        if let urlString = pageToLoad {
            getGists(urlString, completionHandler: completion)
        } else {
            getGists("https://api.github.com/gists/public", completionHandler: completion)
        }
    }
    
    private func handleUnauthorizedResponse(urlString: String) -> NSError {
        self.OAuthToken = nil
        let lostOAuthError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUserAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: "Not logged in", NSLocalizedRecoverySuggestionErrorKey: "please re-enter your github credentials"])
        return lostOAuthError
    }
    
    func getGists(urlString: String, completionHandler: (Result<[GistClass]>, String?) -> Void) {
        alamofireManager.request(.GET, urlString)
            .isUnauthorized{ (req, res, result) -> Void in
                if let unauthorized = result.value where unauthorized == true {
                    let lostOAuthError = self.handleUnauthorizedResponse(urlString)
                    completionHandler(Result.Failure(nil, lostOAuthError), nil)
                    return
                }
            }
            .responseArray { (req, res, result: Result<[GistClass]>) -> Void in
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
    
    func getMyStarredGists(pageToLoad: String?, completionHandler: (Result<[GistClass]>, String?) -> Void) {
        if let urlString = pageToLoad {
            getGists(urlString, completionHandler: completionHandler)
        } else {
            getGists("https://api.github.com/gists/starred", completionHandler: completionHandler)
        }
    }
    
    func getMyGists(pageToLoad: String?, completionHandler: (Result<[GistClass]>, String?) -> Void) {
        if let urlString = pageToLoad {
            getGists(urlString, completionHandler: completionHandler)
        } else {
            getGists("https://api.github.com/gists", completionHandler: completionHandler)
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
        alamofireManager.request(.GET, "https://api.github.com/gists/starred")
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
    
    func isGistStarred(gistId: String, completionHandler: (Bool?, NSError?) -> Void) {
        let urlString = "https://api.github.com/gists/\(gistId)/star"
        alamofireManager.request(.GET, urlString)
            .validate(statusCode: [204])
            .isUnauthorized{ (_, _, result) -> Void in
                if let unauthorized = result.value where unauthorized {
                    let lostOAuthError = self.handleUnauthorizedResponse(urlString)
                    completionHandler(nil, lostOAuthError)
                    return
                }
            }
            .response { (request, response, data, error) -> Void in
                if let anError = error as? NSError {
                    print(anError)
                    if response?.statusCode == 404 {
                        completionHandler(false, nil)
                        return
                    }
                    completionHandler(nil, anError)
                    return
                }
                completionHandler(true, nil)
        }
    }
    
    func starGist(gistId: String, completionHandler: (ErrorType?) -> Void) {
        let urlString = "https://api.github.com/gists/\(gistId)/star"
        alamofireManager.request(.PUT, urlString)
            .isUnauthorized{ (_, _, result) -> Void in
                if let unauthorized = result.value where unauthorized {
                    let lostOAuthError = self.handleUnauthorizedResponse(urlString)
                    completionHandler(lostOAuthError)
                    return
                }
            }
            .response { (request, response, data, error) -> Void in
                if let anError = error {
                    print(anError)
                    return
                }
                completionHandler(error)
        }
    }
    
    func unstarGist(gistId: String, completionHandler: (ErrorType?) -> Void) {
        let urlString = "https://api.github.com/gists/\(gistId)/star"
        alamofireManager.request(.DELETE, urlString)
            .isUnauthorized{ (_, _, result) -> Void in
                if let unauthorized = result.value where unauthorized {
                    let lostOAuthError = self.handleUnauthorizedResponse(urlString)
                    completionHandler(lostOAuthError)
                    return
                }
            }
            .response { (request, response, data, error) -> Void in
                if let anError = error {
                    print(anError)
                    return
                }
                completionHandler(error)
        }
    }
}
