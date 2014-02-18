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
@property (nonatomic, readonly) NSMutableDictionary *jlt_eventHandlers;
@end

@implementation JLTEventBus

- (void)postEvent:(id)event
{
    NSParameterAssert(event);

    [self postEvent:event forType:[event class]];

    for (Protocol *protocol in [[self class] jlt_allProtocolsForClass:[event class]]) {
        [self postEvent:event forType:protocol];
    }
}

- (void)registerEventHandler:(id)eventHandler
{
    NSParameterAssert(eventHandler);

    for (NSValue *selectorValue in [[self class] jlt_allSelectorsForClass:[eventHandler class]]) {
        SEL selector = [selectorValue pointerValue];
        NSString *selectorString = NSStringFromSelector(selector);

        if (![selectorString hasPrefix:@"on"] || ![selectorString hasSuffix:@":"])
            continue;

        NSUInteger onEventLen = [@"on" length];
        NSUInteger colonLen = [@":" length];
        NSRange range = NSMakeRange(onEventLen, [selectorString length] - onEventLen - colonLen);

        NSString *typeString = [selectorString substringWithRange:range];

        Protocol *protocol = NSProtocolFromString(typeString);
        if (protocol)
            [self registerEventHandler:eventHandler selector:selector forType:protocol];

        Class aClass = NSClassFromString(typeString);
        if (aClass)
            [self registerEventHandler:eventHandler selector:selector forType:aClass];
    }
}

- (void)unregisterEventHandler:(id)eventHandler
{
    NSParameterAssert(eventHandler);
    NSNumber *hash = @([eventHandler hash]);

    if (self.jlt_eventHandlers[hash]) {
        for (id observer in self.jlt_eventHandlers[hash]) {
            [self.jlt_center removeObserver:observer];
        }

        [self.jlt_eventHandlers removeObjectForKey:hash];
    } else {
        [self.jlt_center removeObserver:eventHandler];
    }
}

- (void)postEvent:(id)event forType:(id)type
{
    NSParameterAssert(event);
    NSString *token = [[self class] jlt_tokenFromType:type];

    [self.jlt_center postNotificationName:token object:event];
}

- (void)registerEventHandler:(id)eventHandler selector:(SEL)selector forType:(id)type
{
    NSParameterAssert(eventHandler);
    NSParameterAssert(selector);
    NSNumber *hash = @([eventHandler hash]);
    NSString *token = [[self class] jlt_tokenFromType:type];

    id o = [self.jlt_center addObserverForName:token object:nil queue:nil usingBlock:^(NSNotification *note) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [eventHandler performSelector:selector withObject:note.object];
#pragma clang diagnostic pop
    }];

    NSMutableArray *observers = self.jlt_eventHandlers[hash];

    if (observers) {
        [observers addObject:o];
    } else {
        observers = [NSMutableArray arrayWithObject:o];
        self.jlt_eventHandlers[hash] = observers;
    }
}

- (id)registerEventHandlerBlock:(JLTEventHandlerBlock)eventHandlerBlock forType:(id)type
{
    NSParameterAssert(eventHandlerBlock);
    NSString *token = [[self class] jlt_tokenFromType:type];

    id o = [self.jlt_center addObserverForName:token object:nil queue:nil usingBlock:^(NSNotification *note) {
        eventHandlerBlock(note.object);
    }];

    return o;
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

+ (NSArray *)jlt_allProtocolsForClass:(Class)aClass
{
    NSMutableArray *result = [NSMutableArray array];
    Protocol * __unsafe_unretained *protocols = class_copyProtocolList(aClass, NULL);

    if (!protocols)
        return result;

    for (Protocol * __unsafe_unretained *protocol = protocols; *protocol; ++protocol) {
        [result addObject:*protocol];
    }

    free(protocols);
    return result;
}

+ (NSArray *)jlt_allSelectorsForClass:(Class)aClass
{
    NSMutableArray *result = [NSMutableArray array];
    Method *methods = class_copyMethodList(aClass, NULL);

    if (!methods)
        return result;

    for (Method *method = methods; *method; ++method) {
        [result addObject:[NSValue valueWithPointer:method_getName(*method)]];
    }

    free(methods);
    return result;
}

#pragma mark Memory lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        _jlt_center = [NSNotificationCenter new];
        _jlt_eventHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
