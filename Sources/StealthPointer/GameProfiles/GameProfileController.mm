#import "../Application/AppDelegate.h"

NSString *const SPActionShowKeys = @"Escape, Tab, B, C, I, J, K, M, O, P";
NSString *const SPActionHideKeys = @"W, A, S, D, Q, E, Space, Shift";

static CGEventRef ProfileEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *context)
{
    AppDelegate *delegate = (__bridge AppDelegate *)context;
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        if (delegate.gameProfileEventTap) CGEventTapEnable(delegate.gameProfileEventTap, true);
    } else if (type == kCGEventKeyDown || type == kCGEventFlagsChanged) {
        CGEventFlags flags = CGEventGetFlags(event);
        if (type == kCGEventFlagsChanged || !(flags & (kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate))) {
            [delegate handleGameProfileKeyCode:(UInt16)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode) flags:flags eventType:type];
        }
    }
    return event;
}

@implementation AppDelegate (GameProfiles)
- (void)toggleGameProfile:(id)sender
{
    self.gameProfileEnabled = !self.gameProfileEnabled;
    self.gameProfileMenuItem.state = self.gameProfileEnabled;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:self.gameProfileEnabled forKey:@"GameProfileEnabled"];
    [defaults synchronize];
}
- (void)setGameProfilePresetName:(NSString *)name showKeys:(NSString *)show hideKeys:(NSString *)hide
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:name forKey:@"SelectedProfilePreset"];
    if (show) { self.profileShowKeys = show; [defaults setObject:show forKey:@"ProfileShowKeys"]; }
    if (hide) { self.profileHideKeys = hide; [defaults setObject:hide forKey:@"ProfileHideKeys"]; }
    [defaults synchronize];
    [self refreshProfilePresetMenu];
}
- (void)addProfilePresetMenuItemWithName:(NSString *)name showKeys:(NSString *)show hideKeys:(NSString *)hide selectedName:(NSString *)selected
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:@selector(selectProfilePreset:) keyEquivalent:@""];
    item.target = self;
    item.state = [selected isEqualToString:name];
    item.representedObject = @{@"name": name ?: @"", @"showKeys": show ?: @"", @"hideKeys": hide ?: @""};
    [self.profilePresetMenu addItem:item];
}
- (NSArray<NSDictionary *> *)savedGameProfiles
{
    NSString *json = [NSUserDefaults.standardUserDefaults stringForKey:@"SavedGameProfiles"];
    if (!json.length) return @[];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return @[];
    id decoded = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![decoded isKindOfClass:NSArray.class]) return @[];
    NSMutableArray *profiles = [NSMutableArray array];
    for (id row in decoded) {
        if (![row isKindOfClass:NSDictionary.class]) continue;
        NSString *name = [row[@"name"] isKindOfClass:NSString.class] ? row[@"name"] : nil;
        NSString *show = [row[@"showKeys"] isKindOfClass:NSString.class] ? row[@"showKeys"] : @"";
        NSString *hide = [row[@"hideKeys"] isKindOfClass:NSString.class] ? row[@"hideKeys"] : @"";
        if (name.length) [profiles addObject:@{@"name":name, @"showKeys":show, @"hideKeys":hide}];
    }
    return profiles;
}
- (void)refreshProfilePresetMenu
{
    if (!self.profilePresetMenu) return;
    [self.profilePresetMenu removeAllItems];
    NSString *selected = [NSUserDefaults.standardUserDefaults stringForKey:@"SelectedProfilePreset"] ?: @"Action";
    [self addProfilePresetMenuItemWithName:@"Action" showKeys:SPActionShowKeys hideKeys:SPActionHideKeys selectedName:selected];
    [self addProfilePresetMenuItemWithName:@"Strategy" showKeys:@"Escape, Tab, M, P, B" hideKeys:@"Space, Return" selectedName:selected];
    NSArray *profiles = [self savedGameProfiles];
    [self.profilePresetMenu addItem:NSMenuItem.separatorItem];
    if (profiles.count) {
        for (NSDictionary *profile in profiles) {
            [self addProfilePresetMenuItemWithName:profile[@"name"] showKeys:profile[@"showKeys"] hideKeys:profile[@"hideKeys"] selectedName:selected];
        }
    } else {
        NSMenuItem *empty = [[NSMenuItem alloc] initWithTitle:@"No Own Games Saved" action:nil keyEquivalent:@""];
        empty.enabled = NO;
        [self.profilePresetMenu addItem:empty];
    }
}
- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if (menu == self.profilePresetMenu) [self refreshProfilePresetMenu];
}
- (void)selectProfilePreset:(NSMenuItem *)sender
{
    id profile = sender.representedObject;
    if ([profile isKindOfClass:NSDictionary.class]) {
        [self setGameProfilePresetName:profile[@"name"] showKeys:profile[@"showKeys"] hideKeys:profile[@"hideKeys"]];
    }
}
- (void)installGameProfileHook
{
    if (!self.gameProfileGlobalMonitor) {
        __weak AppDelegate *weakSelf = self;
        self.gameProfileGlobalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *event) {
            AppDelegate *delegate = weakSelf;
            if (!delegate) return;
            NSEventModifierFlags flags = event.modifierFlags;
            if (!(flags & (NSEventModifierFlagCommand | NSEventModifierFlagOption))) {
                [delegate handleGameProfileKeyCode:event.keyCode flags:(flags & (NSEventModifierFlagShift | NSEventModifierFlagControl)) eventType:kCGEventKeyDown];
            }
        }];
    }
    // Both observers are present in the reference. The tap also sees modifiers.
    self.gameProfileEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly,
        CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged), ProfileEventCallback, (__bridge void *)self);
    if (self.gameProfileEventTap) {
        self.gameProfileRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.gameProfileEventTap, 0);
        if (self.gameProfileRunLoopSource) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), self.gameProfileRunLoopSource, kCFRunLoopCommonModes);
            CGEventTapEnable(self.gameProfileEventTap, true);
        } else {
            CFRelease(self.gameProfileEventTap);
            self.gameProfileEventTap = NULL;
        }
    } else {
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES});
    }
}
- (void)removeGameProfileHook
{
    if (self.gameProfileGlobalMonitor) {
        [NSEvent removeMonitor:self.gameProfileGlobalMonitor];
        self.gameProfileGlobalMonitor = nil;
    }
    if (self.gameProfileRunLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self.gameProfileRunLoopSource, kCFRunLoopCommonModes);
        CFRelease(self.gameProfileRunLoopSource);
        self.gameProfileRunLoopSource = NULL;
    }
    if (self.gameProfileEventTap) {
        CGEventTapEnable(self.gameProfileEventTap, false);
        CFRelease(self.gameProfileEventTap);
        self.gameProfileEventTap = NULL;
    }
}
@end
