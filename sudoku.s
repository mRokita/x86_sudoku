section .text
    global sudoku

%define GUESS_PASSED  3
%define GUESS_FAILED  2
%define CHECK_PASSED  1
%define CHECK_FAILED  0

; [[ "Zmienne globalne" ]]
; R13 - sudoku

; [[ Funkcja zwracająca do AX wartość komórki (DI, SI) ]]
; DI - X
; SI - Y
; AX - Wartość komórki
get_cell_value:
    mov r12w, dx ; Przeniesienie dx do r9w, aby uniknać nadpisania przez mul
    xor rax, rax        ; Zerowanie rax
    mov cx, si
    mov ax, cx          ; Wrzucenie SI(Y) do mnożenia
    mov cx, word 9      ; Mnożnik - 9
    mul cx              ; Faktyczne mnożenie
    add ax, di          ; Dodanie X do adresu
    mov al, [r13+rax]   ; Wyciągnięcie wartości z adresu i wrzucenie do AX
    mov dx, r12w
    ret

; [[ Funkcja zapisująca wartość komórki (DI, SI) ]]
; DI - X
; SI - Y
; DX - Wartość komórki
set_cell_value:
    mov r12w, dx ; Przeniesienie dx do r9w, aby uniknać nadpisania przez mul
    mov cx, si
    mov ax, cx          ; Wrzucenie SI(Y) do mnożenia
    mov cx, word 9      ; Mnożnik - 9
    mul cx              ; Faktyczne mnożenie
    add ax, di          ; Dodanie X do adresu
    mov [r13+rax], r12b
    mov dx, r12w
    xor rax, rax        ; Zerowanie rax
    ret

; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe, po pudełku 3x3 ]]
; DI - X
; SI - Y
; DX - Wartość sprawdzana
; AX - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli nie
check_box:
    xor r8, r8
    xor r9, r9
    mov r8w, di ; X sprawdzanej komórki
    mov r9w, si ; Y sprawdzanej komórki
_check_box_calc_offset_x:
    xor r10, r10 ; r10w X offset
_check_box_loop_box_offset_x:
    add r10w, 3
    cmp r10w, di
    jle _check_box_loop_box_offset_x
    sub r10w, 3
_check_box_calc_offset_y:
    xor r11, r11
_check_box_loop_box_offset_y:
    add r11w, 3
    cmp r11w, si
    jle _check_box_loop_box_offset_y
    sub r11w, 3
_check_box_loop_start:
    add di, 1
    add r10w, 2 ; zwiększenie offsetu o 2 do porownania cur_x >= offset_x + 2
    cmp di, r10w
    jle _check_box_skip_col_inc
_check_box_col_inc:
    mov di, r10w
    sub di, 2
    add si, 1
_check_box_skip_col_inc:
    sub r10w, 2;

    add r11w, 2 ; zwiększenie offsetu o 2 do porownania cur_y >= offset_y + 2
    cmp si, r11w
    jle _check_box_skip_row_inc
_check_box_row_inc:
     mov si, r11w
     sub si, 2
_check_box_skip_row_inc:
    sub r11w, 2

    cmp di, r8w
    jne _check_box_check_eq
    cmp si, r9w
    jne _check_box_check_eq
    ; Sprawdzona całość, zwracamy CHECK_PASSED
    jmp _check_box_ret_passed
_check_box_check_eq:
    call get_cell_value
    cmp ax, dx
    jne _check_box_loop_start
_check_box_ret_failed:
    xor rax, rax
    mov si, r9w
    mov di, r8w
    mov al, CHECK_FAILED
    ret
_check_box_ret_passed:
    xor rax, rax
    mov si, r9w
    mov di, r8w
    mov al, CHECK_PASSED
    ret

; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe (po kolumnie)]]
; DI - X
; SI - Y
; DX - Wartość sprawdzana
; AX - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli nie
check_col:
    ; R8W - sprawdzany X
    xor r8, r8
    xor r9, r9
    mov r8w, si ; Przeniesienie si do r9w, aby zachowac Y sprawdzanego pola
_check_col_loop_start:
    add si, 1
    cmp si, 8
    jle _check_col_loop_scroll_end ; Jeśli aktualny X nie przeskoczył za zakres, przejście za operację "przewinięcia"
_check_col_loop_scroll_start:
    mov si, 0
_check_col_loop_scroll_end:
    cmp r8w, si ; Czy wróciliśmy do badanego Ya
    je _check_col_ret_passed
    call get_cell_value
    cmp ax, dx
    jne _check_col_loop_start
_check_col_ret_failed:
    xor rax, rax
    mov si, r8w
    mov al, CHECK_FAILED
    ret
_check_col_ret_passed:
    xor rax, rax
    mov si, r8w
    mov al, CHECK_PASSED
    ret


; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe, po wierszu ]]
; DI - X
; SI - Y
; DX - Wartość sprawdzana
; AX - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli niehttps://www.facebook.com/
check_row:
    ; R8W - sprawdzany X
    xor r8, r8
    xor r9, r9
    mov r8w, di ; Przeniesienie, żeby zachować di do zakonczenia iteracji
_check_row_loop_start:
    add di, 1
    cmp di, 8
    jle _check_row_loop_scroll_end ; Jeśli aktualny X nie przeskoczył za zakres, przejście za operację "przewinięcia"
_check_row_loop_scroll_start:
    mov di, 0
_check_row_loop_scroll_end:
    cmp r8w, di ; Czy wróciliśmy do badanego Xa
    je _check_row_ret_passed
    call get_cell_value
    cmp ax, dx
    jne _check_row_loop_start
_check_row_ret_failed:
    xor rax, rax
    mov di, r8w
    mov dx, dx
    mov ax, CHECK_FAILED
    ret
_check_row_ret_passed:
    xor rax, rax
    mov di, r8w
    mov ax, CHECK_PASSED
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
    add di, 1
    cmp di, 9
    jne _guess_skip_inc_row
_guess_inc_row: ;
    add si, 1
    xor di, di
_guess_skip_inc_row:
    cmp si, 8
    jg _guess_ret_passed
    call get_cell_value
    cmp ax, 0
    jne _guess_first_empty_loop_start

    xor rdx, rdx ; Wartość sprawdzana,
_guess_guessing_loop_start:
    add dx, 1
    cmp dx, 9
    jg _guess_ret_failed
    call check_row
    cmp ax, CHECK_PASSED
    jne _guess_guessing_loop_start

    call check_col
    cmp ax, CHECK_PASSED
    jne _guess_guessing_loop_start

    call check_box
    cmp ax, CHECK_PASSED
    jne _guess_guessing_loop_start
    call set_cell_value
bbp:
    push di
    push si
    push dx
    call guess
    pop dx
    pop si
    pop di
bap:
    cmp ax, GUESS_PASSED
    jne _guess_guessing_loop_start
_guess_ret_passed:
    xor rax, rax
    mov ax, GUESS_PASSED
    pop rbp
    ret
_guess_ret_failed:
    xor dx, dx
    call set_cell_value
    xor rax, rax
    mov ax, GUESS_FAILED
    pop rbp
    ret

sudoku:
    ; PROLOG
	push rbp;
    mov rbp, rsp;
    mov r13, rdi ; Przeniesienie adresu sudoku na R13
    xor rdi, rdi
    xor rsi, rsi ; Początkowa pozycja na zero

    xor rdx, rdx
    sub di, 1 ; ustawienie na -1 do guess
    ; Wywołanie guess
    ; RDI - kolumna
    ; RSI - wiersz
    call guess
end:
    ; EPILOG
	pop rbp
	ret
