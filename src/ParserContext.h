
#ifndef __PARSER_CONTEXT_H
#define __PARSER_CONTEXT_H


#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;

#include "module.h"

#define YY_EXTRA_TYPE ParserContext*
//#define YYLEX_PARAM   parser
//#define YYPARSE_PARAM parser
#define PARSER() (p_ctx)

typedef void* yyscan_t;

class ParserContext {
public:
    ParserContext();

    Module *parse(const char *text, const char *path, int debug);

    yyscan_t scanner;
    
    //FILE *lexerin;
    const char *parser_input_buffer;
    std::string parser_source_path;
    int parser_error_pos;
    
    std::string stringcontents;
    
    std::vector<fs::path> path_stack;
    std::vector<FILE*> openfiles;
    
    std::string filename;
    std::string filepath;
    
    std::vector<Module*> module_stack;
    Module *rootmodule;
    Module *currmodule;
};

#endif /* __PARSER_CONTEXT_H */
