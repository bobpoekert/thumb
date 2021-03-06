#import "AppDelegate.h"
#include "PythonGlue.h"
#include <Python/Python.h>
#include "stdio.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    pythonDelegate = loadDelegate(self);
	[webView setMainFrameURL:[self appURL]];
}

- (void)dealloc {
    if (pythonDelegate != NULL) {
        PyGILState_STATE gilState = PyGILState_Ensure();
        Py_DECREF(pythonDelegate);
        PyGILState_Release(gilState);
    }
    [super dealloc];
}

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
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector { 
    return NO;
    printf("checking selector: %s\n", sel_getName(selector));
    if (selector == @selector(callPython:) || selector == @selector(callPython::)) {
        printf("yes\n");
        return YES;
    } else {
        printf("no\n");
        return NO;
    }

}

+ (NSString *)webScriptingNameForSelector:(SEL)selector {
     if (selector == @selector(callPython:) || selector == @selector(callPython::)) {
         return @"callPython";
     } else {
         return nil;
     }
}

// Here we grab the URL to the bundled index.html document.
// Normally it would be the URL to your web app such as @"http://example.com".
- (NSString *)appURL {
    return [self callPython:@"get_url":@""];
	//return [[[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"] absoluteString];
}

- (NSString *)callPython:(NSString *)method:(NSString *)arg {
    PY_BEGIN
    char *cMethod = [method UTF8String];
    char *cArg = [arg UTF8String];
    PyObject *delegate = pythonDelegate;
    if (delegate == NULL) {
        return NULL;
    }
    PyObject *pyMethod = PyObject_GetAttrString(delegate, cMethod);
    NSString *res = NULL;
    if (pyMethod != NULL) {
        PyObject *arglist = Py_BuildValue("(s)", cArg);
        if (arglist != NULL) {
            PyObject *pyRes = PyObject_CallObject(pyMethod, arglist);
            if (pyRes != NULL) {
                char *string = PyString_AsString(pyRes);
                if (string != NULL) {
                    res = [NSString stringWithUTF8String:string];
                }
                Py_DECREF(pyRes);
            } else {
                PyErr_PrintEx(0);
            }
        }
        Py_DECREF(arglist);
    }
    Py_DECREF(pyMethod);
    PY_END
    return res;
}

- (NSString *)evalJavascript:(NSString *) code {
    return [webView stringByEvaluatingJavaScriptFromString:code];
}


// This delegate method gets triggered every time the page loads, but before the JavaScript runs
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame {
	// Allow this class to be usable through the "window.app" object in JavaScript
	// This could be any Objective-C class
	[windowScriptObject setValue:self forKey:@"app"];
}

@end
