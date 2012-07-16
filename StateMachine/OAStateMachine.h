#import <Foundation/Foundation.h>

@class OAStateMachine;
@protocol OAStateMachineDelegate <NSObject>
@optional
- (void) stateMachine:(OAStateMachine*)sm willTransitionFromState:(NSArray*)state animated:(BOOL)animated;
- (void) stateMachine:(OAStateMachine*)sm willExitState:(NSString*)stateName animated:(BOOL)animated;
- (void) stateMachine:(OAStateMachine*)sm didEnterState:(NSString*)stateName animated:(BOOL)animated;
- (void) stateMachine:(OAStateMachine*)sm didTransitionToState:(NSArray*)state animated:(BOOL)animated;
@end

// OAStateMachine keeps track of a stack of named states and sends its delegate messages in a form willExitState and didEnterState when transitions occur.
//
// Callback selectors:
// - (void) didEnterState;
// - (void) didEnterStateAnimated:(BOOL)animated;
// - (void) didEnterState:(OAStateMachine*)sender;
// - (void) didEnterState:(OAStateMachine*)sender animated:(BOOL)animated;
// - (void) willExitState;
// - (void) willExitStateAnimated:(BOOL)animated;
// - (void) willExitState:(OAStateMachine*)sender;
// - (void) willExitState:(OAStateMachine*)sender animated:(BOOL)animated;
// 
// OAStateMachine looks for the longest version of a selector. If more than one possible callback is found, a warning is logged.
// If OA_STATE_MACHINE_THROW_ON_MULTIPLE_SELECTORS is 1, the exception is thrown.
//
// If OA_STATE_MACHINE_LOG_MISSED_CALLBACKS is 1, state machine warns when state is entered or exited without a callback.
// 
// Notes:
// 1. Wherever state argument is typed as "id", it could be either NSString or NSArray. NSString is always interpreted as a NSArray containing the string.
// 2. To exit all states, use [obj transitionToState:nil].
// 3. 

@interface OAStateMachine : NSObject

@property(nonatomic, assign) id<OAStateMachineDelegate> delegate; // receiver for willExitState and didEnterState


- (NSArray*)  currentState;      // empty array for no state, single-item array for a simple state without nesting.
- (NSArray*)  previousState;     // relevant during didEnterState callback. When called outside, throws an exception.
- (NSArray*)  nextState;         // relevant during willExitState callback. When called outside, throws an exception.

- (NSString*) currentStateName;  // if nil, there is not state.
- (NSString*) previousStateName; // relevant during didEnterState callback. When called outside, throws an exception.
- (NSString*) nextStateName;     // relevant during willExitState callback. When called outside, throws an exception.

// Returns YES if currently in exactly the requested state. If string is given, it is interpreted as a one-item array.
// If state is nil, returns YES if the stack is empty.
- (BOOL) isInState:(id)state;

// Returns YES if the state is contained within the state stack. That is [B, C] is within [A, B, C, D].
// If state is nil, returns YES if the stack is empty.
- (BOOL) isWithinState:(id)state;

// Unconditionally transitions to a new state or state stack. Returns NO if already in that state (transition does not occur).
- (BOOL) transitionToState:(id)state;
- (BOOL) transitionToState:(id)state animated:(BOOL)animated;

// Transitions only if already in the given state.
- (BOOL) transitionFromState:(id)state1 toState:(id)state2 animated:(BOOL)animated;

@end
