
#include "ParserContext.h"


int lexerlex_init_extra (YY_EXTRA_TYPE user_defined,yyscan_t* scanner);
extern int parserdebug;
int parserparse (ParserContext *p_ctx);
void lexerdestroy(yyscan_t yyscanner);
int lexerlex_destroy (yyscan_t yyscanner );


ParserContext::ParserContext() 
    : scanner(NULL), 
    parser_input_buffer(NULL), 
    parser_source_path(""),
    parser_error_pos(-1),
    stringcontents(""),
    filename(""),
    filepath(""),
    currmodule(NULL)
{
    rootmodule = new Module();
}

int ParserContext::has_file(std::string filename)
{
    return (this->srcfiles.find(filename) != this->srcfiles.end());
}

int ParserContext::add(std::string filename, std::string text)
{
    this->srcfiles[filename] = text;
    return 0;
}

std::string ParserContext::getsrc(std::string filename)
{
    if(!this->has_file(filename))
        return NULL;
    return std::string(this->srcfiles[filename]);
}

Module *ParserContext::parse(std::string filename)
{
    
    if(!this->has_file(filename))
        return NULL;
    
    this->parser_input_buffer = this->srcfiles[filename].c_str();
    this->parser_source_path = std::string("/");
    this->path_stack.push_back("/");
    
    lexerlex_init_extra(this, &this->scanner);
    
    this->module_stack.clear();
    
    this->currmodule = this->rootmodule;
    
    //parserdebug = 1;
    
    parserparse(this);
    lexerdestroy(this->scanner);
    
    lexerlex_destroy(this->scanner);
    
    if (!rootmodule) {
        return NULL;
    }
    
    return this->rootmodule;
}
