#import "SMViewController.h"
#import "OAStateMachine.h"

@interface SMViewController ()<OAStateMachineDelegate>
@property (retain, nonatomic) IBOutlet UILabel *stateLabel;
@property (retain, nonatomic) OAStateMachine* stateMachine;
@property (retain, nonatomic) IBOutlet UIButton *beginLoadingButton;
@property (retain, nonatomic) IBOutlet UIButton *finishLoadingButton;
@property (retain, nonatomic) IBOutlet UIButton *failedLoadingButton;
@property (retain, nonatomic) IBOutlet UIButton *startBuyingButton;
@property (retain, nonatomic) IBOutlet UIButton *finishBuyingButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;
@end

@implementation SMViewController
@synthesize stateLabel=_stateLabel;
@synthesize stateMachine=_stateMachine;
@synthesize beginLoadingButton = _beginLoadingButton;
@synthesize finishLoadingButton = _finishLoadingButton;
@synthesize failedLoadingButton = _failedLoadingButton;
@synthesize startBuyingButton = _startBuyingButton;
@synthesize finishBuyingButton = _finishBuyingButton;
@synthesize cancelButton = _cancelButton;

- (void)dealloc
{
	[_stateLabel release];
	[_stateMachine release];
	[_beginLoadingButton release];
	[_finishLoadingButton release];
	[_failedLoadingButton release];
	[_startBuyingButton release];
	[_finishBuyingButton release];
	[_cancelButton release];
	[super dealloc];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
		self.stateMachine = [[[OAStateMachine alloc] init] autorelease];
		self.stateMachine.delegate = self;
	}
	return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
	[self setStateLabel:nil];
	[self setBeginLoadingButton:nil];
	[self setFinishLoadingButton:nil];
	[self setFailedLoadingButton:nil];
	[self setStartBuyingButton:nil];
	[self setFinishBuyingButton:nil];
	[self setCancelButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.stateMachine transitionFromState:nil toState:@"idle" animated:animated];
}






#pragma mark - State Machine



- (void) willExitIdle:(OAStateMachine*)sm
{
	
}

- (void) didEnterIdleAnimated:(BOOL)animated
{
	[self.beginLoadingButton setEnabled:YES];
	[self.finishLoadingButton setEnabled:NO];
	[self.failedLoadingButton setEnabled:NO];
	
	[self.startBuyingButton setEnabled:NO];
	[self.finishBuyingButton setEnabled:NO];
	[self.cancelButton setEnabled:NO];
}

- (void) didEnterLoading
{
	[self.beginLoadingButton setEnabled:NO];
	[self.finishLoadingButton setEnabled:YES];
	[self.failedLoadingButton setEnabled:YES];

	// Generic cancellation UI.
	[self.cancelButton setEnabled:YES];
}

- (void) willExitReady
{
	self.startBuyingButton.enabled = NO;
}

- (void) didEnterReady
{
	[self.beginLoadingButton setEnabled:NO];
	[self.finishLoadingButton setEnabled:NO];
	[self.failedLoadingButton setEnabled:NO];
	
	// Here we can use another state machine for buying and transition to "BuyingReady" state.
	// Or we can just use nested states.
	[self.startBuyingButton setEnabled:YES];
}

- (void) didEnterBuying
{
	self.finishBuyingButton.enabled = YES;
}

- (void) willExitBuying
{
	self.finishBuyingButton.enabled = YES;
}




#pragma mark - State Machine Debugging



- (void) stateMachine:(OAStateMachine*)sm willExitState:(NSString*)stateName animated:(BOOL)animated
{
	NSLog(@"VC: will exit '%@' animated:%@", stateName, animated ? @"YES" : @"NO");
}

- (void) stateMachine:(OAStateMachine*)sm didEnterState:(NSString*)stateName animated:(BOOL)animated
{
	NSLog(@"VC: did enter '%@' animated:%@", stateName, animated ? @"YES" : @"NO");
	
	_stateLabel.text = [_stateMachine.currentState componentsJoinedByString:@" ⊂ "];
	if (animated)
	{
		_stateLabel.alpha = 0;
		[UIView animateWithDuration:0.3 animations:^{
			_stateLabel.alpha = 1;
		}];
	}
}





#pragma mark - Actions




- (IBAction)beginLoading:(id)sender {
	[self.stateMachine transitionToState:@"loading" animated:YES];
}

- (IBAction)finishLoading:(id)sender {
	[self.stateMachine transitionToState:@"ready" animated:YES];
}

- (IBAction)failLoading:(id)sender {
	[self.stateMachine transitionToState:@"idle"];
}

- (IBAction)startBuying:(id)sender {
	[self.stateMachine transitionToState:[NSArray arrayWithObjects:@"ready", @"buying", nil] animated:YES];
}

- (IBAction)finishBuying:(id)sender {
	[self.stateMachine transitionToState:@"idle"];
	[[[[UIAlertView alloc] initWithTitle:@"Thank you!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
}

- (IBAction)cancel:(id)sender {
	[self.stateMachine transitionToState:@"idle"];
}


@end
