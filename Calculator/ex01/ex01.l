%{
%}
%%
[0-9]+ { yylval = atoi(yytext); return NUMBER; }
[\t ] ; /* 공백은 무시 */
\n return 0;
. return yytext[0];
%%