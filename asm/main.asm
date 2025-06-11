LIST    P=16F887
#include <P16F887.inc>
    __CONFIG    _CONFIG1, _WDT_OFF

ORG 0x00
GOTO INICIO

; --- Variables ---
CBLOCK 0x20
    digito_actual   ; 0, 1, 2 para multiplexado
    tabla7seg       ; valor a mostrar en el display
    temp16H
    temp16L
    centenas
    decenas
    unidades
ENDC

INCLUDE "separar_3digitos.asm"
    
; --- Tabla de conversión a 7 segmentos (anodo común) ---
; 0-9: 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
TABLA_7SEG
    ADDWF   PCL, F
    RETLW   0x3F    ; 0
    RETLW   0x06    ; 1
    RETLW   0x5B    ; 2
    RETLW   0x4F    ; 3
    RETLW   0x66    ; 4
    RETLW   0x6D    ; 5
    RETLW   0x7D    ; 6
    RETLW   0x07    ; 7
    RETLW   0x7F    ; 8
    RETLW   0x6F    ; 9

; --- Programa principal ---
INICIO:
    ; Configuración de puertos
    ; ANSEL RA5 digital (banco 3) (11)
    BSF    STATUS, RP0
    BSF    STATUS, RP1
    MOVLW   b'00001000'     ; RA3 como analógico (AN3) y el resto digitales
    MOVWF   ANSEL           ; AN0-AN2 digitales

    ; Configuración de puertos
    ; TRISA y TRISD (banco 1) (01)
    BCF     STATUS, RP1
    CLRF    TRISD           ; PORTD como salida (segmentos)
    MOVLW   b'00011111'
    MOVWF   TRISA           ; RA5, RA6, RA7 como salida (multiplex), RA0-RA2 entrada

    ; Configuración de PORTA y PORTD (banco 0) (00)
    BCF     STATUS, RP0
    CLRF    PORTA
    CLRF    PORTD

    ; Configuración ADC (banco 1) (01)
    BSF     STATUS, RP0
    MOVLW   b'00001111'     ; AN3 (AN3/RA3) habilitado
    MOVWF   ADCON1

    ; ADCON0: canal 3 (AN3), ADC ON (banco 0) (00)
    BCF     STATUS, RP1
    MOVLW   b'00001101'     ; CHS=011 (AN3), ADON=1
    MOVWF   ADCON0

    ; ADCON1: Vref+ = AN3, Vref- = Vss
    ; (ya configurado arriba)

MAIN_LOOP:
    ; --- Iniciar conversión ADC ---
    BSF     ADCON0, GO      ; Iniciar conversión

    ; Pequeño retardo para ADC (requerido por Proteus)
    NOP
    NOP
    NOP
    NOP

ESPERA_ADC:
    BTFSC   ADCON0, GO      ; Esperar fin de conversión
    GOTO    ESPERA_ADC

    ; --- Llamar a rutina de separación de dígitos ---
    CALL    SEPARAR_3DIGITOS

    ; --- Multiplexar displays ---
    CLRF    digito_actual

DISPLAY_LOOP:
    ; Mostrar centenas
    MOVF    digito_actual, W
    BTFSC   STATUS, Z
    GOTO    DISPLAY_CENTENAS
    MOVF    digito_actual, W
    XORLW   0x01
    BTFSC   STATUS, Z
    GOTO    DISPLAY_DECENAS
    GOTO    DISPLAY_UNIDADES

DISPLAY_CENTENAS:
    MOVF    centenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA5 (centenas)
    MOVLW   b'00100000'
    MOVWF   PORTA
    GOTO    SIGUIENTE_DIGITO

DISPLAY_DECENAS:
    MOVF    decenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA6 (decenas)
    MOVLW   b'01000000'
    MOVWF   PORTA
    GOTO    SIGUIENTE_DIGITO

DISPLAY_UNIDADES:
    MOVF    unidades, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA7 (unidades)
    MOVLW   b'10000000'
    MOVWF   PORTA

SIGUIENTE_DIGITO:
    INCF    digito_actual, F
    MOVF    digito_actual, W
    SUBLW   3
    BTFSS   STATUS, Z
    GOTO    DISPLAY_LOOP

    ; --- Pequeña espera para multiplexado ---
    CALL    RETARDO

    GOTO    MAIN_LOOP

; --- Rutina de retardo visible para multiplexado ---
RETARDO:
    MOVLW   D'200'
    MOVWF   temp16H
RET1:
    MOVLW   D'250'
    MOVWF   temp16L
RET2:
    NOP
    NOP
    NOP
    DECFSZ  temp16L, F
    GOTO    RET2
    DECFSZ  temp16H, F
    GOTO    RET1
    RETURN

    END