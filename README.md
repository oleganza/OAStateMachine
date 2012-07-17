

OAStateMachine (work in progress)
=================================

Provides state machine functionality with support of animated transitions and nested states.
It *does not require* a static definition of possible states and a matrix of transitions.
Instead, it dynamically builds willExit* and didEnter* callbacks based on actual state names.
You are free to define the callbacks you actually need with or without a sender argument and "animated:" suffix.

For "myState" string these selectors are supported.

<pre>
- (void) didEnterMyState;
- (void) didEnterMyStateAnimated:(BOOL)animated;
- (void) didEnterMyState:(OAStateMachine*)sender;
- (void) didEnterMyState:(OAStateMachine*)sender animated:(BOOL)animated;
- (void) willExitMyState;
- (void) willExitMyStateAnimated:(BOOL)animated;
- (void) willExitMyState:(OAStateMachine*)sender;
- (void) willExitMyState:(OAStateMachine*)sender animated:(BOOL)animated;
</pre>

If for "didEnter" or "willExit" multiple selectors are implemented, 
OAStateMachine will only use the longest one and issue a warning about duplicates.

To transition to nested states, use NSArray of state names instead of a single NSString state name.

If you want, you may list all possible states as string constants and indent according to their hierarchy.

For simultaneous independent states create multiple state machine instances with the same delegate.

OAStateMachine is not thread-safe. You should synchronize access manually, or use it on a thread you created it on.


Example
-------

<pre>
- (void) willExitPlaying
{
	playButton.enabled = YES;
}

- (void) didEnterPlayingAnimated:(BOOL)animated
{
	playButton.enabled = NO;
	[stream start];
	[self displayLyricsAnimated:animated];
}

- (void) willExitPause
{
	pauseButton.enabled = YES;
}

- (void) didEnterPause
{
	pauseButton.enabled = NO;
	[stream stop];
}

- (void) play:(id)sender
{
	[stateMachine transitionToState:@"play" animated:YES];
}

- (void) pause:(id)sender
{
	[stateMachine transitionToState:@"pause" animated:YES];
}
</pre>




