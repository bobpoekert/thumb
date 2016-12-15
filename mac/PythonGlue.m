#include <Python/Python.h>
#import "AppDelegate.h"

#define CAPSULE_NAME "webkit"

#pragma message "PythonGlue.h"

#define PY_REPL PyRun_SimpleString("import pdb; pdb.set_trace()")

PyObject *NSStringToPythonString(NSString *inp) {
    char *string = [inp UTF8String];
    return PyString_FromString(string);
}

PyObject *wrapNSObject(NSObject *inp) {
    return PyCapsule_New(inp, CAPSULE_NAME, NULL); 
}

static PyObject *module_evalJS(PyObject *self, PyObject *args) {
    PyObject *contextCapsule;
    char *codeString;
    NSString *resString = NULL;
    if (!PyArg_ParseTuple(args, "Os", &contextCapsule, &codeString)) return NULL;
    AppDelegate *context = PyCapsule_GetPointer(contextCapsule, CAPSULE_NAME);
    printf("app delegate context %x\n", context);
    if (context != NULL) {
        resString = [context evalJavascript:[NSString stringWithUTF8String:codeString]];
    }
    Py_DECREF(contextCapsule);
    if (resString == NULL) {
        return NULL;
    } else {
        return NSStringToPythonString(resString);
    }
}

static PyMethodDef CallbackMethods[] = {
    {"eval_js", module_evalJS, METH_VARARGS, "evaluate the given javascript string in the given context and return the result as a string"},
    {NULL, NULL, 0, NULL}
};

void updatePythonPath(char *newPath) {
    PyObject *locals = Py_BuildValue("{s:s}", "resources", newPath);
    PyObject *globals = PyDict_New();
    PyRun_String("import sys; sys.path.insert(0, resources)", 0, globals, locals);
}

void addResourceToPythonPath() {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    char *cResourcePath = [resourcePath UTF8String];
    updatePythonPath(cResourcePath);
}

PyObject *loadDelegate(NSObject *obj) {
    PyGILState_STATE gilState = PyGILState_Ensure();
    PyObject *delegate = NULL;
    PyObject *module = PyImport_ImportModule("main");
    if (module != NULL) {
        PyObject *objRef = wrapNSObject(obj);
        if (objRef != NULL) {
            PyObject *mainFunc = PyObject_GetAttrString(module, "main");
            if (mainFunc != NULL) {
                PyObject *args = Py_BuildValue("(O)", objRef);
                delegate = PyObject_CallObject(mainFunc, args);
                Py_DECREF(mainFunc);
            }
            Py_DECREF(objRef);
        }
        Py_DECREF(module);
    }
    PyGILState_Release(gilState);
    return delegate;
}

PyObject *callFuncWithString(PyObject *func, char *arg) {
    PyObject *args = Py_BuildValue("(s)", arg);
    if (!args) return NULL;
    PyObject *res = PyObject_CallObject(func, args);
    Py_DECREF(args);
    return res;
}

void PythonGlue_Init(int argc, char **argv) {
    Py_SetProgramName(argv[0]);
    Py_Initialize();
    Py_InitModule("_webkit_callback", CallbackMethods);
    //addResourceToPythonPath();
    PyRun_SimpleString("import sys,os; sys.path.insert(0, os.getcwd())");
    //printf("starting repl\n");
    //PY_REPL;
}
