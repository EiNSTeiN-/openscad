
import sys
import os

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import openscad

class ScadParser():
    def __init__(self):
        
        # this is only to set library path
        #openscad.parser_init(cwd)
        
        self.files = openscad.ParserFilesCache()
        
        return
    
    def add(self, name, text):
        r = self.files.add(name, text)
        return r
    
    def getfiles(self):
        r = self.files.getfiles()
        return r
    
    def to_stl(self, name):
        
        ctx = openscad.ParserContext(self.files)
        root_module = ctx.parse(name)
        if not root_module:
            return "error"
        
        tree = openscad.Tree()
        cgalevaluator = openscad.CGALEvaluator(tree)
        
        root_ctx = openscad.Context()
        openscad.register_builtin(root_ctx)
        root_inst = openscad.ModuleInstantiation()
        
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
