//
//  ResponseJSONObjectSerializable.swift
//  Gist
//
//  Created by CuiMingyu on 10/13/15.
//  Copyright © 2015 CuiMingyu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public protocol ResponseJSONObjectSerializable {
    init?(json: JSON)
}

