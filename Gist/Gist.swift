//
//  Gist.swift
//  Gist
//
//  Created by CuiMingyu on 10/13/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import Foundation
import SwiftyJSON

class Gist: ResponseJSONObjectSerializable {
    var id: String?
    var description: String?
    var ownerLogin: String?
    var ownerAvatarURL: String?
    var url: String?
    
    required init?(json: JSON) {
        self.description = json["description"].string
        self.id = json["id"].string
        self.ownerLogin = json["owner", "login"].string
        self.ownerAvatarURL = json["owner", "avatar_url"].string
        self.url = json["url"].string
    }
    
    required init() {
        
    }
}