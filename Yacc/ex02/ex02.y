%{ 
#include <stdio.h>
void yyerror(char* s);
int yylex();
%}
%token NUMBER TOKHEAT STATE TOKTARGET TOKTEMPERATURE
%%
commands: /* empty */
| commands command
;
command: heat_switch
| target_set
;
heat_switch:
TOKHEAT STATE { printf("Heat turned on or off\n"); }
;
target_set:
TOKTARGET TOKTEMPERATURE NUMBER { printf("Temperature set\n"); }
;
%%
#include "lex.yy.c"
void yyerror(char* s) {
	printf("%s\n", s);
}
int main() {
	return yyparse();
}