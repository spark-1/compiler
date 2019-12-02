%{
#include <stdio.h>
void yyerror(char *s);
int yylex();
%}
%token NUMBER
%%
statement: expression { printf("%d\n", $1); }
;
expression: expression '+' expression { $$ = $1 + $3; }
| expression '-' expression { $$ = $1 - $3; }
| expression '*' expression { $$ = $1 * $3; }
| expression '/' expression { $$ = $1 / $3; }
| NUMBER { $$ = $1; }
;
%%
#include "lex.yy.c"
void yyerror(char *s) {
	printf("%s\n", s);
}
int main() {
	return yyparse();
}