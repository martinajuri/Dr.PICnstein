; -----------------------------------------------------------
; Rutina: SEPARAR_3DIGITOS
; Entrada: ADRESH:ADRESL (valor de 10 bits)
; Salida: centenas, decenas, unidades (en RAM)
; Usa: temp16H, temp16L, centenas, decenas, unidades
; -----------------------------------------------------------

SEPARAR_3DIGITOS:
    ; Leer ADRESH (banco 0)
    MOVF    ADRESH, W
    MOVWF   temp16H

    ; Leer ADRESL (banco 1)
    BSF     STATUS, RP0
    BCF     STATUS, RP1
    MOVF    ADRESL, W
    BCF     STATUS, RP0    ; Volver a banco 0
    BCF     STATUS, RP1
    MOVWF   temp16L

    CLRF    centenas
    CLRF    decenas
    CLRF    unidades

CENT_LOOP:
    MOVF    temp16H, W
    BTFSS   STATUS, Z
    GOTO    RESTA_CIEN
    MOVLW   D'100'
    SUBWF   temp16L, W
    BTFSS   STATUS, C
    GOTO    DECI_LOOP
    MOVF    temp16L, W
    ADDLW   0x9C      ; -100
    MOVWF   temp16L
    INCF    centenas, F
    MOVLW   D'100'
    SUBWF   temp16L, W
    BTFSS   STATUS, C
    GOTO    DECI_LOOP
    GOTO    CENT_LOOP

RESTA_CIEN:
    MOVF    temp16L, W
    ADDLW   0x9C      ; -100
    MOVWF   temp16L
    BTFSC   STATUS, C
    GOTO    NO_BORROW_C
    DECF    temp16H, F
NO_BORROW_C:
    INCF    centenas, F
    GOTO    CENT_LOOP

DECI_LOOP:
    MOVF    temp16H, W
    BTFSS   STATUS, Z
    GOTO    RESTA_DIEZ
    MOVLW   D'10'
    SUBWF   temp16L, W
    BTFSS   STATUS, C
    GOTO    UNID_LOOP
    MOVF    temp16L, W
    ADDLW   0xF6      ; -10
    MOVWF   temp16L
    INCF    decenas, F
    GOTO    DECI_LOOP

RESTA_DIEZ:
    MOVF    temp16L, W
    ADDLW   0xF6      ; -10
    MOVWF   temp16L
    BTFSC   STATUS, C
    GOTO    NO_BORROW_D
    DECF    temp16H, F
NO_BORROW_D:
    INCF    decenas, F
    GOTO    DECI_LOOP

UNID_LOOP:
    MOVF    temp16L, W
    MOVWF   unidades
    RETURN