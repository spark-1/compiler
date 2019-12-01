%option main

%{
#include <stdio.h>
%}

%%
"int" { printf("first int"); }
"int" { printf("second int"); }
[0-9]+ { printf("number"); }
[a-zA-Z]+ { printf("text"); }
[a-zA-Z]+[0-9]+ { printf("number + text"); }
. ;
%%