%option main

%{
#include <stdio.h>
%}

%%
[0-9]+ { printf("number\n"); }
[a-zA-Z]+ { printf("string\n"); }
[\n\t ] |
. ;
%%