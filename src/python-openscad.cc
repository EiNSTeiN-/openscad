#include <Python.h>

#include <boost/python.hpp>
#include <boost/foreach.hpp>
#include <boost/filesystem.hpp>
#include "boosty.h"

#include <QApplication>
#include <QDir>
#include <sstream>

#include "openscad.h"
#include "python-openscad.h"
#include "Tree.h"
#include "CGALEvaluator.h"
#include "context.h"
#include "module.h"
#include "CGAL_Nef_polyhedron.h"
#include "polyset.h"
#include "export.h"
#include "state.h"
#include "builtin.h"
#include "parsersettings.h"
#include "handle_dep.h"
#include "ParserContext.h"

using namespace boost::python;
/*
class AbstractModuleWrap : public AbstractModule, public wrapper<AbstractModule>
{
    AbstractNode *evaluate(const Context *ctx, const ModuleInstantiation *inst)
    {
        return this->get_override("evaluate")(ctx, inst);
    }
};*/

CGAL_Nef_polyhedron (CGALEvaluator::*evaluateCGALMesh_node)(const AbstractNode &) = &CGALEvaluator::evaluateCGALMesh;
CGAL_Nef_polyhedron (CGALEvaluator::*evaluateCGALMesh_polyset)(const PolySet &) = &CGALEvaluator::evaluateCGALMesh;

std::string (*export_stl_node)(class CGAL_Nef_polyhedron *) = export_stl;
#ifdef DEBUG
std::string (*export_stl_polyset)(const PolySet &) = &export_stl;
#endif

//std::string commandline_commands;
//std::string currentdir;
//QString examplesdir;

class VisitorWrap : public Visitor, public wrapper<Visitor>
{
    Response visit(class State &state, const class AbstractNode &node)
    {
        return this->get_override("visit")(state, node);
    }
};

class ParserFilesCache_pickle_suite : public boost::python::pickle_suite
{
public:
    static boost::python::tuple getinitargs(ParserFilesCache& files_cache)
    {
        return boost::python::make_tuple(files_cache.getfiles());
    }
};


class ParserFilesCache_wrap : public ParserFilesCache, public wrapper<ParserFilesCache>
{
public:
    boost::python::dict getfiles_wrap()
    {
        boost::python::dict d;
        filemap_t& files = this->getfiles();
        
        for (filemap_t::const_iterator it = files.begin(); it != files.end(); ++it)
            d[it->first] = it->second;
        
        return d;
    }
};


BOOST_PYTHON_MODULE(openscad)
{
    // do some general initialization stuff!
    Builtins::instance()->initialize();
    
    def("parser_init", parser_init);
    def("handle_dep", handle_dep);
    
    def("register_builtin", register_builtin);
    
    def("export_stl", export_stl_node);
    #ifdef DEBUG
    def("export_stl", export_stl_polyset);
    #endif
    
    class_<ParserFilesCache_wrap, boost::noncopyable>("ParserFilesCache")
        .def("has_file", &ParserFilesCache::has_file)
        .def("getsrc", &ParserFilesCache::getsrc)
        .def("getfiles", &ParserFilesCache_wrap::getfiles_wrap)
        .def("add", &ParserFilesCache::add)
        .def_pickle(ParserFilesCache_pickle_suite())
    ;
    class_<ParserContext>("ParserContext", init<ParserFilesCache *>())
        .def("parse", &ParserContext::parse, return_value_policy<reference_existing_object>())
    ;
    class_<Builtins, boost::noncopyable>("Builtins", no_init)
        .def("instance", &Builtins::instance, return_value_policy<reference_existing_object>())
        .staticmethod("instance")
        .def("initialize", &Builtins::initialize)
    ;
    class_<AbstractNode>("AbstractNode", init<const class ModuleInstantiation *>())
        .def("resetIndexCounter", &AbstractNode::resetIndexCounter)
        .staticmethod("resetIndexCounter")
    ;
    
    class_<Tree>("Tree", init< optional<const AbstractNode *> >())
        .add_property("root", make_function(&Tree::root, return_value_policy<reference_existing_object>()), &Tree::setRoot)
    ;
    
    class_<VisitorWrap, boost::noncopyable>("Visitor")
    ;
    
    class_<CGALEvaluator, bases<Visitor> >("CGALEvaluator", init<const class Tree &>())
        .def("evaluateCGALMesh", evaluateCGALMesh_node)
        .def("evaluateCGALMesh", evaluateCGALMesh_polyset)
    ;
    
    class_<Context>("Context", init< optional<const Context *, const class Module *> >())
    ;
    
    class_<AbstractModule>("AbstractModule")
        .def("evaluate", &AbstractModule::evaluate, return_value_policy<reference_existing_object>())
    ;
    
    class_<Module, bases<AbstractModule> >("Module")
        .def("handleDependencies", &Module::handleDependencies)
    ;
    
    class_<ModuleInstantiation>("ModuleInstantiation", init< optional<const std::string &> >())
        
    ;
    
    class_<CGAL_Nef_polyhedron3, shared_ptr<CGAL_Nef_polyhedron3> >("CGAL_Nef_polyhedron3")
        .def("is_simple", &CGAL_Nef_polyhedron3::is_simple)
    ;
    
    
    class_<CGAL_Nef_polyhedron>("CGAL_Nef_polyhedron")
        .def_readonly("dim", &CGAL_Nef_polyhedron::dim)
        .def_readonly("p2", &CGAL_Nef_polyhedron::p2)
        .def_readonly("p3", &CGAL_Nef_polyhedron::p3)
    ;
}

