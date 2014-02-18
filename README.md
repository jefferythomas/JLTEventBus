#JLTEventBus

JLTEventBus is based on [Guava EventBus](https://code.google.com/p/guava-libraries/source/browse/#git%2Fguava%2Fsrc%2Fcom%2Fgoogle%2Fcommon%2Feventbus).

##Events

Events are classes or protocols. Unlike `NSNotification` where the notification is identified as a string, events are identified by their type.

    @interface UserDidChange : NSObject
    @property (nonatomic) User *currentUser;
    @property (nonatomic) User *previousUser;
    @end

##Register For Events

    [[JLTEventBus defaultBus] registerEventHandler:eventHandler]

This registers all the methods in `eventHandler` named `-on<Event>:` as callbacks on the default bus.

###Register Sample

In this sample, a class is created which handles the `UserDidChange` event. When an instance of the class is created, the instance registers itself as an event handler on the default bus. When the instance is released, it unregisters itself as a handler.

    @interface UserMonitor : NSObject
    - (void)onUserDidChange:(UserDidChange *)event;
    @end

    @implementation UserMonitor

    - (void)onUserDidChange:(UserDidChange *)event
    {
        NSLog(@"The user changed from %@ to %@", event.previousUser, event.currentUser);
    }

    - (id)init
    {
        self = [super init];
        if (self) {
            [[JLTEventBus defaultBus] registerEventHandler:self];
        }
        return self;
    }

    - (void)dealloc
    {
        [[JLTEventBus defaultBus] unregisterEventHandler:self];
    }

    @end

##Posting Events

    [[JLTEventBus defaultBus] postEvent:[Event new]]

This sends an instance of the event object to each handler that's been registered on the default bus.

###Post Sample

In this sample, the `-setUser:(User *)user` method posts a `UserDidChange` event.

    - (void)setUser:(User *)user
    {
        if (_user != user) {
            User *previousUser = _user;
            _user = user;

            UserDidChange *event = [UserDidChange new];
            event.currentUser = user;
            event.previousUser = previousUser;
            [[JLTEventBus defaultBus] postEvent:event];
        }
    }
