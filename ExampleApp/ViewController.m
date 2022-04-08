//
//  ViewController.m
//  ExampleApp
//
//  Created by tm on 2022/3/31.
//

#import "ViewController.h"
#import "WebKit/WebKit.h"

@import CRWebViewJavescriptBridge;

@interface ViewController ()<WKNavigationDelegate>

@property(nonatomic, strong)WKWebView *webView;
@property(nonatomic, strong)CRWKWebViewJavascriptBridge *bridge;

@end

@implementation ViewController


#pragma mark life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
}

- (void)dealloc {
    NSLog(@"ViewController dealloc");
}

#pragma mark getter
- (WKWebView *)webView {
    if (_webView == nil) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 13.0, *)) {
            configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        } else {
            configuration.preferences.javaScriptEnabled = YES;
        }
        
        WKWebView *view = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
        view.navigationDelegate = self;
        _webView = view;
    }
    return _webView;
}

#pragma mark ui
- (void)setupView {
    [self.view addSubview:self.webView];
    [CRWKWebViewJavascriptBridge enableLogging];
    self.bridge = [CRWKWebViewJavascriptBridge bridgeForWebView:self.webView];
    [self renderButtons:self.webView];
    [self loadExamplePage:self.webView];
    
    /// 注册供js调用
    [self.bridge registerHandler:@"testObjcCallback" handler:^(id data, CRWVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
    
//    [self.bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" } ];
    [self.bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" } responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler responsed");
    }];
    [self.bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready2" } responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler responsed2");
    }];
    [self.bridge callHandler:@"notExistJsMethod" data:@{ @"foo":@"before ready3" } responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler responsed3 data:%@",responseData);
    }];
}

- (void)renderButtons:(WKWebView*)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    
    CGFloat screenHeight = self.view.bounds.size.height;
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(10, screenHeight-100, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    [reloadButton addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(110, screenHeight-100, 100, 35);
    reloadButton.titleLabel.font = font;
}

#pragma mark action
- (void)callHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
    [self.bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
}

- (void)reload {
    NSLog(@"aaaaaa");
    [self.bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before reload" } responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler before reload responsed");
    }];
    [self.bridge reset];
    [self.webView reload];
    [self.bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"reload after" } responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"testJavascriptHandler reload after responsed");
    }];
}

- (void)loadExamplePage:(WKWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"ExampleApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

#pragma mark navigation delegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"%@",@"webView 开始加载");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 不代表所有内容加载完成，如一些js文件可能并没有加载完
    NSLog(@"%@",@"webView 加载完成");
}


@end
