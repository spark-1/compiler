%{
%}
%%
[0-9]*\.[0-9]+ {
	yylval.dval.tag = 1;
	yylval.dval.rval = atof(yytext); /* 실수로 변환 */
	return NUMBER;
	}
[0-9]+ {
	yylval.dval.tag = 0;
	yylval.dval.ival = atoi(yytext); 
	return NUMBER; 
	}
[\t ] ; /* 공백은 무시 */
[a-z] {
	yylval.ival = yytext[0] - 'a';
	return NAME;
	}
"$" { return 0; } /* 종료문자 */
\n |
. return yytext[0];
%%