%%
[ \t]+ ;
is |
am |
are |
do |
have |
go { return VERB; }
I |
you |
he |
she |
we |
they { return PRONOUN; }
kind |
happy |
sad |
gentle { return ADJECTIVE; }
[a-zA-Z]+ { printf("%s: don't recognize\n", yytext); }
.|\n { ECHO; }
%%