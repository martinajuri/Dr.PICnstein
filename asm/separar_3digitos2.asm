; -----------------------------------------------------------
; Rutina: SEPARAR_3DIGITOS
; Entrada: ADRESH:ADRESL (valor de 10 bits)
; Salida: centenas, decenas, unidades (en RAM)
; Usa: temp16H, temp16L, centenas, decenas, unidades
; -----------------------------------------------------------

SEPARAR_3DIGITOS:
    ; Leer ADRESH y ADRESL (banco 0 y 1)
    MOVF    ADRESH, W
    MOVWF   temp16H
    BSF     STATUS, RP0
    MOVF    ADRESL, W
    BCF     STATUS, RP0
    MOVWF   temp16L

    CLRF    centenas
    CLRF    decenas
    CLRF    unidades

    ; Combinar temp16H:temp16L en temp16H (valor de 0 a 1023)
    ; temp16H = ADRESH (8 bits), temp16L = ADRESL (2 bits útiles)
    ; valor = (ADRESH << 2) | (ADRESL >> 6)
    SWAPF   temp16L, W
    ANDLW   b'00000011'
    IORWF   temp16H, W
    MOVWF   temp16H

    ; Ahora temp16H tiene el valor de 0 a 255 (si solo usás 8 bits)
    ; Si querés usar los 10 bits, necesitás más código.

    ; Separar centenas
    MOVLW   D'100'
SEP_CENT:
    SUBWF   temp16H, W
    BTFSS   STATUS, C
    GOTO    SEP_DECS
    INCF    centenas, F
    MOVF    temp16H, W
    ADDLW   0x9C
    MOVWF   temp16H
    GOTO    SEP_CENT

SEP_DECS:
    MOVLW   D'10'
SEP_DECS_LOOP:
    SUBWF   temp16H, W
    BTFSS   STATUS, C
    GOTO    SEP_UNITS
    INCF    decenas, F
    MOVF    temp16H, W
    ADDLW   0xF6
    MOVWF   temp16H
    GOTO    SEP_DECS_LOOP

SEP_UNITS:
    MOVF    temp16H, W
    MOVWF   unidades
    RETURN