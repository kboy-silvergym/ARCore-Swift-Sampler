//
//  ViewController.swift
//  CloudAnchorSwift
//
//  Created by Kei Fujikawa on 2018/05/12.
//  Copyright © 2018年 Kboy. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ARCore
import Firebase

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    private lazy var firebaseReference = Database.database().reference().child("hotspot_list")
    private var gSession: GARSession!
    private var fetchedAnchorIds: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        gSession = try! GARSession(apiKey: Const.apiKey, bundleIdentifier: nil)
        gSession.delegate = self
        gSession.delegateQueue = DispatchQueue.main
        
        observeAnchors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchLocation, types: [.existingPlane, .existingPlaneUsingExtent, .estimatedHorizontalPlane])
        
        if let result = hitTestResults.first {
            addAnchor(transform: result.worldTransform)
        }
    }
    
    @IBAction func fetchButtonTapped(_ sender: Any) {
        resolveAnchors()
    }
    
}

// MARK: - Some Original Method
extension ViewController {
    
    // fetch anchors from Firebase Database
    private func observeAnchors() {
        firebaseReference.observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [String : Any] else {
                return
            }
            let list = value.values
            list.forEach { value in
                if let dic = value as? [String: Any],
                    let anchorId = dic["hosted_anchor_id"] as? String {
                    self.fetchedAnchorIds.append(anchorId)
                }
            }
        }
    }
    
    private func resolveAnchors(){
        fetchedAnchorIds.forEach { id in
            _ = try! gSession?.resolveCloudAnchor(withIdentifier: id)
        }
        fetchedAnchorIds.removeAll()
    }
    
    // addAnchor to AR Space and share the anchor data to Google Cloud
    private func addAnchor(transform: matrix_float4x4) {
        let arAnchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: arAnchor)
        
        do {
            _ = try gSession.hostCloudAnchor(arAnchor)
        } catch {
            print(error)
        }
    }
}

// MARK: - <#ARSCNViewDelegate#>
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Basicaly, you can get only ARPlaneAnchor,
        // but this case, you can also get another anchor which is created by ARCore.
        if !(anchor is ARPlaneAnchor) {
            let scene = SCNScene(named: "art.scnassets/ship.scn")!
            return scene.rootNode.childNode(withName: "ship", recursively: false)
        }
        return nil
    }
}

// MARK: - <#ARSCNViewDelegate#>
extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        do {
            try gSession.update(frame)
        } catch {
            print(error)
        }
    }
}

// MARK: - <#GARSessionDelegate#>
extension ViewController: GARSessionDelegate {
    
    func session(_ session: GARSession, didHostAnchor anchor: GARAnchor) {
        let id = anchor.cloudIdentifier
        firebaseReference.childByAutoId().child("hosted_anchor_id").setValue(id)
    }
    
    func session(_ session: GARSession, didFailToHostAnchor anchor: GARAnchor) {
        print("didFailToHostAnchor")
    }
    
    func session(_ session: GARSession, didResolve anchor: GARAnchor) {
        let arAnchor = ARAnchor(transform: anchor.transform)
        sceneView.session.add(anchor: arAnchor)
    }
    
    func session(_ session: GARSession, didFailToResolve anchor: GARAnchor) {
        print("didFailToResolve")
    }
}
