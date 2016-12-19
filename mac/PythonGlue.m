#include <Python/Python.h>
#import "AppDelegate.h"
#include "PythonGlue.h"

#define CAPSULE_NAME "webkit"
#define PY_REPL PyRun_SimpleString("import pdb; pdb.set_trace()")

PyObject *NSStringToPythonString(NSString *inp) {
    char *string = [inp UTF8String];
    return PyString_FromString(string);
}

PyObject *wrapNSObject(NSObject *inp) {
    return PyCapsule_New(inp, CAPSULE_NAME, NULL); 
}

NSString *_callJavascript(AppDelegate *context, NSString *codeString) {
    NSString *resString = [context evalJavascript:codeString];
    return resString;
}

static PyObject *module_evalJS(PyObject *self, PyObject *args) {
    PyObject *contextCapsule;
    PyObject *res;
    char *codeString;
    __block NSString *resString = NULL;
    if (!PyArg_ParseTuple(args, "Os", &contextCapsule, &codeString)) return NULL;
    AppDelegate *context = PyCapsule_GetPointer(contextCapsule, CAPSULE_NAME);
    NSString *nsCodeString = [NSString stringWithUTF8String:codeString];
   
    Py_BEGIN_ALLOW_THREADS
    if ([NSThread isMainThread]) {
        resString = _callJavascript(context, nsCodeString);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            resString = _callJavascript(context, nsCodeString);
        });
    }
    Py_END_ALLOW_THREADS
    
    return NSStringToPythonString(resString);
}

static PyObject *module_resourcePath(PyObject *self, PyObject *args) {
    NSString *mainPath = [[[NSBundle mainBundle] resourceURL] absoluteString];
    return NSStringToPythonString(mainPath);
}

static PyMethodDef CallbackMethods[] = {
    {"eval_js", module_evalJS, METH_VARARGS, "evaluate the given javascript string in the given context and return the result as a string"},
    {"path", module_resourcePath, METH_VARARGS, 
        "returns the filesystem path that application python modules are in"},
    {NULL, NULL, 0, NULL}
};

PyObject *loadDelegate(NSObject *obj) {
    PY_BEGIN
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
    PY_END
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
    Py_InitModule("_webkit", CallbackMethods);
    PyRun_SimpleString(
            "import sys,_webkit,os,urlparse,urllib;"
            "path = urllib.unquote(urlparse.urlparse(_webkit.path()).path);"
            "sys.path.insert(0, path);"
            "sys.path.insert(0, os.getcwd());");
    PyEval_InitThreads();
    PyEval_SaveThread();
}

void PythonGlue_Finalize() {
    Py_Finalize();
}
