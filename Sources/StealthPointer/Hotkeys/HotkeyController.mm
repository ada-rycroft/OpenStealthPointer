#import "../Application/AppDelegate.h"

static OSStatus GlobalHotkeyHandler(EventHandlerCallRef next, EventRef event, void *context)
{
    EventHotKeyID hotkey;
    GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotkey), NULL, &hotkey);
    AppDelegate *delegate = (__bridge AppDelegate *)context;
    if (hotkey.id == 2) [delegate startCursorShow];
    else if (hotkey.id == 1) [delegate startCursorHide];
    return noErr;
}

@implementation AppDelegate (Hotkeys)
- (NSString *)keyCodeToString:(int)code modifiers:(int)modifiers
{
    NSMutableString *label = [NSMutableString string];
    if (modifiers & cmdKey) [label appendString:@"Cmd+"];
    if (modifiers & controlKey) [label appendString:@"Ctrl+"];
    if (modifiers & optionKey) [label appendString:@"Alt+"];
    if (modifiers & shiftKey) [label appendString:@"Shift+"];
    NSDictionary *keys = @{@122: @"F1", @120: @"F2", @99: @"F3", @118: @"F4", @96: @"F5", @97: @"F6", @98: @"F7", @100: @"F8", @101: @"F9", @109: @"F10", @103: @"F11", @111: @"F12", @49: @"Space", @36: @"Return", @48: @"Tab", @53: @"Escape", @51: @"Delete", @0: @"A", @11: @"B", @8: @"C", @2: @"D", @14: @"E", @3: @"F", @5: @"G", @4: @"H", @34: @"I", @38: @"J", @40: @"K", @37: @"L", @46: @"M", @45: @"N", @31: @"O", @35: @"P", @12: @"Q", @15: @"R", @1: @"S", @17: @"T", @32: @"U", @9: @"V", @13: @"W", @7: @"X", @16: @"Y", @6: @"Z"};
    NSString *name = keys[@(code)];
    if (name) [label appendString:name];
    else [label appendFormat:@"Key%d", code];
    return label;
}
- (void)loadHotkeySettings
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.gameProfileEnabled = [defaults objectForKey:@"GameProfileEnabled"] ? [defaults boolForKey:@"GameProfileEnabled"] : YES;
    self.profileShowKeys = [defaults stringForKey:@"ProfileShowKeys"] ?: SPActionShowKeys;
    self.profileHideKeys = [defaults stringForKey:@"ProfileHideKeys"] ?: SPActionHideKeys;
    self.autoHideEnabled = [defaults boolForKey:@"AutoHideEnabled"];
    double delay = [defaults doubleForKey:@"AutoHideDelaySeconds"];
    if (delay <= 0) delay = 5;
    if (delay < 1) delay = 1;
    if (delay > 60) delay = 60;
    self.autoHideDelaySeconds = delay;
    // The hide key alone determines whether all four stored fields are loaded.
    if ([defaults objectForKey:@"HideKeyCode"]) {
        self.hideKeyCode = (UInt32)[defaults integerForKey:@"HideKeyCode"];
        self.showKeyCode = (UInt32)[defaults integerForKey:@"ShowKeyCode"];
        self.hideKeyModifiers = (UInt32)[defaults integerForKey:@"HideKeyModifiers"];
        self.showKeyModifiers = (UInt32)[defaults integerForKey:@"ShowKeyModifiers"];
    } else {
        self.hideKeyCode = 122;
        self.showKeyCode = 120;
        self.hideKeyModifiers = 0;
        self.showKeyModifiers = 0;
    }
}
- (void)reloadHotkeySettingsFromUserDefaults
{
    [self loadHotkeySettings];
    [self scheduleAutoHideTimeout];
    [self unregisterHotkeys];
    [self registerHotkey];
}
- (void)unregisterHotkeys
{
    if (self.hideHotKeyRef) { UnregisterEventHotKey(self.hideHotKeyRef); self.hideHotKeyRef = NULL; }
    if (self.showHotKeyRef) { UnregisterEventHotKey(self.showHotKeyRef); self.showHotKeyRef = NULL; }
    if (self.keyMonitor) { [NSEvent removeMonitor:self.keyMonitor]; self.keyMonitor = nil; }
}
- (void)registerHotkey
{
    [self unregisterHotkeys];
    EventTypeSpec event = {kEventClassKeyboard, kEventHotKeyPressed};
    InstallEventHandler(GetApplicationEventTarget(), GlobalHotkeyHandler, 1, &event, (__bridge void *)self, NULL);
    EventHotKeyRef hide = NULL, show = NULL;
    RegisterEventHotKey(self.hideKeyCode, self.hideKeyModifiers, (EventHotKeyID){'htk1',1}, GetApplicationEventTarget(), 0, &hide);
    RegisterEventHotKey(self.showKeyCode, self.showKeyModifiers, (EventHotKeyID){'htk2',2}, GetApplicationEventTarget(), 0, &show);
    self.hideHotKeyRef = hide;
    self.showHotKeyRef = show;
}
@end
