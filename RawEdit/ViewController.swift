//
//  ViewController.swift
//  RawEdit
//
//  Created by Ege on 26.11.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit
import Photos
class ViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    @IBOutlet weak var imageViewer: UIImageView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var exposureSlider: UISlider!
    var rawURL : URL?
    var rawAsCIImage : CIImage?
    var rawImage: CIFilter?
    
    lazy var contextForSaving:CIContext = CIContext(options:
        [kCIContextCacheIntermediates : false ,
         kCIContextPriorityRequestLow : true ])
    
    @IBAction func selectPhoto(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    //    methods for the picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled")
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let rawURL = info["UIImagePickerControllerImageURL"] as? URL{
            print(rawURL)
            self.rawURL = rawURL
            guard let rawAsCIImage = getAdjustedRaw() else {return}
            self.rawAsCIImage = rawAsCIImage
            let rawAsUIImage = UIImage(ciImage: rawAsCIImage)
            print(rawAsUIImage)
            imageViewer.image = rawAsUIImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exposureChanged(_ sender: Any) {
        guard let rawAsCIImage = getAdjustedRaw() else {return}
        self.rawAsCIImage = rawAsCIImage
        let rawAsUIImage = UIImage(ciImage: rawAsCIImage)
        imageViewer.image = rawAsUIImage
    }
    
    func getAdjustedRaw() -> CIImage?{
    
        guard let shadowHighlight = CIFilter(name: "CIHighlightShadowAdjust") else{return nil}
        //open raw to edit
        if self.rawImage == nil {
            self.rawImage = CIFilter(imageURL: rawURL!, options: nil)
        }
        
        guard let rawImage = self.rawImage else {return nil}
        let exValue = exposureSlider.value
        rawImage.setValue(exValue, forKey: kCIInputEVKey)
        rawImage.setValue(2, forKey: kCIInputBoostShadowAmountKey)
        shadowHighlight.setValue(rawImage.outputImage, forKey: kCIInputImageKey)
        shadowHighlight.setValue(1, forKey: "inputHighlightAmount")
        shadowHighlight.setValue(0.3 , forKey: "inputShadowAmount")
        rawImage.setValue(shadowHighlight, forKey: kCIInputLinearSpaceFilter)
    
        return rawImage.outputImage
    }
    func createCGIImage(from rawImage: CIImage ) -> CGImage? {
        return contextForSaving.createCGImage(rawImage, from: rawImage.extent, format: kCIFormatRGBAh, colorSpace: CGColorSpace(name:CGColorSpace.extendedLinearSRGB), deferred: true)
    }
    
    @IBAction  func save(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges( {
            let creationRequet = PHAssetCreationRequest.forAsset()
            let creationOptions = PHAssetResourceCreationOptions()
            creationOptions.shouldMoveFile = true
            let cs = CGColorSpace(name: CGColorSpace.displayP3)!
            let jpegPhotoData =  self.contextForSaving.jpegRepresentation(of: self.rawAsCIImage!, colorSpace: cs, options: [kCGImageDestinationLossyCompressionQuality : 1.0])
            
            creationRequet.addResource(with: .photo, data: jpegPhotoData!, options: creationOptions)
        }, completionHandler: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        dont get values everytime
        exposureSlider.isContinuous = false
    }
}

