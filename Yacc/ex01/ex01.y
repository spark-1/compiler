%{
#include <stdio.h>
void yyerror(char* s);
int yylex();
%}
%token DING DONG DELL
%%
rhyme : sound place { printf("Great!!!"); }
;
sound : DING DONG
;
place : DELL
;
%%
#include "lex.yy.c"
void yyerror(char* s) {
	printf("%s\n", s);
}
int main() {
	return yyparse();
}