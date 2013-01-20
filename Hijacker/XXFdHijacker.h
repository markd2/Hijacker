#import <Foundation/Foundation.h>

@protocol XXFdHijackerDelegate;


@interface XXFdHijacker : NSObject

+ (id) hijackerWithFd: (int) fileDescriptor;

@property (weak, nonatomic) id <XXFdHijackerDelegate> delegate;
@property (readonly, assign, nonatomic) int fileDescriptor;

- (void) startHijacking;
- (void) stopHijacking;

- (void) startReplicating;
- (void) stopReplicating;

@end // XXFdHijacker


@protocol XXFdHijackerDelegate

- (void) hijacker: (XXFdHijacker *) hijacker  gotText: (NSString *) text;

@end // XXFdHijackerDelegate
