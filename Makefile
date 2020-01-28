all:
	gcc -g -m64 -std=c99 -o main.o -c main.c
	nasm -f elf64 sudoku.s
	gcc -g -m64 -o sudoku main.o sudoku.o
32bit:
	gcc -g -m32 -std=c99 -o main.o -c main.c
	nasm -f elf32 sudoku.i386.s -o sudoku.o
	gcc -g -m32 -o sudoku main.o sudoku.o
clean:
	@rm -f *.o
	@rm -f sudoku
