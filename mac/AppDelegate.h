#pragma once

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <Python/Python.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet id webView;
	IBOutlet NSWindow *window;
    PyObject *pythonDelegate;
}

- (NSString *)evalJavascript:(NSString *)code;
- (IBAction)bringMainWindowToFront:(id)sender;
- (NSString *)appURL;
- (NSString *)callPython:(NSString *)method:(NSString *)arg;

@end
