#import "OAStateMachine.h"
#import <objc/message.h>

@interface OAStateMachineStateSelectors : NSObject {
	@public
	SEL didEnterState;
	SEL didEnterStateAnimated_;
	SEL didEnterState_;
	SEL didEnterState_animated_;
	SEL willExitState;
	SEL willExitStateAnimated_;
	SEL willExitState_;
	SEL willExitState_animated_;
}
@end
@implementation OAStateMachineStateSelectors
@end



/////////////////////////////////////////////////////////////////////////////////



@implementation OAStateMachine {
	NSMutableArray* _state;
	NSMutableDictionary* _selectorsByState; // {"stateName" => OAStateMachineStateSelectors}
	NSArray* _previousState;
	NSArray* _nextState;
	BOOL _inTransition;
}

@synthesize delegate=_delegate;

- (id) init
{
	if (self = [super init])
	{
		_state = [[NSMutableArray array] retain];
		_selectorsByState = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void)dealloc
{
    [_state release];
	[_selectorsByState release];
	[_previousState release];
	[_nextState release];
    [super dealloc];
}

- (NSArray*)  currentState
{
	return [[_state copy] autorelease];
}

- (NSArray*)  previousState     // relevant during didEnterState callback. When called outside, throws an exception.
{
	if (!_inTransition)
	{
		@throw [NSException exceptionWithName:@"[OAStateMachine previousState] cannot be accessed outside of transition (willExitState/didEnterState)." reason:@"Cannot use previousState." userInfo:nil];
	}

	return [[_previousState retain] autorelease];
}

- (NSArray*)  nextState         // relevant during willExitState callback. When called outside, throws an exception.
{
	if (!_inTransition)
	{
		@throw [NSException exceptionWithName:@"[OAStateMachine nextState] cannot be accessed outside of transition (willExitState/didEnterState)." reason:@"Cannot use nextState." userInfo:nil];
	}
	
	return [[_nextState retain] autorelease];
}


- (NSString*) currentStateName
{
	return [_state lastObject];
}

- (NSString*) previousStateName
{
	return [_previousState lastObject];
}

- (NSString*) nextStateName
{
	return [_nextState lastObject];
}

// Returns YES if currently in exactly the requested state. If string is given, it is interpreted as a one-item array.
- (BOOL) isInState:(id)state
{
	if (!state) return _state.count == 0;
	
	if ([state isKindOfClass:[NSString class]]) return _state.count == 1 && [[_state objectAtIndex:0] isEqual:state];
	
	return [_state isEqualToArray:state];
}

// Returns YES if the state is contained within the state stack. That is [B, C] is within [A, B, C, D].
- (BOOL) isWithinState:(id)state
{
	if (!state) return _state.count == 0;
	
	if ([state isKindOfClass:[NSString class]]) return [_state containsObject:state];
	
	if ([state count] == 0) return [_state count] == 0;
	
	if ([state count] <= _state.count)
	{
		NSUInteger previndex = NSNotFound;
		for (NSString* st in state)
		{
			NSUInteger j = [_state indexOfObject:st];
			if (j == NSNotFound) return NO;
			if (previndex == NSNotFound)
			{
				previndex = j;
			}
			else
			{
				// Should be the next index after the previous one.
				if (previndex + 1 != j) return NO;
				previndex = j;
			}
		}
		return YES;
	}
	return NO;
}

// Unconditionally transitions to a new state or state stack. Returns NO if already in that state (transition does not occur).
- (BOOL) transitionToState:(id)state
{
	return [self transitionToState:state animated:NO];
}

- (BOOL) transitionFromState:(id)state1 toState:(id)state2 animated:(BOOL)animated
{
	if ([self isInState:state1])
	{
		return [self transitionToState:state2 animated:animated];
	}
	return NO;
}

- (BOOL) transitionToState:(id)state animated:(BOOL)animated
{
	if ([self isInState:state]) return NO;
	
	NSArray* nextState = state;
	
	if (!nextState)
	{
		nextState = [NSArray array];
	}
	if ([nextState isKindOfClass:[NSString class]])
	{
		nextState = [NSArray arrayWithObject:state];
	}
	
	// Previous state: A B C D E
	// Next state:     A B X Y
	
	// 1. Set previousState to A B C D E and nextState to A B X Y.
	// 2. Find common prefix (A B).
	// 3. Exit E, then D, then C.
	// 4. Switch to new state.
	// 5. Enter X, then Y.
	// 6. Clear previousState and nextState.
	
	
	// 1. Set previous and next states.
	
	[_previousState release]; _previousState = nil;
	_previousState = [_state copy];
	[_nextState release]; _nextState = nil;
	_nextState = [nextState copy];
	
	_inTransition = YES;
	
	
	// 2. Find common states.
	
	NSUInteger startingIndex = 0;
	
	for (NSUInteger i = 0;
		 i < _previousState.count && i < _nextState.count; 
		 i++)
	{
		id s1 = [_previousState objectAtIndex:i];
		id s2 = [_nextState objectAtIndex:i];
		
		if ([s1 isEqual:s2])
		{
			startingIndex = i + 1;
		}
		else
		{
			break;
		}
	}

	
	// 3. Exit necessary states.
	
	if ([_delegate respondsToSelector:@selector(stateMachine:willTransitionFromState:animated:)])
	{
		[_delegate stateMachine:self willTransitionFromState:_previousState animated:animated];
	}
	
	if (_previousState.count > 0)
	{
		for (NSUInteger i = _previousState.count - 1; i >= startingIndex; i--)
		{
			id sn = [_previousState objectAtIndex:i];
			if ([_delegate respondsToSelector:@selector(stateMachine:willExitState:animated:)])
			{
				[_delegate stateMachine:self willExitState:sn animated:animated];
			}
			[self notifyDelegateForTransition:-1 state:sn animated:animated];
			if (i == 0) break;
		}
	}
	
	// 4. Switch to new state.
	
	[_state release]; _state = nil;
	_state = [_nextState mutableCopy];

	
	// 5. Enter new states.
	
	for (NSUInteger i = startingIndex; i < _nextState.count; i++)
	{
		id sn = [_nextState objectAtIndex:i];
		[self notifyDelegateForTransition:+1 state:sn animated:animated];
		if ([_delegate respondsToSelector:@selector(stateMachine:didEnterState:animated:)])
		{
			[_delegate stateMachine:self didEnterState:sn animated:animated];
		}
	}
	
	if ([_delegate respondsToSelector:@selector(stateMachine:didTransitionToState:animated:)])
	{
		[_delegate stateMachine:self didTransitionToState:_nextState animated:animated];
	}	
	
	// 6. Clear previousState and nextState.
	
	_inTransition = NO;
	[_previousState release]; _previousState = nil;
	[_nextState release]; _nextState = nil;
	
	return YES;
}



- (NSString*) capitalizedWordForString:(NSString*)string
{
	if (string.length < 1) return string;
	NSString* firstLetter = [[string substringToIndex:1] uppercaseString];
	return [firstLetter stringByAppendingString:[string substringFromIndex:1]];
}

- (void) notifyDelegateForTransition:(int)direction state:(NSString*)stateName animated:(BOOL)animated
{
	OAStateMachineStateSelectors* selectorsObject = [_selectorsByState objectForKey:stateName];
	
	if (!selectorsObject)
	{
		selectorsObject = [[[OAStateMachineStateSelectors alloc] init] autorelease];
		id capitalizedState = [self capitalizedWordForString:stateName];
		selectorsObject->willExitState           = NSSelectorFromString([NSString stringWithFormat:@"willExit%@", capitalizedState]);
		selectorsObject->willExitState_          = NSSelectorFromString([NSString stringWithFormat:@"willExit%@:", capitalizedState]);
		selectorsObject->willExitStateAnimated_  = NSSelectorFromString([NSString stringWithFormat:@"willExit%@Animated:", capitalizedState]);
		selectorsObject->willExitState_animated_ = NSSelectorFromString([NSString stringWithFormat:@"willExit%@:animated:", capitalizedState]);
		selectorsObject->didEnterState           = NSSelectorFromString([NSString stringWithFormat:@"didEnter%@", capitalizedState]);
		selectorsObject->didEnterState_          = NSSelectorFromString([NSString stringWithFormat:@"didEnter%@:", capitalizedState]);
		selectorsObject->didEnterStateAnimated_  = NSSelectorFromString([NSString stringWithFormat:@"didEnter%@Animated:", capitalizedState]);
		selectorsObject->didEnterState_animated_ = NSSelectorFromString([NSString stringWithFormat:@"didEnter%@:animated:", capitalizedState]);
		[_selectorsByState setObject:selectorsObject forKey:stateName];
	}
	
	SEL selectors[] = {NULL, NULL, NULL, NULL};
	
	if (direction == -1)
	{
		selectors[0] = selectorsObject->willExitState_animated_;
		selectors[1] = selectorsObject->willExitStateAnimated_;
		selectors[2] = selectorsObject->willExitState_;
		selectors[3] = selectorsObject->willExitState;
	}
	else
	{
		selectors[0] = selectorsObject->didEnterState_animated_;
		selectors[1] = selectorsObject->didEnterStateAnimated_;
		selectors[2] = selectorsObject->didEnterState_;
		selectors[3] = selectorsObject->didEnterState;
	}
	
	SEL foundSelector = NULL;
	
	for (int i = 0; i < 4; i++)
	{
		if ([_delegate respondsToSelector:selectors[i]])
		{
			if (foundSelector == NULL)
			{
				foundSelector = selectors[i];
				if (i == 0) // didEnterState:(id) animated:(BOOL)
				{
					void (*objc_msgSendTyped)(id self, SEL _cmd, id sender, BOOL animated) = (void*)objc_msgSend;
					objc_msgSendTyped(self.delegate, foundSelector, self, animated);
				}
				else if (i == 1) // didEnterStateAnimated:(BOOL)
				{
					void (*objc_msgSendTyped)(id self, SEL _cmd, BOOL animated) = (void*)objc_msgSend;
					objc_msgSendTyped(self.delegate, foundSelector, animated);
				}
				else if (i == 2) // didEnterState:(id)
				{
					[_delegate performSelector:foundSelector withObject:self];
				}
				else if (i == 3) // didEnterState
				{
					[_delegate performSelector:foundSelector];
				}
			}
			else // found another selector
			{
				NSLog(@"WARNING: OAStateMachine found duplicate selector '%@', already called '%@'", NSStringFromSelector(selectors[i]), NSStringFromSelector(foundSelector));
#if OA_STATE_MACHINE_THROW_ON_MULTIPLE_SELECTORS
				@throw [NSException exceptionWithName:@"OAStateMachine Duplicate Selector" 
											   reason:[NSString stringWithFormat:@"Found duplicate selector '%@', already called '%@'", NSStringFromSelector(selectors[i]), NSStringFromSelector(foundSelector)] 
											 userInfo:nil];
#endif
			}
		}
	}
	
	if (!foundSelector)
	{
#if OA_STATE_MACHINE_LOG_MISSED_CALLBACKS
		NSLog(@"WARNING: OAStateMachine could not find selector '%@' or similar.", NSStringFromSelector(selectors[3]));
#endif
	}
}


@end


