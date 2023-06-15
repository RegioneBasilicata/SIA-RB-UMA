CREATE OR REPLACE PACKAGE PACK_MANAGE_SEQUENCE AS

  /******************************************************************************
   NAME:       PACK_MANAGE_SEQUENCE
   PURPOSE:    dati 3 parametri ->
               
               - nome sequence
               - nome colonna PK sulla quale agisce la sequence
               - nome tabella
               
               ripristina la sequence al valore massimo della PK esistente in
               tabella così che il NEXTVAL sia una PK non utilizzata.

               N.B. se la procedura deve agire sugli oggetti di un altro USER,
                    bisogna ricordarsi di valorizzare USER.seqName e USER.tableName
                    come parametri passati.

   ******************************************************************************/
   
PROCEDURE resetThisSequence(PseqName IN VARCHAR2,
                           PPKcolumn IN VARCHAR2,
                           PtableName IN VARCHAR2);                          
END;
/


CREATE OR REPLACE PACKAGE BODY PACK_MANAGE_SEQUENCE AS

    msgErr VARCHAR2(1000);
    
    PROCEDURE resetThisSequence(PseqName IN VARCHAR2,
                                PPKcolumn IN VARCHAR2,
                                PtableName IN VARCHAR2) IS

      Ntmp   NUMBER;
      NPKval NUMBER;

    BEGIN
        --  recupero l'ultimo valore della PK della tabella
    --    EXECUTE IMMEDIATE 'SELECT NVL(MAX(' || PPKcolumn || '),0) FROM ' || PtableName INTO NPKval;
        -- 
        -- 1) calcolo l'indice di decremento: differenza tra max i
        EXECUTE IMMEDIATE 'SELECT ((SELECT NVL(MAX(' || PPKcolumn || '),0) FROM ' || PtableName || ') ' ||
        '- (' || PseqName || '.NEXTVAL)) FROM DUAL' INTO Ntmp;
          
        -- solo se ho sfasati sequence e max..
        IF Ntmp != 0 THEN                     
                   
            -- 2) alter sequence con indice di decremento
            EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || PseqName || ' MINVALUE -1 INCREMENT BY ' || TO_CHAR(Ntmp);           
            
            -- 3) decremento sequence
            EXECUTE IMMEDIATE 'SELECT ' || PseqName || '.NEXTVAL FROM ' || 'DUAL' INTO Ntmp;
               
        --     se non ho record o comunque la mia PK ha valore 0.. reset a MINVALUE = 0 e riparto con il NEXTVAL = 1 ...
        --     IF NPKval <= 0 THEN  
        --        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || PseqName || ' MINVALUE 0';
        --     END IF;   
            
            -- 4) alter per riportare la sequence a indice incremento normale
            EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || PseqName || ' MINVALUE 0 INCREMENT BY 1';
        END IF;        

    --EXCEPTION
    --    WHEN OTHERS THEN
    --        msgErr := SQLERRM; --> da gestire...
            
    END resetThisSequence;                                                                  

END PACK_MANAGE_SEQUENCE;
/
