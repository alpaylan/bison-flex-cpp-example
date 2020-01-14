/*
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 Krzysztof Narkiewicz <krzysztof.narkiewicz@VLang.com>
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 * 
 */

%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.0"
%defines
%define parser_class_name { Parser }

%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define api.namespace { VLang }
%code requires
{
    #include <iostream>
    #include <string>
    #include <vector>
    #include <stdint.h>
    #include "command.h"

    using namespace std;

    namespace VLang {
        class Scanner;
        class Interpreter;
    }
}

// Bison calls yylex() function that must be provided by us to suck tokens
// from the scanner. This block will be placed at the beginning of IMPLEMENTATION file (cpp).
// We define this function here (function! not method).
// This function is called only inside Bison, so we make it static to limit symbol visibility for the linker
// to avoid potential linking conflicts.
%code top
{
    #include <iostream>
    #include "scanner.h"
    #include "parser.hpp"
    #include "interpreter.h"
    #include "location.hh"
    
    // yylex() arguments are defined in parser.y
    static VLang::Parser::symbol_type yylex(VLang::Scanner &scanner, VLang::Interpreter &driver) {
        return scanner.get_next_token();
    }
    
    // you can accomplish the same thing by inlining the code using preprocessor
    // x and y are same as in above static function
    // #define yylex(x, y) scanner.get_next_token()
    
    using namespace VLang;
}

%lex-param { VLang::Scanner &scanner }
%lex-param { VLang::Interpreter &driver }
%parse-param { VLang::Scanner &scanner }
%parse-param { VLang::Interpreter &driver }
%locations
%define parse.trace
%define parse.error verbose

%define api.token.prefix {TOKEN_}


%token END          0           "end of file"
%token <std::string>
    ID          "id"
    STRING      "string"
    ;
%token <uint64_t>   NUMBER      "number";
%token <double>     FLOAT       "float" ;
%token LP           ;
%token RP           ;
%token LB           ;
%token RB           ;
%token SEMICOLON    ;
%token COLON        ;
%token COMMA        ;
%token ASSN         ;

%token STRLTRL      ;

%token EQ           ;
%token NE           ;
%token LT           ;
%token LTE          ;
%token GT           ;
%token GTE          ;

%token AND          ;
%token OR           ;
%token NOT          ;

%token PLUS         ;
%token MIN          ;
%token MUL          ;
%token IDIV         ;
%token FDIV         ;
%token MOD          ;

%token Func         ;
%token Endfunc      ;
%token If           ;
%token Then         ;
%token Else         ;
%token Endif        ;
%token While        ;
%token Do           ;
%token Endwhile     ;
%token Print        ;
%token Read         ;
%token Return       ;
%token For          ;
%token Endfor       ;
%token To           ;
%token By           ;
%token Var          ;
%token Int          ;
%token Real         ;


%type<int> constant 





%type< VLang::Command > command;
%type< std::vector<uint64_t> > arguments;

%start program

%%

program : { driver.clear(); }
        | declaration_list_p function_list {
            cout << "There exists Global Variables" << endl; 
        }
        | function_list {
            cout << "No globals" << endl;
        }
        ;

        
declaration_list_p : declaration_list | declaration_list declaration_list_p;

function_list : function | function function_list;

function :  basic_type Func ID LP parameter_list RP 
                function_body
            Endfunc 
            {
                cout << "Function ID: " << $3 << endl;
            }
            | basic_type Func ID LP RP 
                function_body
            Endfunc {
                cout << "Function ID: " << $3 << endl;
            };
basic_type : Int | Real;

parameter_list : variable_list {
};

variable_list   : ID COLON type {
                }               
                | variable_list COMMA ID COLON type {
                }

type    : basic_type vector_extension
        | basic_type
        ;

vector_extension :  LB constant RB
                    | LB RB
                    ;

function_body   : declaration_list_p statement_list
                | statement_list
                ;

declaration_list : Var declaration SEMICOLON;

declaration : variable_list;


statement_list  : statement SEMICOLON
                | statement SEMICOLON statement_list
                ;

statement : assignment_statement
          | return_statement
          | print_statement
          | read_statement
          | for_statement
          | if_statement
          | while_statement
          ;


assignment_statement : variable ASSN expression;
return_statement : Return expression;
print_statement : Print printables;
read_statement : Read variables;
for_statement : For variable ASSN expression To expression By expression
                statement_list
                Endfor
                | For variable ASSN expression To expression
                statement_list
                Endfor
                ;
if_statement :  If lexpression
                  Then statement_list
                Endif
                | If lexpression
                  Then statement_list
                Else statement_list
                Endif
                ;
while_statement :   While lexpression
                        Do statement_list
                    Endwhile
                    ;

printable : expression | STRLTRL;
printables : printable COMMA printables
            | printable;

variable : ID | ID LB expression RB;
variables : variable COMMA variables
            | variable
            ;


expression : term
           | expression addop term
           ;

lexpression : expression
            | expression relop expression
            | lexpression logop lexpression
            | logop lexpression
            ;

addop : PLUS | MIN;
relop : EQ | NE | LT | LTE | GT | GTE;
logop : AND| OR | NOT;

term : factor
     | term mulop factor
     ;

mulop : MUL | IDIV | FDIV | MOD;

factor : variable
        | ID LP RP
        | ID LP argument_list RP
        | constant
        | LP expression RP
        | MIN expression
        ;

argument_list : expression_list;

expression_list : expression
                | expression_list COMMA expression
                ;





constant    : NUMBER {
	        $$ = $1;
            }           
            | FLOAT {
            $$ = $1;
            }

command : STRING LP RP
        {
            string &id = $1;
            $$ = Command(id);
        }
    | STRING LP arguments RP
        {
            string &id = $1;
            const std::vector<uint64_t> &args = $3;
            $$ = Command(id, args);
        }
    ;

arguments : constant
        {
            uint64_t number = $1;
            $$ = std::vector<uint64_t>();
            $$.push_back(number);
        }
    | arguments COMMA NUMBER
        {
            uint64_t number = $3;
            std::vector<uint64_t> &args = $1;
            args.push_back(number);
            $$ = args;
        }
    ;
    
%%

// Bison expects us to provide implementation - otherwise linker complains
void VLang::Parser::error(const location &loc , const std::string &message) {
        
        // Location should be initialized inside scanner action, but is not in this example.
        // Let's grab location directly from driver class.
	// cout << "Error: " << message << endl << "Location: " << loc << endl;
	
        cout << "Error: " << message << endl << "Error location: " << driver.location() << endl;
}
