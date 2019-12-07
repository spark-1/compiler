%{
#include <stdio.h>
#include <string.h>
#include "interpreter.c"

#define CONST 	0
#define VAR 	1
#define PROC 	2
#define IDENT 	3  	/* CONST + VAR */
#define TBSIZE 100	// symbol table size
#define LVLmax 20	// max level depth
#define BUCKETSIZE 17	// 해시테이블 버켓사이즈
#define FUNCSIZE 100	// 라벨 개수

// symbol table
struct {
	char name[20];
	int type;	/* 0-CONST	1-VARIABLE	2-PROCEDURE */
	int lvl;	// level
	int offst;
	int link;
} table[TBSIZE];

int block[LVLmax]; // Data for Set/Reset symbol table
int bucket[BUCKETSIZE]; // 해시 버켓
int ln=1, cp=0;
int lev=0; int tx=0, level=0;
int LDiff=0, Lno=0, OFFSET=0; // Lno : 라벨 수
int CodeIndex=0;
char Lname[10];
int funcaddr[FUNCSIZE];
int var_num;

void yyerror(char *);
int yylex();
void init();
int hash(char *);
int Lookup(char *, int);
void Enter(char *, int, int, int);
void SetBlock();
void ResetBlock();
void DisplayTable();
void DisplayCode();
void GenLab(char *);
void EmitLab(char *);
void Emit1(char *, int, int);
void Emit2(char *, int, char *);
void Emit3(char *, char *);
void Emit(char *);
void display_var();
%}

%union {
	char ident[50];	// id lvalue
	int number;	// num lvalue
}
%token TCONST TVAR TPROC TCALL TBEGIN TIF TTHEN TWHILE TDO TEND ODD NE LE GE ASSIGN
%token <ident> ID 
%token <number> NUM
%type <number> Dcl VarDcl Ident_list ProcHead
%left '+' '-'
%left '*' '/' /* 왼쪽 결합 법칙을 따르며 우선 순위 적용 "곱 나눗셈" > "더하기 빼기" */
%left UM /* unary operator '-'의 정의로 결합법칙이 적용이 안되는 것을 명시. */

%%
Program: Block '.' { Emit("Program END"); printf("==== valid syntax ====\n"); DisplayCode(); } 
;
Block: { GenLab(Lname); Emit3("JMP", strcpy($<ident>$, Lname)); } 
	Dcl { EmitLab($<ident>1); Emit1("INT", 0, $2); var_num = $2;} 
	Statement { DisplayTable(); } 
;
Dcl: ConstDcl VarDcl ProcDef_list { $$=$2; }
;
ConstDcl:
| TCONST Constdef_list ';'
;
Constdef_list: Constdef_list ',' ID '=' NUM { Enter($3, CONST, level, $5); }
| ID '=' NUM { Enter($1, CONST, level, $3); }  
;
VarDcl: TVAR Ident_list ';' { $$=$2; }
| { $$=3; }
;
Ident_list: Ident_list ',' ID { Enter($3, VAR, level, $1); $$=$1+1; }
| ID { Enter($1, VAR, level, 3); $$=4; }  
;
ProcDef_list: ProcDef_list ProcDef
|
;
ProcDef: ProcHead Block ';' { Emit("RET"); ResetBlock(); }  
;
ProcHead: TPROC ID ';' { Enter($2, PROC, level, Lno+1); EmitLab($2); SetBlock(); } // 프로시저의 offset에 대한 고민 필요  
;
Statement: ID ASSIGN Expression {
		if (Lookup($1, VAR)) Emit1("STO", LDiff, OFFSET); 
		else printf("undefined var\n") ;
	}
| TCALL ID {
		if (Lookup($2, PROC)) Emit2("CAL", LDiff, $2); 
		else /* error: undefined proc */ ; 
	}
| TBEGIN Statement_list TEND
| TIF Condition { GenLab(Lname); Emit3("JPC", strcpy($<ident>$, Lname)); }
	TTHEN Statement { EmitLab($<ident>3) }
| TWHILE { GenLab(Lname); EmitLab(strcpy($<ident>$, Lname))}
	Condition { GenLab(Lname); Emit3("JPC", strcpy($<ident>$, Lname)); }
	TDO Statement { Emit3("JMP", $<ident>2); EmitLab($<ident>4); }
|
;
Statement_list: Statement_list ';' Statement
| Statement
;
Condition: ODD Expression { Emit("ODD"); }
| Expression '&' Expression { Emit("AND"); }
| Expression '=' Expression { Emit("EQ"); }
| Expression NE Expression { Emit("NE"); }
| Expression '<' Expression { Emit("LT"); }
| Expression '>' Expression { Emit("GT"); }
| Expression GE Expression { Emit("GE"); }
| Expression LE Expression { Emit("LE"); }  
;
Expression: Expression '+' Term	{ Emit("ADD"); }
| Expression '-' Term { Emit("SUB"); }
| '+' Term %prec UM 
| '-' Term %prec UM { Emit("NEG"); }
| Term
;
Term: Term '*' Factor { Emit("MUL"); }
| Term '/' Factor { Emit("DIV"); }
| Factor
;
Factor: ID { 
		if (Lookup($1, VAR)) {
			Emit1("LOD", LDiff, OFFSET);
		}
		else if (Lookup($1, CONST)) {
			Emit1("LIT", LDiff, OFFSET);
		}
		else {
			/* error: undefined var */
		}
	} 
| NUM { Emit1("LIT", 0, $1); }
| '(' Expression ')'
;

%%
#include "lex.yy.c"
void yyerror(char* s) {
	printf("line: %d cp: %d %s\n", ln, cp, s);
}

void init() { // 버켓과 테이블 초기화
	int i = 0;
	for (i = 0; i < BUCKETSIZE; i++){
		bucket[i] = -1;
	}
	for (i = 0; i < TBSIZE; i++){
		table[i].link = -1;
	}
	for (i = 0; i < FUNCSIZE; i++){
		funcaddr[i] = -1;
	}
}

int hash(char *s) {

	int c, hash = 401;

	while (c = *s++)
		hash = ((hash << 4) + hash) + c; /* hash */

	return ((int)(hash%BUCKETSIZE));
}

//look up a symbol table entry, add if not present
int Lookup(char *name, int type) { // 심볼 테이블에 같은것이 없으면 1리턴 있으면 0리턴
	int i = hash(name); // name에 대한 해시값을 뽑기
	i = bucket[i]; // 해시버켓이 가르키는 심볼 테이블 인덱스 뽑기
	while(i != -1){ // 테이블 link를 따라 찾는다
		if (!strcmp(table[i].name, name)) {
			if (table[i].type == type) {
				LDiff = level - table[i].lvl;
				OFFSET = table[i].offst;
				return 1;
			}
		}
		i = table[i].link;
	}
	return 0;
}

void Enter(char *name, int type, int lvl, int offst) {
	
	int i = hash(name);
	int temp = bucket[i]; // 기존 버켓이 가르키는 심볼 테이블 인덱스 저장
	
	/* 새로운 심볼 등록 */
	bucket[i] = tx; 
	strcpy(table[tx].name, name);
	table[tx].type = type;
	table[tx].lvl = lvl;
	table[tx].offst = offst;
	table[tx].link = temp;
	tx++; // 심볼테이블 탑 하나 증가
}

void SetBlock() {
	block[level]=tx;
	level++;
	printf("Setblock: level=%d, tindex=%d\n", level, tx);
}

void ResetBlock() { 
	int i = 0;
	level--;
	int h = 0;
	tx = block[level];
	i = tx;
	while (table[i].name[0] != '\0') {
		h = hash(table[i].name);
		bucket[h] = table[i].link;
		strcpy(table[i].name, "");
		table[i].type = 0;
		table[i].lvl = 0;
		table[i].offst = 0;
		table[i].link = -1;
		i++;
	}
	printf("Resetblock: level=%d, tindex=%d\n", level, tx);
}

void DisplayTable() { 
	int idx=tx;
	printf("----HASH BUCKET----\n");
	for (int i = BUCKETSIZE - 1; i >= 0; i--) {
		printf("index %d | value %d\n", i, bucket[i]);
	}
	printf("------------------\n");
	printf("-----------------------SYMBOL TABLE-----------------------\n");
	printf("|INDEX\t|NAME\t\t|DATATYPE  |LEVEL\t|OFFSET\t|LINK\n");
	printf("-------------------------------------------------------------\n");
	while (--idx>=0) { 
		printf("|%d\t|%-15s|%d\t   |%d\t\t|%d\t|%d\n",
		idx, table[idx].name, table[idx].type, table[idx].lvl, table[idx].offst, table[idx].link);
	}
	printf("-----------------------------------------------------------\n");
}
void DisplayCode() { 
	int i = CodeIndex;
	printf("--------------Code--------------\n");
	printf("|INDEX\t|CODE\t|LDiff\t|OFFSET\t|\n");
	while(--i >= 0) {
		if(Code[i].f == 1)
			printf("|%d\t|%s\t|%d\t|%d\t|\n", i, opr[8 + Code[i].a], Code[i].l, Code[i].a);
		else 
			printf("|%d\t|%s\t|%d\t|%d\t|\n", i, opr[Code[i].f], Code[i].l, Code[i].a);
	}
	printf("--------------------------------\n");
	i = CodeIndex;
	printf("-----------Binary Code----------\n");
	while(--i >= 0) {
		printf("%d\t%d\t%d\t%d\t\n", i, Code[i].f, Code[i].l, Code[i].a);
	}
	printf("--------------------------------\n");
}
void GenLab(char *label) { // Lname에 LAB%d을 입력
	Lno++;
	sprintf(label, "LAB%d", Lno);
}
void EmitLab(char *label) { // 라벨의 위치 지정
	printf("%s\n", label);
	int i = 0;
	i = atoi(&label[3]);
	if(Code[funcaddr[i]].a == -1) Code[funcaddr[i]].a = CodeIndex;
	else funcaddr[i] = CodeIndex; // 라벨의 코드 주소를 funcaddr에 저장
}
void Emit1(char *code, int ld, int offst) { // INT, LOD, STO, LIT
	printf("%d	%s	%d	%d\n", CodeIndex, code, ld, offst);
	if (!strcmp(code, "INT")) {
		Code[CodeIndex].f = Int;
	}
	else if (!strcmp(code, "LOD")) {
		Code[CodeIndex].f = Lod;
	}
	else if (!strcmp(code, "STO")) {
		Code[CodeIndex].f = Sto;
	}
	else if (!strcmp(code, "LIT")) {
		Code[CodeIndex].f = Lit;
	}
	Code[CodeIndex].l = ld;
	Code[CodeIndex].a = offst;
	CodeIndex++;
}
void Emit2(char *code, int ld, char *name) { // CAL
	printf("%d	%s	%d	%s\n", CodeIndex, code, ld, name);
	Code[CodeIndex].f = Cal;
	Code[CodeIndex].l = ld;
	Code[CodeIndex].a = funcaddr[OFFSET];
	CodeIndex++;
}
void Emit3(char *code, char *label) { // JMP JPC
	printf("%d	%s	%s\n", CodeIndex, code, label);
	if (!strcmp(code, "JMP")) {
		Code[CodeIndex].f = Jmp;
	}
	else if (!strcmp(code, "JPC")) {
		Code[CodeIndex].f = Jpc;
	}
	Code[CodeIndex].l = 0;
	Code[CodeIndex].a = funcaddr[atoi(&label[3])]; // 라벨의 위치를 미리 알고 있으면 잘 저장됨
	if ( funcaddr[atoi(&label[3])] == -1 ) { // 라벨의 위치를 모르고 있으면 나중을 위해 현재 코드 위치를 저장
		funcaddr[atoi(&label[3])] = CodeIndex;
	}
	CodeIndex++;
}
void Emit(char *code) { // OPR
	printf("%s\n", code);
	if (!strcmp(code, "RET")) {
		Code[CodeIndex].a = 0;
	}
	else if (!strcmp(code, "NEG")) {
		Code[CodeIndex].a = 1;
	}
	else if (!strcmp(code, "ADD")) {
		Code[CodeIndex].a = 2;
	}
	else if (!strcmp(code, "SUB")) {
		Code[CodeIndex].a = 3;
	}
	else if (!strcmp(code, "MUL")) {
		Code[CodeIndex].a = 4;
	}
	else if (!strcmp(code, "DIV")) {
		Code[CodeIndex].a = 5;
	}
	else if (!strcmp(code, "ODD")) {
		Code[CodeIndex].a = 6;
	}
	else if (!strcmp(code, "AND")) {
		Code[CodeIndex].a = 7;
	}
	else if (!strcmp(code, "EQ")) {
		Code[CodeIndex].a = 8;
	}
	else if (!strcmp(code, "NE")) {
		Code[CodeIndex].a = 9;
	}
	else if (!strcmp(code, "LT")) {
		Code[CodeIndex].a = 10;
	}
	else if (!strcmp(code, "GT")) {
		Code[CodeIndex].a = 11;
	}
	else if (!strcmp(code, "GE")) {
		Code[CodeIndex].a = 12;
	}
	else if (!strcmp(code, "LE")) {
		Code[CodeIndex].a = 13;
	}
	Code[CodeIndex].f = Opr;
	Code[CodeIndex].l = 0;
	CodeIndex++;
}
void display_var() {
	int flag = 0;
	int w = 0;
	printf("===== global_var result =====\n");	
	for (int t = 0; t < tx; t++) {
		if(table[t].type == 1 && flag == 0) {
			flag = 1;
			w = t;	
		}
		if(table[t].type == 1 && flag == 1) {
			printf("%s=%d ", table[t].name, s[3 + t - w]);	
		}
	}
}
int main() {
	init();
	yyparse();
	interprete();
	display_var();
}
