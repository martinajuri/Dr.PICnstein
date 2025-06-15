LIST    P=16F887
#include <P16F887.inc>
#include <macros.inc>
#include <rutinas.inc>
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
    


; --- Programa principal ---
INICIO:
    ; ConfiguraciÃ³n de puertos
    ; ANSEL RA5 digital (banco 3) (11)
    BANK3
    MOVLW   b'00011111'     ; RA2 como analÃ³gico (AN2) y el resto digitales
    MOVWF   ANSEL
    CLRF    ANSELH          ; Setear puerto B como digital          

    ; ConfiguraciÃ³n de puertos
    ; TRISA y TRISD (banco 1) (01)
    BANK1
    MOVLW   b'00011111'
    MOVWF   TRISA           ;  RA0-RA2 entrada
    CLRF    TRISC           ; PORTC como salida para LEDs
    CLRF    TRISD           ; PORTD como salida (segmentos)
    CLRF    TRISE           ; PORTD como salida RE0, RE1, RE2 como salida (multiplex)
    MOVLW   0x0F            ; RB7-RB4 Salidas (fil), RB3-RB0 Entradas (col)
    MOVWF	TRISB

    ; ConfiguraciÃ³n de OPTION_REG
    MOVLW   B'00000111'     ; Habilitar pull-ups, prescaler 1:16
    MOVWF   OPTION_REG
    
    ; Configuracion de OSCCON
    MOVLW   B'01100001'
    MOVWF    OSCCON

    ; ConfiguraciÃ³n ADC ADCON1: (banco 1) (01)
    MOVLW   b'10000000'     ; vref+ = AN3, vref- = Vss (porque es el puerto AN2 donde esta el sensor)
    MOVWF   ADCON1

    ; Configuracion de IOCB
    MOVLW   B'00000001' ; Habilitar interrupciones por cambio en RB0
    MOVWF   IOCB

    ; ADCON0: canal 2 (AN2), ADC ON (banco 0) (00)
    BANK0
    MOVLW   b'01000101'     ; ADCS=10(Fosc/32) CHS=0010 (AN2), ADON=1, GO=0
    MOVWF   ADCON0

    ; ConfiguraciÃ³n de interrupciones
    MOVLW   b'10001000' ; Habilitar interrupciones globales y por cambio Puerto B
    MOVWF   INTCON

    ; ConfiguraciÃ³n de PORTA y PORTD (banco 0) (00)
    CLRF    PORTA
    CLRF    PORTD
    CLRF    PORTE
    MOVLW   b'00001111' ; Inicializar PORTC con LEDs apagados
    MOVWF   PORTC

    BCF PORTC, 3        ; Prender LED RC0 (inicio del ciclo)
    ; PequeÃ±o retardo para ADC (requerido por Proteus)
    CALL RETARDO
    ; Iniciar conversiÃ³n ADC
    BSF     ADCON0, GO
    BCF     PORTC, 4        ; Prender LED RC1 (inicio ADC)

    CLRF    digito_actual

MAIN_LOOP:
    BCF    PORTC, 2             ; prender LED RC2 (inicio del ciclo)   
    CALL    MOSTRAR_DISPLAY     ; Mostrar los digitos en el display
    BTFSS   ADCON0, GO          ; Verificar si la conversiÃ³n ADC estÃ¡ en curso
    CALL    ADC                 ; Si no estÃ¡ en curso, llamar a la rutina de ADC
    BSF    PORTC, 2             ; apagar LED RC2 (fin del ciclo)

    GOTO    MAIN_LOOP




LOOP:   ; hay alguna tecla presionada?
	MOVLW 0x0F	    ; pongo 1 todas las columnas
	MOVWF PORTB	    ; 
	MOVF  PORTB, W	    ; y veo todas las filas
    ANDLW 0xF0          ; enmascarar filas
    BTFSC STATUS, Z
	GOTO  LOOP	    ; no hay teclas presionadas -> vuelvo al loop
	; Si -> Antirebote
	CALL  RETARDO
	MOVF  PORTB, W	    ; 
    ANDLW 0xF0          ; 
    BTFSC STATUS, Z
	GOTO  LOOP	    ; no hay teclas presionadas -> vuelvo al loop
	; Si -> voy a escanear las teclas
	CALL  ESCANEAR_TECLAS
    RETURN

ESCANEAR_TECLAS:
	CLRF  COL	    ; col 1
	MOVLW 0x08	    ; RB3
	MOVWF COLMASK	    ; en alto
ESCANEAR_FILAS:		    ; detectar fila
	CLRF  INDICE
	MOVF  COLMASK, W
	MOVWF PORTB
        BTFSC PORTB, 4	    ; fila 1 en alto?
        GOTO  OFFSET_COL	    ; si -> offset=0
	CALL  SUMO_4	    ; no -> Indice += 4, y sigo
	BTFSC PORTB, 5	    ; fila 2 en alto?
        GOTO  OFFSET_COL	    ; si -> offset=4
	CALL  SUMO_4	    ; no -> Indice += 4, y sigo
        BTFSC PORTB, 6	    ; fila 3 en alto?
        GOTO  OFFSET_COL	    ; si -> offset=8	    
	CALL  SUMO_4	    ; no -> Indice += 4, y sigo
	BTFSC PORTB, 7	    ; fila 4 en alto?
        GOTO  OFFSET_COL     ; si -> offset=12
	RRF   COLMASK	    ; no -> siguiente columna
	INCF  COL, 1	    ; 
	MOVLW 0x04
	SUBWF COL
	BTFSS STATUS, Z	    ; todas las columnas?
	GOTO  ESCANEAR_FILAS; no -> seguimos
	MOVLW 0xFF	    ; si -> volvemos
	MOVF  INDICE, 1	    ;	    con el indice en 0xFF
	RETURN
OFFSET_COL:
	MOVF  COL, W
	ADDWF INDICE, 1
	RETURN		    



ISR:
    BTFSC   INTCON, RBIF ; Verificar si es interrupción por cambio en PORTB
    GOTO    ISR_PORTB

    RETFIE              ; Si no es interrupción por cambio, retornar de la interrupción


ISR_PORTB:
    BTFSS   
    END

    ;CALL en la interrupción