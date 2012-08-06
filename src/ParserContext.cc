
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

Module *ParserContext::parse(const char *text, const char *path, int debug)
{
    
    this->parser_input_buffer = text;
    this->parser_source_path = std::string(path);
    
    lexerlex_init_extra(this, &this->scanner);
    
    this->module_stack.clear();
    
    this->currmodule = this->rootmodule;
    
    parserdebug = debug;
    
    parserparse(this);
    lexerdestroy(this->scanner);
    
    lexerlex_destroy(this->scanner);
    
    if (!rootmodule) {
        return NULL;
    }
    
    return this->rootmodule;
}
