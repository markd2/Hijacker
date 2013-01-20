#import "XXViewController.h"

#import <QuartzCore/QuartzCore.h>  // For layer styles

#import "XXFdHijacker.h"


@interface XXViewController () <XXFdHijackerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *loggingView;
@property (strong, nonatomic) XXFdHijacker *stdoutHijacker;
@property (strong, nonatomic) XXFdHijacker *stderrHijacker;

@property (strong, nonatomic) NSMutableString *contents;

@end

@implementation XXViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.loggingView.layer.borderWidth = 1.0f;
    self.loggingView.layer.borderColor = [UIColor blackColor].CGColor;

    self.stdoutHijacker = [XXFdHijacker hijackerWithFd: 0];
    self.stdoutHijacker.delegate = self;

    self.stderrHijacker = [XXFdHijacker hijackerWithFd: 1];
    self.stderrHijacker.delegate = self;

    self.contents = [NSMutableString string];

} // viewDidLoad


- (IBAction) toggleHijack: (UISwitch *) toggle {
    if (toggle.on) {
        [self.stdoutHijacker startHijacking];
        [self.stderrHijacker startHijacking];
    } else {
        [self.stdoutHijacker stopHijacking];
        [self.stderrHijacker stopHijacking];
    }

} // toggleHijack


- (IBAction) toggleReplicate: (UISwitch *) toggle {
    if (toggle.on) {
        [self.stdoutHijacker startReplicating];
        [self.stderrHijacker startReplicating];
    } else {
        [self.stdoutHijacker stopReplicating];
        [self.stderrHijacker stopReplicating];
    }

} // toggleReplicate


- (IBAction) log: (UIButton *) button {
    NSLog (@"ALL KIDS LOVE LOG");
} // log


- (IBAction) throw: (UIButton *) button {
    // Wonder if we can have UIApplication print out its exception trace, but not exit?
    [@[] objectAtIndex: 0];
} // throw


- (void) scrollToEnd {
    NSRange range = NSMakeRange (self.contents.length, 0);
    [self.loggingView scrollRangeToVisible: range];
} // scrollToEnd


- (void) hijacker: (XXFdHijacker *) hijacker  gotText: (NSString *) text {
    if (hijacker == self.stdoutHijacker) [self.contents appendString: @"stdout: "];
    if (hijacker == self.stderrHijacker) [self.contents appendString: @"stderr: "];

    [self.contents appendString: text];
    [self.contents appendString: @"\n"];
    self.loggingView.text = self.contents;
    [self scrollToEnd];
} // hijacker

@end // XXViewController
