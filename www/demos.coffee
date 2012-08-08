
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
            </div>
            <div id="demo" style="float: left; border: 0px #808080 solid; padding: 4px;">
                
            </div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @select('#simple')[0].observe 'click', (e) => @show_demo(SimpleDemo)
        @select('#include')[0].observe 'click', (e) => @show_demo(IncludeDemo)
        
        demo = @anchor_demo()
        console.log demo
        if demo?
            @show_demo(SimpleDemo) if demo == 'simple'
            @show_demo(IncludeDemo) if demo == 'include'
        
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

Event.observe window, 'load', () ->
    o = new App()
    $('body').insert o
