//
//  BrytescoreAPIManager.swift
//  Pods
//
//  Created by Emily Morehouse on 8/7/17.
//
//

public class BrytescoreAPIManager {
    private var params = [String : String]()

    public init(apiKey: String) {
        params["APPID"] = apiKey
    }
}
