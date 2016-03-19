//
//  PhotoPicker.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/18/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit

public typealias PhotoCompletionHandler = ((image:UIImage?)->Void)
public typealias MemoCompletionHandler = ((memo:NSData?)->Void)

private let _sharedInstance = PhotoPicker()

public class PhotoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var photoHandler:PhotoCompletionHandler?
    private var memoHandler:MemoCompletionHandler?
    private var viewController:UIViewController?
    private var imagePickerController:UIImagePickerController?
    
    public class func sharedInstance()->PhotoPicker {
        return _sharedInstance
    }
    
    public func requestPhoto(viewController vc:UIViewController, completion:PhotoCompletionHandler)
    {
        photoHandler = completion
        viewController = vc
        
        let alert = UIAlertController(title: "Select Image", message: "What would you like to do?", preferredStyle: .ActionSheet)
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let takePhotoButton = UIAlertAction(title: "Take Photo", style: .Default) { (action) -> Void in
            self.photoFromCamera()
        }
        let selectPhotoButton = UIAlertAction(title: "Choose From Library", style: .Default) { (action) -> Void in
            self.photoFromLibrary()
        }
        alert.addAction(cancelButton)
        alert.addAction(takePhotoButton)
        alert.addAction(selectPhotoButton)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.viewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func photoFromLibrary()
    {
        imagePickerController = UIImagePickerController()
        imagePickerController?.sourceType = .PhotoLibrary;
        imagePickerController?.delegate = self;
        viewController?.presentViewController(imagePickerController!, animated: true, completion: nil)
    }
    
    private func photoFromCamera()
    {
        imagePickerController = UIImagePickerController()
        imagePickerController?.delegate = self;
        imagePickerController?.allowsEditing = true
        imagePickerController?.sourceType = .Camera;
        viewController?.presentViewController(imagePickerController!, animated: true, completion: nil)
    }
    
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        print("Picker Finished")
        let chosenImage = image
        photoHandler?(image: chosenImage)
        picker.dismissViewControllerAnimated(true, completion: nil)
        imagePickerController = nil
    }
}
