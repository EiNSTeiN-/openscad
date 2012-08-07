/*
 *  OpenSCAD (www.openscad.org)
 *  Copyright (C) 2009-2011 Clifford Wolf <clifford@clifford.at> and
 *                          Marius Kintel <marius@kintel.net>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  As a special exception, you have permission to link this program
 *  with the CGAL library and distribute executables, as long as you
 *  follow the requirements of the GNU GPL in regard to all of the
 *  software in the executable aside from CGAL.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

%{

#include "handle_dep.h"
#include "printutils.h"
#include "parsersettings.h"
#include "parser_yacc.h"
#include "module.h"
#include <assert.h>
#include <boost/foreach.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;
#include "boosty.h"
#include "ParserContext.h"

//isatty for visual c++ and mingw-cross-env
#if defined __WIN32__ && ! defined _MSC_VER
#include "unistd.h"
#endif
#if defined __WIN32__ || defined _MSC_VER
extern "C" int __cdecl _isatty(int _FileHandle);
#define isatty _isatty
#endif

class IncludeFile {
public:
    IncludeFile(std::string content) : content(content), pos(0) {}
    char getc() { return content[pos++]; }
private:
    std::string content;
    unsigned int pos;
};

#define LEXER_TO_PARSER() ((ParserContext *)lexerget_extra(yyscanner))

#define YY_INPUT(buf,result,max_size) {   \
  if (LEXER_TO_PARSER()->includestack.size() > 0) {            \
    int c = LEXER_TO_PARSER()->includestack.back()->getc();                  \
    if (c != 0) {                         \
      result = 1;                         \
      buf[0] = c;                         \
    } else {                              \
      result = YY_NULL;                   \
    }                                     \
  } else {                                \
    if (*LEXER_TO_PARSER()->parser_input_buffer) {  \
      result = 1;                         \
      buf[0] = *(LEXER_TO_PARSER()->parser_input_buffer++);  \
      LEXER_TO_PARSER()->parser_error_pos++;                 \
    } else {                              \
      result = YY_NULL;                   \
    }                                     \
  }                                       \
}

void includefile(yyscan_t yyscanner);
fs::path sourcepath(yyscan_t);

%}

%option yylineno
%option noyywrap
%option reentrant
%option bison-bridge

%x cond_comment cond_string
%x cond_include
%x cond_use

D [0-9]
E [Ee][+-]?{D}+

%%

include[ \t\r\n>]*"<"	{ BEGIN(cond_include); }
<cond_include>{
[^\t\r\n>]*"/"	{ LEXER_TO_PARSER()->filepath = yytext; }
[^\t\r\n>/]+	{ LEXER_TO_PARSER()->filename = yytext; }
">"		{ BEGIN(INITIAL); includefile(yyscanner); }
}


use[ \t\r\n>]*"<"	{ BEGIN(cond_use); }
<cond_use>{
[^\t\r\n>]+	{ LEXER_TO_PARSER()->filename = yytext; }
 ">"		{ 
	BEGIN(INITIAL); 
     
     #if 0
        fs::path usepath;
        if (boosty::is_absolute(fs::path(LEXER_TO_PARSER()->filename))) {
          usepath = LEXER_TO_PARSER()->filename;
        }
        else {
          usepath = sourcepath(yyscanner) / LEXER_TO_PARSER()->filename;
          if (!fs::exists(usepath)) {
            usepath = locate_file(LEXER_TO_PARSER()->filename);
          }
        }
        /* Only accept regular files which exists */
        if (usepath.has_parent_path() && fs::exists(usepath)) {
          handle_dep(usepath.string());
          yylval_param->text = strdup(usepath.string().c_str());
          return TOK_USE;
        }
    #endif
 }
}

<<EOF>> {
	if(!LEXER_TO_PARSER()->path_stack.empty())
        LEXER_TO_PARSER()->path_stack.pop_back();
	if (LEXER_TO_PARSER()->includestack.size() > 0) {
		assert(!LEXER_TO_PARSER()->includestack.empty());
		delete LEXER_TO_PARSER()->includestack.back();
		LEXER_TO_PARSER()->includestack.pop_back();
	}
	yypop_buffer_state(yyscanner);
	if (!YY_CURRENT_BUFFER)
		yyterminate();
}

"module"	return TOK_MODULE;
"function"	return TOK_FUNCTION;
"if"		return TOK_IF;
"else"		return TOK_ELSE;

"true"		return TOK_TRUE;
"false"		return TOK_FALSE;
"undef"		return TOK_UNDEF;

{D}+{E}? | 
{D}*\.{D}+{E}? |
{D}+\.{D}*{E}?          { yylval_param->number = boost::lexical_cast<double>(yytext); return TOK_NUMBER; }
"$"?[a-zA-Z0-9_]+       { yylval_param->text = strdup(yytext); return TOK_ID; }

\"			{ BEGIN(cond_string); LEXER_TO_PARSER()->stringcontents.clear(); }
<cond_string>{
\\n			{ LEXER_TO_PARSER()->stringcontents += '\n'; }
\\t			{ LEXER_TO_PARSER()->stringcontents += '\t'; }
\\r			{ LEXER_TO_PARSER()->stringcontents += '\r'; }
\\\\			{ LEXER_TO_PARSER()->stringcontents += '\\'; }
\\\"			{ LEXER_TO_PARSER()->stringcontents += '"'; }
[^\\\n\"]+		{ LEXER_TO_PARSER()->stringcontents += lexerget_text(yyscanner); }
\"			{ BEGIN(INITIAL); 
			yylval_param->text = strdup(LEXER_TO_PARSER()->stringcontents.c_str()); 
			return TOK_STRING; }
}

[\n\r\t ]
\/\/[^\n]*\n?
"/*" BEGIN(cond_comment);
<cond_comment>"*/" BEGIN(INITIAL);
<cond_comment>.|\n

"<="	return LE;
">="	return GE;
"=="	return EQ;
"!="	return NE;
"&&"	return AND;
"||"	return OR;

. { return yytext[0]; }

%%

fs::path sourcepath(yyscan_t yyscanner)
{
  if (!LEXER_TO_PARSER()->path_stack.empty())
      return LEXER_TO_PARSER()->path_stack.back();
  
  return fs::path(LEXER_TO_PARSER()->parser_source_path);
}

/*
  Rules for include <path/file>
  1) include <sourcepath/path/file>
  2) include <librarydir/path/file>
 */
void includefile(yyscan_t yyscanner)
{
    if (LEXER_TO_PARSER()->filename.empty()) {
        return;
    }
    
    fs::path dirinfo = sourcepath(yyscanner);
    if (boosty::is_absolute(fs::path(LEXER_TO_PARSER()->filepath))) {
      dirinfo = LEXER_TO_PARSER()->filepath;
    }
    else {
      dirinfo /= LEXER_TO_PARSER()->filepath;
    }
    
    fs::path finfo = dirinfo / LEXER_TO_PARSER()->filename;
    if (!LEXER_TO_PARSER()->files_cache->has_file(finfo.string())) {
        //finfo = locate_file((fs::path(LEXER_TO_PARSER()->filepath) / LEXER_TO_PARSER()->filename).string());
        PRINTB("WARNING: Can't find input file '%s'.", finfo.string());
        return;
    }
    
    LEXER_TO_PARSER()->path_stack.push_back(finfo.parent_path());

    std::string fullname = finfo.string(); //boosty::absolute(finfo).string();
    //handle_dep(fullname);
    
    LEXER_TO_PARSER()->currmodule->registerInclude(fullname);
    std::string s = LEXER_TO_PARSER()->files_cache->getsrc(finfo.string());
    IncludeFile *f = new IncludeFile(s);
    
    LEXER_TO_PARSER()->includestack.push_back(f);
    
    LEXER_TO_PARSER()->filename.clear();
    LEXER_TO_PARSER()->filepath.clear();
    
    yypush_buffer_state(yy_create_buffer(NULL, YY_BUF_SIZE, yyscanner), yyscanner);
}

/*!
  In case of an error, this will make sure we clean up our custom data structures 
  and close all files.
*/
void lexerdestroy(yyscan_t yyscanner)
{
  BOOST_FOREACH (IncludeFile *f, LEXER_TO_PARSER()->includestack) delete f;
  LEXER_TO_PARSER()->includestack.clear();
  LEXER_TO_PARSER()->path_stack.clear();
}
