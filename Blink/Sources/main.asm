;** ===================================================================
;**     Programa        : main.asm
;**
;**     Descripcion     : punto de entrada invocado en _Startup
;** ===================================================================

            INCLUDE 'derivative.inc'
;
; export symbols
;
            XDEF _Startup
            ABSENTRY _Startup

; Existe el Location Counter. Su valor actual se obtiene con '*'
            
;
; Constantes
;
LED_PIN     EQU   (1 << PTBD_PTBD4)
LED_PORT    EQU   PTBD
DELAY       EQU   500
BTIM        EQU   100          ; tiempo de debouncing ms
LED_BIT     EQU   PTBD_PTBD4

* Estados del teclado:              ; los comentarios tambien pueden comenzar con *

SCAN        EQU   0
BOUNCE1     EQU   1
RELEASE     EQU   2
BOUNCE2     EQU   3


* Hardware del teclado

KPORT       EQU   PTAD
KMASK       EQU   %00000110         ; mascara para filtar bits no usados
KFREE       EQU   %00000110         ; teclado libre
KEY0        EQU   %00000100
KEY1        EQU   %00000010
KBOTH       EQU   %00000000

;
* Flags del sistema:

KEYREADY    EQU   %00000001


; Variables en ZRAM
;
            ORG   Z_RAMStart
            
COUNTER     RMB   1
FLAGS       RMB   1
KEY         RMB   1       ; scancode (no es lo mismo que keycode)
KSTATE      RMB   1
KTIM        RMB   1

;
; Variables en RAM
;
            ORG    RAMStart

; Codigo
;
            ORG    ROMStart

; Se incluye codigo generado por Device Initializacion
            
            INCLUDE 'MCUInit.inc'

;
; Entry point cargado en el vector de interrupciones
; (ver MCUinit.inc)

_Startup:
            LDHX   #RAMEnd+1        ; initialize the stack pointer
            TXS
            ; Se invoca MCU_init, definido en MCUinit.inc, generado
            ; por Device Initialization
            JSR    MCU_init
;
; Codigo main
;
MAIN:            
            LDHX  #DELAY    ; inicializo contador en #DELAY
            STHX   COUNTER
            
            CLI             ; habilito interrupciones
      
            JSR   INISYS

; Bucle infinito
;
LOOP:       BRCLR KEYREADY,FLAGS,LOOP     ; hay tecla ?
            BCLR  KEYREADY,FLAGS          ; acknowledge
            
            LDA   KEY
            CMP   #KEY0
            BEQ   DO_CERO
            CMP   #KEY1
            BEQ   DO_UNO
            CMP   #KBOTH
            BEQ   DO_BOTH
            BRA   LOOP
            
DO_CERO     BSET  LED_BIT,LED_PORT
            BRA   LOOP

DO_UNO      BCLR  LED_BIT,LED_PORT
            BRA   LOOP    
            
DO_BOTH     BSET  LED_BIT,LED_PORT
            BRA   LOOP                     
            
******************************************************
* aqui cada 1 ms LLamada desde la interrupt del timer
******************************************************

TICK1MS     
*           JSR   BLINK     ; invoco rutina para blinquear LED
            JSR   KEYBD     ; tratamiento del teclado
            
            RTS

*************************
* Inicializa el sistema
*************************

INISYS      JSR   INIKEY
            RTS

; Limitacion del MOV: funciona solo a pag cero

INIKEY      BCLR  KEYREADY,FLAGS    ; limpiar novedad del teclado
            MOV   #SCAN,KSTATE      ; estado inicial de la maquina de teclado
            CLR   KEY
            RTS

;** ===================================================================
;** Funcion que blinquea un led cada 1 segundo, asume que la invocan
;** cada 1ms, manteniendo un contador con el estado.
;** ===================================================================

BLINK:
            LDHX   COUNTER
            AIX    #-1
            CPHX  #0
            BNE   END_BLINK            
TOGGLE:
            LDA   LED_PORT
            EOR   #LED_PIN
            STA   LED_PORT            
            LDHX  #DELAY
END_BLINK:
            STHX   COUNTER
            RTS

*****************************
* Rutina de teclado:
* Es una maquina de 4 estados
*****************************

KEYBD       LDA   KSTATE
            CMP   #SCAN
            BEQ   SSCAN
            CMP   #BOUNCE1
            BEQ   SBNCE1
            CMP   #RELEASE
            BEQ   SREL
            CMP   #BOUNCE2
            BEQ   SBNCE2
            
            BRA   OUTKEY

* Espero una sospecha de tecla:

SSCAN       LDA   KPORT             ; leer port
            AND   #KMASK            ; filtrar bits laterales
            CMP   #KFREE            ; teclado libre ?
            BEQ   OUTKEY            ; no hay teclas - me voy

* procesar un tecla posible 

HAYTEC      STA   KEY               ; hay sospecha de tecla - guardo codigo               
            MOV   #BTIM,KTIM        ; cargar timer de debouncing
            MOV   #BOUNCE1,KSTATE   ; cambio al proximo estado
            BRA   OUTKEY            

* Aqui esperamos el tiempo de rebote

SBNCE1      DBNZ  KTIM,OUTKEY

* vencio el timer:

            LDA   KPORT
            AND   #KMASK            ; filtrar bits laterales
            CMP   #KFREE            ; teclado libre ?
            BEQ   TOSCAN
            
* Se confirma la tecla

            BSET  KEYREADY,FLAGS    ; avisar al principal la novedad
            MOV   #RELEASE,KSTATE   ; proximo estado
            BRA   OUTKEY            
            
TOSCAN      MOV   #SCAN,KSTATE      ; falsa alarma - no hubo tecla
            BRA   OUTKEY                                    

* Esperamos que el usuario suelte la tecla tecla confirmada

SREL        LDA   KPORT
            AND   #KMASK            ; filtrar bits laterales
            CMP   #KFREE            ; teclado libre ?
            BNE   OUTKEY            ; no solto aun ... esperar mas
            
* Sospecha de soltada

            MOV   #BTIM,KTIM        ; cargar el timer de debouncing
            MOV   #BOUNCE2,KSTATE   ; proximo estado
            BRA   OUTKEY

* Esperar el tiempo de debouncing de soltada
           
SBNCE2      DBNZ  KTIM,OUTKEY       ; esperar ...
            
* Confirmar el release de la tecla
            
            LDA   KPORT
            AND   #KMASK            ; filtrar bits laterales
            CMP   #KFREE            ; teclado libre ?
            BNE   TOSCAN2           ; todavia no solto

* Todo listo, se libero el teclado, volvemos al principio

            MOV   #SCAN,KSTATE
            BRA   OUTKEY

            
* Le otorgamos otros BTIM ms de oportunidad            
            
TOSCAN2     MOV   #RELEASE,KSTATE   ; volver al estado anterior
            
OUTKEY      RTS
    
            
            
            
            