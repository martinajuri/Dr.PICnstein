LIST    P=16F887
#include <P16F887.inc>
    __CONFIG    _CONFIG1, _WDT_OFF

ORG 0x00
GOTO INICIO

ORG 0x04
GOTO ISR

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
    MOVWF   TRISA           ;  RA0-RA2 entrada
    CLRF    TRISC           ; PORTC como salida para LEDs
    CLRF    TRISD           ; PORTD como salida (segmentos)
    CLRF    TRISE           ; PORTD como salida RE0, RE1, RE2 como salida (multiplex)

    ; Configuración ADC ADCON1: (banco 1) (01)
    MOVLW   b'00010000'     ; vref+ = AN3, vref- = Vss (porque es el puerto AN2 donde esta el sensor)
    MOVWF   ADCON1

    ; Habilitar interrupciones ADC PIE1: (banco 1) (01)
    BSF     PIE1, ADIE      ; Habilita interrupción ADC
    BSF     INTCON, PEIE    ; Habilita interrupciones periféricas
    BSF     INTCON, GIE     ; Habilita interrupciones globales


    ; ADCON0: canal 2 (AN2), ADC ON (banco 0) (00)
    BCF     STATUS, RP0
    MOVLW   b'10001001'     ; ADCS=10(Fosc/32) CHS=0010 (AN2), ADON=1, GO=0
    MOVWF   ADCON0

    ; Configuración de PORTA y PORTD (banco 0) (00)
    CLRF    PORTA
    CLRF    PORTD
    CLRF    PORTE
    MOVLW   b'00001111' ; Inicializar PORTC con LEDs apagados
    MOVWF   PORTC

    BCF PORTC, 0        ; Prender LED RC0 (inicio del ciclo)
    ; Pequeño retardo para ADC (requerido por Proteus)
    NOP
    NOP
    NOP
    NOP
    ; Iniciar primera conversión ADC
    BSF     ADCON0, GO
    BCF     PORTC, 1        ; Prender LED RC1 (inicio ADC)

    CLRF    digito_actual

MAIN_LOOP:
    BCF    PORTC, 2        ; prender LED RC2 (inicio del ciclo)
    ; --- Multiplexar displays continuamente ---
    MOVF    digito_actual, W
    BTFSC   STATUS, Z
    GOTO    DISPLAY_CENTENAS
    MOVF    digito_actual, W
    XORLW   0x01
    BTFSC   STATUS, Z
    GOTO    DISPLAY_DECENAS
    GOTO    DISPLAY_UNIDADES
    BSF    PORTC, 2        ; apagar LED RC2 (fin del ciclo)


DISPLAY_CENTENAS:
    MOVF    centenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA5 (centenas)
    MOVLW   b'00000001'
    MOVWF   PORTE
    GOTO    RETARDO_Y_SIG

DISPLAY_DECENAS:
    MOVF    decenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA6 (decenas)
    MOVLW   b'00000010'
    MOVWF   PORTE
    GOTO    RETARDO_Y_SIG

DISPLAY_UNIDADES:
    MOVF    unidades, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA7 (unidades)
    MOVLW   b'00000100'
    MOVWF   PORTE

RETARDO_Y_SIG:
    CALL    RETARDO

    INCF    digito_actual, F
    MOVF    digito_actual, W
    SUBLW   d'3'
    BTFSS   STATUS, Z
    GOTO    MAIN_LOOP
    CLRF    digito_actual
    GOTO    MAIN_LOOP

; --- Rutina de retardo visible para multiplexado ---
RETARDO:
    MOVLW   D'250'
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

; --- Rutina de interrupción ---
ISR:
    BTFSS   PIR1, ADIF      ; ¿Interrupción ADC?
    RETFIE
    BCF     PIR1, ADIF      ; Limpia flag ADC
    BSF     PORTC, 1        ; Apagar LED RC1 (fin del ciclo)
    ; Actualiza centenas, decenas y unidades
    CALL    SEPARAR_3DIGITOS

    ; Retardo antes de iniciar nueva conversión ADC
    MOVLW   D'100'
    MOVWF   temp16H

WAIT_ADC:
    NOP
    DECFSZ  temp16H, F
    GOTO    WAIT_ADC

    ; Inicia una nueva conversión ADC
    BSF     ADCON0, GO
    BCF     PORTC, 1        ; Prender LED RC1 (inicio ADC)

    RETFIE
    
    END

    ;CALL en la interrupción