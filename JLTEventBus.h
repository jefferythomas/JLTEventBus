//
//  JLTEventBus.h
//  JLTEventBusDemo
//
//  Created by Jeffery Thomas on 2/15/14.
//  Copyright (c) 2014 JLT Source. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^JLTEventHandlerBlock)(id event);

@interface JLTEventBus : NSObject

- (void)postEvent:(id)event;
- (void)postEvent:(id)event forType:(id)type;

- (id)registerEventHandlerBlock:(JLTEventHandlerBlock)eventHandlerBlock forType:(id)type;
- (void)unregisterHandler:(id)eventHandler;

+ (instancetype)defaultBus;

@end
