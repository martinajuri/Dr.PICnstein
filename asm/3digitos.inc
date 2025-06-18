; -----------------------------------------------------------
; Rutina: SEPARAR_3DIGITOS
; Entrada: temp16H, temp16L (valor de 10 bits)
; Salida: decenas, unidades, decimas (en RAM)
; Usa: decenas, unidades, decimas
; -----------------------------------------------------------

SEPARAR_3DIGITOS:
    BANK0
    CLRF    decenas
    CLRF    unidades
    CLRF    decimas

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
    INCF    decenas, F
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
    INCF    decenas, F
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
    INCF    unidades, F
    GOTO    DECI_LOOP

RESTA_DIEZ:
    MOVF    temp16L, W
    ADDLW   0xF6      ; -10
    MOVWF   temp16L
    BTFSC   STATUS, C
    GOTO    NO_BORROW_D
    DECF    temp16H, F

NO_BORROW_D:
    INCF    unidades, F
    GOTO    DECI_LOOP

UNID_LOOP:
    MOVF    temp16L, W
    MOVWF   decimas
    RETURN

;----------------------------------------------------------
; RUTINA: COMBINAR_3DIGITOS
; Entrada: decenas, unidades, decimas (RAM)
; Salida:  TCH (parte alta), TCL (parte baja)
; Usa:     temp16H, temp16L, factor (temporales)
;----------------------------------------------------------

COMBINAR_3DIGITOS:
    BANK0
    CLRF    temp16H             ; temp16H:temp16L = 0
    CLRF    temp16L

    ; Sumar decenas * 100
    MOVF    decenas, W
    MOVWF   factor              ; factor = decenas
    MOVLW   D'100'
    MOVWF   factore10
    CALL    MULTIPLICAR         ; resultado en temp16H:temp16L
    ; temp16H:temp16L = decenas * 100

    ; Guardar resultado parcial en TCH:TCL
    MOVF    temp16H, W
    MOVWF   TCH
    MOVF    temp16L, W
    MOVWF   TCL

    ; Sumar unidades * 10
    MOVF    unidades, W
    MOVWF   factor              ; factor = decenas
    MOVLW   D'10'
    MOVWF   factore10
    CALL    MULTIPLICAR     ; resultado en temp16H:temp16L

    ; Sumar a TCH:TCL
    MOVF    TCL, W
    ADDWF   temp16L, W
    MOVWF   TCL
    
    ; Si hay carry, sumarlo a TCH
    BTFSC   STATUS, C
    INCF    TCH, F
    
    MOVF    TCH, W
    ADDWF  temp16H, W
    MOVWF   TCH
    
    ; Sumar decimas
    MOVF    TCL, W
    ADDWF   decimas, W
    MOVWF   TCL

    ; Si hay carry, sumarlo a TCH
    BTFSC   STATUS, C
    INCF    TCH, F

    RETURN

;----------------------------------------------------------
; RUTINA: MULTIPLICAR
; Entrada: factore10, factor
; Salida:  temp16H:temp16L = resultado (16 bits)
;----------------------------------------------------------
MULTIPLICAR:
    CLRF    temp16H
    CLRF    temp16L    

MULT_LOOP:
    MOVF    factor, W
    BTFSC   STATUS, Z
    RETURN
    DECF  factor, 1

    MOVF    temp16L, W
    ADDWF   factore10, 0
    BTFSC   STATUS, C 
    INCF    temp16H, F
    MOVWF   temp16L

    GOTO    MULT_LOOP

    RETURN