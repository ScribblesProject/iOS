//
//  PhotoPicker.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/18/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit

public typealias PhotoCompletionHandler = ((_ image:UIImage?)->Void)
public typealias MemoCompletionHandler = ((_ memo:Data?)->Void)

private let _sharedInstance = PhotoPicker()

open class PhotoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    fileprivate var photoHandler:PhotoCompletionHandler?
    fileprivate var memoHandler:MemoCompletionHandler?
    fileprivate var viewController:UIViewController?
    fileprivate var imagePickerController:UIImagePickerController?
    
    open class func sharedInstance()->PhotoPicker {
        return _sharedInstance
    }
    
    open func requestPhoto(viewController vc:UIViewController, completion:@escaping PhotoCompletionHandler)
    {
        photoHandler = completion
        viewController = vc
        
        let alert = UIAlertController(title: "Select Image", message: "What would you like to do?", preferredStyle: .actionSheet)
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoButton = UIAlertAction(title: "Take Photo", style: .default) { (action) -> Void in
            self.photoFromCamera()
        }
        let selectPhotoButton = UIAlertAction(title: "Choose From Library", style: .default) { (action) -> Void in
            self.photoFromLibrary()
        }
        alert.addAction(cancelButton)
        alert.addAction(takePhotoButton)
        alert.addAction(selectPhotoButton)
        
        DispatchQueue.main.async { () -> Void in
            self.viewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func photoFromLibrary()
    {
        imagePickerController = UIImagePickerController()
        imagePickerController?.sourceType = .photoLibrary;
        imagePickerController?.delegate = self;
        viewController?.present(imagePickerController!, animated: true, completion: nil)
    }
    
    fileprivate func photoFromCamera()
    {
        imagePickerController = UIImagePickerController()
        imagePickerController?.delegate = self;
        imagePickerController?.allowsEditing = true
        imagePickerController?.sourceType = .camera;
        viewController?.present(imagePickerController!, animated: true, completion: nil)
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        print("Picker Finished")
        let chosenImage = image
        photoHandler?(chosenImage)
        picker.dismiss(animated: true, completion: nil)
        imagePickerController = nil
    }
}
