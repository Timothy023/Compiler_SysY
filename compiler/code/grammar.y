%{
#include <bits/stdc++.h>
using namespace std;

extern int yylex(void); 
extern int yyparse(void); 
extern int num_char, num_line;
extern char *yytext;

enum varType {Tint, Tconst, Tvoid, Tarray, TfuncInt, TfuncVoid};
bool isVoid = false;
char funcname[100] = {"\0"};

int tl = 0;

vector <string> command;
vector < vector<pair <int, int> > * > breaklist;
vector < vector<pair <int, int> > * > contilist;

void yyerror(const char *s) {
	printf("[error] %s.\n", s);
    printf("\t(%d, %d): \"%s\".\n", num_line, num_char, yytext);
}

int level = 0;
int offset = 0;
struct var {
    var() {}
    var(varType __type, int __val, int __offset) {
        type = __type;
        val = __val;
        offset = __offset;
    }
    var(varType __type, int __val, int __offset, vector <int> __dim) {
        type = __type;
        val = __val;
        offset = __offset;
        dim = __dim;
    }
    var(varType __type, int __val) {
        type = __type;
        val = __val;
    }
    varType type;
    int val;
    int offset;
    vector <int> dim;
    int num_para;
};

vector < map <string, var> * > idvar;
vector <string> FuncPara;
vector <int> RecordOffset;

struct temp {
    temp() {}
    int offset;
    int arrayoffset;
    int val;
    int labelid;
    bool isConst;
    bool isArray;
    string name;
    vector <int> dim;
    vector <string> para_name;
    vector <int> para_val;
    vector <int> para_offset;
    vector <bool> para_const;
    vector <bool> para_array;
    vector <int> para_arrayoffset;
    vector <int> truelist;
    vector <int> falselist;
}t[100000];

void mergelist(vector <int> &x, vector <int> &y) {
    int len = y.size();
    for (int i = 0; i < len; ++i)
        x.push_back(y[i]);
}

void backpatch(vector <int> &l, int pos) {
    for (int i = 0; i < l.size(); ++i) {
        int id = l[i];
        command[id] = command[id] + ".L" + to_string(pos) + "\n";
    }
}

void move_to_register(int i, const char *ri) {
    char buf[100] = {"\0"};
    if (t[i].isConst == true) {
        sprintf (buf, "\tmovl\t$%d, %%%s\n", t[i].val, ri);
        command.push_back(buf);
    } else if (t[i].offset == 1) {
        if (t[i].isArray) {
            sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[i].arrayoffset);
            command.push_back(buf);
            command.push_back("\tcltq\n");
            sprintf (buf, "\tleaq\t0(, %rax, 4), %%rdx\n");
            command.push_back(buf);
            sprintf (buf, "\tleaq\t%s(%rip), %%rax\n", t[i].name.c_str());
            command.push_back(buf);
            sprintf (buf, "\tmovl\t(%%rdx, %%rax), %%%s\n", ri);
            command.push_back(buf);
        } else {
            sprintf (buf, "\tmovl\t%s(%%rip), %%%s\n", t[i].name.c_str(), ri);
            command.push_back(buf);
        }
    } else {
        if (t[i].isArray) {
            sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[i].arrayoffset);
            command.push_back(buf);
            command.push_back("\tcltq\n");
            sprintf (buf, "\tmovl\t%d(%rbp, %rax, 4), %%%s\n", t[i].offset, ri);
            command.push_back(buf);
        } else {
            sprintf (buf, "\tmovl\t%d(%%rbp), %%%s\n", t[i].offset, ri);
            command.push_back(buf);
        }
    }
}

void move_to_memory(const char *ri, int i) {
    char buf[100] = {"\0"};
    if (t[i].isConst == true) {
        yyerror("constant shouldn't be changed");
        exit(0);
    } else if (t[i].offset == 1) {
        if (t[i].isArray) {
            sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[i].arrayoffset);
            command.push_back(buf);
            command.push_back("\tcltq\n");
            sprintf (buf, "\tleaq\t0(, %rax, 4), %%rdx\n");
            command.push_back(buf);
            sprintf (buf, "\tleaq\t%s(%rip), %%rax\n", t[i].name.c_str());
            command.push_back(buf);
            sprintf (buf, "\tmovl\t%%%s, (%%rdx, %%rax)\n", ri);
            command.push_back(buf);
        } else {
            sprintf (buf, "\tmovl\t%%%s, %s(%rip)\n", ri, t[i].name.c_str());
            command.push_back(buf);
        }
    } else {
        if (t[i].isArray) {
            sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[i].arrayoffset);
            command.push_back(buf);
            command.push_back("\tcltq\n");
            sprintf (buf, "\tmovl\t%%%s, %d(%rbp, %rax, 4)\n", ri, t[i].offset);
            command.push_back(buf);
        } else {
            sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", ri, t[i].offset);
            command.push_back(buf);
        }
    }
}

int add_register(const char *r1, const char *r2) {
    char buf[100] = {"\0"};
    sprintf (buf, "\taddl\t%%%s, %%%s\n", r1, r2);
    command.push_back(buf);
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", r2, offset);
    command.push_back(buf);
    return offset;
}

int sub_register(const char *r1, const char *r2) {
    char buf[100] = {"\0"};
    sprintf (buf, "\tsubl\t%%%s, %%%s\n", r2, r1);
    command.push_back(buf);
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", r1, offset);
    command.push_back(buf);
    return offset;
}

int mul_register(const char *r1, const char *r2) {
    char buf[100] = {"\0"};
    sprintf (buf, "\timull\t%%%s, %%%s\n", r1, r2);
    command.push_back(buf);
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", r2, offset);
    command.push_back(buf);
    return offset;
}

int div_register(const char *r) {
    char buf[100] = {"\0"};
    sprintf (buf, "\tcltd\n");
    command.push_back(buf);
    sprintf (buf, "\tidivl\t%%%s\n", r);
    command.push_back(buf);
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t%%eax, %d(%rbp)\n", offset);
    command.push_back(buf);
    return offset;
}

int mod_register(const char *r) {
    char buf[100] = {"\0"};
    sprintf (buf, "\tcltd\n");
    command.push_back(buf);
    sprintf (buf, "\tidivl\t%%%s\n", r);
    command.push_back(buf);
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t%%edx, %d(%rbp)\n", offset);
    command.push_back(buf);
    return offset;
}

int neg_register(const char *r) {
    char buf[100] = {"\0"};
    sprintf (buf, "\tnegl\t%%%s\n", r);
    command.push_back(buf);
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", r, offset);
    command.push_back(buf);
    return offset;
}

void move_para_to_register(int id, int pos, const char *ri) {
    char buf[100] = {"\0"};
    if (t[id].para_const[pos] == 1) {
        sprintf (buf, "\tmovl\t$%d, %%%s\n", t[id].para_val[pos], ri);
        command.push_back(buf);
    } else {
        if (t[id].para_offset[pos] == 1) {
            if (t[id].para_array[pos] == 1) {
                sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[id].para_arrayoffset[pos]);
                command.push_back(buf);
                command.push_back("\tcltq\n");
                sprintf (buf, "\tleaq\t0(, %rax, 4), %%rdx\n");
                command.push_back(buf);
                sprintf (buf, "\tleaq\t%s(%rip), %%rax\n", t[id].para_name[pos].c_str());
                command.push_back(buf);
                sprintf (buf, "\tmovl\t(%%rdx, %%rax), %%%s\n", ri);
                command.push_back(buf);
            } else {
                sprintf (buf, "\tmovl\t%s(%rip), %%%s\n", t[id].para_name[pos].c_str(), ri);
                command.push_back(buf);
            }
        } else {
            if (t[id].para_array[pos] == 1) {
                sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[id].para_arrayoffset[pos]);
                command.push_back(buf);
                command.push_back("\tcltq\n");
                sprintf (buf, "\tmovl\t%d(%rbp, %rax, 4), %%%s\n", t[id].para_offset[pos], ri);
                command.push_back(buf);
            } else {
                sprintf (buf, "\tmovl\t%d(%rbp), %%%s\n", t[id].para_offset[pos], ri);
                command.push_back(buf);
            }
        }
    }
}

void lea_para_to_register(int id, int pos, const char *ri) {
    char buf[100] = {"\0"};
    if (t[id].para_const[pos] == 1) {
        yyerror("constant shouldn't be changed");
        exit(0);
    } else {
        if (t[id].para_offset[pos] == 1) {
            if (t[id].para_array[pos] == 1) {
                sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[id].para_arrayoffset[pos]);
                command.push_back(buf);
                command.push_back("\tcltq\n");
                sprintf (buf, "\tleaq\t0(, %rax, 4), %%rdx\n");
                command.push_back(buf);
                sprintf (buf, "\tleaq\t%s(%rip), %%rax\n", t[id].para_name[pos].c_str());
                command.push_back(buf);
                sprintf (buf, "\leaq\t(%%rdx, %%rax), %%%s\n", ri);
                command.push_back(buf);
            } else {
                sprintf (buf, "\tleaq\t%s(%rip), %%%s\n", t[id].para_name[pos].c_str(), ri);
                command.push_back(buf);
            }
        } else {
            if (t[id].para_array[pos] == 1) {
                sprintf (buf, "\tmovl\t%d(%rbp), %%eax\n", t[id].para_arrayoffset[pos]);
                command.push_back(buf);
                command.push_back("\tcltq\n");
                sprintf (buf, "\tleaq\t%d(%rbp, %rax, 4), %%%s\n", t[id].para_offset[pos], ri);
                command.push_back(buf);
            } else {
                sprintf (buf, "\tleaq\t%d(%rbp), %%%s\n", t[id].para_offset[pos], ri);
                command.push_back(buf);
            }
        }
    }
}

void output(int i) {
    if (abs(offset) % 16 != 0) {
        int o = 16 - abs(offset) % 16;
        offset -= o;
        char buf[100] = {"\0"};
        sprintf (buf, "\tsubq\t$%d, %rsp\n", o);
        command.push_back(buf);
    }
    if (t[i].para_name.size() != 1) {
        yyerror("printf error");
        exit(0);
    }
    char buf[100] = {"\0"};
    move_para_to_register(i, 0, "esi");
    sprintf (buf, "\tleaq\t.LC1(%rip), %rdi\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t$0, %%eax\n");
    command.push_back(buf);
    sprintf (buf, "\tcall\tprintf@PLT\n");
    command.push_back(buf);
}

void input(int i) {
    if (abs(offset) % 16 != 0) {
        int o = 16 - abs(offset) % 16;
        offset -= o;
        char buf[100] = {"\0"};
        sprintf (buf, "\tsubq\t$%d, %rsp\n", o);
        command.push_back(buf);
    }
    if (t[i].para_name.size() != 1) {
        yyerror("printf error");
        exit(0);
    }
    char buf[100] = {"\0"};
    lea_para_to_register(i, 0, "rsi");
    sprintf (buf, "\tleaq\t.LC0(%rip), %rdi\n");
    command.push_back(buf);
    sprintf (buf, "\tmovl\t$0, %%eax\n");
    command.push_back(buf);
    sprintf (buf, "\tcall\t__isoc99_scanf@PLT\n");
    command.push_back(buf);
}

void newPara(int dataof, const char *nam) {
    char buf[100] = {"\0"};
    offset -= 4;
    sprintf (buf, "\tsubq\t$4, %rsp\n"); command.push_back(buf);
    sprintf (buf, "\tmovl\t%d(%%rbp), %%r8d\n", dataof); command.push_back(buf);
    sprintf (buf, "\tmovl\t%%r8d, %d(%%rbp)\n", offset); command.push_back(buf);
    (*idvar[level])[nam] = var(Tint, 0, offset);
}

FILE *ft, *fd, *as;

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

int main(int argc, char *argv[]) {
	freopen (argv[1], "r", stdin);
    ft = fopen("Tree.dot", "w");
    fd = fopen("Detail.txt", "w");
    as = fopen("assemble.s", "w");
    
    char buf[100] = {"\0"};
    sprintf (buf, ".LC0:\n");  command.push_back(buf);
    sprintf (buf, "\t.string	\"%%d\"\n"); command.push_back(buf);
    sprintf (buf, ".LC1:\n"); command.push_back(buf);
    sprintf (buf, "\t.string	\"%%d\\n\"\n"); command.push_back(buf);
    idvar.push_back(new map <string, var> );
    RecordOffset.push_back(0);

    yyparse();

    for (int i = 0; i < command.size(); ++i) {
        fprintf (as, "%s", command[i].c_str());
    }
    fprintf (as, "\n");

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

    }
;
oCompUnit: 
    Decl { 

    }
    | FuncDef { 

    }
;
Decl:
    ConstDecl { 

    }
    | VarDecl { 

    }
;
ConstDecl:
    CONST INT ConstDef oConstDef BS { 
        /* empty */
    }
    | CONST error BS {printf("        Const declaration error.\n");}
;
oConstDef:
    /* empty */ {$$ = 0;}
    | BC ConstDef oConstDef { 

    }
;
ConstDef:
    IDENT ConstArrayIndex OE CIV {
        char buf[100] = {"\0"};
        if (level == 0) {
            if (t[$4].isConst == false) {
                yyerror("ConstExp error");
                exit(0);
            }
            if ($2 == 0) {
                sprintf (buf, "\t.section\t.rodata\n"); command.push_back(buf);
                sprintf (buf, "\t.align\t4\n"); command.push_back(buf);
                sprintf (buf, "\t.type\t%s, @object\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.size\t%s, 4\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "%s:\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.long\t%d\n", t[$4].val); command.push_back(buf);
                sprintf (buf, "\t.text\n"); command.push_back(buf);
                (*idvar[0])[Labe[$1]] = var(Tconst, t[$4].val, 1);
            } else {

            }
        } else {
            if ($2 == 0) {
                offset -= 4;
                sprintf (buf, "\tsubq\t$4, %rsp\n"); command.push_back(buf);
                if (t[$4].isConst == true) {
                    sprintf (buf, "\tmovl\t$%d, %%edi\n", t[$4].val); command.push_back(buf);
                } else {
                    yyerror("constant should not be modified");
                    exit(0);
                }
                sprintf (buf, "\tmovl\t%%edi, %d(%rbp)\n", offset); command.push_back(buf);
                (*idvar[level])[Labe[$1]] = var(Tconst, t[$4].val, offset);
            } else {

            }
        }
    }
;
ConstArrayIndex:
    /* empty */ {$$ = 0;}
    | BLM ConstExp BRM ConstArrayIndex { 
        $$ = $4;
        int sz = t[$2].val;
        if ($4 != 0) sz = sz * t[$4].val;
        else $$ = (cnt += 1);
        t[$$].val = sz;
        t[$$].dim.push_back(t[$2].val);
    }
;
CIV:
    ConstExp { 
        $$ = $1;
    }
    | BLB CIV oCIV BRB { 

    }
;
oCIV:
    /* empty */ {$$ = 0;}
    | BC CIV { 

    }
;
VarDecl:
    INT VarDef oVarDef BS { 

    }
    | INT error BS {printf("        Variable declaration error.\n");}
;
oVarDef:
    /* empty */ {$$ = 0;}
    | BC VarDef oVarDef { 

    }
;
VarDef:
    IDENT ConstArrayIndex { 
        if (idvar[level]->find(Labe[$1]) != idvar[level]->end()) {
            yyerror("definition error");
            exit(0);
        }
        char buf[100] = {"\0"};
        if (level == 0) {
            if ($2 == 0) {
                sprintf (buf, "\t.globl\t%s\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.data\n"); command.push_back(buf);
                sprintf (buf, "\t.align\t4\n"); command.push_back(buf);
                sprintf (buf, "\t.type\t%s, @object\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.size\t%s, 4\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "%s:\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.long\t0\n"); command.push_back(buf);
                sprintf (buf, "\t.text\n"); command.push_back(buf);
                (*idvar[0])[Labe[$1]] = var(Tint, 0, 1);
            } else {
                sprintf (buf, "\t.comm\t%s,%d,%d\n", Labe[$1], t[$2].val * 4, 32); command.push_back(buf);
                sprintf (buf, "\t.text\n"); command.push_back(buf);
                (*idvar[0])[Labe[$1]] = var(Tarray, 0, 1, t[$2].dim);
            }
        } else {
            if ($2 == 0) {
                offset -= 4;
                sprintf (buf, "\tsubq\t$4, %rsp\n"); command.push_back(buf);
                (*idvar[level])[Labe[$1]] = var(Tint, 0, offset);
            } else {
                offset -= t[$2].val * 4;
                sprintf (buf, "\tsubq\t$%d, %rsp\n", t[$2].val * 4); command.push_back(buf);
                (*idvar[level])[Labe[$1]] = var(Tarray, 0, offset, t[$2].dim);
            }
        }
    }
    | IDENT ConstArrayIndex OE InitVal { 
        char buf[100] = {"\0"};
        if (idvar[level]->find(Labe[$1]) != idvar[level]->end()) {
            yyerror("definition error");
            exit(0);
        }
        if (level == 0) {
            if (t[$4].isConst == false) {
                yyerror("ConstExp error");
                exit(0);
            }
            if ($2 == 0) {
                sprintf (buf, "\t.globl\t%s\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.data\n"); command.push_back(buf);
                sprintf (buf, "\t.align\t4\n"); command.push_back(buf);
                sprintf (buf, "\t.type\t%s, @object\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.size\t%s, 4\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "%s:\n", Labe[$1]); command.push_back(buf);
                sprintf (buf, "\t.long\t%d\n", t[$4].val); command.push_back(buf);
                sprintf (buf, "\t.text\n"); command.push_back(buf);
                (*idvar[0])[Labe[$1]] = var(Tint, 0, 1);
            } else {

            }
        } else {
            if ($2 == 0) {
                move_to_register($4, "edi");
                offset -= 4;
                sprintf (buf, "\tsubq\t$4, %rsp\n"); command.push_back(buf);
                sprintf (buf, "\tmovl\t%%edi, %d(%rbp)\n", offset); command.push_back(buf);
                (*idvar[level])[Labe[$1]] = var(Tint, 0, offset);
            } else {

            }
        }
    }
;
InitVal:
    Exp { 
        $$ = $1;
    }
    | BLB InitVal oInitVal BRB { 

    }
;
oInitVal:
    BC InitVal { 

    }
;
FuncDef:
    VOID FuncName ClearParaList BLL FuncFParams BRL FSvoid_with_para Block { 
        delete idvar[level];
        level -= 1;
        idvar.pop_back();
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
        offset = 0;
        isVoid = false;
    }
    | INT FuncName ClearParaList BLL FuncFParams BRL FSint_with_para Block { 
        delete idvar[level];
        level -= 1;
        idvar.pop_back();
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
        offset = 0;
        isVoid = false;
    }
    | VOID FuncName ClearParaList BLL BRL FSvoid_no_para Block { 
        delete idvar[level];
        level -= 1;
        idvar.pop_back();
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
        offset = 0;
        isVoid = false;
    }
    | INT FuncName ClearParaList BLL BRL FSint_no_para Block { 
        delete idvar[level];
        level -= 1;
        idvar.pop_back();
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
        offset = 0;
    }
    | INT MAIN BLL BRL FSmain Block {
        delete idvar[level];
        level -= 1;
        idvar.pop_back();
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
        offset = 0;
    }
    | INT error Block {printf("        Function definition error.\n");}
    | VOID error Block {printf("        Function definition error.\n");}
;
ClearParaList:
    /* empty */ {
        FuncPara.clear();
    }
;
FuncName:
    IDENT {
        strcpy(funcname, Labe[$1]);
    }
;
FSint_with_para:
    /* empty */ {
        isVoid = false;
        for (int i = level; i >= 0; --i) {
            if (idvar[i]->find(funcname) != idvar[i]->end()) {
                yyerror("definition error.");
                exit(0);
            }
        }
        (*idvar[level])[funcname] = var(TfuncInt, 0, 0);
        level += 1;
        idvar.push_back(new map <string, var>);
        char buf[100] = {"\0"};
        sprintf (buf, "\t.globl\t%s\n", funcname); command.push_back(buf);
        sprintf (buf, "\t.type\tmain, @function\n"); command.push_back(buf);
        sprintf (buf, "%s:\n", funcname); command.push_back(buf);
        sprintf (buf, "\tpushq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tmovq\t%rsp, %rbp\n"); command.push_back(buf);

        for (int i = 0; i < FuncPara.size(); ++i) {
            newPara(32 + i * 4, FuncPara[i].c_str());
        }
    }
;
FSvoid_with_para:
    /* empty */ {
        isVoid = true;
        for (int i = level; i >= 0; --i) {
            if (idvar[i]->find(funcname) != idvar[i]->end()) {
                yyerror("definition error.");
                exit(0);
            }
        }
        (*idvar[level])[funcname] = var(TfuncVoid, 0, 0);
        level += 1;
        idvar.push_back(new map <string, var>);
        char buf[100] = {"\0"};
        sprintf (buf, "\t.globl\t%s\n", funcname); command.push_back(buf);
        sprintf (buf, "\t.type\tmain, @function\n"); command.push_back(buf);
        sprintf (buf, "%s:\n", funcname); command.push_back(buf);
        sprintf (buf, "\tpushq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tmovq\t%rsp, %rbp\n"); command.push_back(buf);

        for (int i = 0; i < FuncPara.size(); ++i) {
            newPara(32 + i * 4, FuncPara[i].c_str());
        }
    }
;
FSint_no_para:
    /* empty */ {
        isVoid = false;
        for (int i = level; i >= 0; --i) {
            if (idvar[i]->find(funcname) != idvar[i]->end()) {
                yyerror("definition error.");
                exit(0);
            }
        }
        (*idvar[level])[funcname] = var(TfuncInt, 0, 0);
        level += 1;
        idvar.push_back(new map <string, var>);
        char buf[100] = {"\0"};
        sprintf (buf, "\t.globl\t%s\n", funcname); command.push_back(buf);
        sprintf (buf, "\t.type\tmain, @function\n"); command.push_back(buf);
        sprintf (buf, "%s:\n", funcname); command.push_back(buf);
        sprintf (buf, "\tpushq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tmovq\t%rsp, %rbp\n"); command.push_back(buf);
    }
;
FSvoid_no_para:
    /* empty */ {
        isVoid = true;
        for (int i = level; i >= 0; --i) {
            if (idvar[i]->find(funcname) != idvar[i]->end()) {
                yyerror("definition error.");
                exit(0);
            }
        }
        (*idvar[level])[funcname] = var(TfuncVoid, 0, 0);
        level += 1;
        idvar.push_back(new map <string, var>);
        char buf[100] = {"\0"};
        sprintf (buf, "\t.globl\t%s\n", funcname); command.push_back(buf);
        sprintf (buf, "\t.type\tmain, @function\n"); command.push_back(buf);
        sprintf (buf, "%s:\n", funcname); command.push_back(buf);
        sprintf (buf, "\tpushq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tmovq\t%rsp, %rbp\n"); command.push_back(buf);
    }
;
FSmain:
    /* empty */ {
        level += 1;
        idvar.push_back(new map <string, var>);
        char buf[100] = {"\0"};
        sprintf (buf, "\t.globl\tmain\n"); command.push_back(buf);
        sprintf (buf, "\t.type\tmain, @function\n"); command.push_back(buf);
        sprintf (buf, "main:\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpushq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tmovq\t%rsp, %rbp\n"); command.push_back(buf);
    }
;
FuncFParams:
    FuncFParam oFuncFParam { 
        
    }
;
FuncFParam:
    INT IDENT oB { 
        FuncPara.push_back(Labe[$2]);
    }
;
oFuncFParam:
    /* empty */ {$$ = 0;}
    | BC FuncFParam oFuncFParam { 

    }
;
oB:
    BLM BRM {

    }
    | ooB {
        $$ = $1;
    }
;
ooB:
    /* empty */ {$$ = 0;}
    | BLM Exp BRM ooB { 
        if ($4 != 0) $$ = $4;
        else $$ = (cnt += 1);
        t[$$].dim.push_back($2);
    }
;
Block:
    BLB BlockItem BRB { 

    }
    | BLB error BRB {printf("        Details in block error.\n");}
;
BlockItem:
    /* empty */ {$$ = 0;}
    | Decl BlockItem { 

    }
    | Stmt BlockItem { 

    }
;
Stmt:
    LVal OE Exp BS { 
        if (t[$1].isConst == true) {
            yyerror("constant should not be modified");
            exit(0);
        }
        move_to_register($3, "r9d");
        move_to_memory("r9d", $1);
    }
    | Exp BS { 
        /* empty */
    }
    | Block { 
        /* empty */
    }
    | IF BLL Cond BRL SetLabel Enter Stmt Exit SetLabel %prec NOELSE {
        delete idvar[level];
        level -= 1;
        idvar.pop_back();

        for (int i = 0; i < t[$3].truelist.size(); ++i) {
            int id = t[$3].truelist[i];
            command[id] = command[id] + ".L" + to_string($5) + "\n";
        }
        for (int i = 0; i < t[$3].falselist.size(); ++i) {
            int id = t[$3].falselist[i];
            command[id] = command[id] + ".L" + to_string($9) + "\n";
        }
    }
    | IF BLL Cond BRL SetLabel Enter Stmt Exit SetLabel OutIF SetLabel Enter Stmt Exit SetLabel %prec ELSE { 
        delete idvar[level];
        level -= 1;
        idvar.pop_back();
        
        for (int i = 0; i < t[$3].truelist.size(); ++i) {
            int id = t[$3].truelist[i];
            command[id] = command[id] + ".L" + to_string($5) + "\n";
        }
        for (int i = 0; i < t[$3].falselist.size(); ++i) {
            int id = t[$3].falselist[i];
            command[id] = command[id] + ".L" + to_string($11) + "\n";
        }
        command[t[$10].truelist[0]] = command[t[$10].truelist[0]] + ".L" + to_string($15) + "\n";
    }
    | WHILE BLL SetWhileLabel Enter Cond SetOutLabel BRL SetLabel Stmt SetLabel Exit {
        delete idvar[level];
        level -= 1;
        idvar.pop_back();

        backpatch(t[$5].truelist, $8);
        char buf[100] = {"\0"};
        sprintf (buf, "\tjmp\t.L%d\n", $3);
        command.push_back(buf);
        tl += 1;
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);
        backpatch(t[$5].falselist, t[$6].labelid);
        backpatch(t[$6].truelist, tl);
        
        int po = breaklist.size() - 1;
        int total = breaklist[po]->size();
        for (int i = 0; i < total; ++i) {
            int id = (*breaklist[po])[i].first;
            sprintf (buf, "\taddq\t$%d, %rsp\n", offset - (*breaklist[po])[i].second);
            command[id - 1] = string(buf);
            command[id] = command[id] + ".L" + to_string(tl) + "\n";
        }
        delete breaklist[breaklist.size() - 1];
        breaklist.pop_back();

        po = contilist.size() - 1;
        total = contilist[po]->size();
        for (int i = 0; i < total; ++i) {
            int id = (*contilist[po])[i].first;
            sprintf (buf, "\taddq\t$%d, %rsp\n", offset - (*contilist[po])[i].second);
            command[id - 1] = string(buf);
            command[id] = command[id] + ".L" + to_string($3) + "\n";
        }
        delete contilist[contilist.size() - 1];
        contilist.pop_back();
    }
    | BREAK BS {
        command.push_back("wait");
        command.push_back("\tjmp\t");
        breaklist[breaklist.size() - 1]->push_back(make_pair(command.size() - 1, offset));
    }
    | CONTINUE BS {
        command.push_back("wait");
        command.push_back("\tjmp\t");
        contilist[contilist.size() - 1]->push_back(make_pair(command.size() - 1, offset));
    }
    | RETURN Exp BS { 
        if (isVoid == true) {
            yyerror("void function should not have a return value");
            exit(0);
        }
        move_to_register($2, "eax");
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
    }
    | RETURN BS {
        if (isVoid == false) {
            yyerror("int function should have a return value");
            exit(0);
        }
        char buf[100] = {"\0"};
        sprintf (buf, "\taddq\t$%d, %rsp\n", -offset); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r9\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%r8\n"); command.push_back(buf);
        sprintf (buf, "\tpopq\t%rbp\n"); command.push_back(buf);
        sprintf (buf, "\tret\n"); command.push_back(buf);
    }
;
SetOutLabel:
    /* empty */ {
        char buf[100] = {"\0"};
        tl += 1;
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        int lstof = RecordOffset[RecordOffset.size() - 1];
        sprintf (buf, "\taddq\t$%d, %rsp\n", lstof - offset);
        command.push_back(buf);
        
        $$ = (cnt += 1);
        t[$$].labelid = tl;

        command.push_back("\tjmp\t");
        t[$$].truelist.push_back(command.size() - 1);
    }
;
SetWhileLabel:
    /* empty */ {
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);
        $$ = tl;

        breaklist.push_back(new vector< pair<int, int> >);
        breaklist[breaklist.size() - 1]->clear();
        
        contilist.push_back(new vector< pair<int,int> >);
        contilist[contilist.size() - 1]->clear();
    }
;
OutIF:
    ELSE {
        $$ = (cnt += 1);
        command.push_back("\tjmp\t");
        t[$$].truelist.push_back(command.size() - 1);
    }
;
Enter:
    /* empty */ {
        level += 1;
        idvar.push_back(new map <string, var>);

        RecordOffset.push_back(offset);
        if (abs(offset) % 16 != 0) {
            int o = 16 - abs(offset) % 16;
            offset -= o;
            char buf[100] = {"\0"};
            sprintf (buf, "\tsubq\t$%d, %rsp\n", o);
            command.push_back(buf);
        }
    }
;
Exit:
    /* empty */ {
        char buf[100] = {"\0"};
        int lstof = RecordOffset[RecordOffset.size() - 1];
        sprintf (buf, "\taddq\t$%d, %rsp\n", lstof - offset);
        command.push_back(buf);
        RecordOffset.pop_back();
        offset = lstof;
    }
;
SetLabel:
    /* empty */ {
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);
        $$ = tl;
    }
;
Exp:
    AddExp { 
        $$ = $1;
    }
;
Cond:
    LOrExp { 
        $$ = $1;
    }
;
LVal:
    IDENT ooB {
        if ($2 == 0) {
            bool flag = false;
            for (int i = level; i >= 1; --i) {
                if (idvar[i]->find(Labe[$1]) != idvar[i]->end()) {
                    flag = true;
                    var tmp = (*idvar[i])[Labe[$1]];
                    $$ = (cnt += 1);
                    if (tmp.type == Tconst) {
                        t[$$].isConst = true;
                        t[$$].val = tmp.val;
                    } else {
                        t[$$].isConst = false;
                        t[$$].offset = tmp.offset;
                    }
                    break;
                }
            }
            if (!flag) {
                if (idvar[0]->find(Labe[$1]) != idvar[0]->end()) {
                    flag = true;
                    $$ = (cnt += 1);
                    var tmp = (*idvar[0])[Labe[$1]];
                    if (tmp.type == Tconst) {
                        t[$$].isConst = true;
                        t[$$].val = tmp.val;
                    } else {
                        t[$$].isConst = false;
                        t[$$].offset = tmp.offset;
                        t[$$].name = string(Labe[$1]);
                    }
                }
            }
            if (!flag) {
                yyerror("Ident was not declared in this scope");
                exit(0);
            }
        } else {
            char buf[100] = {"\0"};
            bool flag = false;
            for (int i = level; i >= 1; --i) {
                if (idvar[i]->find(Labe[$1]) != idvar[i]->end()) {
                    var tmp = (*idvar[i])[Labe[$1]];

                    if (tmp.type != Tarray || t[$2].dim.size() != tmp.dim.size()) continue;
                    flag = true;
                    int len = tmp.dim.size();
                    int of = 1, rof = 0;
                    
                    offset -= 4;
                    sprintf (buf, "\tsubq\t$4, %rsp\n");
                    command.push_back(buf);
                    sprintf (buf, "\tmovl\t$0, %d(%rbp)\n", offset);
                    command.push_back(buf);
                    
                    int tmpof = offset;
                    for (int j = 0; j < len; ++j) {
                        move_to_register(t[$2].dim[j], "r8d");
                        sprintf (buf, "\timull\t$%d, %%r8d\n", of);
                        command.push_back(buf);
                        sprintf (buf, "\taddl\t%d(%rbp), %%r8d\n", tmpof);
                        command.push_back(buf);
                        sprintf (buf, "\tmovl\t%%r8d, %d(%rbp)\n", tmpof);
                        command.push_back(buf);

                        of *= tmp.dim[j];
                    }
                    if (flag == false) continue;
                    $$ = (cnt += 1);

                    if (tmp.type != Tconst) {
                        t[$$].isArray = true;
                        t[$$].isConst = false;
                        t[$$].offset = tmp.offset;
                        t[$$].arrayoffset = tmpof;
                    }
                    break;
                }
            }
            if (!flag) {
                if (idvar[0]->find(Labe[$1]) != idvar[0]->end()) {
                    var tmp = (*idvar[0])[Labe[$1]];
                    if (tmp.type == Tarray && t[$2].dim.size() == tmp.dim.size()) {
                        flag = true;

                        int len = tmp.dim.size();
                        int of = 1, rof = 0;
                        
                        offset -= 4;
                        sprintf (buf, "\tsubq\t$4, %rsp\n");
                        command.push_back(buf);
                        sprintf (buf, "\tmovl\t$0, %d(%rbp)\n", offset);
                        command.push_back(buf);
                        
                        int tmpof = offset;
                        for (int j = 0; j < len; ++j) {
                            move_to_register(t[$2].dim[j], "r8d");
                            sprintf (buf, "\timull\t$%d, %%r8d\n", of);
                            command.push_back(buf);
                            sprintf (buf, "\taddl\t%d(%rbp), %%r8d\n", tmpof);
                            command.push_back(buf);
                            sprintf (buf, "\tmovl\t%%r8d, %d(%rbp)\n", tmpof);
                            command.push_back(buf);

                            of *= tmp.dim[j];
                        }

                        $$ = (cnt += 1);

                        if (tmp.type == Tconst) {
                            t[$$].isConst = true;
                            t[$$].val = tmp.val;
                        } else {
                            t[$$].isArray = true;
                            t[$$].isConst = false;
                            t[$$].name = string(Labe[$1]);
                            t[$$].arrayoffset = tmpof;
                            t[$$].offset = 1;
                        }
                    }
                }
            }
            if (!flag) {
                yyerror("Ident was not declared in this scope");
                exit(0);
            }
        }
    }
;
PrimaryExp:
    BLL Exp BRL { 
        $$ = $2;
    }
    | LVal { 
        $$ = $1;
    }
    | NUMBER { 
        $$ = (cnt += 1);
        t[cnt].val = $1;
        t[cnt].isConst = true;
    }
;
UnaryExp:
    PrimaryExp { 
        $$ = $1;
    }
    | IDENT BLL BRL {
        if (idvar[0]->find(Labe[$1]) == idvar[0]->end()) {
            yyerror("no such function");
            exit(0);
        }
        char buf[100] = {"\0"};
        if (abs(offset) % 16 != 0) {
            int o = 16 - abs(offset) % 16;
            offset -= o;
            char buf[100];
            sprintf (buf, "\tsubq\t$%d, %rsp\n", o);
            command.push_back(buf);
        }
        sprintf(buf, "\tcall\t%s\n", Labe[$1]);
        command.push_back(buf);

        var tmp = (*idvar[0])[Labe[$1]];
        if (tmp.type == TfuncInt) {
            offset -= 4;
            sprintf (buf, "\tsubq\t$4, %rsp\n");
            command.push_back(buf);
            sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", "eax", offset);
            command.push_back(buf);
            $$ = (cnt += 1);
            t[$$].offset = offset;
        }
    }
    | IDENT BLL FuncRParams BRL {
        if (strcmp(Labe[$1], "printf") == 0) {
            output($3);
        } else if (strcmp(Labe[$1], "scanf") == 0) {
            input($3);
        } else {
            if (idvar[0]->find(Labe[$1]) == idvar[0]->end()) {
                yyerror("no such function");
                exit(0);
            }
            char buf[100] = {"\0"};
            if ((-(offset - t[$3].para_name.size() * 4)) % 16 != 0) {
                int o = 16 - abs(offset) % 16;
                offset -= o;
                char buf[100];
                sprintf (buf, "\tsubq\t$%d, %rsp\n", o);
                command.push_back(buf);
            }

            for (int i = 0; i < t[$3].para_name.size(); ++i) {
                move_para_to_register($3, i, "r8d");
                offset -= 4;
                sprintf (buf, "\tsubq\t$4, %rsp\n"); command.push_back(buf);
                sprintf (buf, "\tmovl\t%%r8d, %d(%rbp)\n", offset); command.push_back(buf);
            }
            sprintf(buf, "\tcall\t%s\n", Labe[$1]);
            command.push_back(buf);

            var tmp = (*idvar[0])[Labe[$1]];
            if (tmp.type == TfuncInt) {
                offset -= 4;
                sprintf (buf, "\tsubq\t$4, %rsp\n");
                command.push_back(buf);
                sprintf (buf, "\tmovl\t%%%s, %d(%rbp)\n", "eax", offset);
                command.push_back(buf);
                $$ = (cnt += 1);
                t[$$].offset = offset;
            }
        }
    }
    | OP UnaryExp { 
        $$ = $2;
    }
    | OS UnaryExp { 
        if (t[$2].isConst == true) {
            t[$2].val = -t[$2].val;
            $$ = $2;
        } else {
            char buf[100] = {"\0"};
            move_to_register($2, "r8d");
            int of = neg_register("r8d");
            $$ = (cnt += 1);
            t[$$].offset = of;
        }
    }
    | ON UnaryExp { 
        char buf[100] = {"\0"};
        move_to_register($2, "eax");
        sprintf (buf, "\ttestl\t%%eax, %%eax\n");
        command.push_back(buf);
        sprintf (buf, "\tsete\t%%al\n");
        command.push_back(buf);
        sprintf (buf, "\tmovzbl\t%%al, %%eax\n");
        command.push_back(buf);
        
        offset -= 4;
        sprintf (buf, "\tsubq\t$4, %rsp\n");
        command.push_back(buf);
        sprintf (buf, "\tmovl\t%%eax, %d(%rbp)\n", offset);
        command.push_back(buf);
        $$ = (cnt += 1);
        t[$$].offset = offset;
    }
;
FuncRParams:
    Exp oExp {
        if ($2 != 0) {
            $$ = $2;
            t[$$].para_name.push_back(t[$1].name);
            t[$$].para_offset.push_back(t[$1].offset);
            t[$$].para_val.push_back(t[$1].val);
            t[$$].para_const.push_back(t[$1].isConst);
            t[$$].para_array.push_back(t[$1].isArray);
            t[$$].para_arrayoffset.push_back(t[$1].arrayoffset);
        } else {
            $$ = $1;
            t[$$].para_name.push_back(t[$1].name);
            t[$$].para_offset.push_back(t[$1].offset);
            t[$$].para_val.push_back(t[$1].val);
            t[$$].para_const.push_back(t[$1].isConst);
            t[$$].para_array.push_back(t[$1].isArray);
            t[$$].para_arrayoffset.push_back(t[$1].arrayoffset);
        }
    }
;
oExp:
    /* empty */ {$$ = 0;}
    | BC Exp oExp { 
        if ($3 != 0) {
            $$ = $3;
            t[$$].para_name.push_back(t[$2].name);
            t[$$].para_offset.push_back(t[$2].offset);
            t[$$].para_val.push_back(t[$2].val);
            t[$$].para_const.push_back(t[$2].isConst);
        } else {
            $$ = $2;
            t[$$].para_name.push_back(t[$2].name);
            t[$$].para_offset.push_back(t[$2].offset);
            t[$$].para_val.push_back(t[$2].val);
            t[$$].para_const.push_back(t[$2].isConst);
        }
    }
;
MulExp:
    UnaryExp { 
        $$ = $1;
    }
    | MulExp OM UnaryExp {
        if (t[$1].isConst && t[$3].isConst) {
            $$ = (cnt += 1);
            t[$$].val = t[$1].val * t[$3].val;
            t[$$].isConst = true;
        }
        else {
            move_to_register($1, "r8d");
            move_to_register($3, "r9d");
            int of = mul_register("r8d", "r9d");
            $$ = (cnt += 1);
            t[$$].offset = of;
        }
    }
    | MulExp OD UnaryExp {
        if (t[$1].isConst && t[$3].isConst) {
            $$ = (cnt += 1);
            t[$$].val = t[$1].val / t[$3].val;
            t[$$].isConst = true;
        }
        else {
            move_to_register($1, "eax");
            move_to_register($3, "r9d");
            int of = div_register("r9d");
            $$ = (cnt += 1);
            t[$$].offset = of;
        }
    }
    | MulExp OMOD UnaryExp {
        if (t[$1].isConst && t[$3].isConst) {
            $$ = (cnt += 1);
            t[$$].val = t[$1].val % t[$3].val;
            t[$$].isConst = true;
        }
        else {
            move_to_register($1, "eax");
            move_to_register($3, "r9d");
            int of = mod_register("r9d");
            $$ = (cnt += 1);
            t[$$].offset = of;
        }
    }
;
AddExp:
    MulExp { 
        $$ = $1;
    }
    | AddExp OP MulExp { 
        if (t[$1].isConst and t[$3].isConst) {
            $$ = (cnt += 1);
            t[$$].val = t[$1].val + t[$3].val;
            t[$$].isConst = true;
        }
        else {
            char buf[100] = {"\0"};
            move_to_register($1, "r8d");
            move_to_register($3, "r9d");
            int of = add_register("r8d", "r9d");
            $$ = (cnt += 1);
            t[$$].offset = of;
        }
    }
    | AddExp OS MulExp {
        if (t[$1].isConst and t[$3].isConst) {
            $$ = (cnt += 1);
            t[$$].val = t[$1].val - t[$3].val;
            t[$$].isConst = true;
        }
        else {
            char buf[100] = {"\0"};
            move_to_register($1, "r8d");
            move_to_register($3, "r9d");
            int of = sub_register("r8d", "r9d");
            $$ = (cnt += 1);
            t[$$].offset = of;
        }
    }
;
RelExp:
    AddExp { 
        $$ = $1;
    }
    | RelExp OL AddExp {
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        move_to_register($1, "r8d");
        move_to_register($3, "r9d");
        sprintf (buf, "\tcmpl\t%r9d, %r8d\n");
        command.push_back(buf);

        $$ = (cnt += 1);
        sprintf (buf, "\tjl\t"); command.push_back(buf);
        t[$$].truelist.push_back(command.size() - 1);

        sprintf (buf, "\tjge\t"); command.push_back(buf);
        t[$$].falselist.push_back(command.size() - 1);
        t[$$].labelid = tl;
    }
    | RelExp OG AddExp { 
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        move_to_register($1, "r8d");
        move_to_register($3, "r9d");
        sprintf (buf, "\tcmpl\t%r9d, %r8d\n");
        command.push_back(buf);

        $$ = (cnt += 1);
        sprintf (buf, "\tjg\t"); command.push_back(buf);
        t[$$].truelist.push_back(command.size() - 1);

        sprintf (buf, "\tjle\t"); command.push_back(buf);
        t[$$].falselist.push_back(command.size() - 1);
        t[$$].labelid = tl;
    }
    | RelExp OLE AddExp { 
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        move_to_register($1, "r8d");
        move_to_register($3, "r9d");
        sprintf (buf, "\tcmpl\t%r9d, %r8d\n");
        command.push_back(buf);

        $$ = (cnt += 1);
        sprintf (buf, "\tjle\t"); command.push_back(buf);
        t[$$].truelist.push_back(command.size() - 1);

        sprintf (buf, "\tjg\t"); command.push_back(buf);
        t[$$].falselist.push_back(command.size() - 1);
        t[$$].labelid = tl;
    }
    | RelExp OGE AddExp {
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        move_to_register($1, "r8d");
        move_to_register($3, "r9d");
        sprintf (buf, "\tcmpl\t%r9d, %r8d\n");
        command.push_back(buf);

        $$ = (cnt += 1);
        sprintf (buf, "\tjge\t"); command.push_back(buf);
        t[$$].truelist.push_back(command.size() - 1);

        sprintf (buf, "\tjl\t"); command.push_back(buf);
        t[$$].falselist.push_back(command.size() - 1);
        t[$$].labelid = tl;
    }
;
EqExp:
    RelExp { 
        $$ = $1;
    }
    | EqExp OEE RelExp { 
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        move_to_register($1, "r8d");
        move_to_register($3, "r9d");
        sprintf (buf, "\tcmpl\t%r9d, %r8d\n");
        command.push_back(buf);

        $$ = (cnt += 1);
        sprintf (buf, "\tje\t"); command.push_back(buf);
        t[$$].truelist.push_back(command.size() - 1);

        sprintf (buf, "\tjne\t"); command.push_back(buf);
        t[$$].falselist.push_back(command.size() - 1);
        t[$$].labelid = tl;
    }
    | EqExp ONE RelExp { 
        tl += 1;
        char buf[100] = {"\0"};
        sprintf (buf, ".L%d:\n", tl);
        command.push_back(buf);

        move_to_register($1, "r8d");
        move_to_register($3, "r9d");
        sprintf (buf, "\tcmpl\t%r9d, %r8d\n");
        command.push_back(buf);

        $$ = (cnt += 1);
        sprintf (buf, "\tjne\t"); command.push_back(buf);
        t[$$].truelist.push_back(command.size() - 1);

        sprintf (buf, "\tje\t"); command.push_back(buf);
        t[$$].falselist.push_back(command.size() - 1);
        t[$$].labelid = tl;
    }
;
LAndExp:
    EqExp { 
        $$ = $1;
        if (t[$$].labelid == 0) {
            tl += 1;
            char buf[100] = {"\0"};
            sprintf (buf, ".L%d:\n", tl);
            command.push_back(buf);

            move_to_register($1, "r8d");
            sprintf (buf, "\tcmpl\t$0, %r8d\n");
            command.push_back(buf);

            $$ = (cnt += 1);
            sprintf (buf, "\tjne\t"); command.push_back(buf);
            t[$$].truelist.push_back(command.size() - 1);

            sprintf (buf, "\tje\t"); command.push_back(buf);
            t[$$].falselist.push_back(command.size() - 1);
            t[$$].labelid = tl;
        }
    }
    | LAndExp OAND EqExp { 
        backpatch(t[$1].truelist, t[$3].labelid);
        t[$$].falselist = t[$1].falselist;
        mergelist(t[$$].falselist, t[$3].falselist);
        t[$$].truelist = t[$3].truelist;
        t[$$].labelid = t[$1].labelid;
    }
;
LOrExp:
    LAndExp { 
        $$ = $1;
    }
    | LOrExp OOR LAndExp { 
        backpatch(t[$1].falselist, t[$3].labelid);
        t[$$].truelist = t[$1].truelist;
        mergelist(t[$$].truelist, t[$3].truelist);
        t[$$].falselist = t[$3].falselist;
        t[$$].labelid = t[$1].labelid;
    }
;
ConstExp:
    AddExp {
        $$ = $1;
        if (t[$$].isConst == false) {
            yyerror("ConstExp error");
            exit(0);
        }
    }
;
%%