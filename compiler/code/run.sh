flex ./morphology.l
yacc -d ./grammar.y
g++ y.tab.c lex.yy.c -o mc -O2 -w
./mc ./test.sy
gcc assemble.s -o assemble
./assemble