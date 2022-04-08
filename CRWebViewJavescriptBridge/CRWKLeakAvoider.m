//
//  CRWKLeakAvoider.m
//  CRWebViewJavescriptBridge
//
//  Created by tm on 2022/3/31.
//

#import "CRWKLeakAvoider.h"

@interface CRWKLeakAvoider ()

@property(nonatomic, weak)id<WKScriptMessageHandler> handler;

@end

@implementation CRWKLeakAvoider

- (instancetype)initWithHandler:(id<WKScriptMessageHandler>)handler {
    if (self = [super init]) {
        self.handler = handler;
    }
    return self;
}

#pragma mark handler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.handler) {
        [self.handler userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end
