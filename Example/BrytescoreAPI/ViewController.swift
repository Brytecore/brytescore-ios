//
//  ViewController.swift
//  BrytescoreAPI
//
//  Created by emilyemorehouse on 08/07/2017.
//  Copyright (c) 2017 emilyemorehouse. All rights reserved.
//

import UIKit
import BrytescoreAPI

class ViewController: UIViewController {
    // ------------------------------------ MARK: Properties ------------------------------------ //
    @IBOutlet weak var apiKeyLabel: UILabel!
    @IBOutlet weak var toggleDevModeButton: UIButton!
    @IBOutlet weak var toggleDebugModeButton: UIButton!

    // ------------------------------------- MARK: Variables ------------------------------------ //
    // Initialize the API Manager with your API key.
    let _apiManager = BrytescoreAPIManager(apiKey: "107e322f-3410-4d5b-8f43-d2bad8141771")

    // Bools for local status of dev and debug mode, used to toggle state with buttons
    var devMode = true
    var debugMode = true

    // Button helpers - API Key label and button colors
    let defaultAPIKeyLabel = "Your API Key:"
    let blue = UIColor(red:0.15, green:0.66, blue:0.88, alpha:0.8)
    let green = UIColor(red:0.46, green:0.71, blue:0.24, alpha:0.8)
    let orange = UIColor(red:0.87, green:0.53, blue:0.20, alpha:0.8)

    // -------------------------------------- MARK: Methods ------------------------------------- //
    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable dev mode - logs API calls instead of making HTTP request
        _apiManager.devMode(enabled: devMode)
        toggleDevModeButton.setTitle("Toggle Dev Mode: Turn \(devMode ? "Off": "On")", for: .normal)
        toggleDevModeButton.backgroundColor = devMode ? orange : green

        // Enable debug mode - turns on console logs
        _apiManager.debugMode(enabled: debugMode)
        toggleDebugModeButton.setTitle("Toggle Debug Mode: Turn \(debugMode ? "Off": "On")", for: .normal)
        toggleDebugModeButton.backgroundColor = debugMode ? orange : green

        // Update the API Key label to show our API key for debugging
        apiKeyLabel.text = "\(defaultAPIKeyLabel) \(_apiManager.getAPIKey())"
    }

    // -------------------------------------- MARK: Actions ------------------------------------- //
    /**
     - parameter sender: UIButton
     */
    @IBAction func trackPageView(_ sender: UIButton) {
        _apiManager.pageView(data: [:])
    }

    /**
     - parameter sender: UIButton
     */
    @IBAction func trackRegisteredAccount(_ sender: UIButton) {
        let registrationData = [
            "isLead": false,
            "userAccount": [
                "id": 2
            ]
        ] as [String : AnyObject]
        _apiManager.registeredAccount(data: registrationData)
    }


    /**
     Toggle devMode bool, pass to _apiManager, update button title and color

     - parameter sender: UIButton
     */
    @IBAction func toggleDevMode(_ sender: UIButton) {
        devMode = !devMode
        _apiManager.devMode(enabled: devMode)
        sender.setTitle("Toggle Dev Mode: Turn \(devMode ? "Off": "On")", for: .normal)
        sender.backgroundColor = devMode ? orange : green

        // If devMode is now on, debugMode is also. Only update if debugMode wasn't already on.
        if (devMode && !debugMode) {
            toggleDebugModeButton.setTitle("Toggle Debug Mode: Turn Off", for: .normal)
            toggleDebugModeButton.backgroundColor = orange
        }
    }


    /**
     Toggle debugMode bool, pass to _apiManager, update button title and color

     - parameter sender: UIButton
     */
    @IBAction func toggleDebugMode(_ sender: UIButton) {
        debugMode = !debugMode
        _apiManager.debugMode(enabled: debugMode)
        sender.setTitle("Toggle Debug Mode: Turn \(debugMode ? "Off": "On")", for: .normal)
        sender.backgroundColor = debugMode ? orange : green
    }

}
