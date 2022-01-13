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
;Inicia la matriz
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
            MOVEM.L D0-D4/A0,-(A7)
            CLR.L D0
            CLR.L D2
            CLR.L D1
;COMPROBAMOS SI SE HA PULSADO EL MOUSE
            MOVE.B (MOUVAL),D3
            CMP.B #0,D3
            BEQ .FINAL
 ;COMPROBAMOS SI EL MOUSE ESTA DENTRO DE LA MATRIZ          
            MOVE.W (MOUX),D1
            CMP.W #GRDXOFF,D1 ;SI ESTA EN LAS X
            BLE .FINAL
            SUB.W #GRDXOFF,D1 ;POSICION RELATIVA A LA MATRIZ(X)
            CMP.W #GRDPXWID,D1
            BGE .FINAL
           
            MOVE.W (MOUY),D2   
            CMP.W #GRDYOFF,D2  
            BLE .FINAL
            SUB.W #GRDYOFF,D2  ;POSICION RELATIVA A LA MATRIZ (Y)
            CMP.W #GRDPXHEI,D2
            BGE .FINAL
            
           
            DIVS.W #GRDSZCEL,D1
            DIVS.W #GRDSZCEL,D2
            MOVE.L (GRDDST), A0
            MOVE.W D2,D0
            MULS.W #GRDWIDTH,D0
            ADD.W D1,D0
            AND.B #MOUMSKLF,D3
            BEQ .R_GRID
            MOVE.B D1,D4
            DIVS.W #GRDWIDTH/2,D4
            ADDQ.B #1,D4
            MOVE.B D4,(A0,D0)
        
            CMP.B #1,D4 ;LADO IZQUIERDO
            BNE .P2
            ADD.W #1,(GRDNPLR1) ;MARCADOR P3
            JMP .FINAL
.P2         
            CMP.B #2,D4 ;LADO DERECHO
            BNE .FINAL
            ADD.W #1,(GRDNPLR2) ;MARCADOR P2
            JMP .FINAL

;BOTON DERECHO EN LA CASILLA           
.R_GRID:    CLR.B (A0,D0)

.FINAL:   MOVEM.L (A7)+,D0-D4/A0
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

;D0:CONTENIDO CASILLA, D1:PUNTERO CASILLA, D2:FILA, D3:COLUMNA ,
;D4:FILA VECINO, D5:COLUMNA VECINO Y CONTENIDO VECINO, D6:NP1,
;D7:NP2

      
            
    MOVEM.L D0-D7/A0-A1, -(A7)
    
    ;AUMENTAMOS EL NUMERO DE GENERACIONES
    ADDQ.W #1,(GRDNGEN)
    
    ;SWITCH MATRIX POINTERS    
    MOVE.L  (GRDSRC), A0
    MOVE.L  (GRDDST), A1
    MOVE.L  A0, (GRDDST)
    MOVE.L  A1, (GRDSRC)
    
    CLR.L D1        ;INDICE DE LA MATRIZ
    

.BUCLE_PRINCIPAL:
    
    MOVE.W D1,D2
    MOVE.W D1,D3
    LSR.W #GRDSHWID,D2     ;OBTENEMOS FILAS
    AND.W #GRDMSWID,D3     ;OBTENEMOS COLUMNAS
    
;GUARDAMOS COORDENADAS DE LA CASILLA
    MOVE.W D2,D4           
    MOVE.W D3,D5           
    
;------------VECINO ARRIBA-------------------
    CLR.W D6
    CLR.W D7
    
    SUBQ.W #1,D4    ;VECINO ARRIBA
    AND.W #GRDMSHEI,D4    ;MODULO
    LSL.W #GRDSHWID,D4
    ADD.W D5,D4           ;OBTENGO INDICE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5       ;VALOR CELDA VECINO  
    ;AUMENTAMOS NP1 O NP2 
    CMP.W #1,D5
    BNE .P2_1
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .DOWN
    
.P2_1

    CMP.W #2,D5
    BNE .DOWN
    ADD.W #1,D7             ;AUMENTO NP2

;---------------VECINO ABAJO---------------------      
.DOWN

    MOVE.W D2,D4
    MOVE.W D3,D5
    
    ADDQ.W #1,D4       ;VECINO ABAJO
    AND.W #GRDMSHEI,D4 ;MODULO FILAS VECINO
    LSL.W #GRDSHWID,D4
    ADD.W D5,D4         ;OBTENGO INDICE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5       ;VALOR CELDA VECINO 
;AUMENTO NP1 O NP2    
    CMP.W #1,D5
    BNE .P2_2
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .RIGHT
    
.P2_2

    CMP.W #2,D5
    BNE .RIGHT
    ADD.W #1,D7             ;AUMENTO NP2


;------------VECINO DERECHA-------------------------      
.RIGHT       

    MOVE.W D2,D4
    MOVE.W D3,D5
    
    ADDQ.W #1,D5
    AND.W #GRDMSWID,D5  ;MODULO
    LSL.W #GRDSHWID,D4
    ADD.W D4,D5
    MOVE.L D5,D4           ;INDICE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5       ;VALOR CELDA VECINO EN D5
    
    CMP.W #1,D5
    BNE .P2_4
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .LEFT
    
.P2_4

    CMP.W #2,D5
    BNE .LEFT
    ADD.W #1,D7             ;AUMENTO NP2
    

;-----------VECINO IZQUIERDA--------------       
.LEFT       
    
    MOVE.W D2,D4
    MOVE.W D3,D5

    
    SUBQ.W #1,D5         ;RESTO COLUMNA PARA VECINO IZQUIERDA
    AND.W #GRDMSWID,D5   ;MODULO
    LSL.W #GRDSHWID,D4
    ADD.W D4,D5
    MOVE.L D5,D4          ;OBTENGO INDICE DE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5     ;VALOR CELDA VECINO EN D5 
;AUMENTAMOS NP1 O NP2    
    CMP.W #1,D5
    BNE .P2_3
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .UPR
    
.P2_3

    CMP.W #2,D5
    BNE .UPR
    ADD.W #1,D7             ;AUMENTO NP2
    
;--------------VECINO ARRIBA DERECHO------------------       
.UPR

    MOVE.W D2,D4
    MOVE.W D3,D5

    ADDQ.W #1,D5
    SUBQ.W #1,D4
    ;MODULOS FILAS Y COLUMNAS VECINO
    AND.W #GRDMSWID,D5
    AND.W #GRDMSHEI,D4
    LSL.W #GRDSHWID,D4
    ADD.W D4,D5
    MOVE.L D5,D4            ;INDICE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5       ;VALOR CELDA VECINO EN D5
    
    CMP.W #1,D5
    BNE .P2_6
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .UPL
    
.P2_6

    CMP.W #2,D5
    BNE .UPL
    ADD.W #1,D7             ;AUMENTO NP2

;-------------VECINO ARRIBA IZQUIERDA---------------       
.UPL

    MOVE.W D2,D4
    MOVE.W D3,D5

    SUBQ.W #1,D5
    SUBQ.W #1,D4
    ;MODULOS FILAS Y COLUMNAS
    AND.W #GRDMSWID,D5
    AND.W #GRDMSHEI,D4
    LSL.W #GRDSHWID,D4
    ADD.W D4,D5
    MOVE.L D5,D4            ;INDICE A CELDA VECINO
    CLR.W D5
    MOVE.B (A1,D4),D5       ;VALOR CELDA VECINO EN D5
    
    CMP.W #1,D5
    BNE .P2_5
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .DOWNL
    
.P2_5

    CMP.W #2,D5
    BNE .DOWNL
    ADD.W #1,D7             ;AUMENTO NP2



;-------------VECINO ABAJO IZQUIERDA-----------------
.DOWNL 

    MOVE.W D2,D4
    MOVE.W D3,D5

    ;OBTENEMOS FILAS Y COLUMNAS VECINO
    SUBQ.W #1,D5
    ADDQ.W #1,D4
    ;MODULOS FILAS Y COLUMNAS VECINO
    AND.W #GRDMSWID,D5
    AND.W #GRDMSHEI,D4
    LSL.W #GRDSHWID,D4
    ADD.W D4,D5
    MOVE.L D5,D4            ;INDICE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5       ;VALOR CELDA VECINO EN D5
    
    CMP.W #1,D5
    BNE .P2_7
    ADD.W #1,D6             ;AUMENTO NP1
    JMP .DOWNR
    
.P2_7

    CMP.W #2,D5
    BNE .DOWNR
    ADD.W #1,D7             ;AUMENTO NP2

;----------------VECINO ABAJO DERECHA---------------------    
.DOWNR    

    MOVE.W D2,D4
    MOVE.W D3,D5

    
    ADDQ.W #1,D5
    ADDQ.W #1,D4
    ;MODULOS DE FILAS Y COLUMNAS
    AND.W #GRDMSWID,D5
    AND.W #GRDMSHEI,D4
    LSL.W #GRDSHWID,D4
    ADD.W D4,D5
    MOVE.L D5,D4 ;INDICE VECINO EN D4
    CLR.W D5
    MOVE.B (A1,D4),D5   ;VALOR DEL VECINO EN D5    
    
    CMP.W #1,D5
    BNE .P2_8
    ADD.W #1,D6          ;AUMENTAMOS NP1   
    JMP .P1_P2
    
.P2_8

    CMP.W #2,D5
    BNE .P1_P2
    ADD.W #1,D7      ;AUMENTAMOS NP2       
    

;--------------RULES-------------------------------- 
;COMPROBAMOS SI LA CELULA ES 1, 2 O VACIA 
;Y SALTAMOS A SUS NORMAS ESPECIFICAS  
.P1_P2:
    MOVE.B (A1,D1),D0
    CMP #1,D0
    BEQ .SURVIVAL1
    CMP #2,D0
    BEQ .SURVIVAL2
    BNE .BIRTH
 

;----------SURVIVAL RULES---------------------------
;SURVIVAL RULES SI LA CELULA ES 1

.SURVIVAL1:

    MOVE.W D6,D0
    SUB.W D7,D0
    ;RESTA NP1-NP2 EN D0
    CMP.W #2,D0
    BNE .A_1   ; SALTAMOS PARA MIRAR SI LA RESTA VALE 3
    JMP .MOVEMOS_1
    
.A_1

    CMP.W #3,D0
    BNE .CONDICION2_1
    JMP .MOVEMOS_1
    
.CONDICION2_1 ;SEGUNDA CONDICION

    CMP.W #1,D0 ;SI VALE 1 SALTAMOS A MIRAR NP1>=2
    BEQ .B_1
    JMP .MOVEMOS_0
    
.B_1:

    CMP #2,D6
    BGE .MOVEMOS_1
    JMP .MOVEMOS_0   


;SURVIVAL RULES SI LA CELULA ES 2
.SURVIVAL2:
    MOVE.W D7,D0
    SUB.W D6,D0  ;NP2-NP1 EN D0
    ;CONDICION 1
    CMP.W #2,D0
    BNE .A_2
    JMP .MOVEMOS_2
    ;MIRAMOS SI VALE 2
.A_2

    CMP.W #3,D0
    BNE .CONDICION2_2
    JMP .MOVEMOS_2
    
    ;CONDICION 2
.CONDICION2_2:

    CMP.W #1,D0
    BEQ .B_2
    JMP .MOVEMOS_0
    ;MIRAMOS SI TAMBIEN VALE 2
.B_2:

    CMP #2,D7
    BGE .MOVEMOS_2
    JMP .MOVEMOS_0


 
;----------------BIRTH RULES----------------------------------  
.BIRTH:

    CMP #3,D6
    BEQ .COMPRUEBA_P1
    JMP .COND_2
    
.COMPRUEBA_P1:

    CMP #3,D7
    BNE .MOVEMOS_1
    JMP .COND_2    
.COND_2

    CMP #3,D7
    BEQ .COMPRUEBA_P2
    JMP .COND_3

.COMPRUEBA_P2

    CMP #3,D6
    BEQ .COND_3
    JMP .MOVEMOS_2
    
.COND_3
    CMP #3,D6
    BNE .MOVEMOS_0
    CMP #3,D7
    BNE .MOVEMOS_0
    MOVE.L D1,D2  ;GUARDAMOS D1, POREQUE UTLRAND LO MODIFICA
    JSR UTLRAND
    MOVE.B D1,(A0,D2)
    MOVE.W D2,D1  ;RECUPERAMOS D1
    
;---------ETIQUETAS PARA MOVER VALORES--------------------- 
.MOVEMOS_1:
    
    MOVE.B #1,(A0,D1)
    JMP .FINAL   
.MOVEMOS_2:

    MOVE.B #2,(A0,D1)
    JMP .FINAL
    
.MOVEMOS_0:
    
    MOVE.B #0,(A0,D1)
    JMP .FINAL
    
.FINAL:

    ADDQ.W #1,D1
    CMP.W #GRDHEIGH*GRDWIDTH,D1    
    BNE .BUCLE_PRINCIPAL
    MOVEM.L (A7)+, D0-D7/A0-A1

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
            LEA GRDDST, A0                  ; A0: POINTER TO THE DATA TO WRITE
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
            LEA GRDDST, A0                  ; POINTER TO STORE PROCESS. DATA
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
            LEA GRDDST, A0                  ; POINTER TO STORE PROCESS. DATA
            MOVE.W  #GRDHEIGH-1,D3
.LOOP       MOVE.L  A6,A1
            MOVE.B  #53,D0                  ; READ DATA TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            MOVE.W  #GRDWIDTH-1,D2
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
            
            CMP.B #2,D0                     ;SI LEE UN 2 PONE UN 0 Y CONTINUA
            BNE .SIGUIENTE
            MOVE.B #0,(A0)+
            JMP .CLEAR
.SIGUIENTE            
            MOVE.B  D0,(A0)+                ; STORE DATA
.CLEAR            
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            MOVEM.L (A7)+,D0-D7/A0-A6       ; TO BE OPTIMIZED
            RTS
.MSG        DC.B    'SELECT A CSV FILE LEFT TO LOAD',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0













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
            LEA GRDDST, A0                  ; POINTER TO STORE PROCESS. DATA
            MOVE.W  #GRDHEIGH-1,D3
.LOOP       MOVE.L  A6,A1
            MOVE.B  #53,D0                  ; READ DATA TASK NUMBER
            MOVE.L  #GRDWIDTH*2+1,D2        ; NUMBER OF BYTES TO READ
            TRAP    #15                     ; READ THE DATA
            MOVE.W  #GRDWIDTH-1,D2
.COPY       MOVE.B  (A1)+,D0                ; PICK ONE LOADED CHARACTER
            SUB.B   #'0',D0                 ; CONVERT FROM ASCII TO NUMBER
           
            CMP.B #1,D0                     ;SI LEE UN 1 PONE UN 0 Y CONTINUA
            BNE .SIGUIENTE
            MOVE.B #0,(A0)+
            JMP .CLEAR
.SIGUIENTE            
            MOVE.B  D0,(A0)+                ; STORE DATA
.CLEAR            
            ADDQ.L  #1,A1                   ; SKIP THE COMMA
            DBRA.W  D2,.COPY
            DBRA.W  D3,.LOOP
            MOVE.B  #56,D0                  ; CLOSE FILE
            TRAP    #15
.END        ADD.L   #512,A7                 ; RESTORE STACK
            MOVEM.L (A7)+,D0-D7/A0-A6       ; TO BE OPTIMIZED
            RTS
.MSG        DC.B    'SELECT A CSV FILE LEFT TO LOAD',0
.FILTER     DC.B    '*.CSV',0
            DS.W    0

; -----------------------------------------------------------------------------
GRDPLOT
; PLOTS THE GRID
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE

   MOVEM.L D0-D6/A0-A3, -(A7)
    
    MOVE.L (GRDDST), A0            ; A0: POINTER TO THE DATA TO READ
    LEA GRDNPLR1, A1
    LEA GRDNPLR2, A2
    CLR.W (A1)
    CLR.W (A2)
    
    
    ;LAPIZ VERDE
    MOVE.B #80,D0
    MOVE.L #CLRDKGRN,D1
    TRAP #15

  
    ;ANCHO DEL LAPIZ
    MOVE.B #93,D0
    MOVE.B #2,D1
    TRAP #15
    
    ;PINTA
    
    MOVE.W  #GRDHEIGH,D5          ; NUMBER OF ROWS
    MOVE.W  #GRDWIDTH,D6          ; NUMBER OF COLUMNS
    
    MOVE.W #GRDYOFF,D2
.FILAS
    ;PINTAMOS LAS FILAS DE LA MATRIZ
    MOVE.B #84,D0
    MOVE.W #GRDXOFF,D1
    MOVE.W #GRDPXWID,D3
    ADD.W #GRDXOFF,D3
    MOVE.W D2,D4
    TRAP #15
    
    ADD.W #GRDSZCEL,D2
    
    DBRA D5,.FILAS
    
    MOVE.W #GRDXOFF,D1
.COLUMNAS
    ;PINTAMOS LAS COLUMNAS DE LA MATRIZ    
    MOVE.B #84,D0
    MOVE.W #GRDYOFF,D2
    MOVE.W D1,D3
    MOVE.W #GRDPXHEI,D4
    ADD.W #GRDYOFF,D4
    TRAP #15
    
    ADD.W #GRDSZCEL,D1
    
    DBRA D6,.COLUMNAS
    
    
    ;PAINT P1 AND P2 CELLS
        
    MOVE.W  #GRDHEIGH,D5          ; NUMERO DE FILAS 
    SUBQ.W #1,D5
    
    MOVE.W  #GRDWIDTH,D6          ; NUMERO DE COLUMNAS
    SUBQ.W #1,D6
    
    
    
    MOVE.W #GRDXOFF, D3
    MOVE.W #GRDYOFF, D2
    
    
.FILA:
    
    MOVE.B (A0)+,D7
   
    ;PAINT RECTANGLE PLAYER 1
    ;FILL COLOR
    MOVE.B #81,D0
    MOVE.L #CLRBLACK,D1
    TRAP #15
    
    ;JUGADOR 1
    CMP #1,D7
    BEQ .JUGADOR1
    ;JUGADOR 2
    CMP #2,D7
    BEQ .JUGADOR2
    ;NO PLAYER
   
    ADD.W #GRDSZCEL,D3
    ADD.W #GRDSZCEL,D4
        
.LOOP_PLAYER:  

    
    DBRA D6, .FILA
    
    MOVE.W #GRDXOFF,D3
    ADD.W #GRDSZCEL,D2
    
    MOVE.W  #GRDWIDTH,D6          ; NUMERO DE COLUMNAS
    SUBQ.W #1,D6
    
    DBRA D5, .FILA
    JMP .FINAL

.JUGADOR1:


    ;PAINT RECTANGLE PLAYER 1
    ;FILL COLOR
    MOVE.B #81,D0
    MOVE.L #CLRLTBLU,D1
    TRAP #15
    
    ;RECTANGLE
    MOVE.B #87,D0
    MOVE.W D3,D1
    MOVE.W D2,D4
    
    ADD.W #GRDSZCEL,D3
    ADD.W #GRDSZCEL,D4
    TRAP #15
    
    ADDQ.W #1, (A1)
    JMP .LOOP_PLAYER


.JUGADOR2:


    ;PAINT RECTANGLE PLAYER 2
    ;FILL COLOR
    MOVE.B #81,D0
    MOVE.L #CLRLTRED,D1
    TRAP #15
    
    
    ;RECTANGULO
    MOVE.B #87,D0
    MOVE.W D3,D1
    MOVE.W D2,D4
    

    ADD.W #GRDSZCEL,D3
    ADD.W #GRDSZCEL,D4
    
    TRAP #15
    
    ADDQ.W #1, (A2)
    
    JMP .BUCLE_JUGADORES
 
          
.FINAL:

    MOVE.W (GRDNPLR1),D3
    MOVE.W (GRDNPLR2),D4
    
    CMP.W D3,D4
    BLT .P1_WINS
    BGT .P2_WINS
    BEQ .SAME
    
    
.SAME

    MOVE.B #81,D0
    MOVE.L #CLRLTRED,D1
    TRAP #15    
    
    CLR D1
    
    MOVE.B #11,D0
    MOVE.W #GRDSCP2X<<8|GRDSCP2Y-1,D1
    TRAP #15

    MOVE.B #6,D0
    MOVE.B #42,D1
    TRAP #15
    
    MOVE.B #81,D0
    MOVE.L #CLRLTBLU,D1
    TRAP #15       
    
    CLR D1
    
    MOVE.B #11,D0
    MOVE.W #GRDSCP1X<<8|GRDSCP1Y-1,D1
    TRAP #15    
    
    MOVE.B #6,D0
    MOVE.B #42,D1
    TRAP #15
    
    JMP .SCORES        
    
.P2_WINS
    
    MOVE.B #81,D0
    MOVE.L #CLRLTRED,D1
    TRAP #15    
    
    MOVE.B #11,D0
    MOVE.W #GRDSCP2X<<8|GRDSCP2Y-1,D1
    TRAP #15
    
    MOVE.B #6,D0
    MOVE.B #42,D1
    TRAP #15
    
    JMP .SCORES
    
.P1_WINS:

    MOVE.B #81,D0
    MOVE.L #CLRLTBLU,D1
    TRAP #15
  
    MOVE.B #11,D0
    MOVE.W #GRDSCP1X<<8|GRDSCP1Y-1,D1
    TRAP #15
    
    MOVE.B #6,D0
    MOVE.B #42,D1
    TRAP #15
    
.SCORES:    
    ;SCORES
    ;SCORE PLAYER 1
    MOVE.B #81,D0
    MOVE.L #CLRLTBLU,D1
    TRAP #15
    
    CLR D1
    
    MOVE.B #11,D0
    MOVE.W #GRDSCP1X<<8|GRDSCP1Y,D1
    TRAP #15
    
    
    MOVE.B #3,D0     
    LEA GRDNPLR1,A1
    MOVE.W (A1),D2
    MOVE.L D2,D1
    TRAP #15
    
    
    ;SCORE PLAYER 2
    MOVE.B #81,D0
    MOVE.L #CLRLTRED,D1
    TRAP #15
    
    CLR D1
    
    MOVE.B #11,D0
    MOVE.W #GRDSCP2X<<8|GRDSCP2Y,D1
    TRAP #15
    
    MOVE.B #3,D0     
    LEA GRDNPLR2,A1
    MOVE.W (A1),D2
    MOVE.L D2,D1
    TRAP #15
   
    ;SCORE GENERATIONS
    MOVE.B #81,D0
    MOVE.L #CLRLTGRN,D1
    TRAP #15
    
    
    MOVE.B #11,D0
    MOVE.W #GRDSCNGX<<8|GRDSCNGY,D1
    TRAP #15
    
    
    MOVE.B #3,D0     
    LEA GRDNGEN,A1
    MOVE.W (A1),D2
    MOVE.L D2,D1
    TRAP #15

    MOVEM.L  (A7)+, D0-D6/A0-A3
    RTS

 
 
 
 






























*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
