#import "AppDelegate.h"

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        AppDelegate *delegate = [[AppDelegate alloc] init];
        NSApplication *application = [NSApplication sharedApplication];
        application.delegate = delegate;
        return NSApplicationMain(argc, argv);
    }
}
