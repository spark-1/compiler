%option main
STRING [a-zA-Z]

%%
{STRING}+ { printf("text is %s\n", yytext); }
"/*" {
	int c1 = 0, c2 = input();
	for(;;) {
		if(c2 == NULL) break;
		if(c1 == '*' && c2 == '/') break;
		c1 = c2;
		c2 = input();
	}
	printf("This is comment line\n");
}
. ;
%%