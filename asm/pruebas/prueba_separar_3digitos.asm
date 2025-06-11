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

; --- Rutina: Separar ADC de 10 bits en centenas, decenas y unidades ---
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
    ; temp16H == 0, comparar temp16L con 100
    MOVLW   D'100'
    SUBWF   temp16L, W
    BTFSS   STATUS, C
    GOTO    DECI_LOOP
    ; Si temp16L >= 100, restar 100 (0x9C)
    MOVF    temp16L, W
    ADDLW   0x9C      ; -100
    MOVWF   temp16L
    INCF    centenas, F
    ; --- Chequeo extra para evitar pasarse ---
    MOVLW   D'100'
    SUBWF   temp16L, W
    BTFSS   STATUS, C
    GOTO    DECI_LOOP
    GOTO    CENT_LOOP

RESTA_CIEN:
    ; temp16H > 0, siempre restar 100 (0x9C)
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

INICIO:
    BCF STATUS, RP0
    BCF STATUS, RP1

    ; Cargar parte alta (ADRESH, banco 0)
    MOVLW   0x03    ; <-- Cambia aquí para el valor alto
    MOVWF   ADRESH

    ; Cambiar a banco 1 para ADRESL
    BSF     STATUS, RP0
    BCF     STATUS, RP1
    MOVLW   0xFF    ; <-- Cambia aquí para el valor bajo
    MOVWF   ADRESL

    ; Volver a banco 0 antes de llamar a la rutina
    BCF     STATUS, RP0
    BCF     STATUS, RP1

    CALL    SEPARAR_3DIGITOS

    ; Loop infinito para observar resultados
ESPERA:
    GOTO    ESPERA

    END