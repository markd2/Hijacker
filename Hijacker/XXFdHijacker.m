#import "XXFdHijacker.h"

// pipe() fills in an array of two file descriptors.  Whats written to the write-side
// (file descriptor 1) appears on the the read-side (file descriptor 0). 
enum { kReadSide, kWriteSide };  // The two side to every pipe()

@interface XXFdHijacker () {
    int _pipe[2];   // populated by pipe()
    CFRunLoopSourceRef _monitorRunLoopSource;  // Notifies us of activity on the pipe.
}
@property (assign, nonatomic) int fileDescriptor;     // The fd we're hijacking
@property (assign, nonatomic) int oldFileDescriptor;  // The original fd, for unhijacking

@property (assign, nonatomic) BOOL hijacking;   // Are we hijacking or replicating?
@property (assign, nonatomic) BOOL replicating;

@end // extension



@implementation XXFdHijacker


// Convenience method to make a new hijacker with a given file descriptor.

+ (id) hijackerWithFd: (int) fileDescriptor {
    XXFdHijacker *hijacker = [[[self class] alloc] init];
    hijacker.fileDescriptor = fileDescriptor;

    return hijacker;
} // hijackerWithFd


// This is the unixy-core-foundationy dirty work.
- (void) startHijacking {
    if (self.hijacking) return;

    // Unix API is of the "return bad value, set errno" flavor.
    int result;

    // Make the pipe.  Anchor one end of the pipe where the original fd is.
    // The other end will go to a runloop source so we can find bytes written to it.
    result = pipe (_pipe);
    if (result == -1) {
        assert (!"could not make a pipe for standard out");
        return;
    }

    // Make a copy of the file descriptor.  The dup2 will close it, but we want it
    // to stick around for restoration and replication.
    self.oldFileDescriptor = dup (self.fileDescriptor);
    if (self.oldFileDescriptor == -1) {
        assert (!"could not dup our fd");
        return;
    }

    // Replace the file descriptor with one part (the writing side) of the pipe.
    result = dup2 (_pipe[kWriteSide], self.fileDescriptor);
    if (result == -1) {
        assert (!"could not dup2 our fd");
        return;
    }

    // Monitor the reading side of the pipe.
    [self startMonitoringFileDescriptor: _pipe[kReadSide]];

    self.hijacking = YES;
} // startHijacking


// Undo the damage we did.

- (void) stopHijacking {
    if (!self.hijacking) return;

    int result;

    // Replace the file descriptor, which was our pipe, with the original one.
    // This closes the pipe.
    result = dup2 (self.oldFileDescriptor, self.fileDescriptor);
    if (result == -1) {
        assert (!"could not dup2 back");
        return;
    }

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


// We got some text!  Tell the delegate.
- (void) notifyString: (NSString *) contents {
    [self.delegate hijacker: self  gotText: contents];
} // notifyString


// --------------------------------------------------
// The heavy lifting


// Callback function, invoked when new data has been read from our pipe.
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


// Add the file descriptor to the runloop for notification.
- (void) startMonitoringFileDescriptor: (int) fd {
    CFSocketContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    CFSocketRef socketRef = CFSocketCreateWithNative (kCFAllocatorDefault,
                                                      fd,
                                                      kCFSocketDataCallBack,
                                                      ReceiveMessage,
                                                      &context);
    if (socketRef == NULL) {
        NSLog (@"couldn't make cfsocket");
        goto bailout;
    }
    
    _monitorRunLoopSource =
        CFSocketCreateRunLoopSource(kCFAllocatorDefault, socketRef, 0);
    CFRelease (socketRef);

    if (_monitorRunLoopSource == NULL) {
        NSLog (@"couldn't create run loop source");
        goto bailout;
    }
    
    CFRunLoopAddSource (CFRunLoopGetCurrent(), _monitorRunLoopSource,
                        kCFRunLoopDefaultMode);

bailout: 
    return;

} // startMonitoringFileDescriptor


// Remove the file descriptor from monitoring.
- (void) stopMonitoring {
    CFRunLoopRemoveSource (CFRunLoopGetCurrent(), _monitorRunLoopSource,
                           kCFRunLoopDefaultMode);
    CFRelease (_monitorRunLoopSource);
    _monitorRunLoopSource = NULL;

} // stopMonitoring

@end // XXFdHijacker
