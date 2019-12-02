# How to excute 
$ flex [파일명.l] <br>
-> lex.yy.c 생성 <br>
$ bison [파일명.y] <br>
-> [파일명].tab.c 생성 <br>
$ gcc -o [실행파일명] [파일명].tab.c -lfl -ly<br>
-> [실행파일명].exe 생성 <br>
$ ./[실행파일명] <br>
