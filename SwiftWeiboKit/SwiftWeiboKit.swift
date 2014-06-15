//
//  SinaWeiboAuthView.swift
//  testSwift
//
//  Created by Ruoyu Fu on 14-6-13.
//  Copyright (c) 2014年 Ruoyu Fu. All rights reserved.
//

import Foundation
import UIKit
import Social


class SWKClient{
/*
    SWKClient是SwiftWeiboKit的主要工具类
    它封装了整个OAuth2.0的授权流程,并提供了几个简便易用的请求方法：
    使用方法：
    
    1:构造Client，构造时你需要传入新浪开放平台的AppKey，AppSecret以及重定向地址 这3个参数。
    关于这3个参数的解释请参阅新浪开放平台的文档
    
    2:获取用户授权，你通过调用 - presentAuthorizeView 方法，弹出一个WebView，供用户输入用户名及密码，
    并提供一个Closure作为回调
    
    3:用户授权成功后，SWKClient会自动调用新浪API完成OAuth2认证的剩余流程，并调用第二步传入的Closure通知调用者
    
    4:OAuth2完成后，就可以通过SWKClient的 - get - post - put - head 等方法直接调用新浪API了
    
    使用示例： 
    let client = SWKClient(clientID:YOUR_ID, clientSecret:YOUR_SECRET, redirectURI:YOUR_REDIRECT_URI)
    client.presentAuthorizeView(fromViewController: self){
    (isSuccess : Bool) in
    if isSuccess{
        client.get("https://api.weibo.com/2/statuses/user_timeline.json",parameters:nil){
        (response) in
            switch response{
            case .success(let successResp):
                println(successResp.json)
            case .failure(let failureResp):
                println(failureResp)
            }
        }
    }
    }
*/
    
    
    /*
    一些私有变量：Swift目前暂时还没有Access Controll的机制
    但根据这里的说法，今后会很快添加进来
    https://devforums.apple.com/thread/227288
    等Access Controll加入Swift以后再来Handle这堆东西
    */
    let clientID:String
    let clientSecret:String
    let redirectURI:String
    var account:SWKAccount?
    
    init(clientID:String,clientSecret:String,redirectURI:String){
    /*
        构造方法:传入的三个参数参见新浪开放平台的文档
    */
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }
    
    func isAuthValid()->Bool{
    /*
        返回当前的认证是否有效
    */
        if self.account?.accessToken&&self.account?.expireDate&&self.account?.uid{
            return true
        }
        return false
    }
    
    func presentAuthorizeView(fromViewController viewController:UIViewController, authorizeHandler:(Bool)->()){
    /*
        调出用户授权页面给用户输入用户名及密码
        fromViewController: 表示从哪个ViewController将此页面Modal出来，必传。
        authorizeHandler:   表示OAuth完成后的结果，会回调一个布尔值表征成功与否
    */
        let authController = SWKAuthController(clientID:self.clientID,clientSecret:self.clientSecret,redirectURI:self.redirectURI){
            (result : SWKAuthorizationResult) in
            switch result{
            case .Granted(let account):
                self.account = account
                authorizeHandler(true)
                dispatch_async(dispatch_get_main_queue()){
                    viewController.dismissViewControllerAnimated(true, completion: nil)
                }
            default:
                authorizeHandler(false)
            }
        }
        authController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: UIBarButtonItemStyle.Plain, target:viewController, action: "dismissModalViewControllerAnimated:")

        let navigation = UINavigationController(rootViewController:authController)
        
        dispatch_async(dispatch_get_main_queue()){
            viewController.presentViewController(navigation, animated: true){}
        }
    }
    
    func get(url:String, parameters:Dictionary<String,String>! = nil, completion:((SWKHTTPResponse)->())! = nil){
    /*
        HTTP Get方法
    */
        self.sendRequest(url, parameters: parameters, httpMethod: SLRequestMethod.GET, completion: completion)
    }
    
    func get(url:String, completion:((SWKHTTPResponse)->())! = nil){
        self.sendRequest(url, parameters: nil, httpMethod: SLRequestMethod.GET, completion: completion)
    }
    
    func post(url:String, parameters:Dictionary<String,String>! = nil, completion:((SWKHTTPResponse)->())! = nil){
    /*
        HTTP POST方法
    */
        self.sendRequest(url, parameters: parameters, httpMethod: SLRequestMethod.POST, completion: completion)
    }
    
    func sendRequest(url:String, parameters:Dictionary<String,String>! = nil,httpMethod:SLRequestMethod , completion:((SWKHTTPResponse)->())! = nil){
    /*
        通用的发起新浪API HTTP请求的方法，需指明使用的是哪种方法
    */
        var payload : Dictionary<String,String> = [:]
        if let account=self.account{
            payload["access_token"]=account.accessToken
        }
        if parameters{
            for (key,value) in parameters{
                payload[key]=value
            }
        }
        
        let sinaRequest = SLRequest(forServiceType : SLServiceTypeSinaWeibo, requestMethod : httpMethod, URL : NSURL(string:url), parameters: payload)
        sinaRequest.performRequestWithHandler{
            (data : NSData!, httpResponse : NSHTTPURLResponse!, error : NSError!) in
            let response = SWKHTTPResponse(data: data,response: httpResponse,error: error)
            completion(response)
        }
    }
    
    
    struct SWKAccount{
    /*
        封装后的OAuth2信息
    */
        var accessToken:String
        var expireDate:NSDate
        var uid:String
    }
    
    enum SWKAuthorizationResult{
    /*
        Granted,表示用户通过输入用户名密码授权通过，其中的SWKAccount是授权后获取到的的OAuth2信息
        Rejected,表示用户手动取消或驳回授权
        Failed,表示非用户意愿的授权失败,例如,网络错误
    */
        case Granted(SWKAccount)
        case Rejected
        case Failed
    }
    
    enum SWKHTTPResponse:LogicValue{
    /*
        封装后的 新浪API HTTP 响应,分为成功与失败两种不同的enum值：
        两种值分别在其中封装了不同的数据类型及方法。
        同时，由于实现了LogicValue协议，亦可以直接通过if等逻辑控制语句对相应结果进行判断
        
        使用示例1，通过switch语句(推荐):
        {
        httpResponse:SWKHTTPResponse in
        
        switch httpResponse{
        case .success(let successResp):
            println (success.json)  //只有成功的值才拥有.json Property
        case .failure(let failedResp):
            println (failedResp)    //成功与失败的值均遵守Printable协议，可以直接使用println输出文本
        }
        }
        使用实例2，通过if语句:
        if httpResponse{
            println(httpResponse.rawData!)
        }
    */
        
        case success(SuccessResp)
        case failure(FailedResp)
        
        struct SuccessResp:Printable{
        /*
            SWKHTTPResponse值为.success时封装的结构体：
            其中：
            content:        返回的Raw Data，以NSData封装
            statusCode:     返回的HTTP Status Code，在200至299间
            headers:        HTTP Header
            MIMEType:       Content-Type，例如application/json
            encoding:       所采用的编码，例如UTF-8
            json:           Computing Property，序列化后的JSON对象
            string:         纯文本
        */
            let content : NSData
            let statusCode : Int
            let headers : NSDictionary
            let MIMEType : String
            let encoding : String
            var json : AnyObject!{
            return NSJSONSerialization.JSONObjectWithData(content, options: NSJSONReadingOptions.AllowFragments, error: nil)
            }
            var string : String{
            return NSString(data:content,encoding:NSUTF8StringEncoding)
            }
            
            //Protocol Printable
            var description: String {
            return self.string
            }
        }
        
        struct FailedResp:Printable{
        /*
            SWKHTTPResponse值为.failure时封装的结构体：
            其中：
            error:          NSError对象，一般是由底层的 NSURLSession 产生，一般表征网络错误
            message:        新浪服务器对此错误的描述，本来是一段JSON，懒得转了，直接放了文本，凑合着看吧……
        */
            let error : NSError!
            let message : String!
            var description: String {
            if message{
                return message!
                }
                if error{
                    return error!.description
                }
                return "No Detail Description For This Error"
            }
        }
        
        init(data:NSData!, response:NSURLResponse!, error:NSError!) {
        /*
            init方法，必须使用此方法对本enum进行构造
            其中:
            data:NSData!,
            response:NSURLResponse!,
            error:NSError!
            这几个参数就是NSURLSession、NSURLConnection或SLRequest在网络请求时的标准回调参数
        */
            
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200..299:
                    let resp = SuccessResp(
                        content : data,
                        statusCode : httpResponse.statusCode,
                        headers : httpResponse.allHeaderFields,
                        MIMEType : httpResponse.MIMEType,
                        encoding : httpResponse.textEncodingName)
                    self = .success(resp)
                default:
                    var message:String! = nil
                    if data{
                        message = NSString(data:data,encoding:NSUTF8StringEncoding)
                    }
                    let resp = FailedResp(error:error,message:message)
                    self = .failure(resp)
                }
                
            }else{
                var message:String! = nil
                if data{
                    message = NSString(data:data,encoding:NSUTF8StringEncoding)
                }
                let resp = FailedResp(error:error,message:message)
                self = .failure(resp)
            }
        }
        
        //Computing Property:成功时返回数据，失败时返回nil，参见本enum的使用示例2
        var rawData:NSData!{
        switch self{
        case .success(let resp):
            return resp.content
        default:
            return nil
            }
        }
        
        //Protocol LogicValue
        func getLogicValue() -> Bool{
            switch self{
            case .success:
                return true
            default:
                return false
            }
        }
    }
    
    
    class SWKAuthController: UIViewController,UIWebViewDelegate {
    /*
        不稳定的授权Web页面,通过 - presentAuthorizeView 方法调出的Web页面就是由此ViewController生成。
        Web授权完毕后会自动dismiss，并Invoke回调
        由于必须非常操蛋地访问Web，此部分代码与UIKit耦合了，有空可能会想点其他方式来解决这个问题
    */
        let clientID:String
        let clientSecret:String
        let redirectURI:String
        let authorizeCallBack:(SWKAuthorizationResult)->()
        
        init(clientID:String,clientSecret:String,redirectURI:String,callBack:(SWKAuthorizationResult)->()){
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.redirectURI = redirectURI
            self.authorizeCallBack = callBack
            
            super.init(nibName:nil,bundle:nil)
            self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            if let frame = self.view?.bounds{
                let authView = UIWebView(frame: frame)
                authView.delegate = self
                self.view?.addSubview(authView)
                let request = NSURLRequest(URL: NSURL(string:"https://api.weibo.com/oauth2/authorize?client_id=\(clientID)&redirect_uri=\(redirectURI)&display=mobile"))
                authView.loadRequest(request)
            }
        }
        
        func webView(webView: UIWebView!, shouldStartLoadWithRequest request: NSURLRequest!, navigationType: UIWebViewNavigationType) -> Bool{
            if request.URL.absoluteString.hasPrefix(self.redirectURI){
                if let array = request?.URL?.query?.componentsSeparatedByString("&"){
                    for kvPairString in array {
                        let kvArray = kvPairString.componentsSeparatedByString("=")
                        if kvArray.count == 2{
                            if kvArray[0] == "code"{
                                let code = kvArray[1]
                                self.requestAccessToken(code)
                            }
                        }
                    }
                }
            }
            return true;
        }
        
        func requestAccessToken(code:String){
            let url = NSURL(string:"https://api.weibo.com/oauth2/access_token")
            let payload = [
                "client_id":clientID,
                "client_secret":clientSecret,
                "grant_type":"authorization_code",
                "code":code,
                "redirect_uri":redirectURI]
            let sinaRequest = SLRequest(forServiceType : SLServiceTypeSinaWeibo, requestMethod : SLRequestMethod.POST, URL : url, parameters: payload)
            
            sinaRequest.performRequestWithHandler{
                (data : NSData!, urlResponse : NSURLResponse!, error : NSError!) in
                if error{
                    self.authorizeCallBack(SWKAuthorizationResult.Failed)
                    return
                }
                if let json = (NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary) {
                    let expire = json["expires_in"] as? NSNumber
                    let uid = json["uid"] as? NSString
                    let token = json["access_token"] as? NSString
                    if expire&&uid&&token{
                        self.authorizeCallBack(SWKAuthorizationResult.Granted(SWKAccount(accessToken:token!
                            ,expireDate:NSDate(timeIntervalSince1970:expire!.doubleValue),
                            uid:uid!)))
                        return
                        
                    }else{
                        self.authorizeCallBack(SWKAuthorizationResult.Failed)
                        return
                    }
                }else{
                    self.authorizeCallBack(SWKAuthorizationResult.Failed)
                    return
                }
            }
        }
    }
}

