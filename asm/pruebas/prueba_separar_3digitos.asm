LIST    P=16F887
#include <P16F887.inc>
    __CONFIG    _CONFIG1, _WDT_OFF

ORG 0x00
GOTO INICIO

; --- Declaración de variables ---
CBLOCK 0x20
    temp16H
    temp16L
    centenas
    decenas
    unidades
ENDC


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

INICIO:
    BANK0
    MOVLW   0x03
    MOVWF   centenas

    MOVLW   0x02
    MOVWF   decenas

    MOVLW   0x01
    MOVWF   unidades

    GOTO    COMBINAR_3DIGITOS

ESPERA:
    GOTO    ESPERA

    END