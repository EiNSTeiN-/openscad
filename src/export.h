#ifndef EXPORT_H_
#define EXPORT_H_

#include <iostream>

#ifdef ENABLE_CGAL

std::string export_stl(class CGAL_Nef_polyhedron *root_N);
void export_off(CGAL_Nef_polyhedron *root_N, std::ostream &output);
void export_dxf(CGAL_Nef_polyhedron *root_N, std::ostream &output);

#endif

#ifdef DEBUG
std::string export_stl(const class PolySet &ps);
#endif

#endif
