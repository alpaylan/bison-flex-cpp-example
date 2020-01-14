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

%{
	#include <iostream>
	#include <cstdlib>
	#include "scanner.h"
	#include "interpreter.h"
	#include "parser.hpp"
	#include "location.hh"

	using namespace std;

	// Original yyterminate() macro returns int. Since we're using Bison 3 variants
	// as tokens, we must redefine it to change type from `int` to `Parser::semantic_type`
	#define yyterminate() VLang::Parser::make_END(VLang::location());

	// This will track current scanner location.
	// Action is called when length of the token is known.
	#define YY_USER_ACTION m_driver.increaseLocation(yyleng);
	
	// !!!WARNING!!!
	// Location API is used, but the location is not initialized, 'cause I'm lazy. When making
	// a token with make_{something} method you can pass detailed token location. Current location
	// is accessible with m_driver.location() method. All puzzle elements are there - just
	// pass location value in every action code block below. I'm going to waste more time writing
	// this excuse than putting this boilerplate below...
	//
	// Location class can be found in location.hh and posistion.hh files. It's just a bit too much
	// boilerplate for this small example. Bummer.
%}

%option nodefault
%option noyywrap
%option c++
%option yyclass="Scanner"
%option prefix="EzAquarii_"


id 			[A-Za-z]([A-Za-z0-9])*
integer  	[0-9]+ 
exponent  	[eE][-+]?[0-9]+
float  		({integer}"."{integer})|({integer}{exponent})|({integer}"."{integer}{exponent})
num	 		{integer}|{float}

%%


"%".*	{ /* DO NOTHING */ }

\"(\\.|[^"\\])*\" { 
	cout << "Scanner: 'string literal'" << endl;
	return VLang::Parser::make_STRLTRL(VLang::location());
}


"func"     {
	cout << "Scanner: 'func'" << endl;
	return VLang::Parser::make_Func(VLang::location());
}
"endfunc"  {
	cout << "Scanner: 'endfunc'" << endl;
	return VLang::Parser::make_Endfunc(VLang::location());
}
"if"       {
	cout << "Scanner: 'if'" << endl;
	return VLang::Parser::make_If(VLang::location());
}
"then"     {
	cout << "Scanner: 'then'" << endl;
	return VLang::Parser::make_Then(VLang::location());
}
"else"     {
	cout << "Scanner: 'else'" << endl;
	return VLang::Parser::make_Else(VLang::location());
}
"endif"    {
	cout << "Scanner: 'endif'" << endl;
	return VLang::Parser::make_Endif(VLang::location());
}
"while"    {
	cout << "Scanner: 'while'" << endl;
	return VLang::Parser::make_While(VLang::location());
}
"do"       {
	cout << "Scanner: 'do'" << endl;
	return VLang::Parser::make_Do(VLang::location());
}
"endwhile" {
	cout << "Scanner: 'endwhile'" << endl;
	return VLang::Parser::make_Endwhile(VLang::location());
}
"print"    {
	cout << "Scanner: 'print'" << endl;
	return VLang::Parser::make_Print(VLang::location());
}
"read"     {
	cout << "Scanner: 'read'" << endl;
	return VLang::Parser::make_Read(VLang::location());
}
"return"   {
	cout << "Scanner: 'return'" << endl;
	return VLang::Parser::make_Return(VLang::location());
}
"for"      {
	cout << "Scanner: 'for'" << endl;
	return VLang::Parser::make_For(VLang::location());
}
"endfor"   {
	cout << "Scanner: 'endfor'" << endl;
	return VLang::Parser::make_Endfor(VLang::location());
}
"to"       {
	cout << "Scanner: 'to'" << endl;
	return VLang::Parser::make_To(VLang::location());
}
"by"       {
	cout << "Scanner: 'by'" << endl;
	return VLang::Parser::make_By(VLang::location());
}
"var"      {
	cout << "Scanner: 'var'" << endl;
	return VLang::Parser::make_Var(VLang::location());
}
"int"      {
	cout << "Scanner: 'int'" << endl;
	return VLang::Parser::make_Int(VLang::location());
}
"real"     {
	cout << "Scanner: 'real'" << endl;
	return VLang::Parser::make_Real(VLang::location());
}

{id}     { 
	cout << "Scanner: identifier [" << yytext << "]" << endl;
	return VLang::Parser::make_ID(yytext, VLang::location( /* put location data here if	want */ )); 
}
\(          {
	cout << "Scanner: '('" << endl;
	return VLang::Parser::make_LP(VLang::location());
}
            
\)          { 
	cout << "Scanner: ')'" << endl;
	return VLang::Parser::make_RP(VLang::location());
}
            
;           {
	cout << "Scanner: ';'" << endl;
	return VLang::Parser::make_SEMICOLON(VLang::location());
}

:           {
	cout << "Scanner: ':'" << endl;
	return VLang::Parser::make_COLON(VLang::location());
}      
,           {
	cout << "Scanner: ','" << endl;
	return VLang::Parser::make_COMMA(VLang::location());
}
\[			{
	cout << "Scanner: '['" << endl;
	return VLang::Parser::make_LB(VLang::location());
}
\]			{
	cout << "Scanner: ']'" << endl;
	return VLang::Parser::make_RB(VLang::location());
}

[\n\t ]     {
	//cout << "Scanner: whitechar (ignored)" << endl;
}

:= 			{
	cout << "Scanner: ':='" << endl;
	return VLang::Parser::make_ASSN(VLang::location());
}

=			{
	cout << "Scanner: '='" << endl;
	return VLang::Parser::make_EQ(VLang::location());
}
"<>"			{
	cout << "Scanner: '<>'" << endl;
	return VLang::Parser::make_NE(VLang::location());
}
"<"			{
	cout << "Scanner: '<'" << endl;
	return VLang::Parser::make_LT(VLang::location());
}
"<="			{
	cout << "Scanner: '<='" << endl;
	return VLang::Parser::make_LTE(VLang::location());
}
">="			{
	cout << "Scanner: '>='" << endl;
	return VLang::Parser::make_GTE(VLang::location());
}
">"			{
	cout << "Scanner: '>'" << endl;
	return VLang::Parser::make_GT(VLang::location());
}
"and"		{
	cout << "Scanner: 'and'" << endl;
	return VLang::Parser::make_AND(VLang::location());
}
"or"		{
	cout << "Scanner: 'or'" << endl;
	return VLang::Parser::make_OR(VLang::location());
}
"not"		{
	cout << "Scanner: 'not'" << endl;
	return VLang::Parser::make_NOT(VLang::location());
}

"+"			{
	cout << "Scanner: '+'" << endl;
	return VLang::Parser::make_PLUS(VLang::location());
}
"-"			{
	cout << "Scanner: '-'" << endl;
	return VLang::Parser::make_MIN(VLang::location());
}
"*"			{
	cout << "Scanner: '*'" << endl;
	return VLang::Parser::make_MUL(VLang::location());
}
"/"			{
	cout << "Scanner: '/'" << endl;
	return VLang::Parser::make_FDIV(VLang::location());
}
"\'div\'"			{
	cout << "Scanner: 'div'" << endl;
	return VLang::Parser::make_IDIV(VLang::location());
}

"\'mod\'"			{
	cout << "Scanner: 'mod'" << endl;
	return VLang::Parser::make_MOD(VLang::location());
}


{integer} {
    cout << "Scanner: decimal number: " << yytext << endl;
    uint64_t number = strtoull(yytext, 0, 10);
    return VLang::Parser::make_NUMBER(number, VLang::location());
}

({integer}"."{integer})|({integer}{exponent})|({integer}"."{integer}{exponent}) {
    cout << "Scanner: floating point number: " << yytext << endl;
    double number = strtoull(yytext, 0, 10);
    return VLang::Parser::make_FLOAT(number, VLang::location());
}

.           { 
	cout << "Scanner: unknown character [" << yytext << "]" << endl; 
}
            
<<EOF>>     { return yyterminate(); }


%%
