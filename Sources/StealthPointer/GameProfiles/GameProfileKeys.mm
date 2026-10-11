#import "../Application/AppDelegate.h"

@implementation AppDelegate (GameProfileKeyMatching)
- (NSNumber *)profileKeyCodeForToken:(NSString *)token
{
    NSString *key = [[token stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if (!key.length) return nil;
    static NSDictionary<NSString *, NSNumber *> *codes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        codes = @{
        @"'": @39,
        @",": @43,
        @"-": @27,
        @".": @47,
        @"/": @44,
        @"0": @29,
        @"1": @18,
        @"2": @19,
        @"3": @20,
        @"4": @21,
        @"5": @23,
        @"6": @22,
        @"7": @26,
        @"8": @28,
        @"9": @25,
        @";": @41,
        @"=": @24,
        @"A": @0,
        @"ALT": @58,
        @"ALTGR": @61,
        @"B": @11,
        @"BACKSLASH": @42,
        @"BACKSPACE": @51,
        @"C": @8,
        @"CAPS": @57,
        @"CAPSLOCK": @57,
        @"CLEAR": @71,
        @"CMD": @55,
        @"COMMA": @43,
        @"COMMAND": @55,
        @"CONTROL": @59,
        @"CTRL": @59,
        @"D": @2,
        @"DEL": @117,
        @"DELETE": @51,
        @"DOWN": @125,
        @"DOWNARROW": @125,
        @"E": @14,
        @"END": @119,
        @"ENTER": @36,
        @"EQUAL": @24,
        @"ESC": @53,
        @"ESCAPE": @53,
        @"F": @3,
        @"F1": @122,
        @"F10": @109,
        @"F11": @103,
        @"F12": @111,
        @"F13": @105,
        @"F14": @107,
        @"F15": @113,
        @"F2": @120,
        @"F3": @99,
        @"F4": @118,
        @"F5": @96,
        @"F6": @97,
        @"F7": @98,
        @"F8": @100,
        @"F9": @101,
        @"FORWARDDELETE": @117,
        @"G": @5,
        @"GRAVE": @50,
        @"H": @4,
        @"HELP": @114,
        @"HOME": @115,
        @"I": @34,
        @"INSERT": @114,
        @"J": @38,
        @"K": @40,
        @"KEYPAD0": @82,
        @"KEYPAD1": @83,
        @"KEYPAD2": @84,
        @"KEYPAD3": @85,
        @"KEYPAD4": @86,
        @"KEYPAD5": @87,
        @"KEYPAD6": @88,
        @"KEYPAD7": @89,
        @"KEYPAD8": @91,
        @"KEYPAD9": @92,
        @"KEYPADCLEAR": @71,
        @"KEYPADDECIMAL": @65,
        @"KEYPADDIVIDE": @75,
        @"KEYPADENTER": @76,
        @"KEYPADMINUS": @78,
        @"KEYPADMULTIPLY": @67,
        @"KEYPADPLUS": @69,
        @"L": @37,
        @"LALT": @58,
        @"LCMD": @55,
        @"LCOMMAND": @55,
        @"LCONTROL": @59,
        @"LCTRL": @59,
        @"LEFT": @123,
        @"LEFTARROW": @123,
        @"LEFTBRACKET": @33,
        @"LOPTION": @58,
        @"LSHIFT": @56,
        @"M": @46,
        @"MINUS": @27,
        @"N": @45,
        @"NUM*": @67,
        @"NUM+": @69,
        @"NUM-": @78,
        @"NUM.": @65,
        @"NUM/": @75,
        @"NUM0": @82,
        @"NUM1": @83,
        @"NUM2": @84,
        @"NUM3": @85,
        @"NUM4": @86,
        @"NUM5": @87,
        @"NUM6": @88,
        @"NUM7": @89,
        @"NUM8": @91,
        @"NUM9": @92,
        @"NUMENTER": @76,
        @"NUMLOCK": @71,
        @"O": @31,
        @"OPTION": @58,
        @"P": @35,
        @"PAGEDOWN": @121,
        @"PAGEUP": @116,
        @"PERIOD": @47,
        @"PGDN": @121,
        @"PGUP": @116,
        @"Q": @12,
        @"QUOTE": @39,
        @"R": @15,
        @"RALT": @61,
        @"RCMD": @54,
        @"RCOMMAND": @54,
        @"RCONTROL": @62,
        @"RCTRL": @62,
        @"RETURN": @36,
        @"RIGHT": @124,
        @"RIGHTARROW": @124,
        @"RIGHTBRACKET": @30,
        @"RIGHTCMD": @54,
        @"RIGHTCOMMAND": @54,
        @"RIGHTCONTROL": @62,
        @"RIGHTCTRL": @62,
        @"RIGHTSHIFT": @60,
        @"ROPTION": @61,
        @"RSHIFT": @60,
        @"S": @1,
        @"SEMICOLON": @41,
        @"SHIFT": @56,
        @"SLASH": @44,
        @"SPACE": @49,
        @"T": @17,
        @"TAB": @48,
        @"U": @32,
        @"UP": @126,
        @"UPARROW": @126,
        @"V": @9,
        @"W": @13,
        @"X": @7,
        @"Y": @16,
        @"Z": @6,
        @"[": @33,
        @"\\": @42,
        @"]": @30,
        @"`": @50
        };
    });
    NSNumber *code = codes[key];
    if (code) return code;
    if ([key hasPrefix:@"KEY"] && key.length >= 4) {
        // NSString's integer parser also accepts a non-numeric suffix as zero.
        NSInteger value = [[key substringFromIndex:3] integerValue];
        if (value >= 0) return @(value);
    }
    return nil;
}

- (BOOL)profileKeys:(NSString *)keys containsKeyCode:(UInt16)code
{
    return [self profileKeys:keys containsKeyCode:code flags:0 eventType:kCGEventKeyDown];
}

- (BOOL)profileKeys:(NSString *)keys containsKeyCode:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type
{
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@",; \n\t"];
    for (NSString *token in [keys componentsSeparatedByCharactersInSet:separators]) {
        NSString *key = [[token stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        // Generic modifier tokens match a held modifier on any incoming key.
        // A flags-changed release only matches when its modifier is still set.
        if ([key isEqualToString:@"CMD"] || [key isEqualToString:@"COMMAND"]) {
            if ((flags & kCGEventFlagMaskCommand) || (type != kCGEventFlagsChanged && (code == 54 || code == 55))) return YES;
        } else if ([key isEqualToString:@"CTRL"] || [key isEqualToString:@"CONTROL"]) {
            if ((flags & kCGEventFlagMaskControl) || (type != kCGEventFlagsChanged && (code == 59 || code == 62))) return YES;
        } else if ([key isEqualToString:@"SHIFT"]) {
            if ((flags & kCGEventFlagMaskShift) || (type != kCGEventFlagsChanged && (code == 56 || code == 60))) return YES;
        } else if ([key isEqualToString:@"ALT"] || [key isEqualToString:@"OPTION"]) {
            if ((flags & kCGEventFlagMaskAlternate) || (type != kCGEventFlagsChanged && (code == 58 || code == 61))) return YES;
        } else {
            NSNumber *mapped = [self profileKeyCodeForToken:token];
            if (mapped && mapped.unsignedShortValue == code) return YES;
        }
    }
    return NO;
}

- (BOOL)isGameProfileShowKey:(UInt16)code
{
    NSString *keys = [NSUserDefaults.standardUserDefaults stringForKey:@"ProfileShowKeys"] ?: self.profileShowKeys ?: SPActionShowKeys;
    return [self profileKeys:keys containsKeyCode:code];
}
- (BOOL)isGameProfileHideKey:(UInt16)code
{
    NSString *keys = [NSUserDefaults.standardUserDefaults stringForKey:@"ProfileHideKeys"] ?: self.profileHideKeys ?: SPActionHideKeys;
    return [self profileKeys:keys containsKeyCode:code];
}
- (BOOL)isGameProfileShowKey:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type
{
    NSString *keys = [NSUserDefaults.standardUserDefaults stringForKey:@"ProfileShowKeys"] ?: self.profileShowKeys ?: SPActionShowKeys;
    return [self profileKeys:keys containsKeyCode:code flags:flags eventType:type];
}
- (BOOL)isGameProfileHideKey:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type
{
    NSString *keys = [NSUserDefaults.standardUserDefaults stringForKey:@"ProfileHideKeys"] ?: self.profileHideKeys ?: SPActionHideKeys;
    return [self profileKeys:keys containsKeyCode:code flags:flags eventType:type];
}
- (BOOL)currentGameProfileEnabled
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    return [defaults objectForKey:@"GameProfileEnabled"] ? [defaults boolForKey:@"GameProfileEnabled"] : YES;
}
- (void)handleGameProfileKeyCode:(UInt16)code
{
    [self handleGameProfileKeyCode:code flags:0 eventType:kCGEventKeyDown];
}
- (void)handleGameProfileKeyCode:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type
{
    if (![self currentGameProfileEnabled] || self.appIsActive) return;
    if ([self isGameProfileShowKey:code flags:flags eventType:type]) {
        if (self.gameProfileSessionActive || self.shouldHideCursor || self.cursorHidden) {
            [self showCursorKeepingGameProfileSession:YES];
        }
    } else if ([self isGameProfileHideKey:code flags:flags eventType:type] && self.gameProfileSessionActive) {
        [self startCursorHide];
    }
}
@end
