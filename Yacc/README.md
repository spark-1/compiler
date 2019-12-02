# How to excute 
__$ flex [파일명.l]__ <br>
-> lex.yy.c 생성 <br>
__$ bison [파일명.y]__ <br>
-> [파일명].tab.c 생성 <br>
__$ gcc -o [실행파일명] [파일명].tab.c -lfl -ly__ <br>
-> [실행파일명].exe 생성 <br>
__$ ./[실행파일명]__ <br>
