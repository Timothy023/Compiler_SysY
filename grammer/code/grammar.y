%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern int yylex(void); 
extern int yyparse(void); 
extern int num_char, num_line;
extern char *yytext;

FILE *ft, *fd;

int cnt = 0;
int sum = 0;
char Labe[100000][50];
typedef struct {
    int child[10], size, nid, fid;
} node;
node a[100000];

int yywrap() {
	return 1;
}

void yyerror(const char *s) {
	printf("[error] %s", s);
    printf(" (%d, %d): \"%s\"\n", num_line, num_char, yytext);
}

void paint(int ro) {
    if (a[ro].size == 0) return;
    sum += 1;
    fprintf (ft, "node%d[label = \"", sum);
    for (int i = 0; i < a[ro].size; ++i) {
        int now = a[ro].child[i];
        a[now].nid = sum;
        a[now].fid = i;
        fprintf (ft, "<f%d> %s", i, Labe[now]);
        if (i + 1 != a[ro].size) fprintf (ft, "|");
        else fprintf (ft, "\"];\n");
    }
    fprintf (ft, "\"node%d\":f%d->\"node%d\";\n", a[ro].nid, a[ro].fid, sum);
    for (int i = 0; i < a[ro].size; ++i) {
        paint(a[ro].child[i]);
    }
}

int main(int argc, char *argv[]) {
	freopen (argv[1], "r", stdin);
    ft = fopen("Tree.dot", "w");
    fd = fopen("Detail.txt", "w");

    yyparse();

    fprintf (ft, "digraph \" \"{\n");
    fprintf (ft, "node [shape = record,height=.1]\n");
    fprintf (ft, "node0[label = \"<f0> %s\"];\n", Labe[cnt]);
    a[cnt].nid = a[cnt].fid = 0;
	paint(cnt);
    fprintf (ft, "}\n");

    fclose(ft);
    fclose(fd);
	return 0;
}
%}

%token NOELSE
%token INT MAIN RETURN IF BREAK CONTINUE WHILE CONST ELSE VOID
%token IDENT
%token BC BS BLB BRB BLM BRM BLL BRL
%token OE OP OS OM OD OMOD OEE ONE OL OG OLE OGE ON OAND OOR
%token NUMBER
%token ERROR

%left NOELSE
%left ELSE

%%
CompUnit: 
    /* empty */ {$$ = 0;}
    | CompUnit oCompUnit { 
        fprintf (fd, "CompUnit -> CompUnit {CompUnit}\n"); 
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "CompUnit");
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
oCompUnit: 
    Decl { 
        fprintf (fd, "oCompUnit -> Decl\n");
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "OtherCompUnit");
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | FuncDef { 
        fprintf (fd, "oCompUnit -> FuncDef\n"); 
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "OtherCompUnit");
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
Decl:
    ConstDecl { 
        fprintf (fd, "Decl -> ConstDecl\n");
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "Decl");
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | VarDecl { 
        fprintf (fd, "Decl -> VarDecl\n"); 
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "Decl");
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
ConstDecl:
    CONST INT ConstDef oConstDef BS { 
        fprintf (fd, "ConstDecl -> const int ConstDef {, ConstDef};\n"); 
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "ConstDecl");
        strcpy(Labe[$1], "const"); a[$1].size = 0;
        strcpy(Labe[$2], "int"); a[$2].size = 0;
        strcpy(Labe[$5], "\\;"); a[$5].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
    }
    | CONST error BS {printf("        Const declaration error.\n");}
;
oConstDef: 
    /* empty */ {$$ = 0;}
    | BC ConstDef oConstDef { 
        fprintf (fd, "Other ConstDef -> , ConstDef OtherConstDef\n"); 
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "OtherConstDef");
        strcpy(Labe[$1], "\\,"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
ConstDef:
    IDENT ConstArrayIndex OE CIV { 
        fprintf (fd, "ConstDef -> Ident = CIV\n");
        $$ = ++cnt; a[$$].size = 0;
        strcpy(Labe[$$], "ConstDef");
        strcpy(Labe[$3], "\\="); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
;
ConstArrayIndex:
    /* empty */ {$$ = 0;}
    | BLM ConstExp BRM { 
        fprintf (fd, "ConstArrayIndex -> [ ConstExp ]\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstArrayIndex"); a[$$].size = 0;
        strcpy(Labe[$1], "\\["); a[$1].size = 0;
        strcpy(Labe[$3], "\\]"); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
CIV:
    ConstExp { 
        fprintf (fd, "ConstInitVal -> ConstExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstInitVal"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | BLB CIV oCIV BRB { 
        fprintf (fd, "ConstInitVal -> \'{\' ConstInitVal {, ConstInitVal} \'}\'\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstInitVal"); a[$$].size = 0;
        strcpy(Labe[$1], "\\{"); a[$1].size = 0;
        strcpy(Labe[$4], "\\}"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
;
oCIV:
    /* empty */ {$$ = 0;}
    | BC CIV { 
        fprintf (fd, "Other ConstInitVal -> , ConstInitVal\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "OtherConstInitVal"); a[$$].size = 0;
        strcpy(Labe[$1], "\\,"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
VarDecl:
    INT VarDef oVarDef BS { 
        fprintf (fd, "VarDecl -> int\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "VarDecl"); a[$$].size = 0;
        strcpy(Labe[$1], "int"); a[$1].size = 0;
        strcpy(Labe[$4], "\\;"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
    | INT error BS {printf("        Variable declaration error.\n");}
;
oVarDef:
    /* empty */ {$$ = 0;}
    | BC VarDef oVarDef { 
        fprintf (fd, "Other VarDef -> , VarDef\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "OtherVarDef"); a[$$].size = 0;
        strcpy(Labe[$1], "\\,"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
VarDef:
    IDENT ConstArrayIndex { 
        fprintf (fd, "VarDef -> Ident {\'[\'ConstExp\']\'}\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "VarDef"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | IDENT ConstArrayIndex OE InitVal { 
        fprintf (fd, "VarDef -> Ident {\'[\'ConstExp\']\'} = InitVal\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstArrayIndex"); a[$$].size = 0;
        strcpy(Labe[$3], "\\="); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
;
InitVal:
    Exp { 
        fprintf (fd, "InitVal -> Exp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "InitVal"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | BLB InitVal oInitVal BRB { 
        fprintf (fd, "InitVal -> \'{\' Initval {, Initval} \'}\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "InitVal"); a[$$].size = 0;
        strcpy(Labe[$1], "\\{"); a[$1].size = 0;
        strcpy(Labe[$4], "\\}"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
;
oInitVal:
    BC InitVal { 
        fprintf (fd, "Other Initval -> , Initval\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstArrayIndex"); a[$$].size = 0;
        strcpy(Labe[$1], "\\,"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
FuncDef:
    VOID IDENT BLL FuncFParams BRL Block{ 
        fprintf (fd, "FuncDef -> void IDENT \'(\' FuncFParams \')\' Block\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncDef"); a[$$].size = 0;
        strcpy(Labe[$1], "void"); a[$1].size = 0;
        strcpy(Labe[$3], "\\("); a[$3].size = 0;
        strcpy(Labe[$5], "\\)"); a[$5].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
        if ($6) a[$$].child[a[$$].size++] = $6;
    }
    | INT IDENT BLL FuncFParams BRL Block { 
        fprintf (fd, "FuncDef -> int IDENT \'(\' FuncFParams \')\' Block\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncDef"); a[$$].size = 0;
        strcpy(Labe[$1], "int"); a[$1].size = 0;
        strcpy(Labe[$3], "\\("); a[$3].size = 0;
        strcpy(Labe[$5], "\\)"); a[$5].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
        if ($6) a[$$].child[a[$$].size++] = $6;
    }
    | VOID IDENT BLL BRL Block { 
        fprintf (fd, "FuncDef -> void IDENT \'(\'\')\' Block\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncDef"); a[$$].size = 0;
        strcpy(Labe[$1], "void"); a[$1].size = 0;
        strcpy(Labe[$3], "\\("); a[$3].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
    }
    | INT IDENT BLL BRL Block { 
        fprintf (fd, "FuncDef -> int IDENT \'(\'\')\' Block\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncDef"); a[$$].size = 0;
        strcpy(Labe[$1], "int"); a[$1].size = 0;
        strcpy(Labe[$3], "\\("); a[$3].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
    }
    | INT MAIN BLL BRL Block { 
        fprintf (fd, "FuncDef -> int main \'(\'\')\' Block\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncDef"); a[$$].size = 0;
        strcpy(Labe[$1], "int"); a[$1].size = 0;
        strcpy(Labe[$2], "main"); a[$2].size = 0;
        strcpy(Labe[$3], "\\("); a[$3].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
    }
    | INT error Block {printf("        Function definition error.\n");}
    | VOID error Block {printf("        Function definition error.\n");}
;
FuncFParams:
    FuncFParam oFuncFParam { 
        fprintf (fd, "FuncFParams -> FuncFParam {, FuncFParam}\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncFParams "); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
FuncFParam:
    INT IDENT oB { 
        fprintf (fd, "FuncFParam -> INT Ident [\'[\'\']\' {\'[\'Exp\']\'}]\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncFParam"); a[$$].size = 0;
        strcpy(Labe[$1], "int"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
oFuncFParam:
    /* empty */ {$$ = 0;}
    | BC FuncFParam oFuncFParam { 
        fprintf (fd, "Other FuncFParam -> , FuncFParam\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "OtherFuncFParam"); a[$$].size = 0;
        strcpy(Labe[$1], "\\,"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
oB:
    BLM BRM { 
        fprintf (fd, "oB -> \'[\'\']\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "oB"); a[$$].size = 0;
        strcpy(Labe[$1], "\\["); a[$1].size = 0;
        strcpy(Labe[$2], "\\]"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | ooB { 
        fprintf (fd, "oB -> {\'[\'Exp\']\'}\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstArrayIndex"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
ooB:
    /* empty */ {$$ = 0;}
    | BLM Exp BRM ooB { 
        fprintf (fd, "ooB -> \'[\'EXP\']\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "ooB"); a[$$].size = 0;
        strcpy(Labe[$1], "\\["); a[$1].size = 0;
        strcpy(Labe[$3], "\\]"); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
;
Block:
    BLB BlockItem BRB { 
        fprintf (fd, "Block -> \'{\' {BlockItem} \'}\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Block"); a[$$].size = 0;
        strcpy(Labe[$1], "\\{"); a[$1].size = 0;
        strcpy(Labe[$3], "\\}"); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | BLB error BRB {printf("        Details in block error.\n");}
;
BlockItem:
    /* empty */ {$$ = 0;}
    | Decl BlockItem { 
        fprintf (fd, "BlockItem -> Decl BlockItem\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "BlockItem"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | Stmt BlockItem { 
        fprintf (fd, "BlockItem -> Stmt BlockItem\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "BlockItem"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
Stmt:
    LVal OE Exp BS { 
        fprintf (fd, "Stmt -> LVal = Exp;\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$2], "\\="); a[$2].size = 0;
        strcpy(Labe[$4], "\\;"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
    | Exp BS { 
        fprintf (fd, "Stmt -> Exp;\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$2], "\\;"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | Block { 
        fprintf (fd, "Stmt -> Block\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | IF BLL Cond BRL Stmt %prec NOELSE { 
        fprintf (fd, "Stmt -> if \'(\'Cond\')\' Stmt\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "if"); a[$1].size = 0;
        strcpy(Labe[$2], "\\("); a[$2].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
    }
    | IF BLL Cond BRL Stmt ELSE Stmt %prec ELSE { 
        fprintf (fd, "Stmt -> if \'(\'Cond\')\' Stmt else Stmt\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "if"); a[$1].size = 0;
        strcpy(Labe[$2], "\\("); a[$2].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        strcpy(Labe[$6], "else"); a[$6].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
        if ($6) a[$$].child[a[$$].size++] = $6;
        if ($7) a[$$].child[a[$$].size++] = $7;
    }
    | WHILE BLL Cond BRL Stmt { 
        fprintf (fd, "Stmt -> while \'(\'Cond\')\' Stmt\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "while"); a[$1].size = 0;
        strcpy(Labe[$2], "\\("); a[$2].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
        if ($5) a[$$].child[a[$$].size++] = $5;
    }
    | BREAK BS { 
        fprintf (fd, "Stmt -> break;\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "break"); a[$1].size = 0;
        strcpy(Labe[$2], "\\;"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | CONTINUE BS { 
        fprintf (fd, "Stmt -> continue;\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "continue"); a[$1].size = 0;
        strcpy(Labe[$2], "\\;"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | RETURN Exp BS { 
        fprintf (fd, "Stmt -> return Exp;\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "return"); a[$1].size = 0;
        strcpy(Labe[$3], "\\;"); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | RETURN BS { 
        fprintf (fd, "Stmt -> return;\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "Stmt"); a[$$].size = 0;
        strcpy(Labe[$1], "return"); a[$1].size = 0;
        strcpy(Labe[$2], "\\;"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
Exp:
    AddExp { 
        fprintf (fd, "Exp -> AddExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Exp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
Cond:
    LOrExp { 
        fprintf (fd, "Cond -> LOrExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "Cond"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
LVal:
    IDENT ooB {
        fprintf (fd, "Lval -> Ident{\'[\'Exp\']\'}\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "LVal"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
PrimaryExp:
    BLL Exp BRL { 
        fprintf (fd, "PrimaryExp -> \'(\'Exp\')\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "PrimaryExp"); a[$$].size = 0;
        strcpy(Labe[$1], "\\("); a[$1].size = 0;
        strcpy(Labe[$3], "\\)"); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | LVal { 
        fprintf (fd, "PrimaryExp -> LVal\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "PrimaryExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | NUMBER { 
        fprintf (fd, "PrimaryExp -> Number\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "PrimaryExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
UnaryExp:
    PrimaryExp { 
        fprintf (fd, "UnaryExp -> PrimaryExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "UnaryExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | IDENT BLL BRL { 
        fprintf (fd, "UnaryExp -> Ident \'(\'\')\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "UnaryExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\("); a[$2].size = 0;
        strcpy(Labe[$3], "\\)"); a[$3].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | IDENT BLL FuncRParams BRL { 
        fprintf (fd, "UnaryExp -> Ident \'(\'FuncRParams\')\'\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "UnaryExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\("); a[$2].size = 0;
        strcpy(Labe[$4], "\\)"); a[$4].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
        if ($4) a[$$].child[a[$$].size++] = $4;
    }
    | OP UnaryExp { 
        fprintf (fd, "UnaryExp -> + UnaryExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "UnaryExp"); a[$$].size = 0;
        strcpy(Labe[$1], "\\+"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | OS UnaryExp { 
        fprintf (fd, "UnaryExp -> + UnaryExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "UnaryExp"); a[$$].size = 0;
        strcpy(Labe[$1], "\\-"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
    | ON UnaryExp { 
        fprintf (fd, "UnaryExp -> + UnaryExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "UnaryExp"); a[$$].size = 0;
        strcpy(Labe[$1], "\\!"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
FuncRParams:
    Exp oExp { 
        fprintf (fd, "FuncRParams -> Exp {, Exp}\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "FuncRParams"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
    }
;
oExp:
    /* empty */ {$$ = 0;}
    | BC Exp oExp { 
        fprintf (fd, "OtherExp -> ,Exp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "OtherExp"); a[$$].size = 0;
        strcpy(Labe[$1], "\\,"); a[$1].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
MulExp:
    UnaryExp { 
        fprintf (fd, "MulExp -> UnaryExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "MulExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | MulExp OM UnaryExp { 
        fprintf (fd, "MulExp -> MulExp * UnaryExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "MulExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\*"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | MulExp OD UnaryExp { 
        fprintf (fd, "MulExp -> MulExp / UnaryExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "MulExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\\\"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | MulExp OMOD UnaryExp { 
        fprintf (fd, "MulExp -> MulExp % UnaryExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "MulExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\%"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
AddExp:
    MulExp { 
        fprintf (fd, "AddExp -> MulExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "AddExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | AddExp OP MulExp { 
        fprintf (fd, "AddExp -> AddExp + MulExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "AddExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\+"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | AddExp OS MulExp { 
        fprintf (fd, "AddExp -> AddExp - MulExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "AddExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\-"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
RelExp:
    AddExp { 
        fprintf (fd, "RelExp -> AddExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "RelExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | RelExp OL AddExp { 
        fprintf (fd, "RelExp -> RelExp < AddExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "RelExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\<"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | RelExp OG AddExp { 
        fprintf (fd, "RelExp -> RelExp > AddExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "RelExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\>"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | RelExp OLE AddExp { 
        fprintf (fd, "RelExp -> RelExp <= AddExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "RelExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\<\\="); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | RelExp OGE AddExp { 
        fprintf (fd, "RelExp -> RelExp >= AddExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "RelExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\>\\="); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
EqExp:
    RelExp { 
        fprintf (fd, "EqExp -> RelExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "EqExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | EqExp OEE RelExp { 
        fprintf (fd, "EqExp -> EqExp == RelExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "EqExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\=\\="); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
    | EqExp ONE RelExp { 
        fprintf (fd, "EqExp -> EqExp != RelExp\n"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "EqExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\!\\="); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
LAndExp:
    EqExp { 
        fprintf (fd, "LAndExp -> EqExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "LAndExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | LAndExp OAND EqExp { 
        fprintf (fd, "LAndExp -> LAndExp && EqExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "LAndExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\&\\&"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
LOrExp:
    LAndExp { 
        fprintf (fd, "LOrExp -> LAndExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "LOrExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
    | LOrExp OOR LAndExp { 
        fprintf (fd, "LOrExp -> LOrExp || LAndExp"); 
        $$ = ++cnt;
        strcpy(Labe[$$], "LOrExp"); a[$$].size = 0;
        strcpy(Labe[$2], "\\|\\|"); a[$2].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
        if ($2) a[$$].child[a[$$].size++] = $2;
        if ($3) a[$$].child[a[$$].size++] = $3;
    }
;
ConstExp:
    AddExp {
        fprintf (fd, "ConstExp -> AddExp\n");
        $$ = ++cnt;
        strcpy(Labe[$$], "ConstExp"); a[$$].size = 0;
        if ($1) a[$$].child[a[$$].size++] = $1;
    }
;
%%