
# A Makefile example 
#     (Ubuntu 12.04 Linux)

hello: mongoose.o ../mongoose_d.d ../dmongoose.d
	dmd hello.d -I.. ../mongoose_d.d ../dmongoose.d mongoose.o -L-ldl

mongoose.o: ../mongoose/mongoose.h ../mongoose/mongoose.c
	gcc -c ../mongoose/mongoose.c -I../mongoose -std=c99 -O2 -W -Wall -pedantic -pthread -DNO_CGI -DNO_SSL

 

