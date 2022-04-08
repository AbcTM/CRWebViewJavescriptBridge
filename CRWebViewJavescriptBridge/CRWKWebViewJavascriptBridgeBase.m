//
//  CRWKWebViewJavascriptBridgeBase.m
//  CRWebViewJavescriptBridge
//
//  Created by tm on 2022/3/31.
//

#import "CRWKWebViewJavascriptBridgeBase.h"
#import "CRWebViewJavascriptBridge_JS.h"

@interface CRWKWebViewJavascriptBridgeBase ()

@property(nonatomic, assign)long uniqueId;

@end

@implementation CRWKWebViewJavascriptBridgeBase

static bool logging = false;
static int logMaxLength = 500;

#pragma mark 日志
+ (void)enableLogging { logging = true; }
+ (void)setLogMaxLength:(int)length { logMaxLength = length;}

#pragma mark life cycle
- (id)init {
    if (self = [super init]) {
        self.messageHandlers = [NSMutableDictionary dictionary];
        self.startupMessageQueue = [NSMutableArray array];
        self.responseCallbacks = [NSMutableDictionary dictionary];
        _uniqueId = 0;
    }
    return self;
}

- (void)dealloc {
    self.startupMessageQueue = nil;
    self.responseCallbacks = nil;
    self.messageHandlers = nil;
}

#pragma mark

- (void)reset {
    // 重置startup message queue、响应队列、消息ID
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    _uniqueId = 0;
}

- (void)sendData:(id _Nullable)data
responseCallback:(CRWVJBResponseCallback _Nullable)responseCallback
     handlerName:(NSString *)handlerName {
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        /// 回调ID
        NSString* callbackId = [NSString stringWithFormat:@"native_iOS_cb_%ld", ++_uniqueId];
        /// 保存在响应字典里
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _queueMessage:message];
}

//- (void)flushMessageQueue:(NSString *)messageQueueString {
//    if (messageQueueString == nil || messageQueueString.length == 0) {
//        NSLog(@"CRWebViewJavascriptBridge: WARNING: ObjC在从webview获取消息队列JSON时得到了nil。如果webview中当前不存在WebViewJavascriptBridge JS，例如webview刚刚加载了一个新页面，则可能会发生这种情况。");
//        return;
//    }
//    
//    id messages = [self _deserializeMessagesJSON:messageQueueString];
//    for (CRWVJBMessage *message in messages) {
//        [self _revicedNewMessage:message];
//    }
//}

- (void)flushMessageString:(NSString *)messageString {
    if (messageString == nil || messageString.length == 0) {
        NSLog(@"CRWebViewJavascriptBridge: WARNING: ObjC在从webview获取消息队列JSON时得到了nil。如果webview中当前不存在WebViewJavascriptBridge JS，例如webview刚刚加载了一个新页面，则可能会发生这种情况。");
        return;
    }
    
    CRWVJBMessage *message = [self _deserializeMessageJSON:messageString];
    [self _revicedNewMessage:message];
    
}

/// 注入js文件
- (void)injectJavascriptFile {
    NSString *js = CRWebViewJavascriptBridge_js();
    
    __weak typeof(self) weakSelf = self;
    [self _evaluateJavascript:js completionHandler:^(id _Nullable obj, NSError * _Nullable err) {
        if (err) {
            NSLog(@"injectJavascriptFile err:%@", err.localizedDescription);
            return;
        }
        // TODO:这里需要加载完自定义后回调派发的缓存消息
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            /// 探测通道是否可用
            [weakSelf dispachCacheMessage];
        });
    }];
}

- (void)dispachCacheMessage {
    if (self.startupMessageQueue) {
        NSLog(@"有缓存的消息需要发送");
        NSArray *queue = self.startupMessageQueue;
        self.startupMessageQueue = nil;
        for (id queuedMessage in queue) {
            [self _dispatchMessage:queuedMessage];
        }
    }
}

/// 查询命令
- (NSString *)webViewJavascriptFetchQueyCommand {
    return @"WebViewJavascriptBridge._fetchQueue();";
}

#pragma mark private
/// 执行脚本
- (void)_evaluateJavascript:(NSString *)javascriptCommand completionHandler:(nullable void (^)(id _Nullable, NSError * _Nullable))handler {
    
    if (self.delegate == nil) {
        return;
    }
    /// 到主线程调用到实际执行命令的实现
    if ([[NSThread currentThread] isMainThread]) {
        [self.delegate _evaluateJavascript:javascriptCommand completionHandler:handler];
    } else {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate _evaluateJavascript:javascriptCommand completionHandler:handler];
        });
    }
}

/// 处理新收到的消息
- (void)_revicedNewMessage:(CRWVJBMessage *)message {
    if (![message isKindOfClass:[CRWVJBMessage class]]) {
        NSLog(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@", [message class], message);
        return;
    }
    [self _log:@"RCVD" json:message];
    
    /// 需要回调ID
    NSString *responseId = message[@"responseId"];
    if (responseId) {
        /// 根据原生方法中的send-callbackId 接受回为responseId 取出回调函数
        CRWVJBResponseCallback responseCallback = _responseCallbacks[responseId];
        if (responseCallback) {
            /// 根据回调函数调用js带回来的参数
            responseCallback(message[@"responseData"]);
            /// 移出回调函数
            [self.responseCallbacks removeObjectForKey:responseId];
        }

    } else {
        CRWVJBResponseCallback responseCallback = NULL;
        
        /// 取出js调用原生回调callbackId
        NSString *callbackId = message[@"callbackId"];
        
        /// 有就是需要回调，没有不需要回调
        if (callbackId) {
            responseCallback = ^(id responseData) {
                if (responseData == nil) {
                    responseData = [NSNull null];
                }
                
                /// 携带的responseId 对应为callbackId，响应数据带回给js
                CRWVJBMessage* msg = @{ @"responseId":callbackId, @"responseData":responseData };
                [self _queueMessage:msg];
            };
        } else {
            responseCallback = ^(id ignoreResponseData) {
                // Do nothing
            };
        }
        
        /// 根据原生提供消息的方法列表，取出对应的方法，找到相应的实现函数
        CRWVJBHandler handler = self.messageHandlers[message[@"handlerName"]];
        
        if (!handler) {
            NSLog(@"WVJBNoHandlerException, No handler for message from JS: %@", message);
            responseCallback(@{@"error":@"ObjcHandlerNotFound"});
            return;
        }
        
        /// js调用实现的函数并传入的数据；第一个参数为数据，第二个参数为回调参数
        handler(message[@"data"], responseCallback);
    }
}

/// 将消息放入派发队列
- (void)_queueMessage:(CRWVJBMessage *)message {
    /// 若不是消息队列不为nil，则将消息添加队列
    if (self.startupMessageQueue) {
        NSLog(@"放入 startupMessageQueue");
        [self.startupMessageQueue addObject:message];
    } else {
        /// 若已初始化，并派遣这个消息
        [self _dispatchMessage:message];
    }
}

/// 派发消息
- (void)_dispatchMessage:(CRWVJBMessage *)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    [self _log:@"SEND" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    /// 合成js可执行的字符串这里的函数[WebViewJavascriptBridge._handleMessageFromObjC]名字需要跟js中保持一致
    NSString* javascriptCommand = [NSString stringWithFormat:@"WebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON];
    
    [self _evaluateJavascript:javascriptCommand completionHandler:nil];
}

/// 将消息序列化为字符串
- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

/// 将json的字符串反序列化为数组对象
- (NSArray*)_deserializeMessagesJSON:(NSString *)messagesJSON {
    return [NSJSONSerialization JSONObjectWithData:[messagesJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

- (id)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

/// log打印出来
- (void)_log:(NSString *)action json:(id)json {
    if (!logging) { return; }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json pretty:YES];
    }
    /// 日志打印的最大长度
    if ([json length] > logMaxLength) {
        NSLog(@"WVJB %@: %@ [...]", action, [json substringToIndex:logMaxLength]);
    } else {
        NSLog(@"WVJB %@: %@", action, json);
    }
}

@end
