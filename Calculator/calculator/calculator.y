%{
#include <stdio.h>
void yyerror(char *s);
int yylex();

typedef struct {
	int tag;
	union {
		float rval;
		int ival;
	};
} vtype;
vtype vbltable[26];
// 변수의 값을 저장하기 위한 테이블
// 변수의 이름이 배열의 인덱스 역할
%}

%union {
	vtype dval;
	int ival;
}
%token <dval> NUMBER
%token <ival> NAME
%type <dval> expression
%left '-' '+'
%left '*' '/' /* 왼쪽 결합 법칙을 따르며 우선 순위 적용 "곱 나눗셈" > "더하기 빼기" */
%nonassoc UMINUS /* unary operator '-'의 정의로 결합법칙이 적용이 안되는 것을 명시. */

%%
statement_list: statement '\n'
| statement_list statement '\n'
;
statement: expression { 
		if($1.tag) {
			printf("= %lf\n", $1.rval);
		}
		else {
			printf("= %d\n", $1.ival);
		}
	}
| NAME '=' expression { 
		if($3.tag) {
			vbltable[$1].rval = $3.rval; 
			vbltable[$1].tag = 1;
			printf("%lf\n",$3.rval); 
		}
		else {
			vbltable[$1].ival = $3.ival;
			vbltable[$1].tag = 0;
			printf("%d\n",$3.ival); 
		} 
	}
;
expression: expression '+' expression { 
		if($1.tag || $3.tag) {
			$$.tag = 1;
			$$.rval = $1.rval + $3.rval;
		}
		else {
			$$.tag = 0;
			$$.ival = $1.ival + $3.ival;
		}
	}
| expression '-' expression { 
		if($1.tag || $3.tag) {
			$$.tag = 1;
			$$.rval = $1.rval - $3.rval;
		}
		else {
			$$.tag = 0;
			$$.ival = $1.ival - $3.ival;
		}
	}
| expression '*' expression { 
		if($1.tag || $3.tag) {
			$$.tag = 1;
			$$.rval = $1.rval * $3.rval;
		}
		else {
			$$.tag = 0;
			$$.ival = $1.ival * $3.ival;
		}
	}
| expression '/' expression { 
		if((!$3.tag && $3.ival == 0) || ($3.tag && $3.rval == 0.0)) { yyerror("divide by zero"); }
		else { 
			if($1.tag || $3.tag) {
				$$.tag = 1;
				$$.rval = $1.rval / $3.rval;
			}
			else {
				$$.tag = 0;
				$$.ival = $1.ival / $3.ival;
			}
		}
	}
| '-' expression %prec UMINUS { //"단항 -의 우선순위를 가장 높게" 
		if($2.tag) {
			$$.tag = 1;
			$$.rval = -$2.rval;
		}
		else {
			$$.tag = 0;
			$$.ival = -$2.ival;
		}
	}
| '(' expression ')' {
		if($2.tag) {
			$$.tag = 1;
			$$.rval = $2.rval;
		}
		else { 
			$$.tag = 0;
			$$.ival = $2.ival;
		}
	}
| NUMBER {
		if($1.tag) {
			$$.tag = 1;
			$$.rval = $1.rval;
		}
		else { 
			$$.tag = 0;
			$$.ival = $1.ival;
		}	
	}
| NAME { 
		$$ = vbltable[$1];
	}   
;
%%
#include "lex.yy.c"
void yyerror(char *s) {
	printf("%s\n", s);
}
int main() {
	return yyparse();
}