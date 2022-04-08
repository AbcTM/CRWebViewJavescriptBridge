//
//  CRWKWebViewJavascriptBridgeBase.h
//  CRWebViewJavescriptBridge
//
//  Created by tm on 2022/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CRWVJBResponseCallback)(id responseData);
typedef void (^CRWVJBHandler)(id data, CRWVJBResponseCallback responseCallback);
typedef NSDictionary CRWVJBMessage;

@protocol CRWKWebViewJavascriptBridgeBaseDelegate <NSObject>

- (void)_evaluateJavascript:(NSString *)javascriptCommand completionHandler:(nullable void(^)(id _Nullable obj, NSError * _Nullable error))handler;

@end

@interface CRWKWebViewJavascriptBridgeBase : NSObject

@property(weak, nonatomic)id<CRWKWebViewJavascriptBridgeBaseDelegate> delegate;

/// 存放对象
@property(nullable, strong, nonatomic)NSMutableArray <CRWVJBMessage *> *startupMessageQueue;
/// 存放响应回调
@property(nullable, strong, nonatomic)NSMutableDictionary <NSString *, CRWVJBResponseCallback>*responseCallbacks;
/// 提供给js的方法列表
@property(nullable, strong, nonatomic)NSMutableDictionary <NSString *, CRWVJBHandler> *messageHandlers;


#pragma mark 日志
/// 设置能否打印日志
+ (void)enableLogging;
/// 设置消息的最大长度
+ (void)setLogMaxLength:(int)length;

#pragma mark public
/// 重置
- (void)reset;

/// 发送数据到js
- (void)sendData:(id _Nullable)data responseCallback:(CRWVJBResponseCallback _Nullable)responseCallback handlerName:(NSString *)handlerName;

- (void)dispachCacheMessage;

/// 刷新消息队列
//- (void)flushMessageQueue:(NSString *)messageQueueString;

/// 直接派发消息
- (void)flushMessageString:(NSString *)messageString;

/// 加载js文件
- (void)injectJavascriptFile;

/// 查询指令
- (NSString *)webViewJavascriptFetchQueyCommand;

@end

NS_ASSUME_NONNULL_END
