//
//  main.m
//  Cocoa Web App
//
//  Created by Ryan Bates on 1/18/10.
//  Copyright 2010 Artbeats. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "PythonGlue.h"


int main(int argc, char *argv[]) {
    PythonGlue_Init(argc, argv);
    return NSApplicationMain(argc,  (const char **) argv);
}
