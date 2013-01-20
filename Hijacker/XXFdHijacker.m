#import "XXFdHijacker.h"

enum { kReadSide, kWriteSide };  // The two side to every pipe()

@interface XXFdHijacker () {
    int _pipe[2];
    CFSocketRef _socketRef;
}
@property (assign, nonatomic) int fileDescriptor;  // turn of read-onlyibility
@property (assign, nonatomic) int oldFileDescriptor;

@property (assign, nonatomic) BOOL hijacking;
@property (assign, nonatomic) BOOL replicating;

@end // extension



@implementation XXFdHijacker

+ (id) hijackerWithFd: (int) fileDescriptor {
    XXFdHijacker *hijacker = [[[self class] alloc] init];
    hijacker.fileDescriptor = fileDescriptor;

    return hijacker;
} // hijackerWithFd


- (void) startHijacking {
    if (self.hijacking) return;

    int result;

    result = pipe (_pipe);
    if (result == -1) {
        assert (!"could not make a pipe for standard out");
        return;
    }

    self.oldFileDescriptor = dup (self.fileDescriptor);

    if (self.oldFileDescriptor == -1) {
        assert (!"could not dup our fd");
        return;
    }

    result = dup2 (_pipe[kWriteSide], self.fileDescriptor);
    if (result == -1) {
        assert (!"could not dup2 our fd");
        return;
    }

    [self startMonitoringFileDescriptor: _pipe[kReadSide]];

    self.hijacking = YES;
} // startHijacking


- (void) stopHijacking {
    if (!self.hijacking) return;

    [self notifyString: @"stopHijacking"];

    self.hijacking = NO;
} // stopHijacking


- (void) startReplicating {
    if (self.replicating) return;

    self.replicating = YES;
} // startReplicating


- (void) stopReplicating {
    if (!self.replicating) return;

    self.replicating = NO;
} // stopReplicating


- (void) notifyString: (NSString *) contents {
    [self.delegate hijacker: self  gotText: contents];
} // notifyString


// --------------------------------------------------
// The heavy lifting

static void ReceiveMessage (CFSocketRef socket, CFSocketCallBackType type,
                            CFDataRef address, const void *cfdata, void *info) {
    NSData *data = (__bridge NSData *) cfdata;

    NSString *string = [[NSString alloc] initWithData: data
                                         encoding: NSUTF8StringEncoding];

    XXFdHijacker *self = (__bridge XXFdHijacker *) info;
    [self notifyString: string];

    // Now forward on to its original destination.
    if (self.replicating) {
        write (self.oldFileDescriptor, data.bytes, data.length);
    }

} // ReceiveMessage


- (void) startMonitoringFileDescriptor: (int) fd {
    CFSocketContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    _socketRef = CFSocketCreateWithNative (kCFAllocatorDefault,
                                           fd,
                                           kCFSocketDataCallBack,
                                           ReceiveMessage,
                                           &context);
    if (_socketRef == NULL) {
        NSLog (@"couldn't make cfsocket");
        goto bailout;
    }
    
    CFRunLoopSourceRef rls = 
        CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socketRef, 0);

    if (rls == NULL) {
        NSLog (@"couldn't create run loop source");
        goto bailout;
    }
    
    CFRunLoopAddSource (CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease (rls);

bailout: 
    return;

} // startMonitoringFileDescriptor


@end // XXFdHijacker
