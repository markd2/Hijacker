#import "XXViewController.h"

#import <QuartzCore/QuartzCore.h>  // For layer styles


@interface XXViewController ()

@property (weak, nonatomic) IBOutlet UITextView *loggingView;

@end

@implementation XXViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.loggingView.layer.borderWidth = 1.0f;
    self.loggingView.layer.borderColor = [UIColor blackColor].CGColor;

    NSSetUncaughtExceptionHandler (CatchUncaught);

} // viewDidLoad


- (IBAction) toggleHijack: (UISwitch *) toggle {
    NSLog (@"HIJACK TOGGLE");
} // toggleHijack


- (IBAction) toggleReplicate: (UISwitch *) toggle {
    NSLog (@"REPLICATE TOGGLE");
} // toggleReplicate


- (IBAction) log: (UIButton *) button {
    NSLog (@"ALL KIDS LOVE LOG");
} // log


- (IBAction) throw: (UIButton *) button {
    // Wonder if we can have UIApplication print out its exception trace, but not exit?
    [@[] objectAtIndex: 0];
} // throw

@end // XXViewController
