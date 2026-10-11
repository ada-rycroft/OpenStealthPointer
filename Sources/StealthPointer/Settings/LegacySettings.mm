#import "../Application/AppDelegate.h"

static NSTextField *SettingsLabel(NSView *view, NSString *title, NSRect frame)
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = title;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    [view addSubview:label];
    return label;
}

@implementation AppDelegate (LegacySettings)
- (void)createSettingsWindow
{
    self.settingsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,520,390) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
    self.settingsWindow.title = @"Settings";
    [self.settingsWindow center];
    self.settingsWindow.level = NSFloatingWindowLevel;
    self.settingsWindow.releasedWhenClosed = NO;
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,520,390)];
    self.settingsWindow.contentView = view;
    SettingsLabel(view, @"Hide Cursor Key:", NSMakeRect(20,220,120,22));
    SettingsLabel(view, @"Show Cursor Key:", NSMakeRect(20,180,120,22));
    NSButton *hide = [[NSButton alloc] initWithFrame:NSMakeRect(150,220,200,22)];
    hide.title = [self keyCodeToString:self.hideKeyCode modifiers:self.hideKeyModifiers];
    hide.bezelStyle = NSBezelStyleRounded;
    [hide setButtonType:NSButtonTypeMomentaryPushIn];
    hide.target = self;
    hide.action = @selector(captureHideKey:);
    [view addSubview:hide];
    self.hideKeyField = hide;
    NSButton *show = [[NSButton alloc] initWithFrame:NSMakeRect(150,180,200,22)];
    show.title = [self keyCodeToString:self.showKeyCode modifiers:self.showKeyModifiers];
    show.bezelStyle = NSBezelStyleRounded;
    [show setButtonType:NSButtonTypeMomentaryPushIn];
    show.target = self;
    show.action = @selector(captureShowKey:);
    [view addSubview:show];
    self.showKeyField = show;
    SettingsLabel(view, @"Profile Show:", NSMakeRect(20,135,120,22));
    self.profileShowKeysField = [[NSTextField alloc] initWithFrame:NSMakeRect(150,135,330,24)];
    self.profileShowKeysField.stringValue = self.profileShowKeys ?: SPActionShowKeys;
    [view addSubview:self.profileShowKeysField];
    SettingsLabel(view, @"Profile Hide:", NSMakeRect(20,95,120,22));
    self.profileHideKeysField = [[NSTextField alloc] initWithFrame:NSMakeRect(150,95,330,24)];
    self.profileHideKeysField.stringValue = self.profileHideKeys ?: SPActionHideKeys;
    [view addSubview:self.profileHideKeysField];
    NSArray *titles = @[@"Reset", @"Cancel", @"Save"];
    NSArray *actions = @[@"resetDefaults:", @"cancelSettings:", @"saveSettings:"];
    for (NSUInteger i = 0; i < 3; ++i) {
        NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(120+100*i,35,80,32)];
        button.title = titles[i];
        button.target = self;
        button.action = NSSelectorFromString(actions[i]);
        [view addSubview:button];
    }
    NSTextField *instructions = SettingsLabel(view, @"Click on a hotkey field and press the key combination you want.\nProfile keys are comma-separated game keys, for example: I, M, Tab, Escape", NSMakeRect(20,270,480,60));
    instructions.font = [NSFont systemFontOfSize:11];
}
- (void)captureHideKey:(id)sender
{
    [self.settingsWindow makeFirstResponder:self.hideKeyField];
    if ([self.hideKeyField isKindOfClass:NSButton.class]) [(NSButton *)self.hideKeyField setTitle:@"Press a key..."];
    [self captureKeyForField:self.hideKeyField isHideKey:YES];
}
- (void)captureShowKey:(id)sender
{
    [self.settingsWindow makeFirstResponder:self.showKeyField];
    if ([self.showKeyField isKindOfClass:NSButton.class]) [(NSButton *)self.showKeyField setTitle:@"Press a key..."];
    [self captureKeyForField:self.showKeyField isHideKey:NO];
}
- (void)captureKeyForField:(NSControl *)field isHideKey:(BOOL)hide
{
    if (self.keyMonitor) { [NSEvent removeMonitor:self.keyMonitor]; self.keyMonitor = nil; }
    [self unregisterHotkeys];
    if ([field isKindOfClass:NSButton.class]) [(NSButton *)field setTitle:@"Press a key..."];
    self.keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        UInt16 code = event.keyCode;
        UInt32 modifiers = 0;
        if (event.modifierFlags & NSEventModifierFlagCommand) modifiers |= cmdKey;
        if (event.modifierFlags & NSEventModifierFlagControl) modifiers |= controlKey;
        if (event.modifierFlags & NSEventModifierFlagOption) modifiers |= optionKey;
        if (event.modifierFlags & NSEventModifierFlagShift) modifiers |= shiftKey;
        if (code == 53) {
            [self cancelSettings:nil];
        } else {
            if ([field isKindOfClass:NSButton.class]) [(NSButton *)field setTitle:[self keyCodeToString:code modifiers:modifiers]];
            field.needsDisplay = YES;
            if (hide) { self.hideKeyCode = code; self.hideKeyModifiers = modifiers; }
            else { self.showKeyCode = code; self.showKeyModifiers = modifiers; }
        }
        [NSEvent removeMonitor:self.keyMonitor];
        self.keyMonitor = nil;
        [self registerHotkey];
        return nil;
    }];
}
- (void)saveSettings:(id)sender
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:self.hideKeyCode forKey:@"HideKeyCode"];
    [defaults setInteger:self.showKeyCode forKey:@"ShowKeyCode"];
    [defaults setInteger:self.hideKeyModifiers forKey:@"HideKeyModifiers"];
    [defaults setInteger:self.showKeyModifiers forKey:@"ShowKeyModifiers"];
    [defaults setBool:self.gameProfileEnabled forKey:@"GameProfileEnabled"];
    self.profileShowKeys = self.profileShowKeysField.stringValue.length ? self.profileShowKeysField.stringValue : SPActionShowKeys;
    self.profileHideKeys = self.profileHideKeysField.stringValue.length ? self.profileHideKeysField.stringValue : SPActionHideKeys;
    [defaults setObject:@"Own Games" forKey:@"SelectedProfilePreset"];
    [defaults setObject:self.profileShowKeys forKey:@"ProfileShowKeys"];
    [defaults setObject:self.profileHideKeys forKey:@"ProfileHideKeys"];
    [defaults synchronize];
    [self unregisterHotkeys];
    [self registerHotkey];
    [self.settingsWindow orderOut:nil];
}
- (void)cancelSettings:(id)sender
{
    // Captured hotkeys already changed the controller, so Cancel only hides UI.
    if ([self.hideKeyField isKindOfClass:NSButton.class]) [(NSButton *)self.hideKeyField setTitle:[self keyCodeToString:self.hideKeyCode modifiers:self.hideKeyModifiers]];
    else self.hideKeyField.stringValue = [self keyCodeToString:self.hideKeyCode modifiers:self.hideKeyModifiers];
    if ([self.showKeyField isKindOfClass:NSButton.class]) [(NSButton *)self.showKeyField setTitle:[self keyCodeToString:self.showKeyCode modifiers:self.showKeyModifiers]];
    else self.showKeyField.stringValue = [self keyCodeToString:self.showKeyCode modifiers:self.showKeyModifiers];
    self.profileShowKeysField.stringValue = self.profileShowKeys ?: SPActionShowKeys;
    self.profileHideKeysField.stringValue = self.profileHideKeys ?: SPActionHideKeys;
    [self.settingsWindow orderOut:nil];
}
- (void)resetDefaults:(id)sender
{
    self.hideKeyCode = 122;
    self.showKeyCode = 120;
    self.hideKeyModifiers = 0;
    self.showKeyModifiers = 0;
    self.profileShowKeys = SPActionShowKeys;
    self.profileHideKeys = SPActionHideKeys;
    self.autoHideEnabled = NO;
    self.autoHideDelaySeconds = 5;
    if ([self.hideKeyField isKindOfClass:NSButton.class]) [(NSButton *)self.hideKeyField setTitle:[self keyCodeToString:self.hideKeyCode modifiers:self.hideKeyModifiers]];
    if ([self.showKeyField isKindOfClass:NSButton.class]) [(NSButton *)self.showKeyField setTitle:[self keyCodeToString:self.showKeyCode modifiers:self.showKeyModifiers]];
    self.profileShowKeysField.stringValue = self.profileShowKeys;
    self.profileHideKeysField.stringValue = self.profileHideKeys;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:self.hideKeyCode forKey:@"HideKeyCode"];
    [defaults setInteger:self.showKeyCode forKey:@"ShowKeyCode"];
    [defaults setInteger:self.hideKeyModifiers forKey:@"HideKeyModifiers"];
    [defaults setInteger:self.showKeyModifiers forKey:@"ShowKeyModifiers"];
    [defaults setBool:self.autoHideEnabled forKey:@"AutoHideEnabled"];
    [defaults setInteger:(NSInteger)self.autoHideDelaySeconds forKey:@"AutoHideDelaySeconds"];
    [defaults setBool:self.gameProfileEnabled forKey:@"GameProfileEnabled"];
    [defaults setObject:@"Action" forKey:@"SelectedProfilePreset"];
    [defaults setObject:self.profileShowKeys forKey:@"ProfileShowKeys"];
    [defaults setObject:self.profileHideKeys forKey:@"ProfileHideKeys"];
    [defaults synchronize];
    [self scheduleAutoHideTimeout];
    [self unregisterHotkeys];
    [self registerHotkey];
}
@end
