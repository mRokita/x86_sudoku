#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "sudoku.h"

int main(int argc, char *argv[])
{
    int mtx[9][9];
    for(int i=0; i<9; ++i){
        for(int j=0; j<9; ++j){
            int a;
            scanf("%d", &a);
            mtx[i][j] = a;
        }
    }
    printf("---\n");
    int a = sudoku(mtx);
    for(int i=0; i<9; ++i){
        for(int j=0; j<9; ++j){
            printf("%d ", mtx[i][j]);
        }
        printf("\n");
    }
    return 0;
}
