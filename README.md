# SwiftWeiboKit

SwiftWeiboKit is An delightful Sina Weibo library written in Swift

## Getting started

Drag SwiftWeiboKit.swift to your project

```swift
let client = SWKClient(clientID:"YOUR_ID", clientSecret:"YOUR_SECRET", redirectURI:"YOUR_REDIRECT_URI")
    client.presentAuthorizeView(fromViewController: self){
    authResult in
    if authResult{
        client.get("https://api.weibo.com/2/statuses/user_timeline.json"){
        response in
            switch response{
            case .success(let successResp):
                println(successResp.json)
            case .failure(let failureResp):
                println(failureResp)
            }
        }
    }
}
```

