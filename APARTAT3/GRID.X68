; =============================================================================
; TITLE    : GRID MANAGEMENT
; AUTHOR   : ANTONI BURGUERA
; HISTORY  : 05-JULY-2021 - CREATION
; COMMENTS : * THERE ARE TWO MATRICES (GRDMATR0 AND GRDMATR1) AND TWO POINTERS
;              TO THESE MATRICES (GRDSRC AND GRDDST).
;
;            * THE MATRIX TO BE PLOTTED IS ALWAYS THE ONE POINTED BY GRDDST.
;
;            * THE MATRIX TO BE UPDATED BY THE MOUSE (GRDMUPD) IS ALWAYS THE
;              ONE POINTED BY GRDDST.
;
;            * THE RULES-UPDATE (GRDRUPD) SWITCHES THE POINTERS AND THEN READS
;              THE NEW SOURCE MATRIX (GRDSRC) TO DETERMINE THE NUMBER OF
;              NEIGHBORS. THE RESULTING CELL VALUE IS WRITTEN TO THE DESTINA-
;              TION MATRIX, POINTED BY GRDDST.
; =============================================================================

; -----------------------------------------------------------------------------
GRDINIT
; INITIALIZE THE GRID AS FOLLOWS:
; * POINTS THE SOURCE GRID POINTER TO GRDMATR0.
; * POINTS THE DESTINATION GRID POINTER TO GRDMATR1.
; * RESETS THE COUNTERS (GRDNPLR1, GRDNPLR2, GRDNGEN).
; * FILLS THE TWO MATRICES (GRDMATR0 AND GRDMATR1) WITH ZEROS.
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------
            MOVEM.L A0/D0,-(A7)
            MOVE.L  #GRDMATR0,(GRDSRC)
            MOVE.L  #GRDMATR1,(GRDDST)
            CLR.W   (GRDNPLR1)
            CLR.W   (GRDNPLR2)
            CLR.W   (GRDNGEN)
            LEA     GRDMATR0,A0
            MOVE.W  #GRDWIDTH*GRDHEIGH*2-1,D0
.LOOP       CLR.B   (A0)+
            DBRA.W  D0,.LOOP
            MOVEM.L (A7)+,A0/D0
            RTS

; -----------------------------------------------------------------------------
GRDMUPD
; GRID UPDATE USING MOUSE. THE INTERFACE IS AS FOLLOWS:
; * IF MOUSE IS NOT PRESSED OR IS OUTSIDE THE PLOTTED GRID, DOES NOTHING.
; * IF LEFT MOUSE BUTTON IS PRESSED INSIDE THE GRID:
;   - A PLAYER 1 (VALUE=1) CELL IS CREATED AT THE MOUSE POSITION IF THE MOUSE
;     IS ON THE LEFT HALF OF THE GRID.
;   - A PLAYER 2 (VALUE=2) CELL IS CREATED AT THE MOUSE POSITION IF THE MOUSE
;     IS ON THE RIGHT HALF OF THE GRID.
; * IF RIGHT MOUSE BUTTON IS PRESSED INSIDE THE GRID, THE CELL WHERE THE MOUSE
;   IS IS CLEARED (VALUE=0).
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE
;D0:X ->COLUMNA , D1:Y->FILA , D2:MOUVAL, D3:NUM CASILLA
            MOVEM.L D0-D3/A0,-(A7)
            MOVE.W (MOUX),D0
            MOVE.W (MOUY),D1
 ;COMPROBAMOS SI EL MOUSE ESTA DENTRO DE LA MATRIZ          
            CMP.W #GRDXOFF,D0
            BLE  .FINAL        ; MOUSE ESTA EN EL MARGEN IZQUIERDO
            SUB.W #GRDXOFF,D0 
            CMP.W #GRDPXWID,D0
            BLE IN_X
            JMP .FINAL         ; NO ESTA EN LOS MARGENES X DE LA MATRIZ

IN_X:       CMP.W #GRDYOFF,D1
            BLE .FINAL
            SUB.W #GRDYOFF,D1
            CMP.W #GRDPXHEI,D1
            BLE IN_GRID
 
IN_GRID:    
            MOVE.W GRDDST,A0
            DIVS.W #GRDSZCEL,D0 ;MIRAMOS COLUMNA EN D0
            DIVS.W #GRDSZCEL,D1   ;MIRAMOS FILA EN D1 
            MOVE.B (MOUVAL),D2 ;VLOR DEL MOUSE A D2
            AND.B #MOUMSKRT,D2 ;MASCARA PARA CLICK DERECHO
            BNE RT_GRID
            BTST.B #MOUMSKLF,D2 ;MASCARA PARA CLICK IZQUIERDO
            BNE LF_GRID
            JMP .FINAL       ; NO BUTTON PRESSED
            
RT_GRID:   ;BORRAR CASILLA
            CMP.W #31,D0
            BLE BP1 ;MITAD IZQUIERDA
;OBTENEMOS EN D3 EL PUNTERO A LA CASILLA (FIILA*64+COLUMNA)
            MOVE.W D1,D3
            MULS.W #GRDWIDTH,D3
            ADD.W D0,D3
            MOVE.B #2,D3(A0) ;MOVEMOS EL VALOR A LA CASILLA
            JMP .FINAL

BP1:        MOVE.W D1,D3
            MULS.W #GRDWIDTH,D3
            ADD.W D0,D3
            MOVE.B #1,D3(A0)
            JMP .FINAL
LF_GRID:   ;PINTAR CASILLA 
            MOVE.W D1,D3
            MULS.W #GRDWIDTH,D3
            ADD.W D0,D3
            MOVE.B #0,D3(A0)
            

.FINAL:   MOVEM.L (A7)+,D0-D3/A0
          RTS










; -----------------------------------------------------------------------------
GRDRUPD
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
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE
;D0:NUMERO DE CASILLAS, D1:CONTADOR ITERACIONES, D2:CELL VALUE, D3:NP1 ,D4:NP2, D5:EXTRA FOR NEIGHBOURS
        MOVEM.L D0-D3/A0,-(A7)
        
        ADDQ.W #1,GRDNGEN ;ADD 1 TO THE NUMBER OF GENERATIONS
        MOVE.L (GRDDST),A0 ;SWITCH MATRIX POINTERS
        MOVE.L (GRDSRC),GRDDST
        MOVE.L (A0),GRDSRC
;MIRAMOS LAS CASILLAS QUE NACEN O SOBREVIVEN
        MOVE.W #0,D1
        MOVE.L (GRDSRC),A0
        MOVE.L (GRDDST),A1
        MOVE.W #64,D0
        MULU.W #32,D0
        SUBQ.W #1,D0 ;NUMBER OF ITERATIONS
;LOOP THAT CHECKS THE CELL VALUE
.MLOOP: MOVE.W D1(A0),D2 
        JMP .NEIGHBOURS       
.CELL:  CMP.W #0,D2
        BEQ .BIRTH
        JMP .SURVIVAL

.SURVIVAL: 
        
      
.BIRTH: 
 
        DBRA D0,.MLOOP
        JMP .FINAL
        
.NEIGHBOURS: 
        LEA MOVIMIENTOS,A1
.NLOOP: ;VECINA DERECHA
        MOVE.W 1,D5
        ADDQ.W D1,D5
        



.FINAL:
        MOVEM.L (A7)+,D0-D3/A0
        RTS



; -----------------------------------------------------------------------------
GRDSAVE
; SAVES THE GRID INTO A FILE IN CSV FORMAT
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; -----------------------------------------------------------------------------
            MOVEM.L D0-D7/A0-A6,-(A7)       ; TO BE OPTIMIZED
            MOVE.B  #50,D0                  ; CLOSE ALL FILES (RECOMMENDED)
            TRAP    #15
            SUB.L   #512,A7                 ; ROW BUFFER IN LOCAL MEMORY
            MOVE.B  #58,D0                  ; SHOW FILE DIALOG TASK
            MOVE.L  #1,D1                   ; DISPLAY SAVE DIALOG
            LEA     .MSG,A1                 ; STANDARD MESSAGE
            LEA     .FILTER,A2              ; NO FILTER
            MOVE.L  A7,A3                   ; FILE NAME BUFFER
            CLR.W   (A3)                    ; ENSURE THERE IS NO STRING
            TRAP    #15
            TST.B   D1
            BEQ     .END                    ; IF CANCELLED, DO NOTHING
            MOVE.L  A3,A1                   ; PLACE THE FILENAME INTO A1
            MOVE.B  #52,D0                  ; CREATE NEW FILE
            TRAP    #15
            TST.W   D0                      ; CHECK CREATION ERROR
            BNE     .END                    ; DO NOTHING MORE IF ERROR
            MOVE.L  A7,A6                   ; PUT A6 INTO START OF BUFFER
            MOVE.L  A7,A1                   ; PUT A1 INTO START OF BUFFER
            MOVE.L  (GRDDST), A0            ; A0: POINTER TO THE DATA TO WRITE
            MOVE.W  #GRDHEIGH-1,D3          ; D3: NUMBER OF ROWS - 1
.LOOPY      MOVE.W  #GRDWIDTH-1,D2          ; D2: NUMBER OF COLUMNS - 1
.LOOP       MOVE.B  #'0',D0                 ; ADD CHAR '0' AND THE CELL VALUE
            ADD.B   (A0)+,D0
            MOVE.B  D0, (A6)+               ; STORE IT IN THE BUFFER
            MOVE.B  #',',(A6)+              ; NOW PUT THE COMMA
            DBRA.W  D2,.LOOP
            MOVE.B  #$0D,-1(A6)             ; STORE CARRIAGE RETURN (REMOVE ',')
            MOVE.B  #$0A,(A6)               ; STORE LINE FEED
            MOVE.B  #54,D0                  ; WRITE TO FILE TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO WRITE
            TRAP    #15                     ; WRITE (A1 IS ALREADY THERE)
            MOVE.L  A1,A6                   ; GO BACK TO THE BUFFER START
            DBRA.W  D3,.LOOPY
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            MOVEM.L (A7)+,D0-D7/A0-A6       ; TO BE OPTIMIZED
            RTS
.MSG        DC.B    'SELECT A CSV FILE TO SAVE',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDLOAD
; LOADS THE GRID FROM A CSV FORMATTED FILE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; -----------------------------------------------------------------------------
            MOVEM.L D0-D7/A0-A6,-(A7)       ; TO BE OPTIMIZED
            MOVE.B  #50,D0                  ; CLOSE ALL FILES (RECOMMENDED)
            TRAP    #15
            SUB.L   #512,A7                 ; ROW BUFFER IN LOCAL MEMORY
            MOVE.B  #58,D0                  ; SHOW FILE DIALOG TASK
            CLR.L   D1                      ; DISPLAY LOAD DIALOG
            LEA     .MSG,A1                 ; STANDARD MESSAGE
            LEA     .FILTER,A2              ; NO FILTER
            MOVE.L  A7,A3                   ; FILE NAME BUFFER
            CLR.W   (A3)                    ; ENSURE THERE IS NO STRING
            TRAP    #15
            TST.B   D1
            BEQ     .END                    ; IF CANCELLED, DO NOTHING
            MOVE.L  A3,A1                   ; PLACE THE FILENAME INTO A1
            MOVE.B  #51,D0                  ; OPEN EXISTING FILE
            TRAP    #15
            TST.W   D0                      ; CHECK ERRORS
            BNE     .END                    ; IF ERRORS, DO NOTHING MORE
            MOVE.L  A7,A6                   ; PUT A6 INTO START OF BUFFER
            MOVE.L  A7,A1                   ; PUT A1 INTO START OF BUFFER
            MOVE.L  (GRDDST), A0            ; POINTER TO STORE PROCESS. DATA
            MOVE.W  #GRDHEIGH-1,D3
.LOOP       MOVE.L  A6,A1
            MOVE.B  #53,D0                  ; READ DATA TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            MOVE.W  #GRDWIDTH-1,D2
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
            MOVE.B  D0,(A0)+                ; STORE DATA
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            MOVEM.L (A7)+,D0-D7/A0-A6       ; TO BE OPTIMIZED
            RTS
.MSG        DC.B    'SELECT A CSV FILE TO LOAD',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDLLEFT
; LOADS THE LEFT PART OF THE GRID FROM A CSV FORMATTED FILE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; NOTE     : ALL THE ACTIVE CELLS ARE STORED AS PLAYER 1 INDEPENDLY OF THEIR
;            ACTUAL VALUE.
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE












; -----------------------------------------------------------------------------
GRDLRGT
; LOADS THE RIGHT PART OF THE GRID FROM A CSV FORMATTED FILE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; NOTE     : THE LOCAL BUFFER SIZE MUST BE MAX(512,2*GRDWIDTH+1). PLEASE CHANGE
;            IT ACCORDINGLY IF GRDWIDTH*2+1 IS LARGER THAN 512.
; NOTE     : ALL THE ACTIVE CELLS ARE STORED AS PLAYER 2 INDEPENDLY OF THEIR
;            ACTUAL VALUE.
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE











; -----------------------------------------------------------------------------
GRDPLOT
; PLOTS THE GRID
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
