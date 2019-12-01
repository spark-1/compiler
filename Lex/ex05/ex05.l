%option main

%x CMNT
STRING [a-zA-Z]
%%
"/*" { BEGIN CMNT; }
<CMNT>. |
<CMNT>\n ;
<CMNT>"*/" { BEGIN INITIAL; }
{STRING}+ { printf("String is %s\n", yytext); }
%%