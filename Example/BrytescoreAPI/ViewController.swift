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
    //MARK: Properties
    @IBOutlet weak var apiKeyLabel: UILabel!

    // Initialize the API Manager with your API key.
    let _apiManager = BrytescoreAPIManager(apiKey: "107e322f-3410-4d5b-8f43-d2bad8141771")
    let defaultAPIKeyLabel = "Your API Key:"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update the API Key label to show our API key for debugging
        apiKeyLabel.text = "\(defaultAPIKeyLabel) \(_apiManager.getAPIKey())"
    }

    //MARK: Actions
    @IBAction func trackPageView(_ sender: UIButton) {
        _apiManager.pageView(data: [:])
    }
}
