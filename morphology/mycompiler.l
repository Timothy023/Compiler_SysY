%option noyywrap
%{

#include <stdio.h>
#include <stdlib.h>

int num_line = 1, num_char = 1;

%}

digit [0-9]
letter [A-Za-z_]
empty [ \t\r]
operator "="|"+"|"-"|"*"|"/"|"%"|"=="|"!="|"<"|">"|"<="|">="|"!"|"&&"|"||"|"&"|"|"|"^"
keywords "int"|"main"|"return"|"if"|"break"|"continue"|"while"|"const"|"else"
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

{bound} {
    printf ("%s: D, (%d, %d)\n", yytext, num_line, num_char); 
    num_char += yyleng; 
}

{keywords} {
    printf ("%s: K, (%d, %d)\n", yytext, num_line, num_char); 
    num_char += yyleng;
}

{letter}({letter}|{digit})* { 
    printf ("%s: I, (%d, %d)\n", yytext, num_line, num_char);
    num_char += yyleng;
}

{numberD}|{numberO}|{numberH} {
    if (yyleng > 10) printf ("Waring! ");
    printf ("%s: C, (%d, %d)\n", yytext, num_line, num_char);
    num_char += yyleng;
}

{operator} {
    printf ("%s: O, (%d, %d)\n", yytext, num_line, num_char); 
    num_char += yyleng; 
}

\n { num_line++; num_char = 1; }

{empty} { if (yytext != "\r") num_char += yyleng; }

. {
    printf ("%s: T, (%d, %d)\n", yytext, num_line, num_char);
    num_char += yyleng;
}

%%

int main(int argc, char *argv[]) {
    freopen (argv[1], "r", stdin);
    yyin = stdin;
    yylex();
    return 0;
}
