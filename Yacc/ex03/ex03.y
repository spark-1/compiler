%{
#include <stdio.h>
void yyerror(char* s);
int yylex();
%}
%token NOUN VERB PRONOUN ADJECTIVE
%%
sentence : subject VERB object { printf("Sentence is valid.\n"); }
;
subject : NOUN
| PRONOUN
;
object : NOUN
| ADJECTIVE
;
%%
#include "lex.yy.c"
void yyerror(char* s) {
	printf("%s\n", s);
}
int main() {
	return yyparse();
}