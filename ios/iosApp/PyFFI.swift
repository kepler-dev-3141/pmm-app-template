import Foundation
import Common

private let customBuiltinImportString = """
    import sys, imp, types
    from os import environ
    from os.path import exists, join

    try:
        # python 3
        import _imp

        EXTS = _imp.extension_suffixes()
        sys.modules['subprocess'] = types.ModuleType(name='subprocess')
        sys.modules['subprocess'].PIPE = None
        sys.modules['subprocess'].STDOUT = None
        sys.modules['subprocess'].DEVNULL = None
        sys.modules['subprocess'].CalledProcessError = Exception
        sys.modules['subprocess'].check_output = None
    except ImportError:
        EXTS = ['.so']

    # Fake redirection to supress console output
    if environ.get('KIVY_NO_CONSOLE', '0') == '1':
        class fakestd(object):
            def write(self, *args, **kw): pass
            def flush(self, *args, **kw): pass
        sys.stdout = fakestd()
        sys.stderr = fakestd()

    # Custom builtin importer for precompiled modules
    class CustomBuiltinImporter(object):
        def find_module(self, fullname, mpath=None):
            # print(f'find_module() fullname={fullname} mpath={mpath}')
            if '.' not in fullname:
                return
            if not mpath:
                return
            part = fullname.rsplit('.')[-1]
            for ext in EXTS:
                fn = join(list(mpath)[0], '{}{}'.format(part, ext))
            # print('find_module() {}'.format(fn))
            if exists(fn):
                return self
            return

        def load_module(self, fullname):
            f = fullname.replace('.', '_')
            mod = sys.modules.get(f)
            if mod is None:
                # print('LOAD DYNAMIC', f, sys.modules.keys())
                try:
                    mod = imp.load_dynamic(f, f)
                except ImportError:
                    # import traceback; traceback.print_exc();
                    # print('LOAD DYNAMIC FALLBACK', fullname)
                    mod = imp.load_dynamic(fullname, fullname)
                sys.modules[fullname] = mod
                return mod
            return mod

    sys.meta_path.insert(0, CustomBuiltinImporter())
    """

func pyInitialize() -> Void {
    // Special environment to prefer .pyo, and don't write bytecode if .py are found
    // because the process will not have a write attribute on the device.
    setenv("PYTHONOPTIMIZE", "2", 1)
    setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
    setenv("PYTHONNOUSERSITE", "1", 1)
    setenv("PYTHONPATH", ".", 1)
    setenv("PYTHONUNBUFFERED", "1", 1)
    setenv("LC_CTYPE", "UTF-8", 1)
    //setenv("PYTHO/System/Library/CoreServices/Finder.app/Contents/Resources/MyLibraries/myDocuments.cannedSearchNVERBOSE", "1", 1)
    //setenv("PYOBJUS_DEBUG", "1", 1)
    
    // Kivy environment to prefer some implementation on iOS platform
    setenv("KIVY_BUILD", "ios", 1);
    setenv("KIVY_WINDOW", "sdl2", 1);
    setenv("KIVY_IMAGE", "imageio,tex,gif,sdl2", 1);
    setenv("KIVY_AUDIO", "sdl2", 1);
    setenv("KIVY_GL_BACKEND", "sdl2", 1);
    
    // IOS_IS_WINDOWED=True disables fullscreen and then statusbar is shown
    setenv("IOS_IS_WINDOWED", "False", 1);

    #if RELEASE
    setenv("KIVY_NO_CONSOLELOG", "1", 1);
    #endif

    let pythonHome = Bundle.main.bundleURL.path
    setenv("PYTHONHOME", pythonHome, 1)

    setenv("PYTHONPATH", "\(pythonHome)/lib/python3.11/:\(pythonHome)/lib/python3.11/site-packages:\(pythonHome)/Binary", 1)

    setenv("TMP", NSTemporaryDirectory(), 1)

    // Init Python
    Py_Initialize()

    // Import Built-In functions
    PyRun_SimpleString(customBuiltinImportString)
    NSLog("INFO: Python Built-in functions are loaded.")
}

func pyFinalize() -> Void {
    Py_Finalize()
}

func pyImport(module: String) -> KotlinLong {
    let pointer: UnsafePointer<CChar>? = NSString(string: module).utf8String
    return KotlinLong.init(pointer: PyImport_Import(PyUnicode_DecodeFSDefault(pointer)))
}

func pyErrorOccurred() -> KotlinBoolean {
    return KotlinBoolean.init(pointer: PyErr_Occurred())
}

func pyErrorPrint() -> Void {
    PyErr_Print()
}

func pyObjectGetAttrString(obj: KotlinLong, attr: String) -> KotlinLong {
    let pointer: UnsafePointer<CChar>? = NSString(string: attr).utf8String
    let ptrObj = UnsafeMutablePointer<NativePyObject>(bitPattern: obj.uintValue)
    return KotlinLong.init(pointer: PyObject_GetAttrString(ptrObj, PyUnicode_DecodeFSDefault(pointer)))
}

func pyObjectCallObject(callable: KotlinLong, args: KotlinLong) -> KotlinLong {
    let callableObj = UnsafeMutablePointer<NativePyObject>(bitPattern: callable.uintValue)
    let argsObj = UnsafeMutablePointer<NativePyObject>(bitPattern: args.uintValue)
    return KotlinLong.init(pointer: PyObject_CallObject(callableObj, argsObj))
}
