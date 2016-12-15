#import "AppDelegate.h"
#include "PythonGlue.h"
#include <Python/Python.h>
#include "stdio.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    printf("finished launching\n");
    pythonDelegate = loadDelegate(self);
    printf("got delegate: %x\n", pythonDelegate);
	//[webView setMainFrameURL:[self appURL]];
}

/*
- (void)dealloc {
    if (pythonDelegate != NULL) {
        PyGILState_STATE gilState = PyGILState_Ensure();
        Py_DECREF(pythonDelegate);
        PyGILState_Release(gilState);
    }
    [super dealloc];
}
*/

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self bringMainWindowToFront:nil];
	return YES;
}

- (IBAction)bringMainWindowToFront:(id)sender {
	[window makeKeyAndOrderFront:sender];
	if ([[webView mainFrameURL] isEqualTo:@""]) {
		[webView setMainFrameURL:[self appURL]];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	[webView setMainFrameURL:@""];
}

// Make every method in this class available to javascript
// This may be a security risk so you may want to add logic to
// restrict which methods are accessible
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector { return NO; }

// Here we grab the URL to the bundled index.html document.
// Normally it would be the URL to your web app such as @"http://example.com".
- (NSString *)appURL {
	return [[[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"] absoluteString];
}


// Change the application's icon in the dock, this is triggered from JavaScript
- (void)changeIcon:(NSString *)iconName {
	[NSApp setApplicationIconImage:[NSImage imageNamed:iconName]];
}

- (NSString *)callPython:(NSString *)method:(NSString *)arg {
    printf("callPython\n");
    PyGILState_STATE gilState = PyGILState_Ensure();
    printf("got gil\n");
    PyObject *delegate = pythonDelegate;
    PyObject *pyMethod = PyObject_GetAttrString(delegate, method);
    NSString *res = NULL;
    if (pyMethod != NULL) {
        PyObject *arglist = Py_BuildValue("(s)", [arg UTF8String]);
        if (arglist != NULL) {
            PyObject *pyRes = PyObject_CallObject(delegate, arglist);
            if (pyRes != NULL) {
                char *string = PyString_AsString(pyRes);
                if (string != NULL) {
                    res = [NSString stringWithUTF8String:string];
                }
                Py_DECREF(pyRes);
            }
        }
        Py_DECREF(arglist);
    }
    Py_DECREF(pyMethod);
    PyGILState_Release(gilState);
    return res;
}

- (NSString *)evalJavascript:(NSString *) code {
    return [webView stringByEvaluatingJavaScriptFromString:code];
}


// This delegate method gets triggered every time the page loads, but before the JavaScript runs
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	// Allow this class to be usable through the "window.app" object in JavaScript
	// This could be any Objective-C class
	[windowScriptObject setValue:self forKey:@"app"];
}

@end
