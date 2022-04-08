//
//  CRWKLeakAvoider.h
//  CRWebViewJavescriptBridge
//
//  Created by tm on 2022/3/31.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRWKLeakAvoider : NSObject<WKScriptMessageHandler>

- (instancetype)initWithHandler:(id<WKScriptMessageHandler>)handler;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
