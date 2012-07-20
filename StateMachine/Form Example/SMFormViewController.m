#import "SMFormViewController.h"
#import "OAStateMachine.h"


// States

#define kFormIdle             @"formIdle"
#define kFormUploading        @"formUploading"
#define kFormFailed           @"formFailed"
#define kFormFailWhenVisible  @"formFailWhenVisible"
#define kFormFinished         @"formFinished"

#define kLoaderIdle             @"loaderIdle"
#define kLoaderConfigLoading    @"loaderConfigLoading"
#define kLoaderConfigFailed     @"loaderConfigFailed"
#define kLoaderConfigLoaded     @"loaderConfigLoaded"
#define kLoaderUploadInProgress @"loaderUploadInProgress"


@interface SMFormViewController () <OAStateMachineDelegate>
@property (retain, nonatomic) IBOutlet UILabel *formStateLabel;
@property (retain, nonatomic) IBOutlet UIButton *formSubmitButton;
@property (retain, nonatomic) IBOutlet UIButton *formCancelButton;
@property (retain, nonatomic) IBOutlet UIButton *formTryAgainButton;
@property (retain, nonatomic) IBOutlet UIButton *formShowHideButton;

@property (retain, nonatomic) IBOutlet UILabel *loaderStateLabel;
@property (retain, nonatomic) IBOutlet UIButton *configLoadButton;
@property (retain, nonatomic) IBOutlet UIButton *configFailedButton;
@property (retain, nonatomic) IBOutlet UIButton *configLoadedButton;
@property (retain, nonatomic) IBOutlet UIButton *uploadFailedButton;
@property (retain, nonatomic) IBOutlet UIButton *uploadFinishedButton;

@end

@implementation SMFormViewController {
	OAStateMachine* _formStateMachine;
	OAStateMachine* _loaderStateMachine;
	BOOL _formVisible;
}

@synthesize formStateLabel;
@synthesize formSubmitButton;
@synthesize formCancelButton;
@synthesize formTryAgainButton;
@synthesize formShowHideButton;
@synthesize loaderStateLabel;
@synthesize configLoadButton;
@synthesize configFailedButton;
@synthesize configLoadedButton;
@synthesize uploadFailedButton;
@synthesize uploadFinishedButton;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
		_formStateMachine   = [[OAStateMachine alloc] init];
		_formStateMachine.delegate = self;
		_loaderStateMachine = [[OAStateMachine alloc] init];
		_loaderStateMachine.delegate = self;
	}
	return self;
}


- (void)dealloc {
	[_formStateMachine release];
	[_loaderStateMachine release];
	[formStateLabel release];
	[formSubmitButton release];
	[formCancelButton release];
	[formTryAgainButton release];
	[formShowHideButton release];
	[loaderStateLabel release];
	[configLoadButton release];
	[configFailedButton release];
	[configLoadedButton release];
	[uploadFailedButton release];
	[uploadFinishedButton release];
	[super dealloc];
}
- (void)viewDidUnload {
	[self setFormStateLabel:nil];
	[self setFormSubmitButton:nil];
	[self setFormCancelButton:nil];
	[self setFormTryAgainButton:nil];
	[self setFormShowHideButton:nil];
	[self setLoaderStateLabel:nil];
	[self setConfigLoadButton:nil];
	[self setConfigFailedButton:nil];
	[self setConfigLoadedButton:nil];
	[self setUploadFailedButton:nil];
	[self setUploadFinishedButton:nil];
	[super viewDidUnload];
}


- (void) viewDidAppear:(BOOL)animated
{
	[_formStateMachine   transitionFromState:nil toState:kFormIdle   animated:animated];
	[_loaderStateMachine transitionFromState:nil toState:kLoaderIdle animated:animated];
	_formVisible = NO;
}


#pragma mark - Form Events


- (IBAction)formSubmit:(id)sender {
	[_formStateMachine transitionToState:kFormUploading];
	
}

- (IBAction)formCancel:(id)sender {
	[_formStateMachine transitionToState:kFormIdle];
}

- (IBAction)formTryAgain:(id)sender {
	[self formSubmit:sender];
}

- (IBAction)formShow:(id)sender {
	_formVisible = YES;
	[formShowHideButton setTitle:@"Hide Form" forState:UIControlStateNormal];
	[formShowHideButton removeTarget:self action:_cmd forControlEvents:UIControlEventTouchUpInside];
	[formShowHideButton addTarget:self   action:@selector(formHide:) forControlEvents:UIControlEventTouchUpInside];
	
	// If pending error, show it.
	[_formStateMachine transitionFromState:kFormFailWhenVisible toState:kFormFailed animated:YES];
}

- (IBAction)formHide:(id)sender {
	_formVisible = NO;
	[formShowHideButton setTitle:@"Show Form" forState:UIControlStateNormal];
	[formShowHideButton removeTarget:self action:_cmd forControlEvents:UIControlEventTouchUpInside];
	[formShowHideButton addTarget:self   action:@selector(formShow:) forControlEvents:UIControlEventTouchUpInside];
}



#pragma mark - Form States


- (void) didEnterFormIdleAnimated:(BOOL)animated
{
	self.formStateLabel.text        = @"Idle";
	self.formSubmitButton.enabled   = YES;
	self.formCancelButton.enabled   = NO;
	self.formTryAgainButton.enabled = NO;
	self.formShowHideButton.enabled = NO;
}

- (void) willExitFormIdleAnimated:(BOOL)animated
{
	self.formSubmitButton.enabled = NO;
}




#pragma mark - Form Loader Delegate (called by Loader)


- (void) loaderDelegateFailedWithError:(NSString*)error
{
	
}

- (void) loaderDelegateDidFinish:(NSString*)message
{
	
}





////////////////////////////////////////////////////////////////////////////





#pragma mark - Loader API (called by Form)


- (void) loaderUpload
{
	
}




#pragma mark - Loader Events (happen internally in a loader)


- (IBAction)configLoad:(id)sender {
}

- (IBAction)configFailed:(id)sender {
}

- (IBAction)configLoaded:(id)sender {
}

- (IBAction)uploadFailed:(id)sender {
}

- (IBAction)uploadFinished:(id)sender {
}



#pragma mark - Loader States








////////////////////////////////////////////////////////////////////////////





#pragma mark - State Machine Debugging



- (void) stateMachine:(OAStateMachine*)sm willExitState:(NSString*)stateName animated:(BOOL)animated
{
	NSLog(@"VC: will exit '%@' animated:%@", stateName, animated ? @"YES" : @"NO");
}

- (void) stateMachine:(OAStateMachine*)sm didEnterState:(NSString*)stateName animated:(BOOL)animated
{
	NSLog(@"VC: did enter '%@' animated:%@", stateName, animated ? @"YES" : @"NO");
}


@end
