//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit


class GameViewController: NSViewController {

    // debugging labels
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debugInfoLabel: NSTextField!
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    @IBOutlet weak var cursorTracker: NSTextField!
    @IBOutlet weak var graphButton: NSButton!

    let demoController = DemoController.default
    var loggingLevel: LoggingLevel = .debug

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView
        // set the controller view
        demoController.view = skView


        guard let currentURL = demoController.currentURL else {
            print("[GameViewController]: WARNING: no tilemap to load.")
            return
        }

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsPhysics = true
        #endif

        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        setupDebuggingLabels()

        //set up notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindowTitle), name: NSNotification.Name(rawValue: "updateWindowTitle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGraphControls), name: NSNotification.Name(rawValue: "updateGraphControls"), object: nil)
        debugInfoLabel?.isHidden = true


        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        scene.setup(tmxFile: currentURL.relativePath, inDirectory: nil, tilesets: [], verbosity: loggingLevel)

    }


    override func viewDidAppear() {
        super.viewDidAppear()
    }

    /**
     Set up the debugging labels. (Mimics the text style in iOS controller).
     */
    func setupDebuggingLabels() {
        mapInfoLabel.stringValue = "Map: "
        tileInfoLabel.stringValue = "Tile: "
        propertiesInfoLabel.stringValue = "Properties:"
        cameraInfoLabel.stringValue = "~"

        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 2, height: 1)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.75)
        shadow.shadowBlurRadius = 0.5

        mapInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        debugInfoLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
    }

    /**
     Action called when `fit to view` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func fitButtonPressed(_ sender: Any) {
        self.demoController.fitSceneToView()
    }

    /**
     Action called when `show grid` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.demoController.toggleMapDemoDraw()
    }

    /**
     Action called when `show graph` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func graphButtonPressed(_ sender: Any) {
        self.demoController.toggleMapGraphVisualization()
    }

    /**
     Action called when `show objects` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func objectsButtonPressed(_ sender: Any) {
        self.demoController.toggleMapObjectDrawing()
    }

    /**
     Action called when `next` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func nextButtonPressed(_ sender: Any) {
        self.demoController.loadNextScene()
    }

    /**
     Mouse scroll wheel event handler.

     - parameter event: `NSEvent` mouse event.
     */
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else { return }

        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.scrollWheel(with: event)
        }
    }

    /**
     Update the window's title bar with the current scene name.

     - parameter withFile: `String` currently loaded scene name.
     */
    @objc func updateWindowTitle(notification: Notification) {
        if let wintitle = notification.userInfo!["wintitle"] {
            if let infoDictionary = Bundle.main.infoDictionary {
                if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                    self.view.window?.title = "\(bundleName): \"\(wintitle as! String)\""
                }
            }
        }
    }

    /**
     Update the debugging labels with scene information.

     - parameter notification: `Notification` notification.
     */
    @objc func updateDebugLabels(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }

        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.stringValue = propertiesInfo as! String
        }

        if let debugInfo = notification.userInfo!["debugInfo"] {
            debugInfoLabel.stringValue = debugInfo as! String
        }

        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.stringValue = cameraInfo as! String
        }
    }

    @objc func updateGraphControls(notification: Notification) {
        if let hasGraphs = notification.userInfo!["hasGraphs"] {
            graphButton.isEnabled = (hasGraphs as? Bool) == true
        }
    }
}
