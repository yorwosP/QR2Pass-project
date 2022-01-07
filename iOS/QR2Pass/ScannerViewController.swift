//
//  ScannerViewController.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/3/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import LocalAuthentication
import UIKit
import AVFoundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    
    //MARK: - outlets
    
    @IBOutlet var previewView: UIView!
    @IBOutlet var cancelButton: CustomButton!
    
    @IBOutlet var statusLabel: UILabel!
    //MARK: - class properties
    
    var qrCode: QRData?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var scanLayer: CAShapeLayer?
    var size:CGSize{
        get{
            return CGSize(width: 2*view.frame.width/3, height: 2*view.frame.width/3)
        }
    }
    
    var timer: Timer?
    
    
    var currentStatus: String?{
        didSet{
            timer?.invalidate()
            DispatchQueue.main.async{[weak self] in
                self?.statusLabel.isHidden = false
                self?.statusLabel.text = self?.currentStatus
                self?.scanLayer?.strokeColor = UIColor.red.cgColor
                self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { timer in
                    self?.statusLabel.text = ""
                    self?.statusLabel.isHidden = true
                    self?.scanLayer?.strokeColor = UIColor.white.cgColor

                
                })
            }

            
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView.frame = view.frame
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        

        // setup the capture session

        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
 
            
            presentAlert(title: "AV device failed", message: "Cannot setup video device")
 
            return
            
        }
        let videoDeviceInput:AVCaptureDeviceInput
        do{
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        }catch{
           
            // inform the user
            presentAlert(title: "Camera not available", message: "Default camera is not available. Try allowing the use of camera for this app")
            return
        }
        
        if (captureSession.canAddInput(videoDeviceInput)){
            captureSession.addInput(videoDeviceInput)
        }else{
            // inform the user
            presentAlert(title: "Video stream error", message: "Cannot initate capture stream for the camera. Quitting")
            return
        }
        
      
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput){
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }else{
            // inform the user
            presentAlert(title: "Video stream error", message: "Camera cannot output video stream. Quitting")
            return
        }

        

        // setup the appearance
        let rectOfInterest = createScanRect(size) // rect defining the (QR) scan area
        scanLayer = createScanLayerOn(rectOfInterest, borderWidth: 6)

        captureSession?.commitConfiguration()

        //        setup the preview Layer
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
     
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        
        // create a layer on top to darken the background
        let onTopLayer = CALayer()
        onTopLayer.frame = previewLayer.frame
        onTopLayer.opacity = 0.5
        onTopLayer.backgroundColor = UIColor.black.cgColor
        
        // create a "hole" (i.e not darkened) in it the size/place of the scan area
        let maskLayer = CAShapeLayer()
        maskLayer.frame = onTopLayer.bounds
        let path = UIBezierPath(rect: maskLayer.bounds) // path around the whole view
        path.append(UIBezierPath(rect: rectOfInterest)) // path around the scan rect (this will be subtracted)
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        onTopLayer.mask = maskLayer
        
        // define the area of interest for scanning
        metadataOutput.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: rectOfInterest)
        
        
        // setup the status text
        // status text is going to be 75% of scan layer's width and 33% of scan layer's height
        
        
        if scanLayer != nil {

            let xInset = 0.25*scanLayer!.frame.width/2
            let yInset = 0.33*scanLayer!.frame.height
            let statusLabelRect = scanLayer!.frame.insetBy(dx: xInset, dy: yInset)
            statusLabel.frame = statusLabelRect
            statusLabel.isHidden = true

            
            // add the layers
            previewView.layer.addSublayer(previewLayer)
            previewView.layer.addSublayer(onTopLayer)
            previewView.layer.addSublayer(scanLayer!)
            
            // bring button and statusLabel to front
            previewView.bringSubviewToFront(statusLabel)
            previewView.bringSubviewToFront(cancelButton)
            // start capturing
            captureSession.startRunning()
        }
        
        
        
    }
    
    
    // when app moves to backround return to main VC
    @objc func appMovedToBackground() {
        
        captureSession.stopRunning()
        performSegue(withIdentifier: "unwind to main", sender: self)



    }

    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // called when a QR code is scanned
        
        if let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject{
            // machine readable code detected, check if this a valid QR code
            if let request =  code.stringValue?.data(using: .utf8){
                // first get the data from the string represantation (if possible)
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                jsonDecoder.dateDecodingStrategy = .secondsSince1970
                if let decoded = try? jsonDecoder.decode(QRData.self, from: request){
                    // found a valid code
                    qrCode = decoded
                    found(code: qrCode!)

                }else{
    
                    currentStatus = "Invalid QR code"
                }
                
            }else{
                currentStatus = "Could not get data from code. Probably invalid QR"

            }
        }else{
            // currentStatus = "Could not get QR code"
            print ("Could not get qr code")
        }

    }
    
    /// a valid QR code was scanned.
    /// Stop capturing,  vibrate the device and
    /// unwind to main VC
    /// - Parameter code: the QRData object that was scanned
    private func found(code: QRData?){
        
        qrCode = code
        // vibrate the device
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        captureSession.stopRunning()
        performSegue(withIdentifier: "unwind to main", sender: self)

        
    }
    
    
    /// create a CGRect defining the area for QR scanning
    /// - Parameter size: the size of the rect
    /// - Returns: a CGRect
    private func createScanRect(_ size: CGSize) -> CGRect{
        
        // x = middle of the view
        // y = middle between top of the view and the bottom of the cancel button
        
        let x = previewView.center.x
        let y = cancelButton.frame.maxY/2
        let center = CGPoint(x: x, y: y)
        let originX = center.x - size.width/2
        let originY = center.y - 1.2*(size.height/2)
        
        let rect = CGRect(origin: CGPoint(x: originX, y: originY), size: size)
        return rect
        
    }
    
    
    /// create a transparent rect CAShapeLayer with outline only on the angles. Only works for square with no rounded corners
    /// - Parameters:
    ///   - rect: the CGRect on which the shape will be based on
    ///   - borderWidth: width of the partial border
    ///   - borderColor: color of the partial border
    /// - Returns: a CAShapeLayer
    private func createScanLayerOn(
        _ rect:CGRect, borderWidth:CGFloat,
        borderColor:UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ) -> CAShapeLayer{
    
        let scanLayer = CAShapeLayer()
        scanLayer.lineWidth = borderWidth
        scanLayer.strokeColor = borderColor.cgColor
//        following only works with square with no rounded corners
        let dashLength = rect.width/2
        let dashSpace = rect.width/2
        let dashPhase = dashSpace/2
        scanLayer.lineDashPattern = [dashLength, dashSpace] as [NSNumber]
        scanLayer.lineDashPhase = dashPhase
        scanLayer.frame = rect
        scanLayer.fillColor = nil
       
//        TODO: make it work with rounded corners as well
//        if cornerRadius > 0 {
//            scanLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
//        } else {
        scanLayer.path = UIBezierPath(rect: scanLayer.bounds).cgPath
        scanLayer.lineCap = .round
////        }
        
        return scanLayer
    }
    
    
    /// create and present a UIALertController
    /// - Parameters:
    ///   - title:
    ///   - message:
    private func presentAlert(title: String, message:String){
         
         let alertMessage = UIAlertController(title: title, message: message, preferredStyle: .alert)
         let action = UIAlertAction(title: "Ok", style: .cancel) { action in

             
         }
         alertMessage.addAction(action)
         DispatchQueue.main.async {
               self.present(alertMessage, animated: true, completion: nil)
         }
         
     }
    
    
    
    
    
}
