%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
void yyerror(char* s);
int yylex();
char *heater = NULL;
%}
%union {
int number;
char *string;
}
%token TOKHEATER TOKHEAT TOKTARGET TOKTEMPERATURE
%token <number> STATE NUMBER
%token <string> WORD
%%
commands: /* empty */
| commands command
;
command: heat_switch
| target_set
| heater_select
;
heat_switch: TOKHEAT STATE {
	if($2) printf("Heat turned on\n");
	else printf("Heat turned off\n");
};
target_set: TOKTARGET TOKTEMPERATURE NUMBER {
	printf("Heater '%s' temperature set to %d\n",heater, $3);
};
heater_select: TOKHEATER WORD {
	printf("Selected '%s' heater\n", $2);
	heater = $2;
};
%%
#include "lex.yy.c"
void yyerror(char* s) {
	printf("%s\n", s);
}
int main() {
	return yyparse();
}