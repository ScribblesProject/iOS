//
//  BackendAPI.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/16/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import Alamofire

private let BASE = "https://tams-142602.appspot.com"
//private let BASE = "http://localhost:9000"

public struct Asset {
    var id:NSNumber
    var name:String
    var description:String
    var type:String
    var category:Category
    var imageUrl:String
    var voiceUrl:String
    
    struct LocationType:Equatable {
        var latitude:Double
        var longitude:Double
        
        static func ==(lhs: LocationType, rhs: LocationType) -> Bool {
            return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
        }
    }
    var locations:[Int:LocationType]
    
    /// Meant for update/creation
    func formatDictionary()->[String:Any]
    {
        var result = [String:Any]()
        result["id"] = id as AnyObject?
        result["name"] = name as AnyObject?
        result["description"] = description as AnyObject?
        result["category"] = category as AnyObject?
        result["category-id"] = category.id as AnyObject?
        result["category-description"] = category.description as AnyObject?
        result["type-name"] = type as AnyObject?
        
        var locDic = [String:[String:Any]]()
        for (order, loc) in locations {
            var newLoc = [String:Any]()
            newLoc["latitude"] = loc.latitude
            newLoc["longitude"] = loc.longitude
            let orderStr = "\(order)"
            locDic[orderStr] = newLoc
        }
        result["locations"] = locDic
        
        return result
    }
}

public struct Type {
    var id:NSNumber
    var name:String
    
    func formatDictionary()->[String:AnyObject]
    {
        var result = [String:AnyObject]()
        result["id"] = id as AnyObject?
        result["name"] = name as AnyObject?
        return result
    }
}

public struct Category {
    var id:NSNumber
    var name:String
    var description:String
    
    func formatDictionary()->[String:AnyObject]
    {
        var result = [String:AnyObject]()
        result["id"] = id as AnyObject?
        result["name"] = name as AnyObject?
        result["description"] = description as AnyObject?
        return result
    }
}

class BackendAPI: NSObject {
    
    fileprivate class func parseAsset(_ JSON:[String:AnyObject])->Asset {
        let id              = JSON["id"] as! NSNumber
        let name            = JSON["name"] as! String
        let description     = JSON["description"] as! String
        let imageUrl        = JSON["media-image-url"] as! String
        let voiceUrl        = JSON["media-voice-url"] as! String
        let locations       = JSON["locations"] as! [String:[String:Any]]
        let category        = JSON["category"] as! String
        let category_id     = JSON["category-id"] as! NSNumber
        let category_desc   = JSON["category-description"] as! String
        let type            = JSON["asset-type"] as! String
        
        var locDic = [Int:Any]()
        for (order, loc) in locations {
            var newLoc = Asset.LocationType(latitude: 0.0, longitude: 0.0)
            newLoc.latitude = loc["latitude"] as! Double
            newLoc.longitude = loc["longitude"] as! Double
            let orderNum = Int(order)!
            locDic[orderNum] = newLoc
        }
        
        return Asset(
            id: id,
            name: name,
            description: description,
            type: type,
            category: Category(id: category_id, name: category, description: category_desc),
            imageUrl: imageUrl,
            voiceUrl: voiceUrl,
            locations: locDic as! [Int : Asset.LocationType]
        )
    }
    
    class func getBASE()->String {
        return BASE
    }
    
    class func printResponse(_ response:DataResponse<Any>) {
        let error = response.result.error
        print("\n------------\n[ERROR] \(error)")
        print(response.debugDescription)
        print(response.data)
        print(response.result)
        if let data = response.data {
            print(String(data: data, encoding: String.Encoding.utf8))
        }
        print("------------\n")
    }
    
//MARK: Asset Methods
    
    class func list(_ completion:@escaping (([Asset])->Void))
    {
        let endpoint = "/api/asset/list/"
        print(BASE+endpoint)
        
        Alamofire.request(BASE+endpoint, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    var result = [Asset]()
                    if let JSON = response.result.value as? [String:Any] {
                        let assets = JSON["assets"] as? [[String:AnyObject]] ?? []
                        for item in assets {
                            result.append(self.parseAsset(item))
                        }
                    }
                    completion(result)
                    
                case .failure(let error):
                    print("[ERROR] \(error)")
                    completion([])
                }
        }
    }
    
    class func delete(_ newAsset:Asset, completion:@escaping ((Bool)->Void))
    {
        let endpoint = "/api/asset/delete/\(newAsset.id)/"
        print(BASE+endpoint)
        
        Alamofire.request(BASE+endpoint, method: .delete)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let JSON = response.result.value as? [String:Any] {
                        let success = JSON["success"] as? Bool ?? false
                        if success {
                            completion(true)
                            return
                        }
                    }
                case .failure:
                    break
                }
                
                printResponse(response)
                completion(false)
                return
        }
    }
    
    class func create(_ newAsset:Asset, completion:@escaping ((_ success:Bool, _ id:NSNumber)->Void))
    {
        let endpoint = "/api/asset/create/"
        print(BASE+endpoint)
        
        let parameters = newAsset.formatDictionary()
        let url = BASE+endpoint
        
        print(parameters)

        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
        .validate()
        .responseJSON { (response) in
            switch response.result {
            case .success:
                if let JSON = response.result.value as? [String:Any] {
                    print("RESPONSE: \(JSON)")
                    let success:Bool = JSON["success"] as? Bool ?? false
                    let assetId:NSNumber = JSON["id"] as! NSNumber
                    
                    print(assetId)
                    
                    if success && assetId != 0 {
                        completion(true, assetId)
                        return
                    }
                }
                break
            case .failure:
                printResponse(response)
                completion(false, 0)
                return
            }
            completion(false, 0)
        }
    }
    
//MARK: Asset-Type Methods
    
    class func typeList(category:Category, _ completion:@escaping (([Type])->Void))
    {
        let endpoint = "/api/asset/type/list/\(category.id)/"
        print(BASE+endpoint)
        
        Alamofire.request(BASE+endpoint, method:.get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    var result = [Type]()
                    if let JSON = response.result.value as? [String:Any] {
                        let types = JSON["types"] as? [[String:AnyObject]] ?? []
                        for item in types {
                            let tId = item["id"] as! NSNumber
                            let tName = item["name"] as? String ?? ""
                            
                            result.append(Type(id: tId, name: tName))
                        }
                    }
                    completion(result)
                    
                case .failure(let error):
                    print("[ERROR] \(error)")
                    completion([])
                }
        }
    }
    
//MARK: Asset-Category Methods
    
    class func categoryList(_ completion:@escaping (([Category])->Void))
    {
        let endpoint = "/api/asset/category/list/"
        print(BASE+endpoint)
        
        Alamofire.request(BASE+endpoint, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    var result = [Category]()
                    if let JSON = response.result.value as? [String:Any] {
                        let types = JSON["categories"] as? [[String:AnyObject]] ?? []
                        for item in types {
                            let cId = item["id"] as! NSNumber
                            let cName = item["name"] as? String ?? ""
                            let cDescriptiom = item["description"] as? String ?? ""
                            
                            result.append(Category(id: cId, name: cName, description: cDescriptiom))
                        }
                    }
                    completion(result)
                    
                case .failure(let error):
                    print("[ERROR] \(error)")
                    completion([])
                }
        }
    }
    
//MARK: Media Methods
    
    class func uploadImage(_ image:UIImage, assetId:NSNumber, progress:@escaping ((_ percent:Double)->Void), completion:@escaping ((Bool)->Void))
    {
        let endpoint = "/api/asset/media/image-upload/\(assetId)/"
        let imageData = UIImageJPEGRepresentation(image, 0.5)!
        
        print(BASE+endpoint)
        
        let url = BASE + endpoint
        let headers = ["content-type":"image/jpeg"]
        
        Alamofire.upload(imageData, to: url, method: .post, headers: headers).uploadProgress { (prog) in
            progress(prog.fractionCompleted)
        }
        .responseJSON { (response) in
            if let JSON = response.result.value as? [String:Any] {
                let success = JSON["success"] as? Bool ?? false
                if success {
                    completion(true)
                    return
                }
            }
            
            //failed
            print(response.result.error)
            completion(false)
        }
    }
    
    class func uploadMemo(_ memoFileURL:URL, assetId:NSNumber, progress:@escaping ((_ percent:Double)->Void), completion:@escaping ((Bool)->Void))
    {
        let endpoint = "/api/asset/media/voice-upload/\(assetId)/"
        
        print(BASE+endpoint)
        
        let headers = ["content-type":"audio/aac"]
        
        Alamofire.upload(memoFileURL, to: BASE+endpoint, method: .post, headers: headers).uploadProgress { (prog) in
            progress(prog.fractionCompleted)
        }
        .responseJSON { (response) in
            if let JSON = response.result.value as? [String:Any] {
                print(JSON)
                let success = JSON["success"] as? Bool ?? false
                if success {
                    completion(true)
                    return
                }
            }
            completion(false)
            return
        }
    }
}

