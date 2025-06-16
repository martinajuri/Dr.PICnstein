LIST    P=16F887
#include <P16F887.inc>
#include <macros.inc>
    __CONFIG    _CONFIG1, _WDT_OFF

ORG 0x00
    GOTO INICIO
ORG 0x04
    GOTO ISR
    
; --- Variables ---
CBLOCK 0x20
    tabla7seg       
    temp16H
    temp16L
    centenas
    decenas
    unidades
    factor
    TCH
    TCL
ENDC

; --- KEYPAD ---
;RB0-RB3: Columnas (entrada)
;RB0 = Columna 4
;RB1 = Columna 3    
;RB2 = Columna 2
;RB3 = Columna 1
;RB4-RB7: Filas (salida)
;RB4 = Fila 4
;RB5 = Fila 3
;RB6 = Fila 2
;RB7 = Fila 1
; --- Variables para el keypad ---
CBLOCK 0x30
    ROW             ; Fila seleccionada
    ROWMASK         ; Mascara de filas
    INDICE          ; Indice de la tecla presionada
    COL             ; Columna seleccionada
    COLMASK         ; Mascara de columnas
    TECLA           ; Tecla presionada
ENDC

INCLUDE "3digitos.asm"
INCLUDE "rutinas.asm"
    
; --- Programa principal ---
INICIO:
    ; Configuración de puertos
    ; ANSEL RA5 digital (banco 3) (11)
    BANK3
    MOVLW   b'00011111'     ; RA2 como analógico (AN2) y el resto digitales
    MOVWF   ANSEL
    CLRF    ANSELH          ; Setear puerto B como digital          

    ; Configuración de puertos
    ; TRISA y TRISD (banco 1) (01)
    BANK1
    MOVLW   b'00011111'
    MOVWF   TRISA           ;  RA0-RA2 entrada
    CLRF    TRISC           ; PORTC como salida para LEDs
    CLRF    TRISD           ; PORTD como salida (segmentos)
    CLRF    TRISE           ; PORTD como salida RE0, RE1, RE2 como salida (multiplex)
    MOVLW   0x0F            ; RB7-RB4 Salidas (fil), RB3-RB0 Entradas (col)
    MOVWF	TRISB

    ; Configuración de OPTION_REG
    MOVLW   B'10000111'     ; Deshabilitar pull-ups, prescaler 1:16
    MOVWF   OPTION_REG
    
    ; Configuracion de OSCCON
    MOVLW   B'01100001'
    MOVWF    OSCCON

    ; Configuración ADC ADCON1: (banco 1) (01)
    MOVLW   b'10000000'     ; vref+ = AN3, vref- = Vss (porque es el puerto AN2 donde esta el sensor)
    MOVWF   ADCON1

    ; Configuracion de IOCB
    MOVLW   B'00000001' ; Habilitar interrupciones por cambio en RB0
    MOVWF   IOCB

    ; ADCON0: canal 2 (AN2), ADC ON (banco 0) (00)
    BANK0
    MOVLW   b'01000101'     ; ADCS=10(Fosc/32) CHS=0010 (AN2), ADON=1, GO=0
    MOVWF   ADCON0

    ; Configuración de interrupciones
    MOVLW   b'10001000' ; Habilitar interrupciones globales y por cambio Puerto B
    MOVWF   INTCON

    ; Inicialización de puertos (banco 0) (00)
    CLRF    PORTA
    CLRF    PORTD
    CLRF    PORTE
    MOVLW   b'00001111' ; Inicializar PORTC con LEDs apagados
    MOVWF   PORTC
    MOVLW   0xF0            ; Inicializar PORTB con filas en alto
    MOVWF   PORTB

    ; Pequeño retardo para ADC (requerido por Proteus)
    CALL    RETARDO

    ; Inicializo la temperatura de corte en 80 grados
    MOVLW   B'00000011'
    MOVWF   TCH
    MOVLW   B'00100000'
    MOVWF   TCL

    ; Iniciar conversión ADC
    BSF     ADCON0, GO



MAIN_LOOP:
    CALL    MOSTRAR_DISPLAY     ; Mostrar los digitos en el display
    BTFSS   ADCON0, GO          ; Verificar si la conversión ADC está en curso
    CALL    ADC                 ; Si no está en curso, llamar a la rutina de ADC
    BTFSC   PORTC, 2            ; Verifico si esta calentando
    CALL    CONTROL             ; Controlo no superar la temperatura de corte

    GOTO    MAIN_LOOP


CONTROL:
; Testeo la parte Alta
    BANK0
    MOVF    TCH, W
    SUBWF   ADRESH, 0
    BTFSC   STATUS, Z           ; Si dio 0, chequeo la parte baja
    GOTO    CONTROLB
    BTFSS   STATUS, C           ; Si me pase de temperatura, apago la pava
    BCF     PORTC, 2
    RETURN

; Testeo la parte Baja
CONTROLB:                       
    MOVF    TCL, W
    SUBWF   ADRESL, 0
    BTFSC   STATUS, Z           ; Si dio 0, apago la pava
    BCF     PORTC, 2
    BTFSS   STATUS, C           ; Si me pase de temperatura, apago la pava
    BCF     PORTC, 2
    RETURN

LOOP_KEYPAD:                        ; hay alguna tecla presionada?
    CALL    MOSTRAR_DISPLAY         ; Mostrar los digitos en el display
    CALL    RETARDO_200ms

	MOVLW   0xF0	                ; Pongo 1 todas las filas
	MOVWF   PORTB	    
	MOVF    PORTB, W	            ; Testeo columnas
    ANDLW   0x0F                    ; Enmascarar columnas
    BTFSC   STATUS, Z
	GOTO    LOOP_KEYPAD	            ; No hay teclas presionadas -> vuelvo al loop
	; Si -> Antirebote
	CALL    RETARDO
	MOVF    PORTB, W	     
    ANDLW   0x0F                    ; Enmascarar columnas
    BTFSC   STATUS, Z
	GOTO    LOOP_KEYPAD	            ; No hay teclas presionadas -> vuelvo al loop
	; Si -> Escanear las teclas
	CALL    ESCANEAR_TECLAS
    RETURN

ESCANEAR_TECLAS:
	CLRF    ROW
	MOVLW   B'10000000'             ; Pongo fila 1 en alto
	MOVWF   ROWMASK

ESCANEAR_COL:		                ; Detectar columna
	CLRF    INDICE
	MOVF    ROWMASK, W
	MOVWF   PORTB
    BTFSC   PORTB, 3	            ; Columna 1 (RB3) en alto?
    GOTO    OFFSET_ROW	            ; si -> offset = 0
	CALL    SUMO_4	                ; no -> Indice += 4, y sigo
    
	BTFSC   PORTB, 2	            ; Columna 2 (RB2) en alto?
    GOTO    OFFSET_ROW	            ; si -> offset = 4
	CALL    SUMO_4	                ; no -> Indice += 4, y sigo

    BTFSC   PORTB, 1	            ; Columna 3 (RB1) en alto?
    GOTO    OFFSET_ROW	            ; si -> offset = 8	    
	CALL    SUMO_4	                ; no -> Indice += 4, y sigo

	BTFSC   PORTB, 0	            ; Columna 4 (RB0) en alto?
    GOTO    OFFSET_ROW              ; si -> offset = 12
	RRF     ROWMASK	                ; no -> siguiente fila
    
	INCF    ROW, 1	        
	MOVLW   0x04
	SUBWF   ROW
	BTFSS   STATUS, Z	            ; Se revisaron todas las filas?
    GOTO    ESCANEAR_COL            ; no -> seguimos escaneando columnas
	MOVLW   0xFF	                ; si -> volvemos
	MOVF    INDICE, 1	            ; con el indice en 0xFF
	RETURN

OFFSET_ROW:
	MOVF    ROW, W
	ADDWF   INDICE, 1
    CALL    TECLAS	                ; Obtener tecla presionada
    MOVWF   TECLA	                ; Guardar tecla presionada
	RETURN		    

SUMO_4:
	MOVLW   0x04	                ; Sumo 4
    ADDWF   INDICE	                ; al indice
    RETURN

; --- Interrupciones ---
ISR:
    BTFSC   INTCON, RBIF ; Verificar si es interrupción por cambio en PORTB
    GOTO    ISR_PORTB

    RETFIE              ; Si no es interrupción por cambio, retornar de la interrupción


ISR_PORTB:
    ; Antirebote
	MOVLW   0xF0	                ; Pongo 1 todas las filas
	MOVWF   PORTB	    
    CALL    RETARDO   
	MOVF    PORTB, 0	            ; Testeo la columna
    ANDLW   0x0F                    ; Enmascarar columnas
    BTFSC   STATUS, Z
	RETFIE	                        ; No hay teclas presionadas -> salgo de la interrupcion

    
    ; Selecciono la primer Fila:
    MOVLW   B'10000000'           
	MOVWF   ROWMASK
	MOVF    ROWMASK, W
	MOVWF   PORTB
    BTFSC   PORTB, 0	            ; fila 1 en alto?
    GOTO    ISR_OPTIONS	            ; Entro a la rutina de OPTIONS
    
    ; Selecciono la segunda Fila:
    MOVLW   B'01000000'           
	MOVWF   ROWMASK
    MOVF    ROWMASK, W
    MOVWF   PORTB
	BTFSC   PORTB, 0	            ; fila 2 en alto?
    GOTO    ISR_ONOFF	            ; Entro a la rutina de INICIAR/PARAR

    ; Si no es las filas utilizadas salgo de la interrupcion
    RETFIE


; Rutina de OPTIONS
ISR_OPTIONS:
    BSF     PORTC, 5                        ; Prendo un LED que me indica que estoy en OPTIONS
    BCF     PORTC, 2                        ; Apago la pava

    ; Guardo la temperatura de corte en variable temporales para separarla en digitos
    BANK0
    MOVF    TCH, W
    MOVWF   temp16H
    BANK1
    MOVF    TCL, W
    BANK0
    MOVWF   temp16L
    CALL    SEPARAR_3DIGITOS                ; Separo los digitos de la temperatura de corte actual para mostrala en los display

; Display centenas
T1:
    CALL    LOOP_KEYPAD             ; Escaneo el teclado
    BTFSC   TECLA, 4
    GOTO    SET_TEMP                ; Si se apreto options seteo la temperatura
    BTFSC   TECLA, 5
    GOTO    T1                      ; Si se apreto cualquier tecla sin utilidad escaneo denuevo
    MOVF    TECLA,W
    MOVWF   centenas                ; Guardo el valor de la tecla escaneada en centenas
    
; Display decenas
T2:
    CALL    LOOP_KEYPAD             ; Repito para decenas
    BTFSC   TECLA, 4
    GOTO    SET_TEMP
    BTFSC   TECLA, 5
    GOTO    T2
    MOVF    TECLA,W
    MOVWF   decenas
    
; Display unidades         
T3:
    CALL    LOOP_KEYPAD             ; Repito para unidades
    BTFSC   TECLA, 4
    GOTO    SET_TEMP
    BTFSC   TECLA, 5
    GOTO    T3
    MOVF    TECLA,W
    MOVWF   unidades
    GOTO    T1                      ; Retorno al display 1
    
SET_TEMP:                           ; Guardo el valor de la temperatura de corte y salgo de la Interrupcion
    CALL    COMBINAR_3DIGITOS
    BCF     PORTC, 5                ; Apago el LED que me indica que estoy en OPTIONS
    RETFIE

; Rutina de INICIAR/PARAR
ISR_ONOFF:
    BTFSS   PORTC, 2                ; Me fijo si esta prendida, si es asi skipeo
    GOTO    TURNON_I
    GOTO    TURNOFF_I

TURNON_I:
    BSF     PORTC, 2
    RETFIE
TURNOFF_I:
    BCF     PORTC,2
    RETFIE


END