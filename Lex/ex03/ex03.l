%option main

%{
int wordCount = 0;
%}

WORD [^ \t\n]+
EOL \n

%%
{WORD} { wordCount++; }
{EOL} { printf("%d\n", wordCount); wordCount = 0; }
%%