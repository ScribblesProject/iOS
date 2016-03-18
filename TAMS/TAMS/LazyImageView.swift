//
//  LazyImageView.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/17/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import Alamofire

class LazyImageView: UIImageView {
    
    func loadUrl(url:String) {
        Alamofire.request(.GET, url)
            .validate()
            .response { request, response, data, error in
                if let _data = data {
                    self.image = UIImage(data: _data)
                }
        }
    }
    
}
