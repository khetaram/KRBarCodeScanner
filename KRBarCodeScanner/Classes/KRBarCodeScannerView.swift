//
//  KRBarCodeScannerView.swift
//  KRBarCodeScanner
//
//  Created by khetaram on 16/08/16.
//  Copyright © 2016 khetaram. All rights reserved.
//

import UIKit
import AVFoundation
@objc protocol KRBarCodeScannerDelegate {
    func BarCode(barcode:NSString,ofType type:NSString)
    optional func BarCode(error error:NSString)
}

public class KRBarCodeScannerView: UIView,AVCaptureMetadataOutputObjectsDelegate {
    
    //MARK: Properties
    private let cameraView = UIView()
    private let captureSession = AVCaptureSession()
    private var captureDevice:AVCaptureDevice?
    private var captureLayer:AVCaptureVideoPreviewLayer?
    private var player:AVAudioPlayer?
    private let rectLayer = CAShapeLayer()
    private let torchButton = UIButton(frame: CGRectMake(5,5,55,30))
    weak var delegate:KRBarCodeScannerDelegate?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        torchButton.layer.cornerRadius = 15
        torchButton.setBackgroundImage(UIImage(named: "torch.png"), forState: .Normal)
        torchButton.addTarget(self, action: #selector(KRBarCodeScannerView.torchOnOff), forControlEvents: .TouchUpInside)
        torchButton.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(torchButton)
        cameraView.frame = frame
        self.setupCaptureSession()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KRBarCodeScannerView.appEnteredBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    required  public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc private func torchOnOff(){
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                if (device.torchMode == AVCaptureTorchMode.On) {
                    device.torchMode = AVCaptureTorchMode.Off
                    self.torchButton.backgroundColor = UIColor.lightGrayColor()
                } else {
                    device.torchMode = AVCaptureTorchMode.On
                    self.torchButton.backgroundColor = UIColor.greenColor()
                }
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    @objc private func appEnteredBackground(){
        self.torchButton.backgroundColor = UIColor.lightGrayColor()
    }
    public func startScanning() {
        rectLayer.removeFromSuperlayer()
        self.captureSession.startRunning()
    }
    public func stopScanning(){
        self.captureSession.stopRunning()
    }
    
    //MARK: Session Startup
    private func setupCaptureSession(){
        self.captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do{
            let deviceInput = try AVCaptureDeviceInput(device:(self.captureDevice))
            //Add the input feed to the session and start it
            self.captureSession.addInput(deviceInput)
            self.setupPreviewLayer({
                self.addMetaDataCaptureOutToSession()
            })
        }catch{
            self.showError("Input device not available")
        }
    }
    
    private func setupPreviewLayer(completion:() -> ()){
        self.captureLayer = AVCaptureVideoPreviewLayer(session:self.captureSession)
        if let capLayer = self.captureLayer{
            capLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            capLayer.frame = self.cameraView.bounds
            self.layer.addSublayer(capLayer)
            self.bringSubviewToFront(torchButton)
            completion()
        }else{
            self.showError("An error occured beginning video capture.")
        }
    }
    
    //MARK: Metadata capture
    private func addMetaDataCaptureOutToSession(){
        let metadata = AVCaptureMetadataOutput()
        self.captureSession.addOutput(metadata)
        metadata.metadataObjectTypes = metadata.availableMetadataObjectTypes
        metadata.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    }
    
    //MARK: Delegate Methods
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!){
        for metaData in metadataObjects{
            if(metaData.isKindOfClass(AVMetadataMachineReadableCodeObject)){
                let path = NSBundle.mainBundle().pathForResource("beep-A", ofType: "wav")
                do{
                    player = try  AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path!))
                    player!.prepareToPlay()
                    player!.play()
                }catch{
                    print("Audio not played")
                }
                self.captureSession.stopRunning()
                let decodedData:AVMetadataMachineReadableCodeObject = metaData as! AVMetadataMachineReadableCodeObject
                if (delegate != nil){
                    let barCodeObject = captureLayer!.transformedMetadataObjectForMetadataObject(decodedData) as! AVMetadataMachineReadableCodeObject
                    self.drawBox(barCodeObject.bounds)
                    self.delegate?.BarCode(decodedData.stringValue, ofType: decodedData.type)
                }
            }
        }
    }
    
    private func drawBox(rect:CGRect){
        let path = UIBezierPath(rect: rect)
        path.lineWidth = 2
        rectLayer.path = path.CGPath
        rectLayer.fillColor = UIColor.clearColor().CGColor
        rectLayer.strokeColor = UIColor.redColor().CGColor
        captureLayer?.addSublayer(rectLayer)
    }
    
    private func showError(error:String)
    {
        if (delegate != nil){
            self.delegate?.BarCode!(error: error)
        }
    }
    
}
