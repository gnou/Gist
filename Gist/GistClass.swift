//
//  GistClass.swift
//  Gist
//
//  Created by CuiMingyu on 10/13/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import Foundation
import SwiftyJSON

class GistClass: ResponseJSONObjectSerializable {
    var id: String?
    var description: String?
    var ownerLogin: String?
    var ownerAvatarURL: String?
    var url: String?
    var files: [File]?
    var createdAt: NSDate?
    var updatedAt: NSDate?
    
    required init?(json: JSON) {
        self.description = json["description"].string
        self.id = json["id"].string
        self.ownerLogin = json["owner", "login"].string
        self.ownerAvatarURL = json["owner", "avatar_url"].string
        self.url = json["url"].string
        
        self.files = [File]()
        if let fileJSON = json["files"].dictionary {
            for (_, fileJSON) in fileJSON {
                if let newFile = File(json: fileJSON) {
                    self.files?.append(newFile)
                }
            }
        }
        
        let dateFormatter = GistClass.dateFormatter()
        if let dateString = json["created_at"].string {
            self.createdAt = dateFormatter.dateFromString(dateString)
        }
        if let dateString = json["update_at"].string {
            self.updatedAt = dateFormatter.dateFromString(dateString)
        }
    }
    
    class func dateFormatter() -> NSDateFormatter {
        let aDateFormatter = NSDateFormatter()
        aDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        aDateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        aDateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return aDateFormatter
    }

}