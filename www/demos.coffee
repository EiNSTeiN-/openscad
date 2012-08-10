
class App
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, App.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        t = """
        <div>
            <div style="float: left; width: 800px; height: 20px; border: 1px #808080 solid; padding: 4px;">
                <a href="#demo/simple" id="simple">simple demo</a>
                <a href="#demo/include" id="include">include demo</a>
                <a href="#demo/git" id="git">git demo</a>
            </div>
            <div id="demo" style="float: left; border: 0px #808080 solid; padding: 4px;">
                
            </div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @select('#simple')[0].observe 'click', (e) => @show_demo(SimpleDemo)
        @select('#include')[0].observe 'click', (e) => @show_demo(IncludeDemo)
        @select('#git')[0].observe 'click', (e) => @show_demo(GitDemo)
        
        demo = @anchor_demo()
        console.log demo
        if demo?
            @show_demo(SimpleDemo) if demo == 'simple'
            @show_demo(IncludeDemo) if demo == 'include'
            @show_demo(GitDemo) if demo == 'git'
        
        return
    
    anchor_demo: () ->
        
        console.log document.location.href
        demo = document.location.href.match(/#demo\/(.+)/i)
        
        if demo and demo.length >= 2
            return demo[1]
        
        return
    
    cleanup: () ->
        @select('#demo')[0].update ''
    
    show_demo: (ctor) ->
        
        @cleanup()
        
        @demo = new ctor()
        @select('#demo')[0].insert @demo
        
        return
    

class SimpleDemo
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, SimpleDemo.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        t = """
        <div>
            <div style="float: left; width: 500px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <textarea id="text" style="width: 490px; height: 470px;">cylinder(h = 30, r = 8);</textarea>
                <input id="submit" type="button" value="OK" />
            </div>
            <div style="float: left; width: 800px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <canvas id="viewer" style="border: 1px solid;" width="780" height="468" ></canvas>

            </div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @viewer = new JSC3D.Viewer(@select('#viewer')[0])
        @viewer.setParameter('InitRotationX', -20);
        @viewer.setParameter('InitRotationY', 20);
        @viewer.setParameter('InitRotationZ', 0);
        @viewer.setParameter('ModelColor', '#CAA618');
        @viewer.setParameter('BackgroundColor1', '#FFFFFF');
        @viewer.setParameter('BackgroundColor2', '#383840');
        @viewer.setParameter('RenderMode', 'smooth');
        @viewer.setParameter('Definition', 'standard');
        @viewer.init();
        @viewer.update();

        @stl = new JSC3D.StlLoader((scene) => @viewer.replaceScene(scene))
        
        @select('#submit')[0].observe 'click', (e) => @new_session(e)
            
        return
        
    new_session: () ->
        
        console.log 'creating new session'
            
        # Make the request
        new Ajax.Request '/scad.wsgi/new', {
            asynchronous: false,
            parameters: {},
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'create session response: ' + response.responseText
                @add_file '/main.scad', $('text').value
                return
            onException: (t, e) => e.url = t.url; new api.Exception(e)
            onFailure: (t) => new api.Exception('Ajax error while getting photo list: ' + t.toString())
        }
        
        return
        
    add_file: (name, text) ->
        
        console.log 'adding file'
            
        # Make the request
        new Ajax.Request '/scad.wsgi/add', {
            asynchronous: false,
            parameters: {
                name: name,
                text: text
            },
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'add file response: ' + response.responseText
                @to_stl name
                return
            onException: (t, e) => e.url = t.url; new api.Exception(e)
            onFailure: (t) => new api.Exception('Ajax error while getting photo list: ' + t.toString())
        }
        
        return
        
    to_stl: (name) ->
        
        console.log 'generating stl'
        
        @stl.loadFromUrl('/scad.wsgi/to_stl?name=' + name)
        
        return
    
    render: () =>
        
        return

class IncludeDemo
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, IncludeDemo.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        file = """
        include <foo.scad>
        
        cube([bar, bar, 2]);
        """
        
        t = """
        <div>
            <div style="float: left; width: 500px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                File #1 name: <input type="text" id="name1" style="width: 400px;" value="main.scad" />
                <textarea id="file1" style="width: 490px; height: 210px;">#{file}</textarea>
                File #2 name: <input type="text" id="name2" style="width: 400px;" value="foo.scad" />
                <textarea id="file2" style="width: 490px; height: 210px;">bar = 12.4;</textarea>
                <input id="submit" type="button" value="OK" />
            </div>
            <div style="float: left; width: 800px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <canvas id="viewer" style="border: 1px solid;" width="780" height="468" ></canvas>

            </div>
        </div>
        """
        
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @viewer = new JSC3D.Viewer(@select('#viewer')[0])
        @viewer.setParameter('InitRotationX', -20);
        @viewer.setParameter('InitRotationY', 20);
        @viewer.setParameter('InitRotationZ', 0);
        @viewer.setParameter('ModelColor', '#CAA618');
        @viewer.setParameter('BackgroundColor1', '#FFFFFF');
        @viewer.setParameter('BackgroundColor2', '#383840');
        @viewer.setParameter('RenderMode', 'smooth');
        @viewer.setParameter('Definition', 'standard');
        @viewer.init();
        @viewer.update();

        @stl = new JSC3D.StlLoader((scene) => @viewer.replaceScene(scene))
        
        @select('#submit')[0].observe 'click', (e) => @new_session(e)
            
        return
        
    new_session: () ->
        
        console.log 'creating new session'
            
        # Make the request
        new Ajax.Request '/scad.wsgi/new', {
            asynchronous: false,
            parameters: {},
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'create session response: ' + response.responseText
                @add_file '/' + $('name1').value, $('file1').value
                @add_file '/' + $('name2').value, $('file2').value
                @to_stl $('name1').value
                return
            onException: (t, e) => e.url = t.url; new api.Exception(e)
            onFailure: (t) => new api.Exception('Ajax error while getting photo list: ' + t.toString())
        }
        
        return
    
    add_file: (name, text) ->
        
        console.log 'adding file'
            
        # Make the request
        new Ajax.Request '/scad.wsgi/add', {
            asynchronous: false,
            parameters: {
                name: name,
                text: text
            },
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'add file ' + name + ' response: ' + response.responseText
                return
            onException: (t, e) => e.url = t.url; new api.Exception(e)
            onFailure: (t) => new api.Exception('Ajax error while getting photo list: ' + t.toString())
        }
        
        return
        
    to_stl: (name) ->
        
        console.log 'generating stl'
        
        @stl.loadFromUrl('/scad.wsgi/to_stl?name=' + name)
        
        return
    
    render: () =>
        
        return

class GitDemo
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, GitDemo.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        t = """
        <div>
            <div style="float: left; width: 500px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                Git URL: <input type="text" id="repo-url" style="width: 365px;" value="https://github.com/GregFrost/rostock.git" />
                <input id="import" type="button" value="import" />
                <div id="please-wait">Please wait...</div>
                <div id="git-browser">
                    <select id="file">
                    
                    </select>
                    <textarea id="text" style="width: 490px; height: 395px;"></textarea>
                    <input id="submit" type="button" value="Generate this file" /> changes are not saved for now...
                </div>
            </div>
            <div style="float: left; width: 800px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <canvas id="viewer" style="border: 1px solid;" width="780" height="468" ></canvas>

            </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @select('#please-wait')[0].hide()
        @select('#git-browser')[0].hide()
        
        @viewer = new JSC3D.Viewer(@select('#viewer')[0])
        @viewer.setParameter('InitRotationX', -20);
        @viewer.setParameter('InitRotationY', 20);
        @viewer.setParameter('InitRotationZ', 0);
        @viewer.setParameter('ModelColor', '#CAA618');
        @viewer.setParameter('BackgroundColor1', '#FFFFFF');
        @viewer.setParameter('BackgroundColor2', '#383840');
        @viewer.setParameter('RenderMode', 'smooth');
        @viewer.setParameter('Definition', 'standard');
        @viewer.init();
        @viewer.update();

        @stl = new JSC3D.StlLoader((scene) => @viewer.replaceScene(scene))
        
        @select('#import')[0].observe 'click', (e) => @new_session(e)
        @select('#submit')[0].observe 'click', (e) => @to_stl($('file').value)
        @select('#file')[0].observe 'change', (e) => @openfile($('file').value)
            
        return
        
    new_session: () ->
        
        console.log 'creating new session'
            
        # Make the request
        new Ajax.Request '/scad.wsgi/new', {
            asynchronous: false,
            parameters: {},
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'create session response: ' + response.responseText
                @git_import $('repo-url').value
                return
            onException: (t, e) =>
                console.log(t.toString())
                console.log(e.toString())
            onFailure: (t) => console.log(t.toString())
        }
        
        return
    
    git_import: (url) ->
        
        console.log 'importing repository'
        
        $('please-wait').show()
        
        # Make the request
        new Ajax.Request '/scad.wsgi/git_import', {
            asynchronous: true,
            parameters: {
                url: url
            },
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'import ' + url + ' response: ' + response.responseText
                
                @getfiles()
                return
            onException: (t, e) =>
                console.log(t.toString())
                console.log(e.toString())
            onFailure: (t) => console.log(t.toString())
        }
        
        return
    
    getfiles: () ->
        
        console.log 'getting imported files'
        
        # Make the request
        new Ajax.Request '/scad.wsgi/getfiles', {
            asynchronous: true,
            parameters: {
            },
            evalJSON: true,
            onSuccess: (response) =>
                json = response.responseJSON
                console.log 'get files response: ' + response.responseText
                
                @files = $(json.files)
                
                for entry in @files
                    console.log entry[0]
                    
                    o = new Element('option')
                    o.text = entry[0]
                    o.value = entry[0]
                    $('file').add o
                
                @openfile @files[0][0]
                
                $('please-wait').hide()
                $('git-browser').show()
                return
            onException: (t, e) =>
                console.log(t.toString())
                console.log(e.toString())
            onFailure: (t) => console.log(t.toString())
        }
        
        #console.log 'starting import status checker'
        #@exec = new PeriodicalExecuter(((pe) => @import_check(pe)), 0.5)
        
        return
    
    openfile: (name) ->
        
        for entry in @files
            continue if entry[0] != name
            
            $('text').value = entry[1]
            
            break
        
        return
    
    
    add_file: (name, text) ->
        
        console.log 'adding file'
            
        # Make the request
        new Ajax.Request '/scad.wsgi/add', {
            asynchronous: false,
            parameters: {
                name: name,
                text: text
            },
            evalJSON: true,
            onSuccess: (response) =>
                #json = response.responseJSON
                console.log 'add file ' + name + ' response: ' + response.responseText
                return
            onException: (t, e) =>
                console.log(t.toString())
                console.log(e.toString())
            onFailure: (t) => console.log(t.toString())
        }
        
        return
        
    to_stl: (name) ->
        
        console.log 'generating stl'
        
        @stl.loadFromUrl('/scad.wsgi/to_stl?name=' + name)
        
        return
    
    render: () =>
        
        return

Event.observe window, 'load', () ->
    o = new App()
    $('body').insert o
