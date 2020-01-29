section .text
global sudoku

%define GUESS_PASSED  3
%define GUESS_FAILED  2
%define CHECK_PASSED  1
%define CHECK_FAILED  0

; [[ "Zmienne globalne" ]]
; EDI - sudoku

; [[ Funkcja zwracająca do AX wartość komórki (BL, CL) ]]
; BL - X
; CL - Y
; AL - Wartość komórki
get_cell_value:
    xor eax, eax
    mov al, cl
    lea eax, [eax*8 + eax]   ; Wyciągnięcie wartości z adresu i wrzucenie do AX
    add al, bl
    mov al, [edi + eax]
    ret

; [[ Funkcja zapisująca wartość komórki (DI, SI) ]]
; BL - X
; CL - Y
; DL - Wartość komórki
set_cell_value:
    xor eax, eax
    mov al, cl
    lea eax, [eax*8 + eax]
    add al, bl
    mov [edi + eax], dl
    ret

; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe, po pudełku 3x3 ]]
; BL - X
; CL - Y
; DL - Wartość sprawdzana
; AL - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli nie
check_box:
    xor bh, bh
    xor ch, ch
    mov bh, bl ; X sprawdzanej komórki
    mov ch, cl ; Y sprawdzanej komórki
_check_box_calc_offset_x:
    xor dh, dh ; r10w X offset
_check_box_loop_box_offset_x:
    add dh, 3
    cmp dh, bl
    jle _check_box_loop_box_offset_x
    sub dh, 3
_check_box_calc_offset_y:
    xor ah, ah
_check_box_loop_box_offset_y:
    add ah, 3
    cmp ah, cl
    jle _check_box_loop_box_offset_y
    sub ah, 3
_check_box_loop_start:
    inc bl
    add dh, 2 ; zwiększenie offsetu o 2 do porownania cur_x >= offset_x + 2
    cmp bl, dh
    jle _check_box_skip_col_inc
_check_box_col_inc:
    mov bl, dh
    sub bl, 2
    inc cl
_check_box_skip_col_inc:
    sub dh, 2;

    add ah, 2 ; zwiększenie offsetu o 2 do porownania cur_y >= offset_y + 2
    cmp cl, ah
    jle _check_box_skip_row_inc
_check_box_row_inc:
    mov cl, ah
    sub cl, 2
_check_box_skip_row_inc:
    sub ah, 2

    cmp bl, bh
    jne _check_box_check_eq
    cmp cl, ch
    jne _check_box_check_eq
    ; Sprawdzona całość, zwracamy CHECK_PASSED
    jmp _check_box_ret_passed
_check_box_check_eq:
    push eax
    call get_cell_value
    cmp al, dl
    pop eax
    jne _check_box_loop_start
_check_box_ret_failed:
    xor al, al
    mov cl, ch
    mov bl, bh
    mov al, CHECK_FAILED
    ret
_check_box_ret_passed:
    xor al, al
    mov cl, ch
    mov bl, bh
    mov al, CHECK_PASSED
    ret

; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe (po kolumnie)]]
; bl - X
; SI - Y
; DL - Wartość sprawdzana
; AL - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli nie
check_col:
    ; R8W - sprawdzany X
    xor bh, bh
    xor ch, ch
    mov bh, cl ; Przeniesienie si do r9w, aby zachowac Y sprawdzanego pola
_check_col_loop_start:
    inc cl
    cmp cl, 8
    jle _check_col_loop_scroll_end ; Jeśli aktualny X nie przeskoczył za zakres, przejście za operację "przewinięcia"
_check_col_loop_scroll_start:
    xor cl, cl
_check_col_loop_scroll_end:
    cmp bh, cl ; Czy wróciliśmy do badanego Ya
    je _check_col_ret_passed
    push eax
    call get_cell_value
    cmp al, dl
    pop eax
    jne _check_col_loop_start
_check_col_ret_failed:
    xor al, al
    mov cl, bh
    mov al, CHECK_FAILED
    ret
_check_col_ret_passed:
    xor al, al
    mov cl, bh
    mov al, CHECK_PASSED
    ret


; [[ Funkcja sprawdzająca, czy wstawienie wartości DX do komórki (DI, SI) jest możliwe, po wierszu ]]
; DI - X
; SI - Y
; DX - Wartość sprawdzana
; AX - CHECK_PASSED, jeśli można, CHECK_FAILED, jeśli niehttps://www.facebook.com/
check_row:
    ; R8W - sprawdzany X
    xor bh, bh
    xor ch, ch
    mov bh, bl ; Przeniesienie, żeby zachować di do zakonczenia iteracji
_check_row_loop_start:
    inc bl
    cmp bl, 8
    jle _check_row_loop_scroll_end ; Jeśli aktualny X nie przeskoczył za zakres, przejście za operację "przewinięcia"
_check_row_loop_scroll_start:
    xor bl, bl
_check_row_loop_scroll_end:
    cmp bh, bl ; Czy wróciliśmy do badanego Xa
    je _check_row_ret_passed
    push eax
    call get_cell_value
    cmp al, dl
    pop eax
    jne _check_row_loop_start
_check_row_ret_failed:
    xor al, al
    mov bl, bh
    mov al, CHECK_FAILED
    ret
_check_row_ret_passed:
    xor al, al
    mov bl, bh
    mov al, CHECK_PASSED
    ret


; [[ Funkcja  ]]
; BL - X
; CL - Y
; AL - c_PASSED, jeśli udało się znaleźć wartość dla aktualnego i każdego następnego, GUESS_FAILED, jeśli nie nie udało
guess:
    push ebp;
    xor al, al;
    mov ebp, esp;

_guess_first_empty_loop_start: ; Pętla szukająca pierwszego pustego miejsca
    inc bl
    cmp bl, 9
    jne _guess_skip_inc_row
_guess_inc_row:
    inc cl
    xor bl, bl
_guess_skip_inc_row:
    cmp cl, 8
    jg _guess_ret_passed
    push eax
    call get_cell_value
    cmp al, 0
    pop eax
    jne _guess_first_empty_loop_start

    xor dl, dl ; Wartość sprawdzana,
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

    push eax
    call set_cell_value
    pop eax

    push edi
    push ebx
    push ecx
    push edx
    call guess
    pop edx
    pop ecx
    pop ebx
    pop edi
    cmp al, GUESS_PASSED
    jne _guess_guessing_loop_start
_guess_ret_passed:
    xor al, al
    mov al, GUESS_PASSED
    mov esp, ebp
    pop ebp
    ret
_guess_ret_failed:
    xor dl, dl
    push eax
    call set_cell_value
    pop eax
    xor al, al
    mov al, GUESS_FAILED
    mov esp, ebp
    pop ebp
    ret

sudoku:
    push ebp;
    mov ebp, esp;
    push ebx;
    push edi;
    mov edi, [ebp+8] ; Przeniesienie adresu sudoku na edi
    xor ecx, ecx
    xor ebx, ebx ; Początkowa pozycja na zero
    xor edx, edx
    xor eax, eax

    dec bl ; ustawienie na -1 do guess
    call guess
    pop edi;
    pop ebx;
    mov esp, ebp
    pop ebp;
end:
    ret
