
"""
Configure apache with the following:


  DocumentRoot /some/dir

  <Directory /some/dir>
    SetHandler mod_python
    PythonHandler mod_python.publisher
  </Directory>
"""

def to_stl(req, text):
    #nodecache = openscad.NodeCache()
    #dumper = openscad.NodeDumber(nodecache)
    
    openscad.Builtins.instance(False).initialize()
    
    cwd = os.getcwd()
    filename = os.path.abspath(sys.argv[1])
    path = os.path.dirname(os.path.abspath(filename))
    output = os.path.join(cwd, sys.argv[2])
    
    openscad.parser_init(cwd)
    
    tree = openscad.Tree()
    cgalevaluator = openscad.CGALEvaluator(tree)
    
    root_ctx = openscad.Context()
    openscad.register_builtin(root_ctx)
    
    root_inst = openscad.ModuleInstantiation()
    
    text = file(filename, 'rb').read()
    
    openscad.handle_dep(filename)
    
    root_module = openscad.parse(text, path, False)
    root_module.handleDependencies()
    
    os.chdir(path)
    
    openscad.AbstractNode.resetIndexCounter()
    
    root_node = root_module.evaluate(root_ctx, root_inst)
    tree.root = root_node
    
    root_N = cgalevaluator.evaluateCGALMesh(tree.root)
    
    if root_N.dim != 3:
        return "Current top level object is not a 3D object."
    
    if not root_N.p3.is_simple():
        return "Object isn't a valid 2-manifold! Modify your design."
    
    stl = openscad.export_stl(root_N)
    
    return stl
