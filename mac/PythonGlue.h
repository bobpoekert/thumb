#pragma once

#include <Python/Python.h>
#import "AppDelegate.h"

PyObject *NSStringToPythonString(NSString *inp);
PyObject *wrapNSObject(NSObject *inp);
static PyObject *module_evalJS(PyObject *self, PyObject *args);
void updatePythonPath(char *newPath);
void addResourceToPythonPath();
PyObject *loadModule(char *module_name);
PyObject *loadDelegate(NSObject *obj);
PyObject *callFuncWithString(PyObject *func, char *arg);
void PythonGlue_Init(int argc, char **argv);
