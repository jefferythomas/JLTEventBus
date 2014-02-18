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

- (void)registerEventHandler:(id)eventHandler;
- (void)unregisterEventHandler:(id)eventHandler;

- (void)postEvent:(id)event forType:(id)type;
- (void)registerEventHandler:(id)eventHandler selector:(SEL)selector forType:(id)type;
- (id)registerEventHandlerBlock:(JLTEventHandlerBlock)eventHandlerBlock forType:(id)type;

+ (instancetype)defaultBus;

@end
