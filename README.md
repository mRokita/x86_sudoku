# Pobranie

```
git clone https://github.com/mRokita/x86_sudoku && cd x86_sudoku
```

# Kompilacja

### Wersja 32bit
```
make 32bit
```

### Wersja 64bit

```
make
```

# Testowanie losowym sudoku

### Automatyczne
```
sudo apt install qqwing # instalacja generatora sudoku
./testsudoku.sh
```


### Ręczne

Po kompilacji należy uruchomić plik wykonywalny ./sudoku i wprowadzić sudoku w takiej formie (0 oznacza puste pole):

```
6 0 7 0 9 0 0 3 1 
8 0 3 0 6 0 0 0 4 
9 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 8 0 0 
0 9 0 0 0 0 0 7 0 
0 0 0 3 0 0 0 0 0 
0 0 4 5 0 6 0 1 0 
0 0 0 0 4 0 0 8 0 
0 0 5 7 1 0 6 0 0 
```
