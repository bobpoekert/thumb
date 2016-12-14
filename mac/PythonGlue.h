#include <Python.h>

#define CAPSULE_NAME "webkit"

PyObject *wrapNSObject(NSObject *inp) {
    return PyCapsule_New(inp, CAPSULE_NAME, NULL); 
}

static PyObject *module_evalJS(PyObject *self, PyObject *args) {
    PyObject *contextCapsule;
    char *codeString;
    NSString *res = NULL;
    if (!PyArg_ParseTuple(args, "(Os)", &capsule, &codeString)) return NULL;
    AppDelegate *context = PyCapsule_GetPointer(contextCapsule, CAPSULE_NAME);
    if (context != NULL) {
        res = [context evalJavascript:[NSString stringWithUTF8String:codeString]];
    }
    Py_DECREF(contextCapsule);
    return res;
}

static PyMethodDef CallbackMethods = {
    {"eval_js", module_evalJS, METH_VARARGS, "evaluate the given javascript string in the given context and return the result as a string"},
    {NULL, NULL, 0, NULL}
};


void updatePythonPath(char *newPath) {
    PyObject *path = PySys_GetObject("path");
    PyObject *newPathstring = PyString_FromString(newPath);
    PyList_Insert(path, 0, newPathString);
    Py_DECREF(path);
    Py_DECREF(newPathString);
}

void addResourceToPythonPath() {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    char *cResourcePath = [resourcePath UTF8String];
    updatePythonPath(cResourcePath);
}

PyObject *loadModule(char *module_name) {
    PyObject *pyName = PyString_FromString(module_name);
    PyObject *pyModule = PyImport_Import(pyName);
    Py_DECREF(pyName);
    return pyModule;
}

PyObject *loadDelegate(NSObject *obj) {
    PyObject *delegate = NULL;
    PyObject *module = loadModule("main");
    PyObject *objRef = wrapNSObject(obj);
    if (module != NULL) {
        PyObject *mainFunc = PyObject_GetAttrString(module, "main");
        if (mainFunc != NULL) {
            PyObject *args = Py_BuildValue("(O)", objRef);
            delegate = PyObject_CallObject(mainFunc, args);
        }
        Py_DECREF(mainFunc);
    }
    Py_DECREF(module);
    return delegate;
}

PyObject *callFuncWithString(PyObject *func, char *arg) {
    PyObject *args = Py_BuildValue("(s)", arg);
    if (!args) return NULL;
    PyObject *res = PyObject_CallObject(func, args);
    Py_DECREF(args);
    return res;
}

PyObject *NSStringToPythonString(NSString *inp) {
    char *string = [inp UTF8String];
    return PyString_FromString(string);
}

void PythonGlue_Init(int argc, char *argv) {
    Py_SetProgramName(argv[0]);
    Py_Initialize();
    Py_InitModule("_webkit_callback", CallbackMethods);
    addResourceToPythonPath();
}
