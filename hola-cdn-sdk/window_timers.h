//
//  window_timers.h
//  hola-cdn-sdk
//
//  https://github.com/Lukas-Stuehrk/WindowTimers
//
//  Created by alexeym on 04/08/16.
//  Copyright © 2016 hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface WTWindowTimers: NSObject

- (void)extend:(id)context;

@property (nonatomic) NSUInteger tolerance;
@property (readonly, nonatomic) id setTimeout;
@property (readonly, nonatomic) id clearTimeout;
@property (readonly, nonatomic) id setInterval;

@end