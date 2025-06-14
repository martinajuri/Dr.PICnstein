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
    mux_count       ; contador para multiplexado
    centenas
    decenas
    unidades
ENDC

INCLUDE "separar_3digitos.asm"
    
; --- Tabla de conversión a 7 segmentos (anodo común) ---
; 0-9: 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
TABLA_7SEG
    ADDWF   PCL, F
    RETLW   0xC0    ; 0
    RETLW   0xF9    ; 1
    RETLW   0xA4    ; 2
    RETLW   0xB0    ; 3
    RETLW   0x99    ; 4
    RETLW   0x92    ; 5
    RETLW   0x82    ; 6
    RETLW   0xF8    ; 7
    RETLW   0x80    ; 8
    RETLW   0x90    ; 9

; --- Programa principal ---
INICIO:
    ; Configuración de puertos
    ; ANSEL RA5 digital (banco 3) (11)
    BSF    STATUS, RP0
    BSF    STATUS, RP1
    MOVLW   b'00000100'     ; RA2 como analógico (AN2) y el resto digitales
    MOVWF   ANSEL           

    ; Configuración de puertos
    ; TRISA y TRISD (banco 1) (01)
    BCF     STATUS, RP1
    MOVLW   b'00011111'
    MOVWF   TRISA           ; RA5, RA6, RA7 como salida (multiplex), RA0-RA2 entrada
    CLRF    TRISC           ; PORTC como salida para LEDs
    CLRF    TRISD           ; PORTD como salida (segmentos)

    ; Configuración ADC ADCON1: (banco 1) (01)
    MOVLW   b'00010000'     ; vref+ = AN3, vref- = Vss (porque es el puerto AN2 donde esta el sensor)
    MOVWF   ADCON1

    ; ADCON0: canal 2 (AN2), ADC ON (banco 0) (00)
    BCF     STATUS, RP0
    MOVLW   b'10001001'     ; ADCS=10(Fosc/32) CHS=0010 (AN2), ADON=1
    MOVWF   ADCON0

    ; Configuración de PORTA y PORTD (banco 0) (00)
    CLRF    PORTA
    CLRF    PORTD
    MOVLW   b'00001111'     ;Apagar LEDs en PORTC
    MOVWF   PORTC 

MAIN_LOOP:
    BCF     PORTC, 0   ; Prendeer LED en PORTC para indicar inicio de
    MOVLW   D'100'          ; Cantidad de ciclos de multiplexado
    MOVWF   mux_count

MUX_LOOP:
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
    MOVLW   b'00100000'
    MOVWF   PORTA
    GOTO    RETARDO_Y_SIG

DISPLAY_DECENAS:
    MOVF    decenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    MOVLW   b'01000000'
    MOVWF   PORTA
    GOTO    RETARDO_Y_SIG

DISPLAY_UNIDADES:
    MOVF    unidades, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    MOVLW   b'10000000'
    MOVWF   PORTA

RETARDO_Y_SIG:
    CALL    RETARDO

    INCF    digito_actual, F
    MOVF    digito_actual, W
    SUBLW   d'3'
    BTFSS   STATUS, Z
    GOTO    SIGUE_MUX
    CLRF    digito_actual

SIGUE_MUX:
    DECFSZ  mux_count, F
    GOTO    MUX_LOOP

    ; --- Iniciar conversión ADC ---
    BCF     PORTC, 1        ; Prender LED RC1 (inicio ADC)
    BSF     ADCON0, GO

WAIT_ADC:
    BTFSC   ADCON0, GO
    GOTO    WAIT_ADC

    ; --- Actualiza centenas, decenas y unidades ---
    ;CALL    SEPARAR_3DIGITOS
    MOVLW    D'1'
    MOVWF   centenas
    MOVLW    D'2'
    MOVWF   decenas
    MOVLW    D'3'
    MOVWF   unidades
    ; --- Apagar LED RC1 (fin ADC) ---
    BSF     PORTC, 1
    GOTO    MAIN_LOOP

; --- Rutina de retardo visible para multiplexado ---
RETARDO:
    MOVLW   D'20'
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