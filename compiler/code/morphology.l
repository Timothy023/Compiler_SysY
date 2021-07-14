%option noyywrap
%{

#include <stdio.h>
#include "y.tab.h"

extern int cnt;
extern char Labe[100000][50];

int num_line = 1, num_char = 1;

%}

digit [0-9]
letter [A-Za-z_]
empty [ \t\r]
operator "="|"+"|"-"|"*"|"/"|"%"|"=="|"!="|"<"|">"|"<="|">="|"!"|"&&"|"||"|"&"|"|"|"^"
keywords "int"|"main"|"return"|"if"|"break"|"continue"|"while"|"const"|"else"|"void"
bound ","|";"|"{"|"}"|"["|"]"|"("|")"
numberD (-?)([1-9][0-9]+)|([0-9])
numberO (-?)(0[0-7]+)
numberH (-?)("0x"|"0X")([0-9a-fA-F])+

%%
"//".* {}
"/*"([^*]|[\r\n]|("*"+([^*/]|[\r\n])))*"*"+"/" {
    for (int i = 0; i < yyleng; ++i) {
        if (yytext[i] == '\n') {
            num_line++;
            num_char = 1;
        }
        else {
            num_char++;
        }
    }
}

"int"       { num_char += yyleng; yylval = ++cnt; return INT; }
"main"      { num_char += yyleng; yylval = ++cnt; return MAIN; }
"return"    { num_char += yyleng; yylval = ++cnt; return RETURN; }
"if"        { num_char += yyleng; yylval = ++cnt; return IF; }
"break"     { num_char += yyleng; yylval = ++cnt; return BREAK; }
"continue"  { num_char += yyleng; yylval = ++cnt; return CONTINUE; }
"while"     { num_char += yyleng; yylval = ++cnt; return WHILE; }
"const"     { num_char += yyleng; yylval = ++cnt; return CONST; }
"else"      { num_char += yyleng; yylval = ++cnt; return ELSE; }
"void"      { num_char += yyleng; yylval = ++cnt;  return VOID; }

","     { num_char += yyleng; yylval = ++cnt; return BC; }
";"     { num_char += yyleng; yylval = ++cnt; return BS; }
"{"     { num_char += yyleng; yylval = ++cnt; return BLB; }
"}"     { num_char += yyleng; yylval = ++cnt; return BRB; }
"["     { num_char += yyleng; yylval = ++cnt; return BLM; }
"]"     { num_char += yyleng; yylval = ++cnt; return BRM; }
"("     { num_char += yyleng; yylval = ++cnt; return BLL; }
")"     { num_char += yyleng; yylval = ++cnt; return BRL; }

"="      { num_char += yyleng; yylval = ++cnt; return OE; }
"+"      { num_char += yyleng; yylval = ++cnt; return OP; }
"-"      { num_char += yyleng; yylval = ++cnt; return OS; }
"*"      { num_char += yyleng; yylval = ++cnt; return OM; }
"/"      { num_char += yyleng; yylval = ++cnt; return OD; }
"%"      { num_char += yyleng; yylval = ++cnt; return OMOD; }
"=="     { num_char += yyleng; yylval = ++cnt; return OEE; }
"!="     { num_char += yyleng; yylval = ++cnt; return ONE; }
"<"      { num_char += yyleng; yylval = ++cnt; return OL; }
">"      { num_char += yyleng; yylval = ++cnt; return OG; }
"<="     { num_char += yyleng; yylval = ++cnt; return OLE; }
">="     { num_char += yyleng; yylval = ++cnt; return OGE; }
"!"      { num_char += yyleng; yylval = ++cnt; return ON; }
"&&"     { num_char += yyleng; yylval = ++cnt; return OAND; }
"||"     { num_char += yyleng; yylval = ++cnt; return OOR;}

{letter}({letter}|{digit})* { 
    num_char += yyleng;
    yylval = ++cnt;
    strcpy(Labe[cnt], yytext);
    return IDENT;
}

{numberD}|{numberO}|{numberH} {
    if (yyleng > 10) printf ("Waring! ");
    num_char += yyleng;
    yylval = atoi(yytext);
    strcpy(Labe[cnt], yytext);
    return NUMBER;
}

\n { num_line++; num_char = 1; }

{empty} { if (yytext != "\r") num_char += yyleng; }

. {
    printf ("%s: T, (%d, %d)\n", yytext, num_line, num_char);
    num_char += yyleng;
    return ERROR;
}

%%
