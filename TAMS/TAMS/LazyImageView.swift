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
    
    func loadUrl(_ url:String) {
        
        Alamofire.request(url, method:.get).validate().response { response in
                if let _data = response.data {
                    self.image = UIImage(data: _data)
                }
        }
    }
    
}
