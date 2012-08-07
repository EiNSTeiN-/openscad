"""
Configure apache with the following:


  DocumentRoot /some/dir

  <Directory /some/dir>
    SetHandler mod_python
    PythonHandler mod_python.publisher
  </Directory>
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from scadparser import ScadParser

sys.stdout = sys.stderr

import atexit
import threading
import cherrypy

import mod_wsgi

import traceback

from cherrypy.lib.sessions import Session

cherrypy.config.update({'environment': 'embedded'})
cherrypy.config.update({'tools.sessions.on': True})

if cherrypy.__version__.startswith('3.0') and cherrypy.engine.state == 0:
    cherrypy.engine.start(blocking=False)
    atexit.register(cherrypy.engine.stop)

class Root(object):
    
    def index(self):
        return 'Hello World!'
    index.exposed = True
    
    def new(self):
        
        try:
            s = cherrypy.session
            if s.has_key('parser'):
                del s['parser']
            
            s.clear()
            
            s['parser'] = ScadParser()
            s.save()
        except:
            #return traceback.format_exc().replace('\n', '<br />')
            return "exception"
        
        return "ok"
    new.exposed = True

    def add(self, name, text):
        
        try:
            s = cherrypy.session
            if not s.has_key('parser'):
                return "error"
            
            s['parser'].add(str(name), str(text))
        except:
            return traceback.format_exc().replace('\n', '<br />')
            return "exception"
        
        return "ok"
    add.exposed = True

    def to_stl(self, name):
        
        try:
            s = cherrypy.session
            if not s.has_key('parser'):
                return "error"
            
            stl = s['parser'].to_stl('/main.scad')
            
            return stl
        except:
            #return traceback.format_exc().replace('\n', '<br />')
            return "exception"
        
        return "error?"
    to_stl.exposed = True

application = cherrypy.Application(Root(), script_name=None, config=None)

