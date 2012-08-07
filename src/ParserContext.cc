
#include "ParserContext.h"


int lexerlex_init_extra (YY_EXTRA_TYPE user_defined,yyscan_t* scanner);
extern int parserdebug;
int parserparse (ParserContext *p_ctx);
void lexerdestroy(yyscan_t yyscanner);
int lexerlex_destroy (yyscan_t yyscanner );


int ParserFilesCache::has_file(std::string filename)
{
    return (this->files.find(filename) != this->files.end());
}

int ParserFilesCache::add(char *filename, char *text)
{
    this->files[filename] = text;
    return 0;
}

std::string ParserFilesCache::getsrc(std::string filename)
{
    if(!this->has_file(filename))
        return NULL;
    return std::string(this->files[filename]);
}

ParserContext::ParserContext(ParserFilesCache *cache) 
    : scanner(NULL), 
    parser_input_buffer(NULL), 
    parser_source_path(""),
    parser_error_pos(-1),
    stringcontents(""),
    filename(""),
    filepath(""),
    currmodule(NULL),
    files_cache(cache)
{
    rootmodule = new Module();
}

Module *ParserContext::parse(std::string filename)
{
    
    if(!this->files_cache->has_file(filename))
        return NULL;
    
    this->parser_input_buffer = this->files_cache->getsrc(filename).c_str();
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
