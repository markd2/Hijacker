#import "XXFdHijacker.h"

@interface XXFdHijacker ()
@property (assign, nonatomic) int fileDescriptor;  // turn of read-onlyibility
@end // extension



@implementation XXFdHijacker

+ (id) hijackerWithFd: (int) fileDescriptor {
    XXFdHijacker *hijacker = [[[self class] alloc] init];
    hijacker.fileDescriptor = fileDescriptor;

    return hijacker;
} // hijackerWithFd


- (void) startHijacking {
    [self notifyString: @"startHijacking"];
} // startHijacking


- (void) stopHijacking {
    [self notifyString: @"stopHijacking"];

} // stopHijacking


- (void) startReplicating {
    [self notifyString: @"startReplicating"];

} // startReplicating


- (void) stopReplicating {
    [self notifyString: @"stopReplicating"];

} // stopReplicating


- (void) notifyString: (NSString *) contents {
    [self.delegate hijacker: self  gotText: contents];
} // notifyString

@end // XXFdHijacker
