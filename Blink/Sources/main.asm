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

;
; Constantes
;
LED_PIN     EQU   (1 << PTBD_PTBD4)
LED_PORT    EQU   PTBD
DELAY       EQU   500

;
; Variables en ZRAM
;
            ORG   Z_RAMStart
COUNTER: DS.W   1

;
; Variables en RAM
;
            ORG    RAMStart


;
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
;
; Bucle infinito
;
LOOP:
            NOP
            BRA    LOOP


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