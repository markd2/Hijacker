#import "XXViewController.h"

#import <QuartzCore/QuartzCore.h>  // For layer styles

#import "XXFdHijacker.h"


@interface XXViewController () <XXFdHijackerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *loggingView;

@property (strong, nonatomic) XXFdHijacker *stdoutHijacker;
@property (strong, nonatomic) XXFdHijacker *stderrHijacker;

@property (strong, nonatomic) NSMutableString *contents;

@end // extension


@implementation XXViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // Add a border around the text view.
    self.loggingView.layer.borderWidth = 1.0f;
    self.loggingView.layer.borderColor = [UIColor blackColor].CGColor;

    // Hijack standard out.
    self.stdoutHijacker = [XXFdHijacker hijackerWithFd: fileno(stdout)];
    setbuf (stdout, NULL);
    self.stdoutHijacker.delegate = self;
    [self.stdoutHijacker startHijacking];
    [self.stdoutHijacker startReplicating];

    // Hijack standard error
    self.stderrHijacker = [XXFdHijacker hijackerWithFd: fileno(stderr)];
    setbuf (stderr, NULL);
    self.stderrHijacker.delegate = self;
    [self.stderrHijacker startHijacking];
    [self.stderrHijacker startReplicating];

    self.contents = [NSMutableString string];

    NSLog (@"All Kids Love Log");

} // viewDidLoad


- (IBAction) toggleHijack: (UISwitch *) toggle {
    if (toggle.on) {
        if (toggle.tag == 0) [self.stdoutHijacker startHijacking];
        if (toggle.tag == 1) [self.stderrHijacker startHijacking];
    } else {
        if (toggle.tag == 0) [self.stdoutHijacker stopHijacking];
        if (toggle.tag == 1) [self.stderrHijacker stopHijacking];
    }

} // toggleHijack


- (IBAction) toggleReplicate: (UISwitch *) toggle {
    if (toggle.on) {
        if (toggle.tag == 0) [self.stdoutHijacker startReplicating];
        if (toggle.tag == 1) [self.stderrHijacker startReplicating];
    } else {
        if (toggle.tag == 0) [self.stdoutHijacker stopReplicating];
        if (toggle.tag == 1) [self.stderrHijacker stopReplicating];
    }

} // toggleReplicate


- (IBAction) log: (UIButton *) button {
    // Print out stuff
    NSLog (@"All Kids Love Log!");
    printf ("all kds lv lg!\n");
} // log


- (IBAction) toolkitGripes: (UIButton *) button {
    // Force the toolkit to gripe.
    void *ook = malloc (13);
    free (ook);
    free (ook);
} // toolkitGripes


- (IBAction) clearTextfield: (UIButton *) button {
    self.contents = [NSMutableString string];
    self.loggingView.text = self.contents;
    [self scrollToEnd];
} // clearTextfield


- (void) scrollToEnd {
    NSRange range = NSMakeRange (self.contents.length, 0);
    [self.loggingView scrollRangeToVisible: range];
} // scrollToEnd


- (void) hijacker: (XXFdHijacker *) hijacker  gotText: (NSString *) text {
    if (hijacker == self.stdoutHijacker) [self.contents appendString: @"stdout: "];
    if (hijacker == self.stderrHijacker) [self.contents appendString: @"stderr: "];

    [self.contents appendString: text];
    self.loggingView.text = self.contents;
    [self scrollToEnd];
} // hijacker

@end // XXViewController
