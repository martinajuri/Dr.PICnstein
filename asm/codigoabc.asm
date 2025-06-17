;--------------------------------------
; Configuración inicial del PIC16F887
;--------------------------------------
	    LIST P=16F887
	    #include "p16f887.inc"

	    ; CONFIG1
	    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
	    ; CONFIG2
	    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;--------------------------------------
; Declaración de variables en el banco de registros
;--------------------------------------
CBLOCK 0X20
	DISPLAY1POR10;31 PARA GUARDAR EL RESULTADO DEL DISPLAY1 POR 10
	TEMPX;22 PARA MULTIPLICAR DISPLAY1 POR 10
	TEMPY;23 PARA MULTIPLICAR DISPLAY1 POR 10
	DISPLAY0T;24 VALOR NUMÉRICO DEL DISPLAY0 PARA UTILIZARLO EN EL DUTY CYCLE DEL MOTOR
	DISPLAY1T;25 VALOR NUMÉRICO DEL DISPLAY1 PARA UTILIZARLO EN EL DUTY CYCLE DEL MOTOR
	DISPLAY2T;26 VALOR NUMÉRICO DEL DISPLAY2 PARA UTILIZARLO EN EL DUTY CYCLE DEL MOTOR
	;MOT_ON;27 PARA ENCENDER EL MOTOR	   
	NvueltasH; para almacenars los valores del contador del TMR1H
	NvueltasL; para almacenars los valores del contador del TMR1L
	CONTde200; para utilizar el TMR0 con 2ms durante 0.4s
	CONTde5; para repetir el ciclo de 0.4s y llegar a 2segundos
	FInicio; 
ENDC	    
	
CBLOCK 0x70
	    W_TEMP; 0x70
	    STATUS_TEMP; 0x71
	    CONT; 0x72 Contador De Teclas
	    FILA; 0x73 Filas Del Teclado
	    TECLASCII; 0x74
	    TECLA7SLN; 0x75
	    MASK; 0x76 Mascara usada para limpiar los 3 bits de las columnas sin modificar el resto
	    INDEX; 0x77 Index de las filas
	    OuterCount; 0x78
	    InnerCount; 0x79
	    CONT0A3VAR; 0x7A PARA IR GUARDANDO LOS NÚMEROS INGRESADOS POR TECLADO 
	    CONT0A3D; 0x7B PARA IR HABILITANDO LOS DISPLAY 
	    DISPLAY0; 0x7C GUARDAN EL NÚMERO QUE MUESTRA EL DISPLAY 0 
	    DISPLAY1; 0x7D GUARDAN EL NÚMERO QUE MUESTRA EL DISPLAY 1 
	    DISPLAY2; 0x7E GUARDAN EL NÚMERO QUE MUESTRA EL DISPLAY 2 
	    NUMINF; 0x7F BANDERA PARA VER SI SE ESTÁN MOSTRANDO LOS NÚMEROS INGRESADOS. 1 EN <0> QUIERE DECIR QUE SÍ
	    ;0 EN  <0> QUIERE DECIR QUE NO SE ESTÁN MOSTRANDO LOS NÚMEROS INGRESADOS 
ENDC
	    
;--------------------------------------
; Punto de entrada del programa
;--------------------------------------
	    ORG 0x00
	    GOTO MAIN
	    ORG 0x04
	    GOTO INTER
	    
;--------------------------------------
; Rutina principal del programa
;--------------------------------------	      
MAIN
	    ;---------------------------------------------
	    ; Inicialización del Programa
	    ; ORG 0x05 - Punto de inicio del programa principal
	    ;---------------------------------------------
	    ORG 0x05
	    
	    CLRF W_TEMP
	    CLRF STATUS_TEMP
	    BANKSEL 0X20
	    CLRF CONTde200
	    CLRF CONTde5
	    CLRF NvueltasH
	    CLRF NvueltasL
	    
	    ;---------------------------------------------
	    ; Configuración de Puertos y Registros
	    ;---------------------------------------------	
	    ; Limpia PORTB y PORTD
	    BANKSEL PORTB
	    CLRF PORTB
	    CLRF PORTD
	    CLRF PORTE
	    CLRF PORTC
	    CLRF PORTA
	    
	    ; Deshabilita las funciones analógicas (configura como E/S digital)
	    BANKSEL ANSELH
	    CLRF ANSELH
	    CLRF ANSEL
	    
	    ;---------------------------------------------
	    ; Configuración de Pines de E/S
	    ;---------------------------------------------
	    ; Configura todos los pines de PORTD como salida para la visualización de segmentos
	    BANKSEL TRISD
	    CLRF TRISD  
	    CLRF TRISA
	    CLRF TRISC
	    BSF TRISC,0; ENTRADA PARA EL PULSO DEL IR (T1CKL)
	    
	    ; Configura los pines de PORTE como salida para habilitar los displays
	    CLRF TRISE
	    
	    ; Configura PORTB RB<2:0> como entrada (entradas digitales), otros como salida
	    MOVLW B'00000111'
	    MOVWF TRISB;
	    
	    ;---------------------------------------------
	    ; Inicialización de Variables
	    ;---------------------------------------------
	    ; Inicializa CONT0A3D y CONT0A3VAR
	    MOVLW B'00000001'
	    MOVWF CONT0A3D
	    MOVWF CONT0A3VAR
	    
	    ; Inicializa CONTde200 y CONTde5 
	    BANKSEL 0X20
	    MOVLW .200;//
	    MOVWF CONTde200
	    MOVLW .5;//
	    MOVWF CONTde5
	    
	    ; Limpia la bandera NUMINF
	    CLRF NUMINF
	    
	    ; Inicializa los registros de visualización al estado predeterminado (0 mostrado en el display)
	    MOVLW B'00111111'
	    MOVWF DISPLAY0
	    MOVWF DISPLAY1
	    MOVWF DISPLAY2
	    
	    ; Energiza las filas y espera una interrupción (pulsación de tecla)
	    BANKSEL PORTB
	    MOVLW B'01111000'
	    MOVWF PORTB
	    
	    ; Inicialización de la tx-rx serie (UART)
	    CALL    INIT_INT	
	    CALL    INIT_UART
	    CALL    BAJAR_FLAG
	    MOVLW   0XAA
	    CALL    SEND_TX
	    
	    ; Configuración e inicialización del PWM
		
	    CALL    INIT_PWM
		
	    
	    ;---------------------------------------------
	    ; Configuración de Interrupciones
	    ;---------------------------------------------
	    ; Habilita las interrupciones de PORTB, TMR0 y configura la interrupción por cambio para RB<2:0>
	    BANKSEL INTCON
	    MOVLW B'00101000'
	    MOVWF INTCON
	    BANKSEL IOCB
	    MOVLW B'00000111'
	    MOVWF IOCB
	    
	    ; Configuración para TMR0
		
	    BANKSEL OPTION_REG
	    BSF OPTION_REG,0
	    BSF OPTION_REG,1
	    BSF OPTION_REG,2;111 EN PRESCALER
	    BCF OPTION_REG,3;PRESCALER EN TM0
	    BCF OPTION_REG,5;TIMER0 TOMA FOSC/4 PARA EL CICLO DE INSTRUCCIÓN
	    
	    ;Configuración para TMR1
	    BANKSEL T1CON
	    MOVLW B'00000110'
	    MOVWF T1CON
	    
	    BANKSEL TMR1H
	    CLRF TMR1H
	    CLRF TMR1L
	    
	    ; Habilita interrupciones globales
	    BANKSEL INTCON
	    BSF INTCON,7 
	    
	    ; Cargo el TMR0
	    BANKSEL TMR0
	    MOVLW 0XF8
	    MOVWF TMR0;CARGO EL TMR0 CON 24
	    
	    BANKSEL PORTC
	    BSF PORTC, 2
	    GOTO MAIN_2
	    
;--------------------------------------------------------------------------------------------------------------------------------------------------------	
;--------------------------------------	    
; SUBRUTINAS
;--------------------------------------	    
	    
;--------------------------------------
; Delay subroutine (100ms)
;--------------------------------------
	Delay100ms
	    MOVLW   D'250'      
	    MOVWF   OuterCount  
	OuterLoop
	    MOVLW   D'245'      
	    MOVWF   InnerCount  
	InnerLoop
	    NOP                 
	    NOP                 
	    DECFSZ  InnerCount, f
	    GOTO    InnerLoop   
	    DECFSZ  OuterCount, f 
	    GOTO    OuterLoop   
	    RETURN 
;--------------------------------------
; Bajar Flag RBIF
;--------------------------------------
	BAJAR_FLAG
	    BANKSEL PORTB
	    ; Bajo el flag de interrupción
	    MOVF PORTB, F
	    BANKSEL INTCON
	    BCF INTCON,RBIF
	    RETURN
;--------------------------------------
; Configuración de interrupciones UART
;--------------------------------------
	INIT_INT    
	    BANKSEL PIE1	    ; - ADIE RCIE TXIE SSPIE CCP1IE TMR2IE TMR1IE
	    MOVLW   b'01100000'	    ; Activamos interrupciones por TXIE y RCIE
	    MOVWF   PIE1
	    RETURN
;--------------------------------------
; Configuración de transmisión serie
;--------------------------------------
	INIT_UART   
	    BANKSEL SPBRG	    ; Seteamos baud-rate = 9600bps (Frecuencia del PIC en 4 MHZ)
	    MOVLW   d'25'
	    MOVWF   SPBRG
	    BANKSEL TXSTA	    
	    MOVLW   b'00100100'	    ; Configuro TXSTA como 8 bit transmission, tx habilitado, modo async, high speed baud rate
	    MOVWF   TXSTA
	    BANKSEL RCSTA	    ; Serial port enable, Continuous Receive
	    MOVLW   b'10010000'	    ; Habilito recepción y pines de puerto
	    MOVWF   RCSTA
	    BANKSEL PIR1
	    RETURN
;--------------------------------------
; Envia datos por transmisión serie
;--------------------------------------    
	SEND_TX	
	    BANKSEL TXREG	    ; Cuando se carga TXREG este comienza a enviarlo por TX.
	    MOVWF   TXREG
	    BANKSEL TXSTA
	    BTFSS   TXSTA, TRMT	    ; Si el TRMT es 1, el dato ya se envio, si no espero.
	    GOTO    $-1
	    RETURN
;--------------------------------------
; Configuracion de escaneo de teclado
;--------------------------------------    
	CONFIG_INDEX_MASCARA_FILA
	    MOVLW B'00001000'
	    MOVWF INDEX
	    MOVLW B'10000111'
	    MOVWF MASK
	    MOVLW D'3'
	    MOVWF FILA  
	    RETURN
	    
;--------------------------------------
; Utiliza MASK, INDEX y CONT para el escaneo del teclado
;--------------------------------------  
	MASK_INDEX_CONT
	    MOVF MASK, W
	    BANKSEL PORTB
	    ANDWF PORTB, F
	    MOVF INDEX, W
	    IORWF PORTB, F
	    INCF CONT, F
	    RETURN
	    
;--------------------------------------
; Configuración e inicialización del PWM 
;-------------------------------------- 
    	INIT_PWM   
	    BANKSEL PR2
	    MOVLW D'99'
	    MOVWF PR2;CARGO EL PR2 PARA TENER EL PERÍODO DE PWM
	    
	    BANKSEL CCP1CON
	    MOVLW B'00001100';<7:6>=P1A MODULADO, ENTRADA SIMPLE
	    ;<5:4> LSB DEL DUTY CYCLE DEL PWM
	    ;<3:0> MODO PWM. P1X EN ACTIVO EN ALTO
	    MOVWF CCP1CON
	    CLRF CCPR1L;EL VALOR DEL DUTY CYCLE ES 0(00000000 00). ES DECIR, MOTOR APAGADO
	    BCF PIR1,TMR2IF;LIMPIO LA BANDERA DE LA INTERRUPCIÓN POR TMR2IF (LO DICE EL SETUP DEL PWM)
	    BSF T2CON,1;PS TMR2 EN 16
	    BSF T2CON,2;TMR2 ENCENDIDO  
	    
;--------------------------------------
; Multiplicación por 10
;--------------------------------------	

	MULV8
	    BANKSEL 0X20
	    CLRF DISPLAY1POR10
	MULU8LOOP
            MOVF TEMPX,W
            BTFSC TEMPY,0
            ADDWF DISPLAY1POR10
            BCF STATUS,C
            RRF TEMPY,F
            BCF STATUS,C
            RLF TEMPX,F
            MOVF TEMPY,F
            BTFSS STATUS,Z
            GOTO MULU8LOOP
            RETURN	    
;--------------------------------------------------------------------------------------------------------------------------------------------------------
;--------------------------------------	    
; Tabla para conversión de dígitos a 7 segmentos
;--------------------------------------
	TABLA_D7S
	    ADDWF PCL,F
	    RETLW B'11000000';0
	    RETLW B'11111001';1
	    RETLW B'10100100';2
	    RETLW B'10110000';3
	    RETLW B'10011001';4
	    RETLW B'10010010';5
	    RETLW B'10000010';6
	    RETLW B'11111000';7
	    RETLW B'10000000';8
	    RETLW B'10010000';9  
;--------------------------------------------------------------------------------------------------------------------------------------------------------

	MAIN_2
	    ; Bucle infinito
    	    ;BTFSC MOT_ON,0
	    ;GOTO 0X04
	    GOTO MAIN_2  
END_MAIN
	    
;--------------------------------------
; Rutina de servicio de interrupción
;--------------------------------------  
INTER
	    ; Guardo el contexto
	    MOVWF W_TEMP
	    SWAPF STATUS,W
	    MOVWF STATUS_TEMP
	    ;MOVLW 0XBB
	    ;CALL SEND_TX
	    ;---VEO QUÉ BANDERA ME TRAJO AQUÍ--
	    BANKSEL INTCON
	    BTFSC INTCON,RBIF;VEO LA BANDERA DE IOCB
	    GOTO INTER_TECLADO
	    BTFSC INTCON,T0IF;VEO LA BANDERA DE TM0
	    GOTO INTER_TM0
	    ;BTFSC MOT_ON,0
	    ;GOTO VEL_MOTOR
	    GOTO FINAL_RSI   
INTER_TECLADO
	    ;MOVF NUMINF, W
	    ;CALL SEND_TX
	    ;MOVLW 0XAA
	    ;CALL SEND_TX
	    BANKSEL PORTC
	    BSF PORTC, 3
	    CALL Delay100ms
	    CALL BAJAR_FLAG
	    CLRF CONT
	    ; Configuración variables y flags
	    
	    CALL CONFIG_INDEX_MASCARA_FILA

	    ; Verifico si los numeros ya se estan mostrando
	    BTFSC NUMINF,0
	    GOTO INTER_TECLADO_DISPLAY_ANDANDO
	    GOTO FILAS
	    
	;---------------------------------------------
	; Manejo del teclado
	;---------------------------------------------    
	FILAS
	    ;MOVLW 0X0A
	    ;CALL SEND_TX
	    
	    CALL MASK_INDEX_CONT
	    
	    
	    ; Verifico columna 1
	    BANKSEL PORTB
	    BTFSC PORTB, 2
	    GOTO GUARDAR_NUM_EN_DISPLAY
	    INCF CONT, F
	    
	    ; Verifico columna 2
	    BANKSEL PORTB
	    BTFSC PORTB, 1
	    GOTO GUARDAR_NUM_EN_DISPLAY
	    INCF CONT, F
	    
	    ; Verifico columna 3
	    BANKSEL PORTB
	    BTFSC PORTB, 0
	    GOTO GUARDAR_NUM_EN_DISPLAY
	    DECFSZ FILA, F
	    
	    ; Rotar para scanear la siguiente fila
	    GOTO ROTAR
	    GOTO FILA4
	    
	ROTAR	
	    BANKSEL STATUS
	    BCF STATUS,C
	    RLF INDEX, F
	    GOTO FILAS
	
	FILA4
	    CLRF CONT
	    
	    CALL FILA4_ENERGIZO
	    
	    ; Verifico columna 3
	    BANKSEL PORTB
	    BTFSC PORTB, 2
	    GOTO INTER_TECLADO_DISPLAY_ANDANDO
	    
	    ; Verifico columna 3
	    BANKSEL PORTB
	    BTFSC PORTB, 1
	    GOTO GUARDAR_NUM_EN_DISPLAY
	    
	    ;MOVLW 0X0B
	    ;CALL SEND_TX
	    ; Verifico columna 3
	    ;BTFSC PORTB, 0
	    GOTO FINAL_TECLADO
	    
	FILA4_ENERGIZO
	    ; Energizo la fila 4
	    MOVLW B'01000000'
	    MOVWF INDEX
	    MOVLW B'10000111'
	    MOVWF MASK
	    MOVF MASK, W
	    BANKSEL PORTB
	    ANDWF PORTB, F
	    MOVF INDEX, W
	    BANKSEL PORTB
	    IORWF PORTB, F
	RETURN
	
	;--------------------------------------
	; Limpia el carry y rota CONT0A3VAR
	;--------------------------------------  
	ROTAR_LIMPIAR
	    BCF STATUS, C
	    RLF CONT0A3VAR,F
	RETURN
	    
	;---------------------------------------------
	; Manejo de visualizacion de numeros 
	;---------------------------------------------   
	GUARDAR_NUM_EN_DISPLAY
	    MOVF CONT0A3VAR,W;
	    CALL SEND_TX
	    MOVF CONT,W;
	    CALL SEND_TX
	    BTFSC CONT0A3VAR,0
	    GOTO GUARDAR_D2
	    BTFSC CONT0A3VAR,1
	    GOTO GUARDAR_D1
	    BTFSC CONT0A3VAR,2
	    GOTO GUARDAR_D0
	    
	; Indico que numero va a mostrar el display 0 (LSB)
	GUARDAR_D2
	    MOVLW 0XD2
	    CALL SEND_TX
	    MOVF CONT, W
	    BANKSEL 0X20
	    MOVWF DISPLAY2T
	    ;CALL SEND_TX
	    ;MOVF CONT, W
	    CALL TABLA_D7S
	    MOVWF DISPLAY2
	    CALL ROTAR_LIMPIAR
	    
	    GOTO FINAL_TECLADO
	    
	; Indico que numero va a mostrar el display 1
	GUARDAR_D1
	    MOVLW 0XD1
	    CALL SEND_TX
	    MOVF CONT, W
	    BANKSEL 0X20
	    MOVWF DISPLAY1T
	    ;CALL SEND_TX
	    ;MOVF CONT, W
	    CALL TABLA_D7S
	    MOVWF DISPLAY1
	    CALL ROTAR_LIMPIAR

	    GOTO FINAL_TECLADO    
	    
	; Indico que numero va a mostrar el display 2 (MSB)    
	GUARDAR_D0
	    MOVLW 0XD0
	    CALL SEND_TX
	    MOVF CONT, W
	    BANKSEL 0X20
	    MOVWF DISPLAY0T
	    ;CALL SEND_TX
	    ;MOVF CONT, W
	    CALL TABLA_D7S
	    MOVWF DISPLAY0
	    
	    ; Reseteo el contador
	    MOVLW B'00000001'
	    MOVWF CONT0A3VAR
	    
	    ; Seteo el flag que indica que ya se ingresaron todos los números
	    BSF NUMINF,0
	    ; Levanto la flag que indica que el motor se encendió
	    BANKSEL 0X20
	    ;BSF MOT_ON,0
	    GOTO VEL_MOTOR
	    ;MOVF NUMINF, W
	    ;CALL SEND_TX
	    
	    ;GOTO FINAL_TECLADO
	   
	;---------------------------------------------
	; Manejo del rebote, flag de interrupcion y reseteo del contador de teclas
	;---------------------------------------------       
	TECLAS
	    CLRF CONT
	    ;CALL Delay100ms
	    
	    CALL BAJAR_FLAG
	RETURN   
	
	;---------------------------------------------
	; Interrupción del teclado con los displays ya funcionando
	;---------------------------------------------  
	INTER_TECLADO_DISPLAY_ANDANDO
	
	    ; Energizo la fila 4
	    CALL FILA4_ENERGIZO
	    
	    ; Verifico si se presionó el asterisco (*)
	    BANKSEL PORTB
	    BTFSS PORTB, 2
	    GOTO FINAL_TECLADO
	    GOTO RESET_DISPLAY
	;---------------------------------------------
	; Seteo de la velocidad del motor en función de los números ingresados por teclado
	;---------------------------------------------     
	VEL_MOTOR  
	    BANKSEL 0X20
	    MOVLW 0XBB
	    CALL SEND_TX
	    BANKSEL 0X20
	    ;BCF MOT_ON,0;BAJO LA BANDERA DEL MOTOR
	    BCF STATUS,Z
	    MOVF DISPLAY2T,F;LO MUEVO A SI MISMO PARA QUE SE SUBA (O NO) EL Z DEL STATUS
	    BTFSS STATUS, Z;VEO SI DISPLAY2 ES 0
	    GOTO VERIFICO_SI_DISPLAY2_ES_UNO;SI NO ES 0, VERIFICO QUE SE HAYA INGRESADO UN 1 EN EL TERCER DISPLAY
	    GOTO VERIFICO_SI_DISPLAY1_ES_0;SI ES 0, VERIFICO SI EL DISPLAY1 ES 0
	
	VERIFICO_SI_DISPLAY2_ES_UNO
	    BANKSEL 0X20
	    MOVF DISPLAY2T,W
	    CALL SEND_TX
	    BCF STATUS, Z
	    SUBLW D'1';LE RESTO 1 A W
	    BTFSS STATUS,Z;VERIFICO SI LA CUENTA DIO 0
	    GOTO RESET_DISPLAY;SI NO ES CERO AL RESTARLE 1, QUIERE DECIR QUE SE INGRESÓ UN NÚMERO MAYOR A 1 EN EL DISPLAY 2, Y ESO NO SE PUEDE
	    ;SI DISPLAY2T ES 1, VERIFICO QUE LOS OTROS SEAN 0
	    MOVLW 0XAA
	    CALL SEND_TX
	    BANKSEL 0X20
	    BCF STATUS, Z
	    MOVF DISPLAY1T,F
	    BTFSS STATUS,Z;VERIFICO SI DISPLAY1T ES 0
	    GOTO RESET_DISPLAY;SI NO ES 0, SE INGRESÓ UN NÚMERO MAYOR A 100, INVÁLIDO
	    MOVLW 0XFF
	    CALL SEND_TX
	    BANKSEL 0X20
	    BCF STATUS, Z
	    MOVF DISPLAY0T,F
	    BTFSS STATUS,Z;VERIFICO SI DISPLAY0T ES 0
	    GOTO RESET_DISPLAY;SI NO ES 0, SE INGRESÓ UN NÚMERO MAYOR A 100, INVÁLIDO
	    MOVLW D'100'
	    ;MOVWF CCPR1L;EL DUTY CYCLE DEL MOTOR ES DEL 100%
	    GOTO MOTOR_ENCEDIDO
	    
	VERIFICO_SI_DISPLAY1_ES_0
	    BCF STATUS, Z
	    MOVF DISPLAY1T,F;LO MUEVO A SI MISMO PARA QUE SE SUBA (O NO) EL Z DEL STATUS
	    BTFSS STATUS, Z;VEO SI DISPLAY1 ES 0
	    GOTO DISPLAY1_POR_10
	    MOVF DISPLAY0T,W;SI EL DISPLAY2 Y EL 1 SON 0, NADA MÁS QUEDA LA UNIDAD (DISPLAY0) PARA EL DUTY CYCLE
	    MOVWF CCPR1L
	    GOTO MOTOR_ENCEDIDO
	    
	DISPLAY1_POR_10;MULTIPLICO POR 10 EL DISPLAY 1, QUE ES LA DECENA
	    BANKSEL 0X20
	    MOVF   DISPLAY1T,W
	    MOVWF  TEMPX
	    MOVLW   D'10'
	    MOVWF  TEMPY
	    CALL   MULV8
	    MOVF   DISPLAY1POR10,W
	    ADDWF DISPLAY0T,W
	    MOVWF CCPR1L;DISPLAY1*10+DISPLAY0=DUTY CYCLE DEL MOTOR
	    GOTO MOTOR_ENCEDIDO
	
	    
	    
	    
	;---------------------------------------------
	; Energizo las filas
	;---------------------------------------------      
	ENERGIZO_FILAS
	    BANKSEL PORTC
	    BCF PORTC, 3
	    BANKSEL PORTB
	    MOVLW B'01111000'
	    MOVWF PORTB; 
	    RETURN
	;---------------------------------------------
	; Reseteo de los displays
	;---------------------------------------------  
	RESET_DISPLAY
	    BANKSEL PORTD
	    ; Todos los displays apagados
	    MOVLW B'00111111'
	    MOVWF DISPLAY0
	    MOVWF DISPLAY1
	    MOVWF DISPLAY2
	    MOVWF PORTD
	    ; Reseteo el contador
	    MOVLW B'00000001'
	    MOVWF CONT0A3VAR
	    ; Limpio el flag para poder volver a ingresar teclas
	    BCF NUMINF,0
	    ;MUEVO UN 0 AL REGISTRO QUE ME CONTROLA EL DUTY CYCLE DEL MOTOR
	    CLRF CCPR1L
	    ;MOVF NUMINF, W
	    ;CALL SEND_TX
	    MOVLW 0XD;RESET
	    CALL SEND_TX
	    
	;---------------------------------------------
	; Reseteo de los displays
	;---------------------------------------------  
	FINAL_TECLADO
	    ;MOVLW 0XC
	    ;CALL SEND_TX
	    CALL TECLAS
	    ;MOVLW 0XE
	    ;CALL SEND_TX
	; Energizo las filas, a la espera de una interrupcion
	    CALL ENERGIZO_FILAS
	    BANKSEL PORTD
	    MOVF PORTD, W
	    CALL SEND_TX
	    ;MOVLW 0XF
	    ;CALL SEND_TX
	    GOTO FINAL_RSI
	;---------------------------------------------
	; Motor encendido
	;---------------------------------------------      
	MOTOR_ENCEDIDO
	    BANKSEL CCPR1L
	    MOVWF CCPR1L;EL DUTY CYCLE DEL MOTOR ES DEL 100%
	    CALL Delay100ms
	    CALL TECLAS
	    CALL ENERGIZO_FILAS
	    BANKSEL PORTD
	    MOVF PORTD, W
	    CALL SEND_TX
	    BANKSEL 0X20
	    BSF FInicio,0; Flag de inicio motor
	    GOTO FINAL_RSI
	    
	    
;--------------------------------------
; Interrupción por TMR0
;--------------------------------------	    
	INTER_TM0
	    ;MOVLW 0XCC
	    ;CALL SEND_TX
	    BANKSEL INTCON
	    BCF INTCON,T0IF;LIMPIO LA BANDERA DE RBIF
	    BANKSEL 0X20
	    BTFSS FInicio,0; verifico si ya puedo comenzar la cuenta
	    GOTO START_MULTIPLEXADO
	    GOTO CONTEO
	    
	;--------------------------------------
	; Empieza el conteo
	;--------------------------------------	  
	CONTEO	
	    BANKSEL T1CON
	    BTFSS T1CON,0; Verifico si ya habilité la cuenta
	    BSF T1CON,0; comienzo la cuenta, salteo si ya habilité T1CKI	
	    BANKSEL 0X20
	    DECFSZ CONTde200,1
	    GOTO START_MULTIPLEXADO
	    MOVLW .200
	    MOVWF CONTde200; recargo contador de 200
	    DECFSZ CONTde5,1
	    GOTO START_MULTIPLEXADO
	    GOTO GUARDAR_CUENTA_FINAL
    
	GUARDAR_CUENTA_FINAL
	    BANKSEL T1CON
	    BCF T1CON,0;
	    
	    BANKSEL TMR1L
	    MOVF TMR1L,W ; Guardo la cantidad de vueltas
	    CALL SEND_TX
	    BANKSEL TMR1L
	    MOVWF NvueltasL 
	    MOVF TMR1H,W  
	    CALL SEND_TX
	    BANKSEL TMR1L
	    MOVWF NvueltasH  
	    
	    BANKSEL TMR1L
	    MOVLW B'00000000'; reseteo el valor del TMR1
	    MOVWF TMR1L
	    MOVWF TMR1H
	      
	    BANKSEL 0X20
	    MOVLW .5
	    MOVWF CONTde5
	    BCF FInicio,0;      
	    GOTO START_MULTIPLEXADO
	    
	;--------------------------------------
	; Empiezo el multiplexado
	;--------------------------------------	            
	START_MULTIPLEXADO
	    ;VEO A QUÉ DISPLAY LE TOCARÍA ENCENDERSE
	    BTFSC CONT0A3D,0;VERIFICO SI LE TOCA ENCENDERSE AL DISPLAY 0
	    GOTO DISP0;VOY HACIA LA SECCIÓN QUE CONTROLA LO QUE MUESTRA EL DISPLAY 0 (lsb)
	    BTFSC CONT0A3D,1;VERIFICO SI LE TOCA ENCENDERSE AL DISPLAY 1
	    GOTO DISP1;VOY HACIA LA SECCIÓN QUE CONTROLA LO QUE MUESTRA EL DISPLAY 1
	    BTFSC CONT0A3D,2;VERIFICO SI LE TOCA ENCENDERSE AL DISPLAY 2
	    GOTO DISP2;VOY HACIA LA SECCIÓN QUE CONTROLA LO QUE MUESTRA EL DISPLAY 2 (MSB) 
	;--------------------------------------
	; Cambio el display que se muestra
	;--------------------------------------    
	    
	MOSTRAR_NUM_DISP
	DISP0
	    ;MOVLW 0XA
	    ;CALL SEND_TX
	    BANKSEL PORTE
	    BCF PORTE,1;APAGO EL DISPLAY 1
	    BCF PORTE,2;APAGO EL DISPLAY 2
	    MOVF DISPLAY0,W;
	    BANKSEL PORTD
	    MOVWF PORTD;MUEVO EL NÚMERO QUE LE CORRESPONDE MOSTRAR AL DISPLAY 0 AL PUERTO D
	    BANKSEL PORTE
	    BSF PORTE,0;HABILITO EL DISPLAY 0
	    BCF STATUS, 0
	    RLF CONT0A3D,F;EL 1 QUE ESTABA EN EL BIT 0 AHORA ESTÁ EN EL 1
	    GOTO FINAL_RSI_TMR0
	DISP1
	    ;MOVLW 0XB
	    ;CALL SEND_TX
	    BANKSEL PORTE
	    BCF PORTE,0;APAGO EL DISPLAY 0
	    BCF PORTE,2;APAGO EL DISPLAY 2
	    MOVF DISPLAY1,W;
	    BANKSEL PORTD
	    MOVWF PORTD;MUEVO EL NÚMERO QUE LE CORRESPONDE MOSTRAR AL DISPLAY 1 AL PUERTO D
	    BANKSEL PORTE
	    BSF PORTE,1;HABILITO EL DISPLAY 1
	    BCF STATUS, 0
	    RLF CONT0A3D,F;EL 1 QUE ESTABA EN EL BIT 1 AHORA ESTÁ EN EL 2 
	    GOTO FINAL_RSI_TMR0
	DISP2
	    ;MOVLW 0XC
	    ;CALL SEND_TX
	    BANKSEL PORTE
	    BCF PORTE,1;APAGO EL DISPLAY 1
	    BCF PORTE,0;APAGO EL DISPLAY 0
	    MOVF DISPLAY2,W;
	    BANKSEL PORTD
	    MOVWF PORTD;MUEVO EL NÚMERO QUE LE CORRESPONDE MOSTRAR AL DISPLAY 2 AL PUERTO D
	    BANKSEL PORTE
	    BSF PORTE,2;HABILITO EL DISPLAY 2
	    MOVLW B'00000001'  
	    MOVWF CONT0A3D;PONGO YA EN EL BIT 0 EL 1 PARA LA PRÓXIMA VEZ QUE INTERRUMPA 
	    GOTO FINAL_RSI_TMR0 
	    
	    ;--------------------------------------
	    ; Final RSI del TMR0
	    ;--------------------------------------  
	    
	FINAL_RSI_TMR0    
	    BANKSEL 0X20;RECARGO EL TIMER0
	    MOVLW 0XF8;248, PARA QUE TARDE 2MS EN DESBORDARSE
	    MOVWF TMR0
	
;--------------------------------------
; Final RSI
;--------------------------------------    
	    
	FINAL_RSI
	    CALL BAJAR_FLAG
	    BANKSEL INTCON
	    BCF INTCON,T0IF;LIMPIO LA BANDERA DE RBIF
	    ;MOVF INTCON, W
	    ;CALL SEND_TX
	    ; Recupero el contexto
	    SWAPF STATUS_TEMP,W;
	    MOVWF STATUS
	    SWAPF W_TEMP,F
	    SWAPF W_TEMP,W
	    ;Return al programa principal 
	    RETFIE


END