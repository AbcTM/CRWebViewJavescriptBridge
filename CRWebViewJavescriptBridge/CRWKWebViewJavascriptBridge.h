//
//  CRWKWebViewJavascriptBridge.h
//  CRWebViewJavescriptBridge
//
//  Created by tm on 2022/3/31.
//

#import <Foundation/Foundation.h>
#import "CRWKWebViewJavascriptBridgeBase.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRWKWebViewJavascriptBridge : NSObject<CRWKWebViewJavascriptBridgeBaseDelegate, WKScriptMessageHandler>

+ (instancetype)bridgeForWebView:(WKWebView*)webView;
+ (void)enableLogging;

- (void)registerHandler:(NSString *)handlerName handler:(CRWVJBHandler)handler;
- (void)removeHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName data:(id _Nullable)data;
- (void)callHandler:(NSString *)handlerName data:(id _Nullable)data responseCallback:(CRWVJBResponseCallback _Nullable)responseCallback;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
