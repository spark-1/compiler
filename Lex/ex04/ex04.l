%option main
%s MYSTATE

%%
<MYSTATE>.+ { BEGIN 0; printf("<MY STATE> "); ECHO; }
run { BEGIN MYSTATE; }
%%