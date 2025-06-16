; -----------------------------------------------------------
; Rutina: SEPARAR_3DIGITOS
; Entrada: temp16H, temp16L (valor de 10 bits)
; Salida: centenas, decenas, unidades (en RAM)
; Usa: centenas, decenas, unidades
; -----------------------------------------------------------

SEPARAR_3DIGITOS:
    BANK0
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

;----------------------------------------------------------
; RUTINA: COMBINAR_3DIGITOS
; Entrada: centenas, decenas, unidades (RAM)
; Salida:  TCH (parte alta), TCL (parte baja)
; Usa:     temp16H, temp16L, factor (temporales)
;----------------------------------------------------------

COMBINAR_3DIGITOS:
    BANK0
    CLRF    temp16H             ; temp16H:temp16L = 0
    CLRF    temp16L

    ; Sumar centenas * 100
    MOVF    centenas, W
    MOVWF   factor              ; factor = centenas
    MOVLW   D'100'
    CALL    MULTIPLICAR         ; resultado en temp16H:temp16L
    ; temp16H:temp16L = centenas * 100

    ; Guardar resultado parcial en TCH:TCL
    MOVF    temp16H, W
    MOVWF   TCH
    MOVF    temp16L, W
    MOVWF   TCL

    ; Sumar decenas * 10
    MOVF    decenas, W
    MOVWF   tabla7seg
    MOVLW   D'10'
    CALL    MULTIPLICAR     ; resultado en temp16H:temp16L

    ; Sumar a TCH:TCL
    MOVF    TCL, W
    ADDWF   temp16L, W
    MOVWF   TCL
    MOVF    TCH, W
    ADDWF  temp16H, W
    MOVWF   TCH

    ; Sumar unidades
    MOVF    TCL, W
    ADDWF   unidades, W
    MOVWF   TCL

    ; Si hay carry, sumarlo a TCH
    BTFSS   STATUS, C
    INCF    TCH, F

    RETURN

;----------------------------------------------------------
; RUTINA: MULTIPLICAR
; Entrada: W = factorx10, factor
; Salida:  temp16H:temp16L = resultado (16 bits)
;----------------------------------------------------------
MULTIPLICAR:
    CLRF    temp16H
    CLRF    temp16L
    MOVWF   temp16L         ; temp16L = factorx10
    CLRF    temp16H
    MOVF    factor, W       ; multiplicador
    MOVWF   factor

MULT_LOOP:
    MOVF    factor, F
    BTFSC   STATUS, Z
    RETURN

    MOVF    temp16L, W
    ADDWF   temp16L, F
    BTFSS   STATUS, C
    INCF    temp16H, F

    DECFSZ  factor, F
    GOTO    MULT_LOOP

    RETURN