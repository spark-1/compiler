%option yylineno

%{
int yywrap();
%}

%%
"123" { printf("%d", yylineno); }
. |
"\n" ;
%%
int yywrap() {
	printf("Lexical analysis is end\n");
	return 1; // 0 : continue, 1 : end
}
int main(){
	yylex();
}