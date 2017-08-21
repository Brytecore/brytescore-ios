//
//  BrytescoreAPIManager.swift
//  Pods
//
//  Created by Emily Morehouse on 8/7/17.
//
//

public class BrytescoreAPIManager {
    // --------------------------------- MARK: static variables --------------------------------- //
    private let _url = "https://api.brytecore.com"
    private let pageViewEventName = "pageView"
    private let hostname = "com.brytecore.mobile"
    private let library = "iOS"
    private let libraryVersion = "0.0.0"
    private let schemaVersion = ["analytics": "0.3.1"]


    // --------------------------------- MARK: dynamic variables -------------------------------- //
    private var _apiKey = String()
    private var userId : Int?  = nil
    private var anonymousId : String? = nil
    private var sessionId : String? = nil
    private var devMode = false
    private var debugMode = false


    // ---------------------------------- MARK: public methods: --------------------------------- //
    /**
     Sets the API key.

     - parameter apiKey: The API key.
     */
    public init(apiKey: String) {
        _apiKey = apiKey
        sessionId = self.generateUUID()
    }

    /**
     Returns the current API key

     - returns: The current API key
     */
    public func getAPIKey() -> String {
        return _apiKey
    }

    /**
     Sets dev mode.
     Logs events to the console instead of sending to the API.
     Turning on dev mode automatically triggers debug mode.

     - parameter enabled: If true, then dev mode is enabled.
     */
    public func devMode(enabled: Bool) {
        devMode = enabled

        // If devMode is turned on, debugMode should be too.
        if (devMode) {
            self.debugMode(enabled: true)
        }
    }

    /**
     Sets debug mode.
     Log events are suppressed when debug mode is off.

     - parameter enabled: If true, then debug mode is enabled.
     */
    public func debugMode(enabled: Bool) {
        debugMode = enabled
    }

    /**
     Start a pageView.

     - parameter data: The pageView data.
     - data.isImpersonating:
     - data.pageUrl:
     - data.pageTitle:
     - data.referrer:
     */
    public func pageView(data: Dictionary<String, Any>) {
        print("Calling pageView: \(data)")
        self.track(eventName: pageViewEventName, eventDisplayName: "Viewed a Page", data: data)
    }

    /**
     Sends a new account registration event.

     - parameter data: The registration data.
     - data.isImpersonating
     - data.userAccount.id
     */
     public func registeredAccount(data: Dictionary<String, AnyObject>) {
        print("Calling registeredAccount: \(data)")

        // TODO handle impersonating
        // If the user is being impersonated, do not track.

        // Ensure that we have a user ID from data.userAccount.id
        guard let userAccount = data["userAccount"] else {
            print("data.userAccount is not defined")
            return
        }
        guard let localUserID: Int = userAccount["id"] as? Int else {
            print("data.userAccount.id is not defined")
            return
        }

        // If we haven't saved the user ID globally, or the user IDs do not match
        if (userId == nil || localUserID != userId) {
            // Retrieve anonymous user ID from brytescore_uu_aid, or generate a new anonymous user ID
            if (UserDefaults.standard.object(forKey: "brytescore_uu_aid") != nil) {
                anonymousId = UserDefaults.standard.object(forKey: "brytescore_uu_aid") as! String
                print("Retrieved anonymous user ID: \(anonymousId)")
            } else {
                print("No user ID has been saved. Generating...")
                anonymousId = self.generateUUID()
                print("Generated new anonymous user ID: \(anonymousId)")
            }

            // Save our new user ID to our global userId
            userId = localUserID

            // Save our anonymous id and user id to local storage.
            UserDefaults.standard.set(anonymousId, forKey: "brytescore_uu_aid")
            UserDefaults.standard.set(userId, forKey: "brytescore_uu_uid")
        }

        // Finally, in any case, track the account registration
        self.track(eventName: "registeredAccount", eventDisplayName: "Created a new account", data: data)
    }


    // ---------------------------------- MARK: private methods --------------------------------- //
    /**
     Main track function

     - parameter eventName: The event name.
     - parameter eventDisplayName: The event display name.
     - parameter data: The event data.
     */
    private func track(eventName: String, eventDisplayName: String, data: Dictionary<String, Any>) {
        print("Calling track: \(eventName) \(eventDisplayName) \(data)")
        self.sendRequest(path: "track", eventName: eventName, eventDisplayName: eventDisplayName, data: data)
    }

    /**
     Helper Function for making CORS calls to the API.

     - parameter path: path for the API URL
     - parameter eventName: name of the event being tracked
     - parameter eventDisplayName: display name of the event being tracked
     - parameter data: metadate of the event being tracked
     */
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

        /**
         Generate the object to send to the API

         - "event"              - param     - eventName
         - "eventDisplayName"   - param     - eventDisplayName
         - "hostName" - static  - static    - custom iOS hostname
         - "apiKey"             - static    - user's API key
         - "anonymousId"        - generated - Brytescore UID
         - "userId"             - retrieved - Client user id, may be null if unauthenticated
         - "pageViewId"         - generated - Brytescore UID            // TODO: Q: difference btwn pageViewId/anonymousId?
         - "sessionId"          - generated - Brytescore session id
         - "library"            - static    - library type
         - "libraryVersion"     - static    - library version
         - "schemaVersion"      - generated - if eventName contains '.', use a custom schemaVersion based on the eventName. otherwise, use schemaVersion.analytics
         - "data"               - param     - data
         */
        let eventData = [
            "event": eventName,
            "eventDisplayName": eventDisplayName,
            "hostName": hostname,
            "apiKey": _apiKey,
            "anonymousId": anonymousId,
            "userId": userId,
            "pageViewId": "anon123",    // TODO: pageViewId
            "sessionId": sessionId,
            "library": library,
            "libraryVersion": libraryVersion,
            "schemaVersion": schemaVersion["analytics"]!, // TODO: Q: i don't think this is a thing. check for '.' (see docstring above)
            "data": data
        ] as [String : Any]

        // Set up the request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: eventData, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }

        // Set up the session
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // Execute the request
        dump(eventData, name: "eventData")
        if (devMode != true) {
            let task = session.dataTask(with: request) {
                (data, response, error) in

                // Check for any explicit errors
                guard error == nil else {
                    self.print("An error occurred while calling:", requestEndpoint, error as Any)
                    return
                }

                // Retrieve the HTTP response status code, check that it exists
                let httpResponse = response as? HTTPURLResponse
                guard let st = httpResponse?.statusCode else{
                    return
                }

                // Check that the response was not a 404 or 500 TODO should handle errors more gracefully
                guard st != 404 && st != 500 else {
                    self.print("An error occurred while calling:", requestEndpoint, st)
                    return
                }

                // Check that data was received from the API
                guard let responseData = data else {
                    self.print("An error occurred: did not receive data")
                    return
                }

                // Parse the API response data
                do {
                    guard let responseJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                        self.print("error trying to convert data to JSON")
                        return
                    }
                    self.print("Call successful, response: \(responseJSON)")
                } catch  {
                    self.print("An error occured while trying to convert data to JSON")
                    return
                }
            }

            task.resume()
        }
    }

    /**
     Generate RFC4112 version 4 compliant UUID using Swift's built-in generator

     - link: https://developer.apple.com/documentation/foundation/uuid
     - returns: a new UUID string
     */
    private func generateUUID() -> String {
        return(UUID().uuidString)
    }

    /**
     Override Swift's print function to only print while in debugMode
     */
    func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if (debugMode == true) {
            Swift.print(items[0], separator:separator, terminator: terminator)
        }
    }

    /**
     Override Swift's dump function to only print while in debugMode
     */
    func dump(_ item: Any..., name: String) {
        if (debugMode == true) {
            Swift.dump(item, name: name)
        }
    }
}
