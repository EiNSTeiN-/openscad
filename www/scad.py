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

from simplejson import JSONEncoder

import atexit
import threading
import cherrypy

import dulwich
import tempfile
import urlparse

import mod_wsgi

import traceback

from cherrypy.lib.sessions import FileSession

cherrypy.config.update({'environment': 'embedded'})
cherrypy.config.update({'tools.sessions.on': True})
#~ cherrypy.config.update({'tools.sessions.storage_type': "file"})
#~ cherrypy.config.update({'tools.sessions.storage_path': "/tmp"})
#~ cherrypy.config.update({'tools.sessions.timeout': '120'})

cherrypy.lib.sessions.init(storage_type='File', storage_path='/tmp')

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
            print traceback.format_exc().replace('\n', '<br />')
            return "exception"
        
        return "ok"
    new.exposed = True
    
    def getfiles(self):
        
        cherrypy.response.headers['Content-Type'] = 'application/json'
        
        try:
            s = cherrypy.session
            s.load()
            if not s.has_key('parser'):
                return "error"
            
            files = s['parser'].getfiles()
            print 'sources...', repr(files)
            
            files = [(k, files[k]) for k in files]
            
            s.save()
            return JSONEncoder().iterencode({'files': files})
        except:
            print traceback.format_exc()
            return "exception"
        
        return "error?"
    getfiles.exposed = True
    
    def git_import(self, url):
        
        try:
            s = cherrypy.session
            s.load()
            if not s.has_key('parser'):
                return "error"
            
            path = tempfile.mkdtemp(prefix = 'git')
            
            p = urlparse.urlparse(url)
            
            left = '%s://%s' % (p.scheme, p.netloc)
            right = '%s' % (p.path, )
            
            print 'importing %s%s into %s' % (left, right, path)
            
            r = dulwich.repo.Repo.init_bare(path)
            
            refs = dulwich.client.HttpGitClient(left).fetch(right, r)
            
            r['HEAD'] = refs['HEAD']
            commit = r.get_object(refs['HEAD'])
            print 'head ==', repr(commit)

            tree = r.tree(commit.tree)
            print 'head tree ==', repr(tree)

            def get_files(r, tree, prefix = ''):
                files = []
                for entry in tree.entries():
                    try:
                        sz, name, sha = entry
                        obj = r.get_object(sha)
                        print repr(name), repr(obj.__class__)
                        if obj.__class__ == dulwich.objects.Tree:
                            files += get_files(r, obj, prefix + '/' + name)
                        elif obj.__class__ == dulwich.objects.Blob:
                            files.append([prefix + '/' + name, sha])
                        else:
                            print 'Unknown object type', repr(obj.__class__)
                    except:
                        print 'failed on', repr(entry)
                return files

            files = get_files(r, tree)

            for entry in files:
                name, sha = entry
                if not name.endswith('.scad'):
                    continue
                
                blob = r.get_object(sha)
                text = blob.data
                
                self.add(str(name), str(text))
            
            s.save()
            print repr(files)
        
        except:
            return traceback.format_exc().replace('\n', '<br />')
            return "exception"

        print 'done', path
        
        return "ok"
    git_import.exposed = True

    def add(self, name, text):
        
        try:
            s = cherrypy.session
            s.load()
            if not s.has_key('parser'):
                return "error"
            
            s['parser'].add(str(name), str(text))
            
            s.save()
        except:
            return traceback.format_exc().replace('\n', '<br />')
            return "exception"
        
        return "ok"
    add.exposed = True

    def to_stl(self, name):
        
        try:
            s = cherrypy.session
            #~ s.load()
            if not s.has_key('parser'):
                return "error"
            
            stl = s['parser'].to_stl(str(name))
            
            print repr(stl)
            
            #~ s.save()
            return stl
        except:
            print traceback.format_exc()
            return "exception"
        
        return "error?"
    to_stl.exposed = True

application = cherrypy.Application(Root(), script_name=None, config=None)

