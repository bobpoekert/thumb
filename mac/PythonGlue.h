#pragma once

#include <Python/Python.h>
#import "AppDelegate.h"

#define PY_BEGIN PyGILState_STATE _gil = PyGILState_Ensure();
#define PY_END PyGILState_Release(_gil);

PyObject *NSStringToPythonString(NSString *inp);
PyObject *wrapNSObject(NSObject *inp);
static PyObject *module_evalJS(PyObject *self, PyObject *args);
PyObject *loadModule(char *module_name);
PyObject *loadDelegate(NSObject *obj);
PyObject *callFuncWithString(PyObject *func, char *arg);
void PythonGlue_Init(int argc, char **argv);
void PythonGlue_Finalize();
void acquireGil();
void releaseGil();
