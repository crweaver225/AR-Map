//
//  SixthViewController.swift
//  ARPracticeApp
//
//  Created by Christopher Weaver on 4/18/18.
//  Copyright © 2018 goeshow. All rights reserved.
//

import UIKit
import ARKit
import Vision
import MapKit
import Foundation
import AudioToolbox


class locateLocation: CLGeocoder {
    var location: CLLocation?
}

class PhysicalMapViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    
    @IBOutlet weak var addSelfButton: UIButton!
    
    @IBAction func addSelf(_ sender: Any) {
        
        if areYouSure {
            let pinMoveAction = SCNAction.rotateBy(x: CGFloat(75.degreesToRadians), y: 0, z: 0, duration: 2.0)
            self.newPin!.runAction(pinMoveAction)
            self.newPin?.runAction(pinMoveAction, completionHandler: {
                self.addNewPin()
            })
        } else {
            newPin = SCNNode(geometry: SCNPlane(width: 0.25, height: 0.25))
            newPin?.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "pin")
            newPin?.geometry?.firstMaterial?.isDoubleSided = true
            newPin?.eulerAngles = SCNVector3(0, 0, 0)
            self.mapNode?.addChildNode(newPin!)
            let x =  0
            let y = 0
            let z = 2
            newPin!.position = SCNVector3(x, 10, 1)
            let nodeMoveAction = SCNAction.move(to: SCNVector3(x, y, Int(z ?? 0)), duration: 2.0)
            newPin!.runAction(nodeMoveAction)
            areYouSure = true
            self.addSelfButton.setTitle("Are you sure?", for: .normal)
        }
    }
    
    var newPin : SCNNode?
    var areYouSure : Bool = false
    
    func addNewPin() {
        let address = "605 N Bridge St Yorkville Illinois 60560"
        turnAddressIntoCoordinates(address: address, completionHandler: { (coordinates) in
            var longitudePercentage : CGFloat
            if let longitudeCoordinate = coordinates?.x {
                longitudePercentage = (longitudeCoordinate / 180)
            } else {
                longitudePercentage = 0
            }
            var latitudePercentage : CGFloat
            if let latitudeCoordinate = coordinates?.y {
                latitudePercentage = (latitudeCoordinate / 90)
            } else {
                latitudePercentage = 0
            }
            
            let nodeWidth = CGFloat((self.mapNode?.boundingBox.max.x)! - (self.mapNode?.boundingBox.min.x)!)
            let nodeHeight = CGFloat((self.mapNode?.boundingBox.max.y)! - (self.mapNode?.boundingBox.min.y)!)
            
            let finalLongitude = (nodeWidth * longitudePercentage) / 2
            let finalLatitude = (nodeHeight * latitudePercentage) / 2
            
            self.newPin!.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "pin")
            self.newPin!.geometry?.firstMaterial?.isDoubleSided = true
            self.newPin!.eulerAngles = SCNVector3(75.degreesToRadians, 0, 0)

            let x =  Float(finalLongitude) - 0.00125
            let y = Float(finalLatitude) - 0.035
            let z = (self.mapNode?.position.z)!
            
            self.newPin!.position = SCNVector3(x, y, 1)
            let nodeMoveAction = SCNAction.move(to: SCNVector3(x, y, z), duration: 1.0)
            self.newPin!.runAction(nodeMoveAction)
            
            let pinMoveAction = SCNAction.rotateBy(x: 0, y: 0, z: 0, duration: 1.0)
            self.newPin!.runAction(pinMoveAction)
        })
    }
    
    @IBOutlet weak var dropPinButton: UIButton!
    var mapNode : SCNNode?
    
    @IBAction func dropPinHit(_ sender: Any) {
        self.placePinOnMap()
        UIView.animate(withDuration: 0.5, animations: {
            self.dropPinButton.alpha = 0
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dropPinButton.frame.origin.y = self.view.frame.height + 110
        self.dropPinButton.layer.cornerRadius = self.dropPinButton.frame.size.width / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayLoadingView()
        /*
        if #available(iOS 11.3, *) {
            guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
                fatalError("Missing expected asset catalog resources.")
            }
            let configuration = ARWorldTrackingConfiguration()
            configuration.detectionImages = referenceImages
            self.sceneView.showsStatistics = true
            self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            self.sceneView.delegate = self
            self.sceneView.session.delegate = self
        } else {
            // Fallback on earlier versions
        }
 */
        
        if #available(iOS 12.0, *) {
            let configuration = ARImageTrackingConfiguration()
            guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { fatalError("No images available") }
            configuration.trackingImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 2
            self.sceneView.session.run(configuration)
            self.sceneView.delegate = self
            self.sceneView.session.delegate = self
        } else {
            // Fallback on earlier versions
        }
    }
    
    func displayLoadingView() {
        
        let loadingView = UINib(nibName: "LoadingView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? LoadingView
        
        loadingView?.frame = CGRect(x: self.view.frame.size.width * 0.175, y: self.view.frame.size.height * 0.30, width: self.view.frame.size.width * 0.65, height: self.view.frame.size.height * 0.225)
        loadingView?.backgroundColor = UIColor(red: 0.977255, green: 0.977255, blue: 0.976863, alpha: 1)
        loadingView?.alpha = 0.8
        loadingView?.layer.borderWidth = 1.0
        loadingView?.layer.borderColor = UIColor.black.cgColor
        loadingView?.layer.cornerRadius = 8
        self.view.addSubview(loadingView!)
        let when = DispatchTime.now() + 5.5
        DispatchQueue.main.asyncAfter(deadline: when) {
            loadingView?.removeFromSuperview()
        }
    }
    
    func turnAddressIntoCoordinates(address : String, completionHandler: @escaping ( _ results : CGPoint?) -> Void) {
        var returnValues : CGPoint?
        let findLocation = locateLocation()
        findLocation.geocodeAddressString(address) { (coordinates, error) in
            
            let geoLocation: [CLPlacemark] = coordinates!
            let latitude =  Double((geoLocation[0].location?.coordinate.latitude)!)
            let longitude = Double((geoLocation[0].location?.coordinate.longitude)!)

            returnValues = CGPoint(x: longitude, y: latitude)
            completionHandler(returnValues)
        }
    }
    
    var addressArray : [String] = ["Nashville, tennessee", "Agra, India", "Berlin, Germany", "Austin, Texas United States", "Moscow, Russia"]
    
    func placePinOnMap() {
        for address in addressArray {
            turnAddressIntoCoordinates(address: address, completionHandler: { (coordinates) in
                var longitudePercentage : CGFloat
                if let longitudeCoordinate = coordinates?.x {
                    longitudePercentage = (longitudeCoordinate / 180)
                } else {
                    longitudePercentage = 0
                }
                var latitudePercentage : CGFloat
                if let latitudeCoordinate = coordinates?.y {
                    latitudePercentage = (latitudeCoordinate / 90)
                } else {
                    latitudePercentage = 0
                }
                
                let nodeWidth = CGFloat((self.mapNode?.boundingBox.max.x)! - (self.mapNode?.boundingBox.min.x)!)
                let nodeHeight = CGFloat((self.mapNode?.boundingBox.max.y)! - (self.mapNode?.boundingBox.min.y)!)
                
                let finalLongitude = (nodeWidth * longitudePercentage) / 2
                let finalLatitude = (nodeHeight * latitudePercentage) / 2

                let pinPoint = SCNNode(geometry: SCNPlane(width: 0.25, height: 0.25))
                pinPoint.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "pin")
                pinPoint.geometry?.firstMaterial?.isDoubleSided = true
                pinPoint.eulerAngles = SCNVector3(75.degreesToRadians, 0, 0)
                
                self.mapNode?.addChildNode(pinPoint)

                let x =  Float(finalLongitude) - 0.00125
                let y = Float(finalLatitude) - 0.035
                let z = (self.mapNode?.position.z)!
                
                pinPoint.position = SCNVector3(x, y, 1)
                let nodeMoveAction = SCNAction.move(to: SCNVector3(x, y, z), duration: 1.0)
                pinPoint.runAction(nodeMoveAction)
                
                let pinMoveAction = SCNAction.rotateBy(x: 0, y: 0, z: 0, duration: 1.0)
                pinPoint.runAction(pinMoveAction)
            })
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        let referenceImage = imageAnchor.referenceImage
        DispatchQueue.main.async {
            let plane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
            self.mapNode = SCNNode(geometry: plane)
            self.mapNode?.eulerAngles.x = -.pi / 2
            self.mapNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.mapNode?.opacity = 0.15
            let when = DispatchTime.now() + 1.5
            DispatchQueue.main.asyncAfter(deadline: when) {
                 self.mapNode?.opacity = 1
                 self.mapNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
            }
            node.addChildNode(self.mapNode!)
            AudioServicesPlaySystemSound(1521)
            UIView.animate(withDuration: 0.5, animations: {
                self.dropPinButton.frame.origin.y = self.view.frame.height - 140
                self.addSelfButton.alpha = 1
            })
        }
        return node
    }
 
}


extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
