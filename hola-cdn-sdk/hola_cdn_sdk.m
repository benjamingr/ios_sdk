//
//  hola_cdn_sdk.m
//  hola-cdn-sdk
//
//  Created by alexeym on 27/07/16.
//  Copyright © 2016 hola. All rights reserved.
//

#import "hola_cdn_sdk.h"
#import "hola_log.h"
#import "hola_cdn_player_proxy.h"

@interface HolaCDN()
{
NSString* _zone;
NSString* _mode;

int serverPort;

UIWebView* webview;
HolaCDNPlayerProxy* playerProxy;

AVPlayer* _player;

}
@end

@implementation HolaCDN

BOOL ready = NO;
HolaCDNLog* _log;

NSString* domain = @"https://player.h-cdn.com";
NSString* webviewUrl = @"%@/webview?customer=%@";
NSString* webviewHTML = @"<script>window.hola_cdn_sdk = {version:'%@'}</script><script src=\"%@/loader_%@.js\"></script>";

NSString* hola_cdn = @"window.hola_cdn";

+(void)setLogLevel:(HolaCDNLogLevel)level {
    [HolaCDNLog setVerboseLevel:level];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        webview = [UIWebView new];
        webview.delegate = self;

        _log = [HolaCDNLog new];
    }

    return self;
}

-(void)configWithCustomer:(NSString*)customer usingZone:(NSString*)zone andMode:(NSString*)mode {
    _customer = customer;
    _zone = zone;
    _mode = mode;

    if (ready) {
        [self unload];
    }
}

-(BOOL)load:(NSError**)error {
    [_log debug:@"load called"];
    if (_customer == nil) {
        *error = [NSError errorWithDomain:@"org.hola.hola-cdn-sdk" code:1 userInfo:nil];
        return NO;
    }

    [_log info:@"load"];
    if (ready) {
        if (_delegate != nil) {
            [_delegate cdnDidLoaded:self];
        }
        return YES;
    }

    JSContext* ctx = [webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    if (ctx == nil) {
        [_log err:@"No context on initContext"];
        return NO;
    }

    ctx.exceptionHandler = ^(JSContext* context, JSValue* exception) {
        [self onException:context value:exception];
    };

    _ctx = ctx;

    NSBundle* bundle = [NSBundle bundleForClass:NSClassFromString(@"HolaCDN")];
    NSString* version = bundle.infoDictionary[@"CFBundleShortVersionString"];
    NSString* htmlString = [NSString stringWithFormat:webviewHTML, version, domain, _customer];

    [webview loadHTMLString:htmlString baseURL:[self makeWebviewUrl]];

    return YES;
}

-(void)set_cdn_enabled:(NSString*)name enabled:(BOOL)enabled {
    if (playerProxy == nil) {
        return;
    }

    NSString* jsString = [NSString stringWithFormat:@"_get_bws().cdns.arr.forEach(function(cdn){ if (cdn.name=='%@') { cdn.enabled = %d; } })", name, enabled ? 1 : 0];
    [_ctx evaluateScript:[NSString stringWithFormat:@"%@.%@", hola_cdn, jsString]];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [_log debug:@"page loaded!"];

    ready = YES;
    if (_delegate != nil) {
        [_delegate cdnDidLoaded:self];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (ready && YES && YES) {
            dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(backgroundQueue, ^{
                [_log info:@"player autoinit"];
                [self attach:_player];
            });
        }
    });
}

-(void)attach:(AVPlayer*)player {
    if (playerProxy != nil) {
        [_log warn:@"CDN is already attached!"];
        return;
    }

    _player = player;

    if (!ready) {
        [_log info:@"not ready on attach: wait for player autoinit"];
        return;
    }

    [_log info:@"attach"];

    playerProxy = [[HolaCDNPlayerProxy alloc] initWithPlayer:_player andCDN:self];

    JSValue* ios_ready = [_ctx evaluateScript:[NSString stringWithFormat:@"%@.%@", hola_cdn, @"api.ios_ready"]];
    if (ios_ready.isUndefined) {
        playerProxy = nil;
        [_log err:@"No ios_ready: something is wrong with cdn js"];
        return;
    }

    [ios_ready callWithArguments:[NSArray new]];
}

-(void)uninit {
    [_log info:@"cdn uninit"];

    [playerProxy uninit];
    playerProxy = nil;
    _player = nil;
}

-(void)unload {
    [self uninit];

    ready = NO;
}

-(NSDictionary*)get_stats {
    if (playerProxy == nil) {
        return nil;
    }

    JSValue* stats = [_ctx evaluateScript:[NSString stringWithFormat:@"%@.%@", hola_cdn, @"get_stats({silent: true})"]];

    return [stats toDictionary];
}

-(NSString*)get_mode {
    if (playerProxy == nil) {
        return ready ? @"detached" : @"loading";
    }

    JSValue* mode = [_ctx evaluateScript:[NSString stringWithFormat:@"%@.%@", hola_cdn, @"get_mode()"]];

    return [mode toString];
}

-(NSDictionary*)get_timeline {
    if (playerProxy == nil) {
        return nil;
    }

    JSValue* stats = [_ctx evaluateScript:[NSString stringWithFormat:@"%@.%@", hola_cdn, @"get_stats({silent: true})"]];

    return [stats toDictionary];
}

-(void)onException:(JSContext*)context value:(JSValue*)value {
    [_log err:[NSString stringWithFormat:@"JS Exception: %@", value]];

    if (_delegate != nil) {
        [_delegate cdnExceptionOccured:self withError:value];
    }
}

-(NSURL*)makeWebviewUrl {
    NSMutableString* url = [NSMutableString stringWithFormat:webviewUrl, domain, _customer];

    if (_zone != nil) {
        [url appendFormat:@"&hola_zone=%@", _zone];
    }
    if (_mode != nil) {
        [url appendFormat:@"&hola_mode=%@", _mode];
    }
    /*
    if (_graphEnabled) {
        [url appendString:@"&hola_graph=1"];
    }
    */

    return [NSURL URLWithString:url];
}

@end
