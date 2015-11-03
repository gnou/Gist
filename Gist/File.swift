//
//  File.swift
//  Gist
//
//  Created by CuiMingyu on 10/21/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import Foundation
import SwiftyJSON

class File: ResponseJSONObjectSerializable {
    var fileName: String?
    var raw_url: String?
    
    required init?(json: JSON) {
        self.fileName = json["filename"].string
        self.raw_url = json["raw_url"].string
    }
}
