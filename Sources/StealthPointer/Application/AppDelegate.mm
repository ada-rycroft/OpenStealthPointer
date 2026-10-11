#import "AppDelegate.h"
#import <unistd.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.cursorHidden = NO;
    self.shouldHideCursor = NO;
    self.shouldShowCursor = NO;
    self.shouldTerminate = NO;
    self.gameProfileSessionActive = NO;
    self.appIsActive = NSApp.isActive;
    self.settingsHubVisible = NO;
    self.autoHidePausedUntil = 0;
    [self loadHotkeySettings];
    [self scheduleAutoHideTimeout];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *image = [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:nil];
    [image setTemplate:YES];
    self.statusItem.button.image = image;
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Hide Cursor" action:@selector(startCursorHide) keyEquivalent:@"1"];
    [menu addItemWithTitle:@"Show Cursor" action:@selector(startCursorShow) keyEquivalent:@"2"];
    [menu addItem:NSMenuItem.separatorItem];
    self.gameProfileMenuItem = [menu addItemWithTitle:@"Game Profile" action:@selector(toggleGameProfile:) keyEquivalent:@""];
    self.gameProfileMenuItem.state = self.gameProfileEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    NSMenuItem *presetItem = [[NSMenuItem alloc] initWithTitle:@"Profile Preset" action:nil keyEquivalent:@""];
    self.profilePresetMenu = [[NSMenu alloc] initWithTitle:@"Profile Preset"];
    self.profilePresetMenu.delegate = self;
    [self refreshProfilePresetMenu];
    presetItem.submenu = self.profilePresetMenu;
    [menu addItem:presetItem];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"Settings" action:@selector(showSettings) keyEquivalent:@""];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"About" action:@selector(showAbout) keyEquivalent:@""];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    self.statusItem.menu = menu;
    [self registerHotkey];
    [self applyCursorHack];
    [self installGameProfileHook];
    [self runCursorHideThread];
    [self runCursorShowThread];
    [self runAutoHideThread];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 350 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self showSettings];
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    self.shouldTerminate = YES;
    [self removeGameProfileHook];
    usleep(100000);
}

- (void)applicationDidBecomeActive:(NSNotification *)notification { self.appIsActive = YES; }
- (void)applicationDidResignActive:(NSNotification *)notification { self.appIsActive = NO; }
- (void)updateSettingsHubVisible:(BOOL)visible { self.settingsHubVisible = visible; }
- (void)setSettingsHubVisibleFromNumber:(NSNumber *)visible { [self updateSettingsHubVisible:visible.boolValue]; }

- (void)showSettings
{
    Class controller = NSClassFromString(@"ModernSettingsWindowController");
    SEL show = NSSelectorFromString(@"showWindow");
    if (controller && [controller respondsToSelector:show]) {
        [controller performSelector:show];
    } else {
        if (!self.settingsWindow || !self.settingsWindow.visible) [self createSettingsWindow];
        [self.settingsWindow makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)showAbout
{
    Class controller = NSClassFromString(@"ModernAboutWindowController");
    SEL show = NSSelectorFromString(@"showWindow");
    if (controller && [controller respondsToSelector:show]) {
        [controller performSelector:show];
    } else {
        NSBundle *bundle = NSBundle.mainBundle;
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"About StealthPointer";
        alert.informativeText = [NSString stringWithFormat:@"StealthPointer v%@ (Build %@)\n\nA simple macOS menubar utility to hide or show the mouse cursor using customizable global hotkeys.\n\nOptimized for Wine gaming with threading-based cursor control.\n\nCreated by Radim Veselý, 2025.", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}
@end
