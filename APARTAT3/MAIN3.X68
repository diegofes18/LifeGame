; =============================================================================
; TITLE    : GAME OF LIFE APPLICATION
; AUTHOR   : ANTONI BURGUERA
; CREATION : 05-JULY-2021
; =============================================================================

            ORG     $1000

; --- CODE INCLUDES -----------------------------------------------------------

            INCLUDE "SYSCONST.X68"          ; SYSTEM CONSTANTS
            INCLUDE "SYSTEM.X68"            ; SYSTEM CODE
            INCLUDE "CONST.X68"             ; USER CONSTANTS
            INCLUDE "UTIL.X68"              ; UTILITY CODE
            INCLUDE "BUTTON.X68"            ; BUTTON MANAGEMENT
            INCLUDE "BTNLIST.X68"           ; BUTTON LIST MANAGEMENT
            INCLUDE "GRID.X68"              ; GRID MANAGEMENT
            INCLUDE "GOL.X68"               ; GAME OF LIFE APPLICATION

; --- INITIALIZE --------------------------------------------------------------

START       JSR     SYSINIT                 ; INITIALIZE SYSTEM CODE
            JSR     GOLINIT                 ; INITIALIZE GAME OF LIFE

; --- UPDATE ------------------------------------------------------------------

.LOOP       TRAP    #MOUTRAP                ; READ MOUSE
            JSR     GOLUPD                  ; UPDATE APPLICATION

; --- PLOT --------------------------------------------------------------------

            JSR     GOLPLOT                 ; PLOT APPLICATION
            TRAP    #SCRTRAP                ; SHOW GRAPHICS
            BRA     .LOOP
            SIMHALT

; --- VARIABLES ---------------------------------------------------------------

            INCLUDE "SYSVAR.X68"            ; SYSTEM VARIABLES
            INCLUDE "VAR.X68"               ; USER VARIABLES

            END    START

; UPDATES THE GRID ACCORDING TO 2-PLAYER GAME OF LIFE RULES AS FOLLOWS:
; * ADDS 1 TO THE NUMBER OF GENERATIONS (GRDNGEN)
; * SWITCHES THE MATRIX POINTERS (GRDDST AND GRDSRC).
; * CHECKS THE NEIGHBORS USING THE NEW SOURCE MATRIX (POINTER BY GRDDRC)
; * THE RESULTS OF APPLYING THE RULES ARE WRITTEN INTO THE NEW DESTINATION
;   MATRIX (POINTED BY GRDDST).
; * THE RULES ARE THE FOLLOWING, WHERE P1 AND P2 ARE 1 AND 2 RESPECTIVELY,
;   DEAD CELLS ARE REPRESENTED BY 0 AND NP1 AND NP2 DENOTE THE NUMBER OF
;   PLAYER 1 AND PLAYER 2 NEIGHBORS RESPECTIVELY:
;   + SURVIVAL RULES
;     - IF CELL IS P1 AND NP1-NP2 IS 2 OR 3 -> NEW VALUE IS P1
;     - IF CELL IS P1 AND NP1-NP2 IS 1 AND NP1>=2 -> NEW VALUE IS P1
;     - OTHERWISE -> NEW VALUE IS 0
;     - IF CELL IS P2 AND NP2-NP1 IS 2 OR 3 -> NEW VALUE IS P2
;     - IF CELL IS P2 AND NP2-NP1 IS 1 AND NP2>=2 -> NEW VALUE IS P2
;     - OTHERWISE -> NEW VALUE IS 0
;   + BIRTH RULES
;     - THE CELL HAS EXACTLY THREE P1 NEIGHBOURS AND THE NUMBER
;       OF P2 NEIGHBOURS IS DIFFERENT FROM THREE. IN THIS CASE A
;       P1 TOKEN IS BORN IN THE CELL.
;     - THE CELL HAS EXACTLY THREE P2 NEIGHBOURS AND THE NUMBER
;       OF P1 NEIGHBOURS IS DIFFERENT FROM THREE. IN THIS CASE A
;       P2 TOKEN IS BORN IN THE CELL.
;     - THE CELL HAS EXACTLY THREE WHITE AND THREE BLACK NEIGHBOURS.
;       IN THIS CASE AN UNBIASED COIN DETERMINES WHETHER A WHITE OR
;       BLACK TOKEN IS BORN IN THE CELL.

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
