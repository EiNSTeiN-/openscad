
#ifndef __PARSER_CONTEXT_H
#define __PARSER_CONTEXT_H

#include <string>
#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;

#include "module.h"

#define YY_EXTRA_TYPE ParserContext*
//#define YYLEX_PARAM   parser
//#define YYPARSE_PARAM parser
#define PARSER() (p_ctx)

typedef void* yyscan_t;

class IncludeFile;

class ParserContext {
public:
    ParserContext();
    
    // add a new file with its text.
    int add(std::string filename, std::string text);
    
    int has_file(std::string filename);
    std::string getsrc(std::string filename);
    
    // parse a file which must already be add()'ed
    Module *parse(std::string filename);
    
    // below is the parser stuff
    yyscan_t scanner;
    
    const char *parser_input_buffer;
    std::string parser_source_path;
    int parser_error_pos;
    
    std::string stringcontents;
    
    std::vector<fs::path> path_stack;
    std::vector<IncludeFile *> includestack;
    
    std::string filename;
    std::string filepath;
    
    std::vector<Module*> module_stack;
    Module *rootmodule;
    Module *currmodule;
    
private:
    // a map of all files in this project.
    boost::unordered_map<std::string, std::string> srcfiles;
};

#endif /* __PARSER_CONTEXT_H */
