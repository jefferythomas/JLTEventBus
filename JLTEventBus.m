//
//  JLTEventBus.m
//  JLTEventBusDemo
//
//  Created by Jeffery Thomas on 2/15/14.
//  Copyright (c) 2014 JLT Source. All rights reserved.
//

#import "JLTEventBus.h"
#import <objc/runtime.h>

@interface JLTEventBus ()
@property (nonatomic, readonly) NSNotificationCenter *jlt_center;
@end

@implementation JLTEventBus

- (void)postEvent:(id)event
{
    NSParameterAssert(event);

    [self postEvent:event forType:[event class]];

    for (NSValue *protocol in [[self class] jlt_allProtocolForClass:[event class]])
        [self postEvent:event forType:[protocol nonretainedObjectValue]];
}

- (void)postEvent:(id)event forType:(id)type
{
    NSParameterAssert(event);

    NSString *token = [[self class] jlt_tokenFromType:type];
    [self.jlt_center postNotificationName:token object:event];
}

- (id)registerEventHandlerBlock:(JLTEventHandlerBlock)eventHandlerBlock forType:(id)type
{
    NSParameterAssert(eventHandlerBlock);

    NSString *token = [[self class] jlt_tokenFromType:type];
    NSNotificationCenter *center = self.jlt_center;

    id observer = [center addObserverForName:token object:nil queue:nil usingBlock:^(NSNotification *note) {
        eventHandlerBlock(note.object);
    }];

    return observer;
}

- (void)unregisterEventHandler:(id)eventHandler
{
    NSParameterAssert(eventHandler);

    [self.jlt_center removeObserver:eventHandler];
}

+ (instancetype)defaultBus
{
    static JLTEventBus *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [JLTEventBus new];
    });
    return instance;
}

#pragma mark Private

+ (NSString *)jlt_tokenFromType:(id)type
{
    NSString *protocolName = NSStringFromProtocol(type);
    if (protocolName) {
        return [NSString stringWithFormat:@"JLTEventBusPrototype%@", protocolName];
    } else if (class_isMetaClass(object_getClass(type))) {
        return [NSString stringWithFormat:@"JLTEventBusClass%@", NSStringFromClass(type)];
    } else {
        NSString *reason = [NSString stringWithFormat:@"%@ is not a prototype or class", type];
        @throw [NSException exceptionWithName:@"JLTEventBusInvalidType" reason:reason userInfo:nil];
    }
}

+ (NSArray *)jlt_allProtocolForClass:(Class)class
{
    NSMutableArray *result = [NSMutableArray array];
    Protocol * __unsafe_unretained *protocols = class_copyProtocolList(class, NULL);

    if (!protocols)
        return result;

    for (Protocol * __unsafe_unretained *p = protocols; *p; ++p) {
        [result addObject:[NSValue valueWithNonretainedObject:*p]];
    }

    free(protocols);
    return result;
}

#pragma mark Memory lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        _jlt_center = [NSNotificationCenter new];
    }
    return self;
}

@end
