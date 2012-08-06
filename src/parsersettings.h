#ifndef PARSERSETTINGS_H_
#define PARSERSETTINGS_H_

#include <string>

void parser_init(const std::string &applicationpath);
void add_librarydir(const std::string &libdir);
std::string locate_file(const std::string &filename);

#endif
