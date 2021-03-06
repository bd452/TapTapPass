#import <libactivator/libactivator.h>
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
BOOL passActive = YES;
BOOL Unlocking = NO;
//BOOL ALXT_Enabled = NO;
BOOL reversed;

@interface SBAwayController
- (BOOL)isLocked;
- (void)_finishedUnlockAttemptWithStatus:(BOOL)fp8;
@end

@interface SBDeviceLockController
- (BOOL)isPasswordProtected;
@end

//AndroidLockXT

/*@interface AndroidLockView
- (BOOL)isPatternRequired;
@end
*/

@interface SBUIController
- (void)lockFromSource:(int)source;
@end

%hook SBUIController

- (void)lockFromSource:(int)source {
    NSDictionary *prefs=[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tigers1m.taptappass.plist"];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ([[prefs objectForKey:@"reversed"] boolValue]){
        reversed = YES;
    }
    else {
        reversed = NO;
    }
    
    [prefs release];
    [pool drain];
    
    %orig;
}
%end


%hook SBAwayController

-(BOOL)isLocked {
    BOOL locked;
    if (Unlocking){
        Unlocking = NO;
        locked = NO;
    }
    if (!Unlocking){
        locked = %orig;
    }
    return locked;
    
}
-(void)_finishedUnlockAttemptWithStatus:(BOOL)fp8{
    if (fp8 == YES) {
        passActive = NO;
        Unlocking = YES;
    }
    if (fp8 == NO) {
        passActive = YES;
        Unlocking = NO;
    }
    %orig;
}
%end
 

%hook SBDeviceLockController
-(BOOL)isPasswordProtected {
    BOOL passEnabled;
    
    if (reversed){
        passEnabled = !passActive;
    }
    else {
        passEnabled = passActive;
    }
    
    return passEnabled;
    //Used for AndroidLockXT compatability - removed temporarily.
    /*
    BOOL axt_Override;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.zmaster.AndroidLock.plist"];
    
    if(fileExists) {
    
        NSDictionary *alxt_prefs=[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.zmaster.AndroidLock.plist"];
    
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
            if ([[alxt_prefs objectForKey:@"Enable"] boolValue]){
                axt_Override = NO;
                }
            else {
                axt_Override = YES;
            }

        [alxt_prefs release];
        [pool drain];
    }
    if(!fileExists) {
        axt_Override = passActive;
    }
 

        return axt_Override;
     */
}
%end

/*
%hook AndroidLockView
-(BOOL)isPatternRequired {
    return passActive;
}
%end
*/


 

@interface PassActive : NSObject<LAListener>
{}
@end

@implementation PassActive


-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    passActive = YES;
    NSLog(@"Lock Enabled");
    
	if ([(SBUIController *)[%c(SBUIController) sharedInstance] respondsToSelector:@selector(lock)])
        [(SBUIController *)[%c(SBUIController) sharedInstance] lock];
	if ([(SBUIController *)[%c(SBUIController) sharedInstance] respondsToSelector:@selector(lockFromSource:)])
		[(SBUIController *)[%c(SBUIController) sharedInstance] lockFromSource:0];
    
    passActive = YES;
    
    [event setHandled:YES];
    
    
    
}


+(void)load
{
    if (![[LAActivator sharedInstance] hasSeenListenerWithName:@"com.tigers1m.taptappass"])
        [[LAActivator sharedInstance] assignEvent:[LAEvent eventWithName:@"libactivator.lock.pressdouble"] toListenerWithName:@"com.tigers1m.taptappass"];
    
    
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {return;}
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.tigers1m.taptappass"];
	[p release];
}

@end

%ctor
{
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]){return;}
}
