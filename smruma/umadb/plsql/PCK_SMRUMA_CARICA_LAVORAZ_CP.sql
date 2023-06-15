CREATE OR REPLACE PACKAGE PCK_SMRUMA_CARICA_LAVORAZ_CP IS
  /*
  Effettua il caricamento delle lavorazioni conto proprio
  */
  PROCEDURE Main(pIdDittaUma      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                 pIdUtente        DB_LAVORAZIONE_CONTO_PROPRIO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
                 pCodErr      OUT VARCHAR2,
                 pDescErr     OUT VARCHAR2);

  FUNCTION ReturnMotLav(pCodiceMotivoLavorazione  DB_TIPO_MOTIVO_LAVORAZIONE.CODICE_MOTIVO_LAVORAZIONE%TYPE) RETURN NUMBER;
END;
/


CREATE OR REPLACE PACKAGE BODY PCK_SMRUMA_CARICA_LAVORAZ_CP IS

FUNCTION ReturnMotLav(pCodiceMotivoLavorazione  DB_TIPO_MOTIVO_LAVORAZIONE.CODICE_MOTIVO_LAVORAZIONE%TYPE) RETURN NUMBER IS
  nIdMotivoLavorazione  DB_TIPO_MOTIVO_LAVORAZIONE.ID_MOTIVO_LAVORAZIONE%TYPE;
BEGIN
  SELECT ID_MOTIVO_LAVORAZIONE
  INTO   nIdMotivoLavorazione
  FROM   DB_TIPO_MOTIVO_LAVORAZIONE
  WHERE  CODICE_MOTIVO_LAVORAZIONE = pCodiceMotivoLavorazione;

  RETURN nIdMotivoLavorazione;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END ReturnMotLav;

PROCEDURE Main(pIdDittaUma      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
               pIdUtente        DB_LAVORAZIONE_CONTO_PROPRIO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
               pCodErr      OUT VARCHAR2,
               pDescErr     OUT VARCHAR2) IS

  TYPE recImp IS RECORD (SupLav          NUMBER,
                         SupLavCollMont  NUMBER,
                         IdMotivLav      DB_TIPO_MOTIVO_LAVORAZIONE.ID_MOTIVO_LAVORAZIONE%TYPE);
                         
  TYPE recLavCTScav IS RECORD(IdCategoriaUtilizzoUma  DB_CATEG_COLTURA_LAVORAZIONI.ID_CATEGORIA_UTILIZZO_UMA%TYPE,
                              IdLavorazioni           DB_CATEG_COLTURA_LAVORAZIONI.ID_LAVORAZIONI%TYPE);

  TYPE tblImp       IS TABLE OF recImp INDEX BY BINARY_INTEGER;
  TYPE tblLavCTScav IS TABLE OF recLavCTScav INDEX BY BINARY_INTEGER;
  
  Imp        tblImp;
  LavCTScav  tblLavCTScav;

  ERRORE                   EXCEPTION;
  nCont                    PLS_INTEGER;
  nSupCollMontSec          NUMBER;
  nContDomAssVal           PLS_INTEGER;
  nSupCollMontPrinc        NUMBER;
  nSupCollMont             NUMBER;
  nSupCompless             NUMBER;
  nSupPrincOld             NUMBER;
  nSupCollMontPrincOld     NUMBER;
  nSupAumento              NUMBER;
  nLast                    PLS_INTEGER;
  nIdCategoriaUtilizzoUma  DB_CATEG_COLTURA_LAVORAZIONI.ID_CATEGORIA_UTILIZZO_UMA%TYPE;
  nIdLavorazioni           DB_CATEG_COLTURA_LAVORAZIONI.ID_LAVORAZIONI%TYPE;
  nContLavCTScav           SIMPLE_INTEGER := 0;
  bInsert                  BOOLEAN := TRUE;
BEGIN
  IF pIdDittaUma IS NULL THEN
    pDescErr := 'Ditta UMA non presente in input';
    RAISE ERRORE;
  END IF;

  IF pIdUtente IS NULL THEN
    pDescErr := 'Utente aggiornamento non presente in input';
    RAISE ERRORE;
  END IF;

  SELECT COUNT(*)
  INTO   nCont
  FROM   DB_LAVORAZIONE_CONTO_PROPRIO LCP
  WHERE  LCP.ID_DITTA_UMA               = pIdDittaUma
  AND    LCP.ANNO_CAMPAGNA              = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
  AND    LCP.DATA_FINE_VALIDITA         IS NULL
  AND    LCP.DATA_CESSAZIONE            IS NULL
  AND    LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL; 

  IF nCont != 0 THEN
    pDescErr := 'Impossibile procedere con il caricamento delle lavorazioni conto proprio per presenza di lavorazioni non consolidate in un''assegnazione carburante. Eliminare le lavorazioni conto proprio non consolidate ed effettuare nuovamente l''importazione dei dati';
    RAISE ERRORE;
  END IF;

  DELETE DB_LAVORAZIONE_CONTO_PROPRIO LCP
  WHERE  LCP.ID_DITTA_UMA               = pIdDittaUma
  AND    LCP.ANNO_CAMPAGNA              = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
  AND    LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL; 

  SELECT COUNT(*)
  INTO   nContDomAssVal
  FROM   DB_DOMANDA_ASSEGNAZIONE DA
  WHERE  DA.ID_DITTA_UMA                     = pIdDittaUma
  AND    TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY') = TO_CHAR(SYSDATE,'YYYY')
  AND    DA.ID_STATO_DOMANDA                 = 30;
  
  -- lavorazioni conto terzi a scavalco
  FOR recLavScav IN (SELECT ID_CATEGORIA_UTILIZZO_UMA,ID_LAVORAZIONI
                     FROM   DB_LAVORAZIONE_CONTOTERZI LC, DB_CAMPAGNA_CONTOTERZISTI CC,DB_DITTA_UMA DU
                     WHERE  CC.ID_CAMPAGNA_CONTOTERZISTI = LC.ID_CAMPAGNA_CONTOTERZISTI
                     AND    CC.ANNO_CAMPAGNA             = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - 1
                     AND    CC.VERSO_LAVORAZIONI         = 'E'
                     AND    DU.ID_DITTA_UMA              = pIdDittaUma
                     AND    LC.EXT_ID_AZIENDA            = DU.EXT_ID_AZIENDA
                     AND    LC.DATA_FINE_VALIDITA        IS NULL
                     AND    LC.DATA_CESSAZIONE           IS NULL
                     AND    LC.LAVORAZIONE_A_SCAVALCO    = 'S') LOOP
                     
    -- Conversione della lavorazione conto terzi dell'anno precedente in una lavorazione conto terzi 
    -- dell'anno in corso 
    BEGIN
      SELECT ID_CATEGORIA_UTILIZZO_UMA,ID_LAVORAZIONI 
      INTO   nIdCategoriaUtilizzoUma,nIdLavorazioni
      FROM   DB_CATEG_COLTURA_LAVORAZIONI CCL
      WHERE  CCL.ID_CATEGORIA_UTILIZZO_UMA    = recLavScav.ID_CATEGORIA_UTILIZZO_UMA
      AND    CCL.ID_LAVORAZIONI               = recLavScav.ID_LAVORAZIONI
      AND    TRUNC(CCL.DATA_INIZIO_VALIDITA) <= TRUNC(SYSDATE)
      AND    (CCL.DATA_FINE_VALIDITA IS NULL OR TRUNC(CCL.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE))
      AND    CCL.ID_TIPO_COLTURA_LAVORAZIONE  = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          SELECT ID_CATEGORIA_UTILIZZO_UMA,ID_LAVORAZIONI 
          INTO   nIdCategoriaUtilizzoUma,nIdLavorazioni
          FROM   DB_R_COLTURA_LAVORAZ_ORIGINE CLO
          WHERE  CLO.ID_CATEGORIA_UTIL_UMA_ORIGINE = recLavScav.ID_CATEGORIA_UTILIZZO_UMA
          AND    CLO.ID_LAVORAZIONI                = recLavScav.ID_LAVORAZIONI
          AND    CLO.ANNO_RIFERIMENTO              = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
          AND    TRUNC(CLO.DATA_INIZIO_VALIDITA)  <= TRUNC(SYSDATE)
          AND    (CLO.DATA_FINE_VALIDITA IS NULL OR TRUNC(CLO.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            nIdCategoriaUtilizzoUma := NULL;
            nIdLavorazioni          := NULL;
        END;
    END;
    
    IF nIdCategoriaUtilizzoUma IS NOT NULL AND nIdLavorazioni IS NOT NULL THEN  
      -- tale coppia esiste come lavorazione conto proprio di default per l'anno in corso
      BEGIN
        SELECT ID_CATEGORIA_UTILIZZO_UMA,ID_LAVORAZIONI 
        INTO   nIdCategoriaUtilizzoUma,nIdLavorazioni
        FROM   DB_CATEG_COLTURA_LAVORAZIONI CCL
        WHERE  CCL.ID_CATEGORIA_UTILIZZO_UMA    = nIdCategoriaUtilizzoUma
        AND    CCL.ID_LAVORAZIONI               = nIdLavorazioni
        AND    TRUNC(CCL.DATA_INIZIO_VALIDITA) <= TRUNC(SYSDATE)
        AND    (CCL.DATA_FINE_VALIDITA IS NULL OR TRUNC(CCL.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE))
        AND    CCL.ID_TIPO_COLTURA_LAVORAZIONE  = 2
        AND    CCL.LAVORAZIONE_DEFAULT          = 'S';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            SELECT ID_CATEGORIA_UTILIZZO_UMA,ID_LAVORAZIONI 
            INTO   nIdCategoriaUtilizzoUma,nIdLavorazioni
            FROM   DB_R_COLTURA_LAVORAZ_ORIGINE CLO
            WHERE  CLO.ID_CATEGORIA_UTIL_UMA_ORIGINE = nIdCategoriaUtilizzoUma
            AND    CLO.ID_LAVORAZIONI                = nIdLavorazioni
            AND    TRUNC(CLO.DATA_INIZIO_VALIDITA)  <= TRUNC(SYSDATE)
            AND    (CLO.DATA_FINE_VALIDITA IS NULL OR TRUNC(CLO.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              nIdCategoriaUtilizzoUma := NULL;
              nIdLavorazioni          := NULL;
          END;
      END;
    
      IF nIdCategoriaUtilizzoUma IS NOT NULL AND nIdLavorazioni IS NOT NULL THEN
        nContLavCTScav                                   := nContLavCTScav + 1;
        LavCTScav(nContLavCTScav).IdCategoriaUtilizzoUma := nIdCategoriaUtilizzoUma;
        LavCTScav(nContLavCTScav).IdLavorazioni          := nIdLavorazioni;
      END IF;
    END IF;
  END LOOP;

  FOR recCat IN (SELECT ID_CATEGORIA_UTILIZZO_UMA,NVL(SUM(SUP_SEC),0) SUP_SEC,NVL(SUM(SUP_PRINC),0) SUP_PRINC 
                 FROM (SELECT CUU.ID_CATEGORIA_UTILIZZO_UMA,
                              DECODE(CP.FLAG_COLTURA_SECONDARIA,'S',NVL(SUPERFICIE_UTILIZZATA,0),0) SUP_SEC,
                              DECODE(CP.FLAG_COLTURA_SECONDARIA,'N',NVL(SUPERFICIE_UTILIZZATA,0),0) SUP_PRINC
                       FROM   DB_CATEGORIA_UTILIZZO_UMA CUU,DB_CATEGORIA_COLTURA CC,DB_COLTURA_PRATICATA CP,DB_SUPERFICIE_AZIENDA SA
                       WHERE  CUU.ID_CATEGORIA_UTILIZZO_UMA = CC.ID_CATEGORIA_UTILIZZO_UMA
                       AND    SA.ID_SUPERFICIE_AZIENDA      = CP.ID_SUPERFICIE_AZIENDA
                       AND    CC.ID_COLTURA                 = CP.ID_COLTURA
                       AND    SA.ID_DITTA_UMA               = pIdDittaUma
                       AND    SA.DATA_SCARICO               IS NULL
                       AND    SA.DATA_FINE_VALIDITA         IS NULL
                       AND    CUU.DATA_FINE_VALIDITA        IS NULL
                       AND    CC.DATA_FINE_VALIDITA         IS NULL)
                 GROUP BY ID_CATEGORIA_UTILIZZO_UMA) LOOP

    SELECT NVL(SUM(SUP_SEC),0) SUP_SEC,NVL(SUM(SUP_PRINC),0) SUP_PRINC
    INTO   nSupCollMontSec,nSupCollMontPrinc
    FROM   (SELECT DECODE(CP.FLAG_COLTURA_SECONDARIA,'S',NVL(PC.SUPERFICIE_UTILIZZATA,0),0) SUP_SEC,
                   DECODE(CP.FLAG_COLTURA_SECONDARIA,'N',NVL(PC.SUPERFICIE_UTILIZZATA,0),0) SUP_PRINC
            FROM   DB_SUPERFICIE_AZIENDA SA,DB_COLTURA_PRATICATA CP,DB_PARTICELLA_COLTURA PC,DB_STORICO_PARTICELLA SP,
                   DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,DB_ZONA_ALTIMETRICA ZA,DB_CATEGORIA_COLTURA CC
            WHERE  CC.ID_CATEGORIA_UTILIZZO_UMA = recCat.ID_CATEGORIA_UTILIZZO_UMA
            AND    SA.ID_SUPERFICIE_AZIENDA     = CP.ID_SUPERFICIE_AZIENDA
            AND    CP.ID_COLTURA_PRATICATA      = PC.ID_COLTURA_PRATICATA
            AND    PC.EX_ID_STORICO_PARTICELLA  = SP.ID_STORICO_PARTICELLA
            AND    SP.ID_ZONA_ALTIMETRICA       = ZAUG.EXT_ID_ZONA_ALTIMETRICA
            AND    ZAUG.ID_ZONA_ALTIMETRICA     = ZA.ID_ZONA_ALTIMETRICA
            AND    ZAUG.DATA_FINE_VALIDITA      IS NULL
            AND    ZA.CODICE                    = 'M'
            AND    SA.ID_DITTA_UMA              = pIdDittaUma
            AND    SA.DATA_SCARICO              IS NULL
            AND    SA.DATA_FINE_VALIDITA        IS NULL
            AND    CP.ID_COLTURA                = CC.ID_COLTURA);

    IF nContDomAssVal = 0 THEN
      nSupCompless := recCat.SUP_PRINC;
      nSupCollMont := nSupCollMontPrinc;
    ELSE
      SELECT NVL(SUM(NVL(SUPERFICIE_UTILIZZATA,0)),0)
      INTO   nSupPrincOld
      FROM   DB_CATEGORIA_UTILIZZO_UMA CUU,DB_CATEGORIA_COLTURA CC,DB_COLTURA_PRATICATA CP,DB_SUPERFICIE_AZIENDA SA,
             DB_DOMANDA_ASSEGNAZIONE DA
      WHERE  CC.ID_CATEGORIA_UTILIZZO_UMA        = recCat.ID_CATEGORIA_UTILIZZO_UMA
      AND    CUU.ID_CATEGORIA_UTILIZZO_UMA       = CC.ID_CATEGORIA_UTILIZZO_UMA
      AND    SA.ID_SUPERFICIE_AZIENDA            = CP.ID_SUPERFICIE_AZIENDA
      AND    CC.ID_COLTURA                       = CP.ID_COLTURA
      AND    SA.ID_DITTA_UMA                     = pIdDittaUma
      AND    CUU.DATA_FINE_VALIDITA              IS NULL
      AND    CC.DATA_FINE_VALIDITA               IS NULL
      AND    FLAG_COLTURA_SECONDARIA             = 'N'
      AND    DA.ID_DITTA_UMA                     = SA.ID_DITTA_UMA
      AND    DA.ID_STATO_DOMANDA                 = 30
      AND    TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY') = TO_CHAR(SYSDATE,'YYYY')
      AND    SA.DATA_INIZIO_VALIDITA            <= DA.DATA_RIFERIMENTO
      AND    NVL(SA.DATA_FINE_VALIDITA,SYSDATE) >= DA.DATA_RIFERIMENTO;

      SELECT NVL(SUM(NVL(PC.SUPERFICIE_UTILIZZATA,0)),0)
      INTO   nSupCollMontPrincOld
      FROM   DB_SUPERFICIE_AZIENDA SA,DB_COLTURA_PRATICATA CP,DB_PARTICELLA_COLTURA PC,DB_STORICO_PARTICELLA SP,
             DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,DB_ZONA_ALTIMETRICA ZA,DB_CATEGORIA_COLTURA CC,
             DB_DOMANDA_ASSEGNAZIONE DA
      WHERE  CC.ID_CATEGORIA_UTILIZZO_UMA        = recCat.ID_CATEGORIA_UTILIZZO_UMA
      AND    SA.ID_SUPERFICIE_AZIENDA            = CP.ID_SUPERFICIE_AZIENDA
      AND    CP.ID_COLTURA_PRATICATA             = PC.ID_COLTURA_PRATICATA
      AND    PC.EX_ID_STORICO_PARTICELLA         = SP.ID_STORICO_PARTICELLA
      AND    SP.ID_ZONA_ALTIMETRICA              = ZAUG.EXT_ID_ZONA_ALTIMETRICA
      AND    ZAUG.ID_ZONA_ALTIMETRICA            = ZA.ID_ZONA_ALTIMETRICA
      AND    ZAUG.DATA_FINE_VALIDITA             IS NULL
      AND    ZA.CODICE                           = 'M'
      AND    SA.ID_DITTA_UMA                     = pIdDittaUma
      AND    CP.ID_COLTURA                       = CC.ID_COLTURA
      AND    DA.ID_DITTA_UMA                     = SA.ID_DITTA_UMA
      AND    FLAG_COLTURA_SECONDARIA             = 'N'
      AND    DA.ID_STATO_DOMANDA                 = 30
      AND    TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY') = TO_CHAR(SYSDATE,'YYYY')
      AND    SA.DATA_INIZIO_VALIDITA            <= DA.DATA_RIFERIMENTO
      AND    NVL(SA.DATA_FINE_VALIDITA,SYSDATE) >= DA.DATA_RIFERIMENTO;

      IF (recCat.SUP_PRINC - nSupPrincOld) > 0 THEN
        nSupCompless := recCat.SUP_SEC + (recCat.SUP_PRINC - nSupPrincOld);
      ELSE
        nSupCompless := recCat.SUP_SEC;
      END IF;

      IF (nSupCollMontPrinc - nSupCollMontPrincOld) > 0 THEN
        nSupCollMont := nSupCollMontSec + (nSupCollMontPrinc - nSupCollMontPrincOld);
      ELSE
        nSupCollMont := nSupCollMontSec;
      END IF;

      nSupAumento := (recCat.SUP_PRINC - nSupPrincOld);
    END IF;

    IF nContDomAssVal = 0 THEN
      nLast                 := 1;
      Imp(1).SupLav         := nSupCompless;
      Imp(1).SupLavCollMont := nSupCollMont;
      Imp(1).IdMotivLav     := ReturnMotLav('LB');
    ELSE
      nLast                 := 2;
      Imp(1).SupLav         := recCat.SUP_SEC;
      Imp(1).SupLavCollMont := nSupCollMontSec;
      Imp(1).IdMotivLav     := ReturnMotLav('CS');

      Imp(2).SupLav         := nSupAumento;
      Imp(2).SupLavCollMont := (nSupCollMontPrinc - nSupCollMontPrincOld);
      Imp(2).IdMotivLav     := ReturnMotLav('AS');
    END IF;

    FOR recLav IN (SELECT CCL.ID_LAVORAZIONI,CCL.ID_UNITA_MISURA,
                          least(NVL(LINEA.MAX_ESECUZIONI_LINEA_LAVORAZ,CCL.MAX_ESECUZIONI), 1) NUM_ESEC,
                          CCL.LITRI_BASE,
                          CCL.LITRI_MEDIO_IMPASTO,CCL.LITRI_TERRENI_DECLIVI
                   FROM   DB_CATEG_COLTURA_LAVORAZIONI CCL,DB_UNITA_MISURA UM,DB_TIPO_LAVORAZIONI TL,
                          (SELECT LLL.MAX_ESECUZIONI_LINEA_LAVORAZ,LLL.ID_LAVORAZIONI,CLL.LINEA_LAVORAZIONE_PRIMARIA
                           FROM   DB_COLTURA_LINEA_LAVORAZIONE CLL,DB_LAVORAZIONI_LINEA_LAVORAZIO LLL
                           WHERE  (LLL.DATA_FINE_VALIDITA IS NULL OR TRUNC(LLL.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE))
                           AND    TRUNC(LLL.DATA_INIZIO_VALIDITA)    <= TRUNC(SYSDATE)
                           AND    (CLL.DATA_FINE_VALIDITA IS NULL OR TRUNC(CLL.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE))
                           AND    TRUNC(CLL.DATA_INIZIO_VALIDITA) <= TRUNC(SYSDATE)
                           AND    CLL.ID_CATEGORIA_UTILIZZO_UMA    = recCat.ID_CATEGORIA_UTILIZZO_UMA
                           AND    CLL.ID_COLTURA_LINEA_LAVORAZIONE = LLL.ID_COLTURA_LINEA_LAVORAZIONE
                           AND    MAX_ESECUZIONI_LINEA_LAVORAZ     > 0) LINEA
                   WHERE  UM.ID_UNITA_MISURA                  = CCL.ID_UNITA_MISURA
                   AND    CCL.ID_CATEGORIA_UTILIZZO_UMA       = recCat.ID_CATEGORIA_UTILIZZO_UMA
                   AND    CCL.ID_TIPO_COLTURA_LAVORAZIONE     = 2
                   AND    CCL.ID_LAVORAZIONI                  = LINEA.ID_LAVORAZIONI(+)
                   AND    TL.ID_LAVORAZIONI                   = CCL.ID_LAVORAZIONI
                   AND    TL.FLAG_ASSERVIMENTO                = 'N'
                   AND    UM.TIPO                             = 'S'
                   AND    TRUNC(CCL.DATA_INIZIO_VALIDITA)    <= TRUNC(SYSDATE)
                   AND    (CCL.DATA_FINE_VALIDITA IS NULL OR TRUNC(CCL.DATA_FINE_VALIDITA) >= TRUNC(SYSDATE))
                   AND    LAVORAZIONE_STRAORDINARIA           = 'N'
                   AND    LAVORAZIONE_DEFAULT                 = 'S'
                   AND    NVL(LINEA.LINEA_LAVORAZIONE_PRIMARIA,'S') = 'S'
                   AND    EXISTS                              (SELECT 'X'
                                                               FROM   DB_CATEG_MACCHINE_LAVORAZIONI CML,
                                                                      DB_TIPO_GENERE_MACCHINA TGM,DB_UTILIZZO U,
                                                                      DB_MACCHINA M
                                                               WHERE  TGM.ID_GENERE_MACCHINA        = CML.ID_GENERE_MACCHINA
                                                               AND    M.ID_MACCHINA                 = U.ID_MACCHINA
                                                               AND    CML.ID_CATEGORIA_UTILIZZO_UMA = recCat.ID_CATEGORIA_UTILIZZO_UMA
                                                               AND    CML.ID_LAVORAZIONI            = CCL.ID_LAVORAZIONI
                                                               AND    CML.DATA_FINE_VALIDITA        IS NULL
                                                               AND    U.ID_DITTA_UMA                = pIdDittaUma
                                                               AND    U.DATA_SCARICO                IS NULL
                                                               AND    TGM.ID_GENERE_MACCHINA        IN (SELECT DM.ID_GENERE_MACCHINA
                                                                                                        FROM   DB_DATI_MACCHINA DM
                                                                                                        WHERE  DM.ID_MACCHINA   = M.ID_MACCHINA
                                                                                                        AND    NVL(CML.ID_CATEGORIA,-1) = NVL(DM.ID_CATEGORIA,-1)
                                                                                                        UNION
                                                                                                        SELECT MAT.ID_GENERE_MACCHINA
                                                                                                        FROM   DB_MATRICE MAT
                                                                                                        WHERE  MAT.ID_MATRICE = M.ID_MATRICE
                                                                                                        AND    NVL(CML.ID_CATEGORIA,-1) = NVL(MAT.ID_CATEGORIA,-1)))
                   ) LOOP
      
      bInsert := TRUE;
      
      FOR j IN 1..LavCTScav.COUNT LOOP
        IF LavCTScav(j).IdCategoriaUtilizzoUma = recCat.ID_CATEGORIA_UTILIZZO_UMA AND
           LavCTScav(J).IdLavorazioni          = recLav.ID_LAVORAZIONI THEN
          bInsert := FALSE;
          EXIT;
        END IF;
      END LOOP;
      
      IF bInsert THEN
        FOR i IN 1..nLast LOOP
          IF Imp(i).SupLav > 0 THEN
            INSERT INTO DB_LAVORAZIONE_CONTO_PROPRIO
            (ID_DITTA_UMA, ID_LAVORAZIONE_CONTO_PROPRIO, ANNO_CAMPAGNA, ID_CATEGORIA_UTILIZZO_UMA,
             ID_LAVORAZIONI, ID_UNITA_MISURA, ID_MACCHINA, NUMERO_ESECUZIONI, SUP_ORE,
             TOT_LITRI_BASE, TOT_LITRI_MEDIO_IMPASTO,
             TOT_LITRI_TERRENI_DECLIVI,
             TOT_LITRI_LAVORAZIONE,
             NOTE, DATA_INIZIO_VALIDITA, DATA_FINE_VALIDITA, DATA_CESSAZIONE, DATA_AGGIORNAMENTO,
             EXT_ID_UTENTE_AGGIORNAMENTO,ID_MOTIVO_LAVORAZIONE)
            VALUES
            (pIdDittaUma,SEQ_DB_LAVORAZIONE_CONTO_PROP.NEXTVAL,TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')),recCat.ID_CATEGORIA_UTILIZZO_UMA,
             recLav.ID_LAVORAZIONI,recLav.ID_UNITA_MISURA,NULL,recLav.NUM_ESEC,Imp(i).SupLav,
             (Imp(i).SupLav*recLav.NUM_ESEC*recLav.LITRI_BASE),(Imp(i).SupLav*recLav.NUM_ESEC*recLav.LITRI_MEDIO_IMPASTO),
             (Imp(i).SupLavCollMont*recLav.NUM_ESEC*recLav.LITRI_TERRENI_DECLIVI),
             ((Imp(i).SupLav*recLav.NUM_ESEC*recLav.LITRI_BASE)+(Imp(i).SupLav*recLav.NUM_ESEC*recLav.LITRI_MEDIO_IMPASTO)+
             (Imp(i).SupLavCollMont*recLav.NUM_ESEC*recLav.LITRI_TERRENI_DECLIVI)),
             NULL,SYSDATE,NULL,NULL,SYSDATE,
             pIdUtente,Imp(i).IdMotivLav);
          END IF;
        END LOOP;
      END IF;
    END LOOP;
  END LOOP;

  COMMIT;

  pCodErr  := '0';
  pDescErr := NULL;
EXCEPTION
  WHEN ERRORE THEN
    pCodErr := '1';
  WHEN OTHERS THEN
    ROLLBACK;
    pCodErr  := '1';
    pDescErr := 'ERRORE NON GESTITO: '||SQLERRM;
END Main;

END;
/
