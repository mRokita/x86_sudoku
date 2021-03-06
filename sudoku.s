section .text
global sudoku

%define GUESS_PASSED  3
%define GUESS_FAILED  2
%define CHECK_PASSED  1
%define CHECK_FAILED  0

; [[ "Zmienne globalne" ]]
; R13 - sudoku

; [[ Funkcja zwracająca do AX wartość komórki (DI, SI) ]]
; DIL - X
; SIL - Y
; AL - Wartość komórki
get_cell_value:
    mov al, sil
    lea eax, [eax*8 + eax]   ; Wyciągnięcie wartości z adresu i wrzucenie do AX
    add al, dil
    mov al, [r13+rax]
    ret

; [[ Funkcja zapisująca wartość komórki (DI, SI) ]]
; DIL - X
; SIL - Y
; DL - Wartość komórki
set_cell_value:
    mov al, sil
    lea eax, [eax*8 + eax]
    add al, dil
    mov [r13+rax], dl
    ret

; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe, po pudełku 3x3 ]]
; DIL - X
; SIL - Y
; DL - Wartość sprawdzana
; AL - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli nie
check_box:
    xor r8b, r8b
    xor r9b, r9b
    mov r8b, dil ; X sprawdzanej komórki
    mov r9b, sil ; Y sprawdzanej komórki
_check_box_calc_offset_x:
    xor r10b, r10b ; r10w X offset
_check_box_loop_box_offset_x:
    add r10b, 3
    cmp r10b, dil
    jle _check_box_loop_box_offset_x
    sub r10w, 3
_check_box_calc_offset_y:
    xor r11b, r11b
_check_box_loop_box_offset_y:
    add r11b, 3
    cmp r11b, sil
    jle _check_box_loop_box_offset_y
    sub r11b, 3
_check_box_loop_start:
    inc dil
    add r10b, 2 ; zwiększenie offsetu o 2 do porownania cur_x >= offset_x + 2
    cmp dil, r10b
    jle _check_box_skip_col_inc
_check_box_col_inc:
    mov dil, r10b
    sub dil, 2
    inc sil
_check_box_skip_col_inc:
    sub r10b, 2;

    add r11b, 2 ; zwiększenie offsetu o 2 do porownania cur_y >= offset_y + 2
    cmp sil, r11b
    jle _check_box_skip_row_inc
_check_box_row_inc:
    mov sil, r11b
    sub sil, 2
_check_box_skip_row_inc:
    sub r11b, 2

    cmp dil, r8b
    jne _check_box_check_eq
    cmp sil, r9b
    jne _check_box_check_eq
    ; Sprawdzona całość, zwracamy CHECK_PASSED
    jmp _check_box_ret_passed
_check_box_check_eq:
    call get_cell_value
    cmp al, dl
    jne _check_box_loop_start
_check_box_ret_failed:
    xor rax, rax
    mov sil, r9b
    mov dil, r8b
    mov al, CHECK_FAILED
    ret
_check_box_ret_passed:
    xor al, al
    mov sil, r9b
    mov dil, r8b
    mov al, CHECK_PASSED
    ret

; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe (po kolumnie)]]
; DIL - X
; SI - Y
; DL - Wartość sprawdzana
; AL - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli nie
check_col:
    ; R8W - sprawdzany X
    xor r8b, r8b
    xor r9b, r9b
    mov r8b, sil ; Przeniesienie si do r9w, aby zachowac Y sprawdzanego pola
_check_col_loop_start:
    inc sil
    cmp sil, 8
    jle _check_col_loop_scroll_end ; Jeśli aktualny X nie przeskoczył za zakres, przejście za operację "przewinięcia"
_check_col_loop_scroll_start:
    mov sil, 0
_check_col_loop_scroll_end:
    cmp r8b, sil ; Czy wróciliśmy do badanego Ya
    je _check_col_ret_passed
    call get_cell_value
    cmp al, dl
    jne _check_col_loop_start
_check_col_ret_failed:
    xor al, al
    mov sil, r8b
    mov al, CHECK_FAILED
    ret
_check_col_ret_passed:
    xor al, al
    mov sil, r8b
    mov al, CHECK_PASSED
    ret


; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe, po wierszu ]]
; DI - X
; SI - Y
; DX - Wartość sprawdzana
; AX - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli niehttps://www.facebook.com/
check_row:
    ; R8W - sprawdzany X
    xor r8b, r8b
    xor r9b, r9b
    mov r8b, dil ; Przeniesienie, żeby zachować di do zakonczenia iteracji
_check_row_loop_start:
    inc dil
    cmp dil, 8
    jle _check_row_loop_scroll_end ; Jeśli aktualny X nie przeskoczył za zakres, przejście za operację "przewinięcia"
_check_row_loop_scroll_start:
    mov dil, 0
_check_row_loop_scroll_end:
    cmp r8b, dil ; Czy wróciliśmy do badanego Xa
    je _check_row_ret_passed
    call get_cell_value
    cmp al, dl
    jne _check_row_loop_start
_check_row_ret_failed:
    xor al, al
    mov dil, r8b
    mov al, CHECK_FAILED
    ret
_check_row_ret_passed:
    xor al, al
    mov dil, r8b
    mov al, CHECK_PASSED
    ret


; [[ Funkcja  ]]
; DI - X
; SI - Y
; AX - c_PASSED, jeśli udało się znaleźć wartość dla aktualnego i każdego następnego, GUESS_FAILED, jeśli nie nie udało
guess:
    push rbp;
    xor rax, rax;
    mov rbp, rsp;

_guess_first_empty_loop_start: ; Pętla szukająca pierwszego pustego miejsca
    inc dil
    cmp dil, 9
    jne _guess_skip_inc_row
_guess_inc_row: ;
    inc sil
    xor dil, dil
_guess_skip_inc_row:
    cmp sil, 8
    jg _guess_ret_passed
    call get_cell_value
    cmp al, 0
    jne _guess_first_empty_loop_start

    xor rdx, rdx ; Wartość sprawdzana,
_guess_guessing_loop_start:
    inc dl
    cmp dl, 9
    jg _guess_ret_failed
    call check_row
    cmp al, CHECK_PASSED
    jne _guess_guessing_loop_start

    call check_col
    cmp al, CHECK_PASSED
    jne _guess_guessing_loop_start

    call check_box
    cmp al, CHECK_PASSED
    jne _guess_guessing_loop_start
    call set_cell_value
bbp:
    push rdi
    push rsi
    push rdx
    call guess
    pop rdx
    pop rsi
    pop rdi
bap:
    cmp al, GUESS_PASSED
    jne _guess_guessing_loop_start
_guess_ret_passed:
    xor al, al
    mov al, GUESS_PASSED
    pop rbp
    ret
_guess_ret_failed:
    xor dl, dl
    call set_cell_value
    xor al, al
    mov al, GUESS_FAILED
    pop rbp
    ret

sudoku:
    push rbp;
    mov rbp, rsp;
    mov r13, rdi ; Przeniesienie adresu sudoku na R13
    xor rdi, rdi
    xor rsi, rsi ; Początkowa pozycja na zero

    xor rdx, rdx
    DEC dil ; ustawienie na -1 do guess
    ; Wywołanie guess
    ; RDI - kolumna
    ; RSI - wiersz
    call guess
end:
    pop rbp
    ret
