//
//  BrytescoreAPIManager.swift
//  Pods
//
//  Created by Emily Morehouse on 8/7/17.
//
//
import Foundation

@objc
public class BrytescoreAPIManager: NSObject {
    // --------------------------------- MARK: static variables --------------------------------- //
    // Variables used to fill event data for tracking
    private let _url = "https://api.brytecore.com/"
    private let _packageUrl = "https://cdn.brytecore.com/packages/"
    private let _packageName = "/package.json"
    private let hostname = "com.brytecore.mobile"
    private let library = "iOS"
    private let libraryVersion = "0.0.0"

    private let eventNames = [
        "authenticated": "authenticated",
        "brytescoreUUIDCreated": "brytescoreUUIDCreated",
        "heartBeat": "heartBeat",
        "pageView": "pageView",
        "registeredAccount": "registeredAccount",
        "sessionStarted": "sessionStarted",
        "startedChat": "startedChat",
        "submittedForm": "submittedForm",
        "updatedUserInfo": "updatedUserInfo"
    ]

    // --------------------------------- MARK: dynamic variables -------------------------------- //
    private var _apiKey : String

    // Variables to hold package-wide IDs
    private var userId : String?  = nil
    private var anonymousId : String? = nil
    private var sessionId : String? = nil
    private var pageViewId : String? = nil

    // Variables used to fill event data for tracking
    // When additional packages are loaded, they are added to this dictionary
    private var schemaVersion : Dictionary<String, String>  = ["analytics": "0.3.1"]

    // Dynamically loaded packages
    private var packageFunctions : Dictionary<String, AnyObject> = [:]

    // Inactivity timers
    private var inactivityId : Int = 0

    // Variables for heartbeat timer
    private var heartbeatTimer = Timer()
    private var isHearbeatTimerRunning = false
    private var hearbeatLength : TimeInterval = 15 // in seconds
    private var startHeartbeatTime = Date(timeIntervalSinceNow: 9999999)
    private var totalPageViewTime : TimeInterval = 0

    // Variables for mode statuses
    private var devMode = false
    private var debugMode = false
    private var impersonationMode = false
    private var validationMode = false

    // ---------------------------------- MARK: public methods: --------------------------------- //
    /**
     Sets the API key.
     Generates a new unique session ID.
     Retrieves the saved user ID, if any.

     - parameter apiKey: The API key.
     */
    @objc
    public init(apiKey: String) {
        _apiKey = apiKey
        super.init()
        
        // Generate and save unique session ID
        sessionId = self.generateUUID()
        UserDefaults.standard.set(sessionId, forKey: "brytescore_session_sid")

        // Retrieve user ID from brytescore_uu_uid and update it in case its retrieved as Int
        userId = String(describing: UserDefaults.standard.object(forKey: "brytescore_uu_uid")!)
        UserDefaults.standard.set(userId, forKey: "brytescore_uu_uid")
        
        // Check if we have an existing aid, otherwise generate
        if (UserDefaults.standard.object(forKey: "brytescore_uu_aid") != nil) {
            anonymousId = UserDefaults.standard.object(forKey: "brytescore_uu_aid") as? String
            print("Retrieved anonymous user ID: \(anonymousId!)")
        } else {
            anonymousId = generateUUID()
            print("Generated anonymous user ID: \(anonymousId!)")
        }
        
        UserDefaults.standard.set(anonymousId, forKey: "brytescore_uu_aid")
    }

    /**
     Returns the current API key

     - returns: The current API key
     */
    @objc
    public func getAPIKey() -> String {
        return _apiKey
    }

    /**
     * Function to load json packages.
     *
     * @param {string} The name of the package.
     */
    @objc
    public func load(package: String) {
        print("Calling load: \(package)")
        print("Loading \(_packageUrl)\(package)\(_packageName)...")

        // Generate the request endpoint
        let requestEndpoint: String = _packageUrl + package + _packageName
        guard let url = URL(string: requestEndpoint) else {
            print("Error: cannot create URL")
            return
        }

         // Set up the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Set up the session
        let session = URLSession(configuration: URLSessionConfiguration.default)

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

            // Check that the response was not a 404 or 500
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

                // Get just the events object of the package
                self.packageFunctions[package] = responseJSON["events"];

                // Get the namespace of the package
                let namespace = responseJSON["namespace"] as! String;
                self.schemaVersion[namespace] = responseJSON["version"] as? String;

            } catch  {
                self.print("An error occured while trying to convert data to JSON")
                return
            }
        }

        task.resume()
    }

    /**
     Sets dev mode.
     Logs events to the console instead of sending to the API.
     Turning on dev mode automatically triggers debug mode.

     - parameter enabled: If true, then dev mode is enabled.
     */
    @objc
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
    @objc
    public func debugMode(enabled: Bool) {
        debugMode = enabled
    }

    /**
     Sets impersonation mode.
     Bypasses sending information to the API when impersonating another user.

     - parameter enabled: If true, then impersonation mode is enabled.
     */
    @objc
    public func impersonationMode(enabled: Bool) {
        impersonationMode = enabled
    }

    /**
     Sets validation mode.
     Adds a validation attribute to the data for all API calls.

     - parameter enabled: If true, then validation mode is enabled.
     */
    @objc
    public func validationMode(enabled: Bool) {
        validationMode = enabled
    }

    /**
     *
     */
    @objc
    public func brytescore(property: String, data: Dictionary<String, Any>) {
        print("Calling brytescore: \(property)")

        // Ensure that a property is provided
        guard (property.count != 0) else {
            print("Abandon ship! You must provide a tracking property.")
            return
        }

        // Retrieve the namespace and function name, from property of format 'namespace.functionName'
        let splitPackage = property.components(separatedBy: ".");
        guard splitPackage.count == 2 else {
            print("Invalid tracking property name received. Should be of the form: 'namespace.functionName'");
            return
        }
        let namespace = splitPackage[0]
        let functionName = splitPackage[1]

        // Retrieve the function details from the loaded package, ensuring that it exists
        guard let functionDetails = packageFunctions[namespace]![functionName] as? Dictionary<String, String> else {
            print("The \(namespace) package is not loaded, or \(functionName) is not a valid function name.");
            return
        }
        guard let eventDisplayName = functionDetails["displayName"] else {
            print("The function display name could not be loaded.");
            return
        }

        // Track the validated listing.
        self.track(eventName: property, eventDisplayName: eventDisplayName, data: data)
    }

    /**
     Start a pageView.

     - parameter data: The pageView data.
     - data.isImpersonating:
     - data.pageUrl:
     - data.pageTitle:
     - data.referrer:
     */
    @objc
    public func pageView(data: Dictionary<String, Any>) {
        print("Calling pageView: \(data)")

        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return
        }

        totalPageViewTime = 0
        pageViewId = self.generateUUID()

        self.track(eventName: eventNames["pageView"]!, eventDisplayName: "Viewed a Page", data: data)

        // Save session information
        UserDefaults.standard.set(sessionId, forKey: "brytescore_session_sid")
        UserDefaults.standard.set(anonymousId, forKey: "brytescore_session_aid")

        // Send the first heartbeat and start the timer
        print("Sending 'first' heartbeat'");
        self.heartBeat();
        heartbeatTimer = Timer.scheduledTimer(timeInterval: hearbeatLength, target: self, selector: #selector(self.checkHeartbeat), userInfo: nil, repeats: true)
    }

    /**
     Sends a new account registration event.

     - parameter data: The registration data.
     - data.isImpersonating
     - data.userAccount.id
     */
    @objc
    public func registeredAccount(data: Dictionary<String, AnyObject>) {
        print("Calling registeredAccount: \(data)")
        let userStatus = self.updateUser(data: data)

        // Finally, as long as the data was valid, track the account registration
        if (userStatus == true) {
            self.track(eventName: eventNames["registeredAccount"]!, eventDisplayName: "Created a new account", data: data)
        }
    }

    /**
     Sends a submittedForm event.

     - parameter data: The chat data.
     - data.isImpersonating
     */
    @objc
    public func submittedForm( data: Dictionary<String, AnyObject>) {
        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return
        }

        self.track(eventName: eventNames["submittedForm"]!, eventDisplayName: "'Submitted a Form", data: data)
    };

    /**
     Sends a startedChat event.

     - parameter data: The form data.
     - data.isImpersonating
     */
    @objc
    public func startedChat( data: Dictionary<String, AnyObject>) {
        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return
        }

        self.track(eventName: eventNames["startedChat"]!, eventDisplayName: "User Started a Live Chat", data: data)
    };

    /**
     * Updates a user's account information.
     *
     * @param {object} data The account data.
     */
    @objc
    public func updatedUserInfo(data: Dictionary<String, AnyObject>) {
        print("updatedUserInfo: \(data)")
        let userStatus = self.updateUser(data: data)

        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return
        }

        // Finally, as long as the data was valid, track the user info update
        if (userStatus == true) {
            self.track(eventName: eventNames["updatedUserInfo"]!, eventDisplayName: "Updated User Information", data: data)
        }
    }

    /**
     Sends a user authentication event.

     - parameter data: The authentication data.
     - data.isImpersonating
     - data.userAccount
     - data.userAccount.id
     */
    @objc
    public func authenticated(data: Dictionary<String, AnyObject>) {
        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return
        }

        // Ensure that we have a user ID from data.userAccount.id
        guard let userAccount = data["userAccount"] as? Dictionary<String, AnyObject> else {
            print("data.userAccount is not defined")
            return
        }
        guard let newUserId: String = userAccount["id"] as? String else {
            print("data.userAccount.id is not defined")
            return
        }

        // Check if we have an existing aid, otherwise generate
        if (UserDefaults.standard.object(forKey: "brytescore_uu_aid") != nil) {
            anonymousId = UserDefaults.standard.object(forKey: "brytescore_uu_aid") as? String
            print("Retrieved anonymous user ID: \(anonymousId!)")
        } else {
            anonymousId = generateUUID()
        }

        // Retrieve user ID from brytescore_uu_uid
        var storedUserID : String? = nil
        if (UserDefaults.standard.object(forKey: "brytescore_uu_uid") != nil) {
            storedUserID = UserDefaults.standard.object(forKey: "brytescore_uu_uid") as? String
            print("Retrieved user ID: \(storedUserID!)")
        }

        // If there is a UID stored locally and the localUID does not match our new UID
        if (storedUserID != nil && storedUserID != newUserId) {
            self.changeLoggedInUser(userID: newUserId);  // Saves our new user ID to our global userId
        }

        // Save our anonymous id and user id to local storage.
        UserDefaults.standard.set(anonymousId, forKey: "brytescore_uu_aid")
        UserDefaults.standard.set(userId, forKey: "brytescore_uu_uid")

        // Finally, in any case, track the authentication
        self.track(eventName: eventNames["authenticated"]!, eventDisplayName: "Logged in", data: data)
    }

    /**
     * Kills the session.
     */
    @objc
    public func killSession() {
        print("Calling killSession")

        // Stop the timer
        heartbeatTimer.invalidate()

        // Reset the heartbeat start time
        startHeartbeatTime = Date(timeIntervalSinceNow: 9999999)

        // Delete and save session id
        sessionId = nil
        UserDefaults.standard.set(sessionId, forKey: "brytescore_session_sid")

        // sessionTimeout = true;
        // Reset pageViewIDs
        pageViewId = nil;
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

        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return
        }

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
        print("Calling sendRequest: path \(path) eventName \(eventName) eventDisplayName \(eventDisplayName)")

        // Generate the request endpoint
        let requestEndpoint: String = _url + path
        guard let url = URL(string: requestEndpoint) else {
            print("Error: cannot create URL")
            return
        }

        guard (_apiKey.count != 0) else {
            print("Abandon ship! You must provide an API key.")
            return
        }

        // Set up the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Deduce the schema version (namespace)
        // Check if the property is of the format 'namespace.functionName'
        // If so, replace the namespace
        var namespace : String = "analytics"
        let splitPackage = path.components(separatedBy: ".");
        if splitPackage.count == 2 {
            namespace = splitPackage[0]
        }

        // Check if sessionId is set, if nil, generate a new one
        if (sessionId == nil) {
            // Generate new sessionId
            sessionId = self.generateUUID()
            UserDefaults.standard.set(sessionId, forKey: "brytescore_session_sid")
        }

        /**
         Generate the object to send to the API

         - "event"              - param     - eventName
         - "eventDisplayName"   - param     - eventDisplayName
         - "hostName" - static  - static    - custom iOS hostname
         - "apiKey"             - static    - user's API key
         - "anonymousId"        - generated - Brytescore UID
         - "userId"             - retrieved - Client user id, may be null if unauthenticated
         - "pageViewId"         - generated - Brytescore UID
         - "sessionId"          - generated - Brytescore session id
         - "library"            - static    - library type
         - "libraryVersion"     - static    - library version
         - "schemaVersion"      - generated - if eventName contains '.', use a custom schemaVersion based on the eventName. otherwise, use schemaVersion.analytics
         - "data"               - param     - data
         */
        var eventData = [
            "event": eventName,
            "eventDisplayName": eventDisplayName,
            "hostName": hostname,
            "apiKey": _apiKey,
            "anonymousId": anonymousId ?? "",
            "userId": userId ?? "",
            "pageViewId": self.generateUUID(),
            "sessionId": sessionId ?? "",
            "library": library,
            "libraryVersion": libraryVersion,
            "schemaVersion": schemaVersion[namespace]!,
            "data": data
        ] as [String : Any]

        // Handle validation mode, if activated
        if (validationMode == true) {
            eventData["validationOnly"] = validationMode
        }

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

                // Check that the response was not a 404 or 500
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
     Process a change in the logged in user:
     - Kill current session for old user
     - Update and save the global user ID variable
     - Generate and save new anonymousId
     - Generate new sessionId

     - parameter userID: The user ID.
     */
    private func changeLoggedInUser(userID: String) {
        // Kill current session for old user
        self.killSession()

        // Update and save the global user ID variable
        userId = userID
        UserDefaults.standard.set(userId, forKey: "brytescore_uu_uid")

        // Generate and save new anonymousId
        anonymousId = self.generateUUID()
        UserDefaults.standard.set(anonymousId, forKey: "brytescore_uu_aid")
        self.track(eventName: eventNames["brytescoreUUIDCreated"]!, eventDisplayName: "New user id Created", data: ["anonymousId": anonymousId!])

        // Generate new sessionId
        sessionId = self.generateUUID()

        self.track(eventName: eventNames["sessionStarted"]!, eventDisplayName: "started new session", data: [
            "sessionId": sessionId!,
            // "browserUA": browserUA,
            "anonymousId": anonymousId!
        ]);

        // Page view will update session cookie no need to write one.
        self.pageView( data: [:] );
    }

    /**
     * Sends a heartbeat event
     */
    private func heartBeat() {
        print("Calling heartBeat")

        totalPageViewTime = totalPageViewTime + hearbeatLength
        self.track(eventName: eventNames["heartBeat"]!, eventDisplayName: "Heartbeat", data: ["elapsedTime": totalPageViewTime])
    }

    /**
     - Ensure that the user is not being impersonated
     - Ensure that we have a user ID in the data parameter
     - Update the global `userId` if it is not accurate
     */
    private func updateUser(data: Dictionary<String, Any>) -> Bool {

        // If the user is being impersonated, do not track.
        guard checkImpersonation(data: data) else {
            return false
        }

        // Ensure that we have a user ID from data.userAccount.id
        guard let userAccount = data["userAccount"] as? Dictionary<String, AnyObject> else {
            print("data.userAccount is not defined")
            return false
        }
        guard let localUserID: String = userAccount["id"] as! String? else {
            print("data.userAccount.id is not defined")
            return false
        }

        // If we haven't saved the user ID globally, or the user IDs do not match
        if (userId == nil || localUserID != userId) {
            // Retrieve anonymous user ID from brytescore_uu_aid, or generate a new anonymous user ID
            if (UserDefaults.standard.object(forKey: "brytescore_uu_aid") != nil) {
                anonymousId = UserDefaults.standard.object(forKey: "brytescore_uu_aid") as? String
                print("Retrieved anonymous user ID: \(anonymousId!)")
            } else {
                print("No anonymous ID has been saved. Generating...")
                anonymousId = self.generateUUID()
                print("Generated new anonymous user ID: \(anonymousId!)")
                self.track(eventName: eventNames["brytescoreUUIDCreated"]!, eventDisplayName: "New user id Created", data: ["anonymousId": anonymousId!])
            }

            // Save our new user ID to our global userId
            userId = localUserID

            // Save our anonymous id and user id to local storage.
            UserDefaults.standard.set(anonymousId, forKey: "brytescore_uu_aid")
            UserDefaults.standard.set(userId, forKey: "brytescore_uu_uid")
        }
        return true
    }

    /**
     *
     */
    private func checkImpersonation(data: Dictionary<String, Any>) -> Bool {
        if (impersonationMode == true || data["impersonationMode"] != nil) {
            print("Impersonation mode is on - will not track event");
            return false
        }
        return true
    }

    /**
     *
     */
    @objc func checkHeartbeat() {
        print("Calling checkHeartbeat");

        let elapsed = Date().timeIntervalSince(startHeartbeatTime)

        // Heartbeat is not dead yet.
        if (elapsed < 1800) {
            print("Heartbeat is not dead yet.")
            startHeartbeatTime = Date()
            self.heartBeat()
        // Heartbeat is dead
        } else {
            print("Heartbeat is dead.")
            self.killSession()
        }
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
            _ = Swift.dump(item, name: name)
        }
    }
}
