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
    @IBOutlet weak var toggleImpersonationModeButton: UIButton!
    @IBOutlet weak var toggleValidationModeButton: UIButton!

    // ------------------------------------- MARK: Variables ------------------------------------ //
    // Initialize the API Manager with your API key.
    let _apiManager = BrytescoreAPIManager(apiKey: "107e322f-3410-4d5b-8f43-d2bad8141771")

    // Bools for local status of dev and debug mode, used to toggle state with buttons
    var devMode = true
    var debugMode = true
    var impersonationMode = false
    var validationMode = false

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

        // Set button colors for unused modes
        toggleImpersonationModeButton.backgroundColor = impersonationMode ? orange : green
        toggleValidationModeButton.backgroundColor = validationMode ? orange : green

        // Update the API Key label to show our API key for debugging
        apiKeyLabel.text = "\(defaultAPIKeyLabel) \(_apiManager.getAPIKey())"

        let notificationCenter = NotificationCenter.default
        // Background listener
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        // Foreground listener
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    func appMovedToBackground() {
        _apiManager.killSession()
    }

    func appMovedToForeground() {
        _apiManager.pageView(data: [:])
    }


    // -------------------------------------- MARK: Actions ------------------------------------- //
    /**
     Example usage of tracking a page view
     - parameter sender: UIButton
     */
    @IBAction func trackPageView(_ sender: UIButton) {
        _apiManager.pageView(data: [:])
    }

    /**
     Example usage of tracking an account registration
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
     Example usage of tracking authentication
     - parameter sender: UIButton
     */
    @IBAction func trackAuthenticated(_ sender: UIButton) {
        let authenticatedData = [
            "userAccount": [
                "id": 2
            ]
        ] as [String : AnyObject]
        _apiManager.authenticated(data: authenticatedData)

    }

    /**
     Example usage of tracking a submitted form
     - parameter sender: UIButton
     */
    @IBAction func trackSubmittedForm(_ sender: UIButton) {
        let submittedFormData = [
            "userAccount": [
                "id": 2
            ]
            ] as [String : AnyObject]
        _apiManager.submittedForm(data: submittedFormData)
    }

    /**
     Example usage of tracking the start of a chat
     - parameter sender: UIButton
     */
    @IBAction func trackStartedChat(_ sender: UIButton) {
        let startedChatData = [
            "userAccount": [
                "id": 2
            ]
            ] as [String : AnyObject]
        _apiManager.startedChat(data: startedChatData)
    }

    /**
     Example usage of tracking the when a user updates their information
     - parameter sender: UIButton
     */
    @IBAction func trackUpdatedUserInfo(_ sender: UIButton) {
        let updatedUserInfoData = [
            "userAccount": [
                "id": 2
            ]
            ] as [String : AnyObject]
        _apiManager.updatedUserInfo(data: updatedUserInfoData)
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

        // If devMode is now on and debugMode was off, debugMode is now on.
        // Only update if debugMode wasn't already on.
        if (devMode && !debugMode) {
            debugMode = true
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

    /**
     Toggle impersonationMode bool, pass to _apiManager, update button title and color

     - parameter sender: UIButton
     */
    @IBAction func toggleImpersonationMode(_ sender: UIButton) {
        impersonationMode = !impersonationMode
        _apiManager.impersonationMode(enabled: impersonationMode)
        sender.setTitle("Toggle Impersonation Mode: Turn \(impersonationMode ? "Off": "On")", for: .normal)
        sender.backgroundColor = impersonationMode ? orange : green
    }

    /**
     Toggle validationMode bool, pass to _apiManager, update button title and color

     - parameter sender: UIButton
     */
    @IBAction func toggleValidationMode(_ sender: UIButton) {
        validationMode = !validationMode
        _apiManager.validationMode(enabled: validationMode)
        sender.setTitle("Toggle Validation Mode: Turn \(validationMode ? "Off": "On")", for: .normal)
        sender.backgroundColor = validationMode ? orange : green
    }
}
