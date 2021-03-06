;** ###################################################################
;**     This code is generated by the Device Initialization Tool.
;**     It is overwritten during code generation.
;**     USER MODIFICATION ARE PRESERVED ONLY INSIDE INTERRUPT SERVICE ROUTINES
;**     OR EXPLICITLY MARKED SECTIONS
;**
;**     Project   : KeyReloaded
;**     Processor : MC9S08SH8CPJ
;**     Version   : Component 01.007, Driver 01.06, CPU db: 3.00.062
;**     Datasheet : MC9S08SH8 Rev. 3 6/2008
;**     Date/Time : 10/01/2015, 03:50 p.m.
;**     Abstract  :
;**         This module contains device initialization code 
;**         for selected on-chip peripherals.
;**         To compile Absolute Assembler correctly, this
;**         module should be included at the end of user module.
;**         Position for code should be set before including
;**         using ORG directive.        	
;**     Contents  :
;**         No public methods
;**
;**     Copyright : 1997 - 2009 Freescale Semiconductor, Inc. All Rights Reserved.
;**     
;**     http      : www.freescale.com
;**     mail      : support@freescale.com
;** ###################################################################

; MODULE MCUinit

;       INCLUDE MC9S08SH8.inc          ; I/O map for MC9S08SH8CPJ

; User declarations and definitions
;   Code, declarations and definitions here will be preserved during code generation
; End of user declarations and definitions


;** ===================================================================
;**     Method      :  MCU_init (component MC9S08SH8_20)
;**
;**     Description :
;**         Device initialization code for selected peripherals.
;** ===================================================================
MCU_init:
  ; ### MC9S08SH8_20 "Cpu" init code ... 

  ; Common initialization of the write once registers 
        ; SOPT1: COPT=0,STOPE=0,IICPS=0,BKGDPE=1,RSTPE=0 
        LDA     #2
        STA     SOPT1                                               
        ; SOPT2: COPCLKS=0,COPW=0,ACIC=0,T1CH1PS=0,T1CH0PS=0 
        CLRA
        STA     SOPT2                                               
        ; SPMSC1: LVWF=0,LVWACK=0,LVWIE=0,LVDRE=1,LVDSE=1,LVDE=1,BGBE=0 
        LDA     #28
        STA     SPMSC1                                               
        ; SPMSC2: LVDV=0,LVWV=0,PPDF=0,PPDACK=0,PPDC=0 
        CLRA
        STA     SPMSC2                                               
  ;  System clock initialization 
        ;Test if the device trim value is stored on the specified address
        LDA     65455
        CBEQA   #255, SkipTrim
        ; ICSTRM: Initialize internal clock trim from a non volatile memory 
        LDA     65455
        STA     ICSTRM
        ; ICSSC: Initialize internal clock trim from a non volatile memory 
        LDA     65454
        STA     ICSSC
SkipTrim:
        ; ICSC1: CLKS=0,RDIV=0,IREFS=1,IRCLKEN=0,IREFSTEN=0 
        MOV     #4,ICSC1               ; Initialization of the ICS control register 1 
        ; ICSC2: BDIV=0,RANGE=0,HGO=0,LP=0,EREFS=0,ERCLKEN=0,EREFSTEN=0 
        CLR     ICSC2                  ; Initialization of the ICS control register 2 
while_Cpu0:                            ; Wait until the source of reference clock is internal clock 
        LDA     #85                    ; Reset watchdog counter - 2x write
        STA     SRS
        LDA     #170
        STA     SRS
        BRCLR   4,ICSSC,while_Cpu0
        ; GNGC: GNGPS7=0,GNGPS6=0,GNGPS5=0,GNGPS4=0,GNGPS3=0,GNGPS2=0,GNGPS1=0,GNGEN=0 
        CLRA
        STA     GNGC                                               
  ; Common initialization of the CPU registers 
        ; PTASE: PTASE4=0,PTASE3=0,PTASE2=0,PTASE1=0,PTASE0=0 
        LDA     PTASE
        AND     #224
        STA     PTASE
        ; PTBSE: PTBSE7=0,PTBSE6=0,PTBSE5=0,PTBSE4=0,PTBSE3=0,PTBSE2=0,PTBSE1=0,PTBSE0=0 
        CLRA
        STA     PTBSE                                               
        ; PTCSE: PTCSE3=0,PTCSE2=0,PTCSE1=0,PTCSE0=0 
        LDA     PTCSE
        AND     #240
        STA     PTCSE
        ; PTADS: PTADS4=0,PTADS3=0,PTADS2=0,PTADS1=0,PTADS0=0 
        CLRA
        STA     PTADS                                               
        ; PTBDS: PTBDS7=0,PTBDS6=0,PTBDS5=0,PTBDS4=0,PTBDS3=0,PTBDS2=0,PTBDS1=0,PTBDS0=0 
        CLRA
        STA     PTBDS                                               
        ; PTCDS: PTCDS3=0,PTCDS2=0,PTCDS1=0,PTCDS0=0 
        CLRA
        STA     PTCDS                                               
  ; ### Init_COP init code 
        LDA     #85
        STA     SRS                    ; Clear WatchDog counter - first part 
        LDA     #170
        STA     SRS                    ; Clear WatchDog counter - second part 
  ; ### Init_GPIO init code 
        ; PTAPE: PTAPE2=1,PTAPE1=1 
        LDA     PTAPE
        ORA     #6
        STA     PTAPE
        ; PTADD: PTADD2=0,PTADD1=0 
        LDA     PTADD
        AND     #249
        STA     PTADD
  ; ### Init_GPIO init code 
        ; PTBDD: PTBDD4=1,PTBDD3=1 
        LDA     PTBDD
        ORA     #24
        STA     PTBDD
  ; ### Init_TPM init code 
        ; TPM1SC: TOF=0,TOIE=0,CPWMS=0,CLKSB=0,CLKSA=0,PS2=0,PS1=0,PS0=0 
        CLR     TPM1SC                 ; Stop and reset counter 
        LDHX    #1250
        STHX    TPM1MOD                ; Period value setting 
        LDA     TPM1SC                 ; Overflow int. flag clearing (first part) 
        ; TPM1SC: TOF=0,TOIE=1,CPWMS=0,CLKSB=0,CLKSA=1,PS2=1,PS1=0,PS0=0 
        MOV     #76,TPM1SC             ; Int. flag clearing (2nd part) and timer control register setting 
  ; ### 
        CLI                            ; Enable interrupts 
        RTS


;** ===================================================================
;**     Interrupt handler : isrVtpm1ovf
;**
;**     Description :
;**         User interrupt service routine. 
;**     Parameters  : None
;**     Returns     : Nothing
;** ===================================================================
        XDEF    isrVtpm1ovf
isrVtpm1ovf:
  ; Write your interrupt code here ... 

      PSHH
        
      BCLR  TPM1SC_TOF, TPM1SC
      JSR TICK_1MS
        
      PULH
      RTI
; end of isrVtpm1ovf 




_code_curPos:   EQU     *              ; remember original position of code for restoring at the end of the file

; Initialization of the CPU registers in FLASH 

        ; NVPROT: FPS7=1,FPS6=1,FPS5=1,FPS4=1,FPS3=1,FPS2=1,FPS1=1,FPDIS=1 
        ORG     NVPROT
        DC.B    255

        ; NVOPT: KEYEN=0,FNORED=1,SEC01=1,SEC00=0 
        ORG     NVOPT
        DC.B    126



; Interrupt vector table 
  ifndef UNASSIGNED_ISR
UNASSIGNED_ISR: EQU     $FFFF          ; unassigned interrupt service routine
  endif

        ORG     $FFC0                  ; Interrupt vector table
_vect:
        DC.W    UNASSIGNED_ISR         ; Int.no. 31 VReserved31 (at FFC0)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 30 Vacmp (at FFC2)                 Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 29 VReserved29 (at FFC4)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 28 VReserved28 (at FFC6)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 27 VReserved27 (at FFC8)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 26 Vmtim (at FFCA)                 Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 25 Vrtc (at FFCC)                  Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 24 Viic (at FFCE)                  Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 23 Vadc (at FFD0)                  Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 22 VReserved22 (at FFD2)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 21 Vportb (at FFD4)                Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 20 Vporta (at FFD6)                Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 19 VReserved19 (at FFD8)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 18 Vscitx (at FFDA)                Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 17 Vscirx (at FFDC)                Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 16 Vscierr (at FFDE)               Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 15 Vspi (at FFE0)                  Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 14 Vtpm2ovf (at FFE2)              Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 13 Vtpm2ch1 (at FFE4)              Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no. 12 Vtpm2ch0 (at FFE6)              Unassigned
        DC.W    isrVtpm1ovf            ; Int.no. 11 Vtpm1ovf (at FFE8)              Used
        DC.W    UNASSIGNED_ISR         ; Int.no. 10 VReserved10 (at FFEA)           Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  9 VReserved9 (at FFEC)            Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  8 VReserved8 (at FFEE)            Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  7 VReserved7 (at FFF0)            Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  6 Vtpm1ch1 (at FFF2)              Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  5 Vtpm1ch0 (at FFF4)              Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  4 VReserved4 (at FFF6)            Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  3 Vlvd (at FFF8)                  Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  2 Virq (at FFFA)                  Unassigned
        DC.W    UNASSIGNED_ISR         ; Int.no.  1 Vswi (at FFFC)                  Unassigned
        DC.W    _Startup               ; Int.no.  0 Vreset (at FFFE)                Reset vector




        ORG     _code_curPos           ; restore original position for code

; MODULE END MCUinit

;** ###################################################################
;**
;**     This file was created by Processor Expert 3.07 [04.41]
;**     for the Freescale HCS08 series of microcontrollers.
;**
;** ###################################################################
