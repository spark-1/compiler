%{
#include <stdio.h>
void yyerror(char *s);
int yylex();
%}
%token NUMBER
%left '-' '+'
%left '*' '/' /* 왼쪽 결합 법칙을 따르며 우선 순위 적용 "곱 나눗셈" > "더하기 빼기" */
%nonassoc UMINUS /* unary operator '-'의 정의로 결합법칙이 적용이 안되는 것을 명시. */
%%
statement: expression { printf("%d\n", $1); }
;
expression: expression '+' expression { $$ = $1 + $3; }
| expression '-' expression { $$ = $1 - $3; }
| expression '*' expression { $$ = $1 * $3; }
| expression '/' expression {
	if( $3 == 0 ) yyerror("divide by zero");
	else $$ = $1 / $3;
	}
| '-' expression %prec UMINUS { $$ = -$2; } //"단항 -의 우선순위를 가장 높게" 
| '(' expression ')' { $$ = $2; }
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