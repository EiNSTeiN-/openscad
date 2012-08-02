#include <boost/python.hpp>

#include "openscad.h"
#include "Tree.h"
#include "CGALEvaluator.h"
#include "context.h"
#include "module.h"
#include "CGAL_Nef_polyhedron.h"
#include "polyset.h"
#include "export.h"

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

BOOST_PYTHON_MODULE(openscad)
{
    def("parse", parse,
        return_value_policy<manage_new_object>()); //Module *parse(const char *text, const char *path, int debug)
    
    def("export_stl", export_stl_node);
    #ifdef DEBUG
    def("export_stl", export_stl_polyset);
    #endif
    
    class_<AbstractNode>("AbstractNode", init<const class ModuleInstantiation *>())
        .def("resetIndexCounter", &AbstractNode::resetIndexCounter)
    ;
    class_<Tree>("Tree", init< optional<const AbstractNode *> >())
        .add_property("root", make_function(&Tree::root, return_value_policy<manage_new_object>()), &Tree::setRoot);
    ;
    
    class_<CGALEvaluator, bases<Visitor> >("CGALEvaluator", init<const class Tree &>())
        .def("evaluateCGALMesh", evaluateCGALMesh_node)
        .def("evaluateCGALMesh", evaluateCGALMesh_polyset)
    ;
    class_<Context>("Context", init< optional<const Context *, const class Module *> >())
    ;
    class_<AbstractModule>("AbstractModule")
        .def("evaluate", &AbstractModule::evaluate,
            return_value_policy<manage_new_object>())
    ;
    class_<Module, bases<AbstractModule> >("Module")
        
    ;
    class_<ModuleInstantiation>("ModuleInstantiation", init< optional<const std::string &> >())
        
    ;
    class_<CGAL_Nef_polyhedron3>("CGAL_Nef_polyhedron3")
        .def("is_simple", &CGAL_Nef_polyhedron3::is_simple)
    ;
    class_<CGAL_Nef_polyhedron>("CGAL_Nef_polyhedron")
        .def_readonly("dim", &CGAL_Nef_polyhedron::dim)
        .def_readonly("p2", &CGAL_Nef_polyhedron::p2)
        .def_readonly("p3", &CGAL_Nef_polyhedron::p3)
    ;
}

