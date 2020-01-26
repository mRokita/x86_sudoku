all:
	gcc -g -m64	-std=c99 -o main.o -c main.c
	nasm -f elf64 sudoku.s
	gcc -g -m64 -o sudoku main.o sudoku.o
clean:
	@rm -f *.o
	@rm -f sudoku
