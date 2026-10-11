#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic) BOOL cursorHidden;
@property(nonatomic) BOOL shouldHideCursor;
@property(nonatomic) BOOL shouldShowCursor;
@property(nonatomic) BOOL shouldTerminate;
@property(nonatomic) BOOL gameProfileEnabled;
@property(nonatomic) BOOL gameProfileSessionActive;
@property(nonatomic) BOOL appIsActive;
@property(nonatomic) BOOL settingsHubVisible;
@property(nonatomic) BOOL autoHideEnabled;
@property(nonatomic) double autoHideDelaySeconds;
@property(nonatomic) CFAbsoluteTime autoHidePausedUntil;
@property(nonatomic, strong) NSWindow *settingsWindow;
@property(nonatomic, strong) NSControl *hideKeyField;
@property(nonatomic, strong) NSControl *showKeyField;
@property(nonatomic, strong) NSTextField *profileShowKeysField;
@property(nonatomic, strong) NSTextField *profileHideKeysField;
@property(nonatomic, strong) NSMenuItem *gameProfileMenuItem;
@property(nonatomic, strong) NSMenu *profilePresetMenu;
@property(nonatomic) CFMachPortRef gameProfileEventTap;
@property(nonatomic) CFRunLoopSourceRef gameProfileRunLoopSource;
@property(nonatomic, strong) id gameProfileGlobalMonitor;
@property(atomic, strong) NSString *profileShowKeys;
@property(atomic, strong) NSString *profileHideKeys;
@property(nonatomic) UInt32 hideKeyCode;
@property(nonatomic) UInt32 showKeyCode;
@property(nonatomic) UInt32 hideKeyModifiers;
@property(nonatomic) UInt32 showKeyModifiers;
@property(nonatomic) EventHotKeyRef hideHotKeyRef;
@property(nonatomic) EventHotKeyRef showHotKeyRef;
@property(atomic, strong) id keyMonitor;
- (void)updateSettingsHubVisible:(BOOL)visible;
- (void)setSettingsHubVisibleFromNumber:(NSNumber *)visible;
- (void)showSettings;
- (void)showAbout;
@end

@interface AppDelegate (CursorControl)
- (void)startCursorHide;
- (void)hideCursorActivatingGameProfileSession:(BOOL)activate;
- (void)startCursorShow;
- (void)showCursorKeepingGameProfileSession:(BOOL)keep;
- (void)runCursorHideThread;
- (void)runCursorShowThread;
- (void)runAutoHideThread;
- (double)clampedAutoHideDelay;
- (void)scheduleAutoHideTimeout;
- (void)applyCursorHack;
@end

@interface AppDelegate (GameProfiles)
- (void)toggleGameProfile:(id)sender;
- (void)setGameProfilePresetName:(NSString *)name showKeys:(NSString *)show hideKeys:(NSString *)hide;
- (void)addProfilePresetMenuItemWithName:(NSString *)name showKeys:(NSString *)show hideKeys:(NSString *)hide selectedName:(NSString *)selected;
- (NSArray<NSDictionary *> *)savedGameProfiles;
- (void)refreshProfilePresetMenu;
- (void)selectProfilePreset:(NSMenuItem *)sender;
- (void)installGameProfileHook;
- (void)removeGameProfileHook;
@end

@interface AppDelegate (GameProfileKeyMatching)
- (NSNumber *)profileKeyCodeForToken:(NSString *)token;
- (BOOL)profileKeys:(NSString *)keys containsKeyCode:(UInt16)code;
- (BOOL)profileKeys:(NSString *)keys containsKeyCode:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type;
- (BOOL)isGameProfileShowKey:(UInt16)code;
- (BOOL)isGameProfileHideKey:(UInt16)code;
- (BOOL)isGameProfileShowKey:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type;
- (BOOL)isGameProfileHideKey:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type;
- (BOOL)currentGameProfileEnabled;
- (void)handleGameProfileKeyCode:(UInt16)code;
- (void)handleGameProfileKeyCode:(UInt16)code flags:(CGEventFlags)flags eventType:(CGEventType)type;
@end

@interface AppDelegate (Hotkeys)
- (NSString *)keyCodeToString:(int)code modifiers:(int)modifiers;
- (void)loadHotkeySettings;
- (void)reloadHotkeySettingsFromUserDefaults;
- (void)unregisterHotkeys;
- (void)registerHotkey;
@end

@interface AppDelegate (LegacySettings)
- (void)createSettingsWindow;
- (void)captureHideKey:(id)sender;
- (void)captureShowKey:(id)sender;
- (void)captureKeyForField:(NSControl *)field isHideKey:(BOOL)hide;
- (void)saveSettings:(id)sender;
- (void)cancelSettings:(id)sender;
- (void)resetDefaults:(id)sender;
@end

extern NSString *const SPActionShowKeys;
extern NSString *const SPActionHideKeys;
