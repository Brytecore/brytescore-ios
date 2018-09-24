<img src="https://raw.githubusercontent.com/Brytecore/brytescore.js/master/examples/lead-booster-analytics.png" width="400" height="98" alt="Lead Booster Analytics">

# brytescore-ios

brytescore-ios is the open-source iOS SDK that connects your website with the Brytescore API. The
Brytescore API allows you to track your users' behavior and score their engagement.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

brytescore-ios is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Brytescore"
```

## Methods

### Initialization

Sets the API key.
Generates a new unique session ID.
Retrieves the saved user ID, if any.

- parameter {string} The API key.

```swift
    let _apiManager = BrytescoreAPIManager(apiKey: "<api-key>")
```

### getAPIKey

Returns the current API key

- returns: The current API key

```swift
    _apiManager.getAPIKey()
```

### load

Function to load json packages.

- parameter {string} The name of the package.

```swift
    _apiManager.load(package: "realestate")
```

### devMode

Sets dev mode.
Logs events to the console instead of sending to the API.
Turning on dev mode automatically triggers debug mode.

- parameter enabled: If true, then dev mode is enabled.

```swift
    _apiManager.devMode(enabled: devMode)
```

### debugMode

Sets debug mode.
Log events are suppressed when debug mode is off.

- parameter enabled: If true, then debug mode is enabled.

```swift
    _apiManager.debugMode(enabled: debugMode)
```

### impersonationMode

Sets impersonation mode.
Bypasses sending information to the API when impersonating another user.

- parameter enabled: If true, then impersonation mode is enabled.

```swift
    _apiManager.impersonationMode(enabled: impersonationMode)
```

### validationMode

Sets validation mode.
Adds a validation attribute to the data for all API calls.

- parameter enabled: If true, then validation mode is enabled.

```swift
    _apiManager.validationMode(enabled: validationMode)
```

### brytescore

Start tracking a property specific to a loaded package.

- parameter property: The property name
- parameter data: The property tracking data

```swift
    _apiManager.brytescore(property: propertyName, data: propertyData)
```

### pageView

Start a pageView.

- parameter data: The pageView data.
- data.isImpersonating
- data.pageUrl
- data.pageTitle
- data.referrer

```swift
    _apiManager.pageView(data: [:])
```

### registeredAccount

Sends a new account registration event.

- parameter data: The registration data.
- data.isImpersonating
- data.userAccount.id

```swift
    _apiManager.registeredAccount(data: registrationData)
```

### submittedForm

Sends a submittedForm event.

- parameter data: The chat data.
- data.isImpersonating

```swift
    _apiManager.submittedForm(data: submittedFormData)
```

### startedChat

Sends a startedChat event.

- parameter data: The form data.
- data.isImpersonating

```swift
    _apiManager.startedChat(data: startedChatData)
```

### updatedUserInfo

Updates a user's account information.

- parameter data: The account data.

```swift
    _apiManager.updatedUserInfo(data: updatedUserInfoData)
```

### authenticated

Sends a user authentication event.

- parameter data: The authentication data.
- data.isImpersonating
- data.userAccount
- data.userAccount.id

```swift
    _apiManager.authenticated(data: authenticatedData)
```

### killSession

Kills the session.

```swift
    _apiManager.killSession()
```
