//
//  BrytescoreAPIManager.swift
//  Pods
//
//  Created by Emily Morehouse on 8/7/17.
//
//

public class BrytescoreAPIManager {
    // --------------------------------- MARK: static variables --------------------------------- //
    private var _apiKey = String()
    private var _url = "https://api.brytecore.com"
    private var pageViewEventName = "pageView"
    private var hostname = "com.brytecore.mobile"
    private var library = "iOS"
    private var libraryVersion = "0.0.0"
    private var schemaVersion = ["analytics": "0.3.1"]
    private var devMode = false


    // --------------------------------- MARK: public functions: -------------------------------- //
    /**
     * Sets the API key.
     *
     * @param {string} apiKey The API key.
     */
    public init(apiKey: String) {
        _apiKey = apiKey
    }

    /**
     * Returns the current API key
     */
    public func getAPIKey() -> String {
        return _apiKey
    }

    /**
     * Sets dev mode.
     * Logs events to the console instead of sending to the API.
     *
     * @param {boolean} enabled If true, then dev mode is enabled.
     */
    public func devMode(enabled: Bool) {
        devMode = enabled
    }

    /**
     * Start a pageView.
     *
     * @param {object} data The pageView data.
     * @param {boolean} data.isImpersonating
     * @param {string} data.pageUrl
     * @param {string} data.pageTitle
     * @param {string} data.referrer
     */
    public func pageView(data: Dictionary<String, Any>) {
        print("Calling pageView: \(data)")
        self.track(eventName: pageViewEventName, eventDisplayName: "Viewed a Page", data: data)
    }


    // --------------------------------- MARK: private functions -------------------------------- //
    /**
     * Main track function
     *
     * @param {string} eventName The event name.
     * @param {string} eventDisplayName The event display name.
     * @param {object} data The event data.
     * @param {boolean} data.isImpersonating
     */
    private func track(eventName: String, eventDisplayName: String, data: Dictionary<String, Any>) {
        print("Calling track: \(eventName) \(eventDisplayName) \(data)")
        self.sendRequest(path: "track", eventName: eventName, eventDisplayName: eventDisplayName, data: data)
    }

    private func sendRequest(path: String, eventName: String, eventDisplayName: String, data: Dictionary<String, Any> ) {
        // Generate the request endpoint
        let requestEndpoint: String = _url + "/" + path
        guard let url = URL(string: requestEndpoint) else {
            print("Error: cannot create URL")
            return
        }

        // Set up the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Generate the object to send to the API
        // "event"              - param     - eventName
        // "eventDisplayName"   - param     - eventDisplayName
        // "hostName" - static  - static    - custom iOS hostname
        // "apiKey"             - static    - user's API key
        // "anonymousId"        - generated - Brytescore UID
        // "userId"             - retrieved - Client user id, may be null if unauthenticated
        // "pageViewId"         - generated - Brytescore UID            // TODO: Q: difference btwn pageViewId/anonymousId?
        // "sessionId"          - generated - Brytescore session id     // TODO: Q: difference btwn sessionId/pageViewId/anonymousId?
        // "library"            - static    - library type
        // "libraryVersion"     - static    - library version
        // "schemaVersion"      - generated - if eventName contains '.', use a custom schemaVersion based on the eventName. otherwise, use schemaVersion.analytics
        // "data"               - param     - data
        let eventData = [
            "event": eventName,
            "eventDisplayName": eventDisplayName,
            "hostName": hostname,
            "apiKey": _apiKey,
            "anonymousId": "anon123",   // TODO: anonymousId
            "userId": 1,                // TODO: userId
            "pageViewId": "anon123",    // TODO: pageViewId
            "sessionId": "anon123",     // TODO: sessionId
            "library": library,
            "libraryVersion": libraryVersion,
            "schemaVersion": schemaVersion["analytics"]!, // TODO: Q: i don't think this is a thing. check for '.' (see docstring above)
            "data": data
        ] as [String : Any]

        print(eventData)

        // Set up the request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: eventData, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }

        // Set up the session
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // Execute the request
        if (devMode == true) {
            print("Dev mode enabled: \(eventData)")
        } else {
            let task = session.dataTask(with: request) {
                (data, response, error) in


                // Check for any explicit errors
                guard error == nil else {
                    print("An error occurred while calling:", requestEndpoint, error as Any)
                    return
                }

                // Retrieve the HTTP response status code, check that it exists
                let httpResponse = response as? HTTPURLResponse
                guard let st = httpResponse?.statusCode else{
                    return
                }

                // Check that the response was not a 404 or 500 TODO should handle errors more gracefully
                guard st != 404 && st != 500 else {
                    print("An error occurred while calling:", requestEndpoint, st)
                    return
                }

                // Check that data was received from the API
                guard let responseData = data else {
                    print("An error occurred: did not receive data")
                    return
                }

                // Parse the API response data
                do {
                    guard let responseJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                        print("error trying to convert data to JSON")
                        return
                    }
                    print("Call successful, response: \(responseJSON)")
                } catch  {
                    print("An error occured while trying to convert data to JSON")
                    return
                }
            }

            task.resume()
        }
    }

}
