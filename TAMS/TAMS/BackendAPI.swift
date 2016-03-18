//
//  BackendAPI.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/16/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import Alamofire

private let BASE = "http://76.216.160.246"
//private let BASE = "http://localhost:8000"

public struct Asset {
    var id:Int
    var name:String
    var description:String
    var type:String
    var category:String
    var category_description:String
    var imageUrl:String
    var voiceUrl:String
    var latitude:Double
    var longitude:Double
    
    /// Meant for update/creation
    func formatDictionary()->[String:AnyObject]
    {
        var result = [String:AnyObject]()
        result["id"] = id
        result["name"] = name
        result["description"] = description
        result["category"] = category
        result["category-description"] = category_description
        result["type-name"] = type
        result["latitude"] = latitude
        result["longitude"] = longitude
        return result
    }
}

public struct Type {
    var id:Int
    var name:String
    
    func formatDictionary()->[String:AnyObject]
    {
        var result = [String:AnyObject]()
        result["id"] = id
        result["name"] = name
        return result
    }
}

public struct Category {
    var id:Int
    var name:String
    var description:String
    
    func formatDictionary()->[String:AnyObject]
    {
        var result = [String:AnyObject]()
        result["id"] = id
        result["name"] = name
        result["description"] = description
        return result
    }
}

class BackendAPI: NSObject {
    
    private class func parseAsset(JSON:[String:AnyObject])->Asset {
        let id              = JSON["id"] as! Int
        let name            = JSON["name"] as! String
        let description     = JSON["description"] as! String
        let imageUrl        = JSON["media-image-url"] as! String
        let voiceUrl        = JSON["media-voice-url"] as! String
        let latitude        = JSON["latitude"] as! Double
        let longitude       = JSON["longitude"] as! Double
        let category        = JSON["category"] as! String
        let category_desc   = JSON["category-description"] as! String
        let type            = JSON["asset-type"] as! String
        
        return Asset(
            id: id,
            name: name,
            description: description,
            type: type,
            category: category,
            category_description: category_desc,
            imageUrl: imageUrl,
            voiceUrl: voiceUrl,
            latitude: latitude,
            longitude: longitude
        )
    }
    
    class func getBASE()->String {
        return BASE
    }
    
    class func printResponse(response:Response<AnyObject, NSError>) {
        let error = response.result.error
        print("\n------------\n[ERROR] \(error)")
        print(response.debugDescription)
        print(response.data)
        print(response.result)
        if let data = response.data {
            print(String(data: data, encoding: NSUTF8StringEncoding))
        }
        print("------------\n")
    }
    
//MARK: Asset Methods
    
    class func list(completion:(([Asset])->Void))
    {
        let endpoint = "/api/asset/list/"
        print(BASE+endpoint)
        
        Alamofire.request(.GET, BASE+endpoint)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    var result = [Asset]()
                    if let JSON = response.result.value {
                        let assets = JSON["assets"] as? [[String:AnyObject]] ?? []
                        for item in assets {
                            result.append(self.parseAsset(item))
                        }
                    }
                    completion(result)
                    
                case .Failure(let error):
                    print("[ERROR] \(error)")
                    completion([])
                }
        }
    }
    
    class func delete(newAsset:Asset, completion:((Bool)->Void))
    {
        let endpoint = "/api/asset/delete/\(newAsset.id)/"
        print(BASE+endpoint)
        
        Alamofire.request(.DELETE, BASE+endpoint)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let JSON = response.result.value {
                        let success = JSON["success"] as? Bool ?? false
                        if success {
                            completion(true)
                            return
                        }
                    }
                case .Failure:
                    break
                }
                
                printResponse(response)
                completion(false)
                return
        }
    }
    
    class func create(newAsset:Asset, completion:((Bool)->Void))
    {
        let endpoint = "/api/asset/create/"
        print(BASE+endpoint)
        
        let parameters = newAsset.formatDictionary()
        let headers = [String:String]()
        
        Alamofire.request(.POST, BASE+endpoint, parameters: parameters, encoding: .JSON, headers: headers)
            .validate()
            .responseJSON { (response) -> Void in
                switch response.result {
                case .Success:
                    if let JSON = response.result.value {
                        let success = JSON["success"] as? Bool ?? false
                        if success {
                            completion(true)
                            return
                        }
                    }
                case .Failure:
                    break
                }
                
                printResponse(response)
                completion(false)
                return
        }
    }
    
//MARK: Asset-Type Methods
    
    class func typeList(completion:(([Type])->Void))
    {
        let endpoint = "/api/asset/type/list/"
        print(BASE+endpoint)
        
        Alamofire.request(.GET, BASE+endpoint)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    var result = [Type]()
                    if let JSON = response.result.value {
                        let types = JSON["types"] as? [[String:AnyObject]] ?? []
                        for item in types {
                            let tId = item["id"] as? Int ?? 0
                            let tName = item["name"] as? String ?? ""
                            
                            result.append(Type(id: tId, name: tName))
                        }
                    }
                    completion(result)
                    
                case .Failure(let error):
                    print("[ERROR] \(error)")
                    completion([])
                }
        }
    }
    
//MARK: Asset-Category Methods
    
    class func categoryList(completion:(([Category])->Void))
    {
        let endpoint = "/api/asset/category/list/"
        print(BASE+endpoint)
        
        Alamofire.request(.GET, BASE+endpoint)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    var result = [Category]()
                    if let JSON = response.result.value {
                        let types = JSON["categories"] as? [[String:AnyObject]] ?? []
                        for item in types {
                            let cId = item["id"] as? Int ?? 0
                            let cName = item["name"] as? String ?? ""
                            let cDescriptiom = item["description"] as? String ?? ""
                            
                            result.append(Category(id: cId, name: cName, description: cDescriptiom))
                        }
                    }
                    completion(result)
                    
                case .Failure(let error):
                    print("[ERROR] \(error)")
                    completion([])
                }
        }
    }
}

