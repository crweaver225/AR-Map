//
//  ARGlobeViewController.swift
//  Conference
//
//  Created by Christopher Weaver on 2/5/18.
//  Copyright © 2018 Netronix Corporation. All rights reserved.
//

import UIKit
import ARKit
import Vision
import MapKit
import Foundation
import AudioToolbox

class ARGlobeViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var earthNode : SCNNode?
    
    var spinning = true
    
    @IBAction func spin(_ sender: Any) {
        if spinning {
            earthNode?.removeAllActions()
            self.spinning = false
        } else {
            let earthRotatationAction = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 20)
            let forever = SCNAction.repeatForever(earthRotatationAction)
            earthNode?.runAction(forever)
            self.spinning = true
        }
    }
    @IBAction func addGlobe(_ sender: Any) {
        addGlobe()
    }
    @IBAction func addMe(_ sender: Any) {
        addPersonToGlobe()
      //  addAllAttendeesToGloble()
    }
    var earthDisplayImage : UIView?
    
    var configuration = ARWorldTrackingConfiguration()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
 
     //   var panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
       // sceneView.addGestureRecognizer(panRecognizer)
    }
    
    func panGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)
        var newAngle = (Float)(translation.x)*(Float)(M_PI)/180.0
        newAngle += (earthNode?.position.x)!//currentAngle
        earthNode?.transform = SCNMatrix4MakeRotation(newAngle, Float(translation.x), Float(translation.y),Float(0.0))
        if(sender.state == UIGestureRecognizer.State.ended) {
           // earthNode?.position.x = newAngle
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    func addGlobe() {

        earthNode = SCNNode(geometry: SCNSphere(radius: 0.75))
        earthNode?.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "earth") //earthDisplayImage
        earthNode?.position = SCNVector3(0, -0.5, -2)
        earthNode?.name = "Just the earth"
        self.sceneView.scene.rootNode.addChildNode(earthNode!)
        
        let earthRotatationAction = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 20)
        let forever = SCNAction.repeatForever(earthRotatationAction)
        earthNode?.runAction(forever)
    }
    
    func pinPointTouched( _ Sender : UITapGestureRecognizer) {
        if let me = Sender.view as? UIView {
            
            print("found me!!!!!!")
            print(me.tag)
        }
    }

    
    func addPersonToGlobe() {
    
        let address = "605 N Bridge St Yorkville Illlinois 60560"
        turnAddressIntoCoordinates(address: address, completionHandler: { (coordinates) in
            
            let pinPoint = SCNNode(geometry: SCNPlane(width: 0.075, height: 0.075))
            let imageMaterial = SCNMaterial()
            imageMaterial.diffuse.contents = UIImage(named: "globePin")
            imageMaterial.isDoubleSided = true
            imageMaterial.transparencyMode = .dualLayer
            pinPoint.geometry?.materials = [imageMaterial]
            pinPoint.eulerAngles = SCNVector3(0, 0, 0)
            pinPoint.position = SCNVector3(0, 2, 0)
            pinPoint.name = "A17248A2-0C1A-E711-9E33-180373F156C0"
            self.earthNode?.addChildNode(pinPoint)
            
            if let coordinates = coordinates {
                
                let z = 0.77 * cos(coordinates.y) * cos(coordinates.x)
                let x = 0.77 * cos(coordinates.y) * sin(coordinates.x)
                let y = 0.77 * sin(coordinates.y)
                
                let nodeMoveAction = SCNAction.move(to: SCNVector3(x, y, z), duration: 2.0)
                pinPoint.runAction(nodeMoveAction)
                pinPoint.eulerAngles = SCNVector3(0, x * 2.75, 0)
            }
        })
    }
    
    func turnAddressIntoCoordinates(address : String, completionHandler : @escaping ( _ results : CGPoint?) -> Void) {
        var returnValues : CGPoint?
        let findLocation = locateLocation()
        findLocation.geocodeAddressString(address) { (coordinates, error) in
            
            let geoLocation: [CLPlacemark] = coordinates!
            let latitude =  Double((geoLocation[0].location?.coordinate.latitude)!) //* 2
            let longitude = Double((geoLocation[0].location?.coordinate.longitude)!)
            
            returnValues = CGPoint(x: longitude.degreesToRadians, y: latitude.degreesToRadians)
            completionHandler(returnValues)
        }
    }
    
    func makeRoundImg(img: UIImageView) -> UIImage {
        let imgLayer = CALayer()
        imgLayer.frame = img.bounds
        imgLayer.contents = img.image?.cgImage;
        imgLayer.masksToBounds = true;
        
        imgLayer.cornerRadius = 28 //img.frame.size.width/2
        
        UIGraphicsBeginImageContext(img.bounds.size)
        imgLayer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.sceneView.session.pause()

        self.sceneView.scene.rootNode.enumerateChildNodes( { (node, _) in
            node.removeFromParentNode()
        })
        
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi/180}
}
