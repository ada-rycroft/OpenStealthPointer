#import "../Application/AppDelegate.h"
#import <unistd.h>

extern "C" int _CGSDefaultConnection(void);
extern "C" CGError CGSSetConnectionProperty(int connection, int target, CFStringRef key, CFTypeRef value);

@implementation AppDelegate (CursorControl)

- (void)startCursorHide { [self hideCursorActivatingGameProfileSession:[self currentGameProfileEnabled]]; }

- (void)hideCursorActivatingGameProfileSession:(BOOL)activate
{
    if (activate) self.gameProfileSessionActive = YES;
    self.shouldShowCursor = NO;
    self.cursorHidden = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"eye.slash" accessibilityDescription:nil];
    });
    self.shouldHideCursor = YES;
}

- (void)startCursorShow { [self showCursorKeepingGameProfileSession:NO]; }

- (void)showCursorKeepingGameProfileSession:(BOOL)keep
{
    self.gameProfileSessionActive = keep;
    self.shouldHideCursor = NO;
    // Games can build up a cursor hide count, showing deliberately drains it.
    for (int i = 0; i < 50; ++i) CGDisplayShowCursor(CGMainDisplayID());
    CGAssociateMouseAndMouseCursorPosition(false);
    CGAssociateMouseAndMouseCursorPosition(true);
    self.cursorHidden = NO;
    [self scheduleAutoHideTimeout];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:nil];
    });
    self.shouldShowCursor = YES;
}

- (void)runCursorHideThread
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while (!self.shouldTerminate) {
            if (self.shouldHideCursor) {
                CGDisplayHideCursor(CGMainDisplayID());
                usleep(200000);
            } else {
                usleep(100000);
            }
        }
    });
}

- (void)runCursorShowThread
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        static int showIterations = 0;
        while (!self.shouldTerminate) {
            if (self.shouldShowCursor) {
                for (int i = 0; i < 50; ++i) CGDisplayShowCursor(CGMainDisplayID());
                CGAssociateMouseAndMouseCursorPosition(false);
                CGAssociateMouseAndMouseCursorPosition(true);
                // Begin with a short interval to recover quickly after focus changes.
                int previous = showIterations++;
                if (previous < 24) usleep(20000);
                else if (previous <= 98) usleep(50000);
                else {
                    usleep(200000);
                    if (showIterations >= 151) showIterations = 100;
                }
            } else {
                usleep(100000);
                showIterations = 0;
            }
        }
    });
}

- (void)runAutoHideThread
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!self.shouldTerminate) {
            BOOL paused = self.settingsHubVisible && self.appIsActive;
            if (self.autoHideEnabled && !paused && !self.cursorHidden && !self.shouldHideCursor) {
                CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
                if (self.autoHidePausedUntil > 0) {
                    if (now >= self.autoHidePausedUntil) {
                        [self hideCursorActivatingGameProfileSession:[self currentGameProfileEnabled]];
                    }
                } else {
                    self.autoHidePausedUntil = now + [self clampedAutoHideDelay];
                }
            } else if (paused) {
                // Sliding this deadline keeps a full delay after leaving the Hub.
                self.autoHidePausedUntil = CFAbsoluteTimeGetCurrent() + [self clampedAutoHideDelay];
            }
            usleep(200000);
        }
    });
}

- (double)clampedAutoHideDelay
{
    double delay = self.autoHideDelaySeconds;
    if (delay < 1) delay = 1;
    if (delay > 60) delay = 60;
    return delay;
}

- (void)scheduleAutoHideTimeout
{
    self.autoHidePausedUntil = self.autoHideEnabled ? CFAbsoluteTimeGetCurrent() + [self clampedAutoHideDelay] : 0;
}

- (void)applyCursorHack
{
    CFStringRef key = CFStringCreateWithCString(NULL, "SetsCursorInBackground", kCFStringEncodingUTF8);
    CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), key, kCFBooleanTrue);
    CFRelease(key);
}
@end
