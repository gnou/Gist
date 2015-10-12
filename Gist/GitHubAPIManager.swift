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
    
    func printPublicGists() -> Void {
        Alamofire.request(.GET, "https://api.github.com/gists/public")
        .responseString { (req, res, result) -> Void in
            if let receivedString = result.value {
                print(receivedString)
            }
        }
    }
}
