//
//  CRWKWebViewJavascriptBridge.m
//  CRWebViewJavescriptBridge
//
//  Created by tm on 2022/3/31.
//

#import "CRWKWebViewJavascriptBridge.h"
#import "CRWKLeakAvoider.h"

#define iOS_Native_InjectJavascript  @"iOS_Native_InjectJavascript"
#define iOS_Native_FlushMessageQueue  @"iOS_Native_FlushMessageQueue"

@interface CRWKWebViewJavascriptBridge ()

@property(nonatomic, weak)WKWebView *webView;
@property(nonatomic, strong)CRWKWebViewJavascriptBridgeBase *base;

@end

@implementation CRWKWebViewJavascriptBridge

#pragma mark api
+ (instancetype)bridgeForWebView:(WKWebView*)webView {
    CRWKWebViewJavascriptBridge *bridge = [[self alloc] init];
    [bridge _setupInstance:webView];
    [bridge reset];
    return bridge;
}

+ (void)enableLogging {
    [CRWKWebViewJavascriptBridgeBase enableLogging];
}

- (void)registerHandler:(NSString *)handlerName
                handler:(CRWVJBHandler)handler {
    [[_base messageHandlers] setObject:handler forKey:handlerName];
}

- (void)removeHandler:(NSString *)handlerName {
    [[_base messageHandlers] removeObjectForKey:handlerName];
}

- (void)callHandler:(NSString *)handlerName {
    [_base sendData:nil responseCallback:nil handlerName:handlerName];
}

- (void)callHandler:(NSString *)handlerName data:(id _Nullable)data {
    [_base sendData:data responseCallback:nil handlerName:handlerName];
}

- (void)callHandler:(NSString *)handlerName data:(id _Nullable)data responseCallback:(CRWVJBResponseCallback _Nullable)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:handlerName];
}

- (void)reset {
    [_base reset];
}

#pragma mark life cycle
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc {
    [self removeScriptMessageHandlers];
}

#pragma mark wkwebview

- (void)_setupInstance:(WKWebView*)webView {
    _webView = webView;
    self.base = [[CRWKWebViewJavascriptBridgeBase alloc] init];
    self.base.delegate = self;
    [self addScriptMessageHandlers];
}

- (void)addScriptMessageHandlers {
    id<WKScriptMessageHandler> _a = (id<WKScriptMessageHandler>)[[CRWKLeakAvoider alloc] initWithHandler:self];
    
    [[_webView configuration].userContentController addScriptMessageHandler:_a name:iOS_Native_InjectJavascript];
    [[_webView configuration].userContentController addScriptMessageHandler:_a name:iOS_Native_FlushMessageQueue];
}

- (void)removeScriptMessageHandlers {
    [[_webView configuration].userContentController removeScriptMessageHandlerForName:iOS_Native_InjectJavascript];
    [[_webView configuration].userContentController removeScriptMessageHandlerForName:iOS_Native_FlushMessageQueue];
}
//
//- (void)flushMessageQueue {
//    __weak typeof(self) weakSelf = self;
//    // 这里的参数需要和js中保持一致
//    [self _evaluateJavascript:[self.base webViewJavascriptFetchQueyCommand] completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
//        NSString *str = result;
//        if (str) {
//            [weakSelf.base flushMessageQueue:str];
//        }
//    }];
//}


#pragma mark base delegate
- (void)_evaluateJavascript:(NSString *)javascriptCommand completionHandler:(nullable void (^)(id _Nullable, NSError * _Nullable))handler {
    [_webView evaluateJavaScript:javascriptCommand completionHandler: handler];
}

#pragma mark hander
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    //NSLog(@"message.name:%@,messageBody:%@",message.name, message.body);
    
    ///
    if ([message.name isEqual: iOS_Native_InjectJavascript]) {
        if (self.webView.isLoading) {
            //NSLog(@"webView %@",self.webView.isLoading ? @"在加载中" : @"加载完成");
        }
        [_base injectJavascriptFile];
    }
    else if ([message.name isEqual: iOS_Native_FlushMessageQueue]) {
        [_base flushMessageString:(NSString *)message.body];
    }
}

@end
