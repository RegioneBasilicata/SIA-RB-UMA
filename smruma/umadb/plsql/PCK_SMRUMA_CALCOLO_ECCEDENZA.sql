CREATE OR REPLACE PACKAGE PCK_SMRUMA_CALCOLO_ECCEDENZA IS

  -- Procedura di calcolo dell'eccedenza di carburante per una determinata ditta Uma e per un determinato anno
  -- di calcolo
  PROCEDURE CalcoloEccedenza(pIdDittaUma       NUMBER,
                             pAnnoCalcolo      NUMBER,
                             pIdUtente         NUMBER,
                             pNoteCalcolo      VARCHAR2,
                             pCodErr       OUT VARCHAR2,
                             pDescErr      OUT VARCHAR2);

  -- Procedura di calcolo dell¿eccedenza per un determinato anno
  FUNCTION Main RETURN NUMBER;

  PROCEDURE CalcoloFattureContoTerzi(pIdDittaUma       NUMBER,
                                   pAnnoCalcolo      NUMBER,
                                   pIdAzienda        DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                                   pFattureCt    OUT NUMBER,
                                   pCodErr       OUT VARCHAR2,
                                   pDescErr      OUT VARCHAR2);

END PCK_SMRUMA_CALCOLO_ECCEDENZA;
/


CREATE OR REPLACE PACKAGE BODY PCK_SMRUMA_CALCOLO_ECCEDENZA IS

PROCEDURE CalcoloFattureContoTerzi(pIdDittaUma       NUMBER,
                                   pAnnoCalcolo      NUMBER,
                                   pIdAzienda        DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                                   pFattureCt    OUT NUMBER,
                                   pCodErr       OUT VARCHAR2,
                                   pDescErr      OUT VARCHAR2) IS

  nCont              SIMPLE_INTEGER := 0;
  nContLavA          SIMPLE_INTEGER := 0;
  nTotCarbLavCP      NUMBER;
  nNumEsecEffLavCp   NUMBER;
  nNumEsecPrevLavCP  NUMBER;
  nNumEsEcc          NUMBER;
BEGIN
  pFattureCt := 0;

  FOR rec IN (SELECT LC.*,CCL.LITRI_MAGGIORAZIONE_CONTO3,
                     (CASE WHEN TRUNC(DECODE(NVL(LEAST(LC.CONSUMO_AMMISSIBILE,LC.CONSUMO_DICHIARATO),0),0,0,LEAST(LC.CONSUMO_AMMISSIBILE,LC.CONSUMO_DICHIARATO) - (NVL(CCL.LITRI_MAGGIORAZIONE_CONTO3 * LC.SUP_ORE,0)))) < 0 THEN 0
                     ELSE
                     TRUNC(DECODE(NVL(LEAST(LC.CONSUMO_AMMISSIBILE,LC.CONSUMO_DICHIARATO),0),0,0,LEAST(LC.CONSUMO_AMMISSIBILE,LC.CONSUMO_DICHIARATO) - (NVL(CCL.LITRI_MAGGIORAZIONE_CONTO3 * LC.SUP_ORE,0))))
                     END) +
                     (CASE WHEN TRUNC(DECODE(NVL(LC.BENZINA,0),0,0,LC.BENZINA - (NVL(CCL.LITRI_MAGGIORAZIONE_CONTO3 * LC.SUP_ORE,0)))) < 0 THEN 0
                     ELSE
                     TRUNC(DECODE(NVL(LC.BENZINA,0),0,0,LC.BENZINA - (NVL(CCL.LITRI_MAGGIORAZIONE_CONTO3 * LC.SUP_ORE,0)))) END) CARB_LAV_CT
              FROM   DB_LAVORAZIONE_CONTOTERZI LC,DB_CAMPAGNA_CONTOTERZISTI CC,
                     DB_CATEG_COLTURA_LAVORAZIONI CCL
              WHERE  CC.ID_CAMPAGNA_CONTOTERZISTI       = LC.ID_CAMPAGNA_CONTOTERZISTI
              AND    CC.ANNO_CAMPAGNA                   = pAnnoCalcolo
              AND    CC.VERSO_LAVORAZIONI               = 'E'
              AND    LC.EXT_ID_AZIENDA                  = pIdAzienda
              AND    LC.DATA_CESSAZIONE                 IS NULL
              AND    LC.DATA_FINE_VALIDITA              IS NULL
              AND    LC.ID_CATEGORIA_UTILIZZO_UMA       = CCL.ID_CATEGORIA_UTILIZZO_UMA
              AND    LC.ID_LAVORAZIONI                  = CCL.ID_LAVORAZIONI
              AND    CCL.ID_CATEGORIA_COLTURA_LAVORAZIO = (SELECT MAX(ID_CATEGORIA_COLTURA_LAVORAZIO)
                                                           FROM   DB_CATEG_COLTURA_LAVORAZIONI
                                                           WHERE  ID_CATEGORIA_UTILIZZO_UMA   = LC.ID_CATEGORIA_UTILIZZO_UMA
                                                           AND    ID_LAVORAZIONI              = LC.ID_LAVORAZIONI
                                                           AND    ID_UNITA_MISURA             = LC.ID_UNITA_MISURA
                                                           AND    ID_TIPO_COLTURA_LAVORAZIONE = 1
                                                           AND    pAnnoCalcolo                BETWEEN TO_NUMBER(TO_CHAR(DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                                                      TO_NUMBER(TO_CHAR(NVL(DATA_FINE_VALIDITA,SYSDATE),'YYYY')))
              ) LOOP

    SELECT COUNT(*)
    INTO   nCont
    FROM   DB_LAVORAZIONE_CONTO_PROPRIO LCC,DB_ASSEGNAZIONE_CARBURANTE AC,DB_DOMANDA_ASSEGNAZIONE DA
    WHERE  AC.ID_ASSEGNAZIONE_CARBURANTE  = LCC.ID_ASSEGNAZIONE_CARBURANTE
    AND    DA.ID_DOMANDA_ASSEGNAZIONE     = AC.ID_DOMANDA_ASSEGNAZIONE
    AND    LCC.ID_CATEGORIA_UTILIZZO_UMA  = REC.ID_CATEGORIA_UTILIZZO_UMA
    AND    LCC.ID_LAVORAZIONI             = REC.ID_LAVORAZIONI
    AND    LCC.ANNO_CAMPAGNA              = pAnnoCalcolo
    AND    LCC.DATA_CESSAZIONE            IS NULL
    AND    LCC.DATA_FINE_VALIDITA         IS NULL
    AND    DA.ID_DITTA_UMA                = pIdDittaUma
    AND    DA.ID_STATO_DOMANDA            = 30
    AND    AC.TIPO_ASSEGNAZIONE          != 'S';

    IF nCont = 0 THEN
      SELECT COUNT(*)
      INTO   nCont
      FROM   DB_LAVORAZIONE_CONTO_PROPRIO LCC,DB_R_COLTURA_LAVORAZIONI_CT_CP CLCC,
             DB_ASSEGNAZIONE_CARBURANTE AC,DB_DOMANDA_ASSEGNAZIONE DA
      WHERE  AC.ID_ASSEGNAZIONE_CARBURANTE      = LCC.ID_ASSEGNAZIONE_CARBURANTE
      AND    DA.ID_DOMANDA_ASSEGNAZIONE         = AC.ID_DOMANDA_ASSEGNAZIONE
      AND    CLCC.ID_CATEGORIA_UTILIZZO_UMA     = REC.ID_CATEGORIA_UTILIZZO_UMA
      AND    CLCC.ID_CATEGORIA_UTILIZZO_UMA     = LCC.ID_CATEGORIA_UTILIZZO_UMA
      AND    CLCC.ID_LAVORAZIONI_CONTO_TERZI    = REC.ID_LAVORAZIONE_CONTOTERZI
      AND    CLCC.ID_LAVORAZIONI_CONTO_PROPRIO  = LCC.ID_LAVORAZIONE_CONTO_PROPRIO
      AND    pAnnoCalcolo                       BETWEEN TO_NUMBER(TO_CHAR(CLCC.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                        TO_NUMBER(TO_CHAR(NVL(CLCC.DATA_FINE_VALIDITA,SYSDATE),'YYYY'))
      AND    LCC.ANNO_CAMPAGNA                  = pAnnoCalcolo
      AND    LCC.DATA_CESSAZIONE                IS NULL
      AND    LCC.DATA_FINE_VALIDITA             IS NULL
      AND    DA.ID_DITTA_UMA                    = pIdDittaUma
      AND    DA.ID_STATO_DOMANDA                = 30
      AND    AC.TIPO_ASSEGNAZIONE              != 'S';
    END IF;

    IF nCont != 0 THEN
      SELECT COUNT(*)
      INTO   nContLavA
      FROM   DB_CATEG_COLTURA_LAVORAZIONI CCL
      WHERE  CCL.ID_CATEGORIA_UTILIZZO_UMA     = REC.ID_CATEGORIA_UTILIZZO_UMA
      AND    CCL.ID_TIPO_COLTURA_LAVORAZIONE   = 2
      AND    CCL.LAVORAZIONE_DEFAULT           = 'N'
      AND    CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
      AND    pAnnoCalcolo                      BETWEEN TO_NUMBER(TO_CHAR(CCL.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                       TO_NUMBER(TO_CHAR(NVL(CCL.DATA_FINE_VALIDITA,SYSDATE),'YYYY'))
      AND    ((CCL.ID_LAVORAZIONI              = REC.ID_LAVORAZIONI) OR
              (CCL.ID_LAVORAZIONI              IN (SELECT CLCC.ID_LAVORAZIONI_CONTO_PROPRIO
                                                   FROM   DB_R_COLTURA_LAVORAZIONI_CT_CP CLCC
                                                   WHERE  CLCC.ID_CATEGORIA_UTILIZZO_UMA  = REC.ID_CATEGORIA_UTILIZZO_UMA
                                                   AND    CLCC.ID_LAVORAZIONI_CONTO_TERZI = REC.ID_LAVORAZIONI
                                                   AND    pAnnoCalcolo                    BETWEEN TO_NUMBER(TO_CHAR(CLCC.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                                                  TO_NUMBER(TO_CHAR(NVL(CLCC.DATA_FINE_VALIDITA,SYSDATE),'YYYY')))));
      IF nContLavA = 0 THEN
        SELECT NVL(SUM(NVL(LCP.TOT_LITRI_LAVORAZIONE,0)),0),NVL(MAX(LCP.NUMERO_ESECUZIONI),0),
               NVL(MAX(CCL.MAX_ESECUZIONI),0)
        INTO   nTotCarbLavCP,nNumEsecEffLavCp,
               nNumEsecPrevLavCP
        FROM   DB_LAVORAZIONE_CONTO_PROPRIO LCP, DB_CATEG_COLTURA_LAVORAZIONI CCL
        WHERE  LCP.ID_CATEGORIA_UTILIZZO_UMA      = CCL.ID_CATEGORIA_UTILIZZO_UMA
        AND    LCP.ID_DITTA_UMA                   = pIdDittaUma  
        AND    LCP.DATA_FINE_VALIDITA             IS NULL
        AND    LCP.DATA_CESSAZIONE                IS NULL
        AND    LCP.ID_LAVORAZIONI                 = CCL.ID_LAVORAZIONI
        AND    CCL.ID_CATEGORIA_UTILIZZO_UMA      = REC.ID_CATEGORIA_UTILIZZO_UMA
        AND    ((CCL.ID_LAVORAZIONI               = REC.ID_LAVORAZIONI) OR
                (CCL.ID_LAVORAZIONI               IN (SELECT CLCC.ID_LAVORAZIONI_CONTO_PROPRIO
                                                      FROM   DB_R_COLTURA_LAVORAZIONI_CT_CP CLCC
                                                      WHERE  CLCC.ID_COLTURA_LAVORAZIONI_CT_CP = (SELECT MAX(ID_COLTURA_LAVORAZIONI_CT_CP)
                                                                                                  FROM   DB_R_COLTURA_LAVORAZIONI_CT_CP
                                                                                                  WHERE  ID_CATEGORIA_UTILIZZO_UMA  = REC.ID_CATEGORIA_UTILIZZO_UMA
                                                                                                  AND    ID_LAVORAZIONI_CONTO_TERZI = REC.ID_LAVORAZIONI
                                                                                                  AND    pAnnoCalcolo               BETWEEN TO_NUMBER(TO_CHAR(DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                                                                                    TO_NUMBER(TO_CHAR(NVL(DATA_FINE_VALIDITA,SYSDATE),'YYYY')))
                                                      AND    CLCC.ID_CATEGORIA_UTILIZZO_UMA  = REC.ID_CATEGORIA_UTILIZZO_UMA
                                                      AND    CLCC.ID_LAVORAZIONI_CONTO_TERZI = REC.ID_LAVORAZIONI
                                                      AND    pAnnoCalcolo                    BETWEEN TO_NUMBER(TO_CHAR(CLCC.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                                             TO_NUMBER(TO_CHAR(NVL(CLCC.DATA_FINE_VALIDITA,SYSDATE),'YYYY')))))
        AND    CCL.ID_CATEGORIA_COLTURA_LAVORAZIO = (SELECT MAX(ID_CATEGORIA_COLTURA_LAVORAZIO)
                                                     FROM   DB_CATEG_COLTURA_LAVORAZIONI
                                                     WHERE  ID_CATEGORIA_UTILIZZO_UMA   = REC.ID_CATEGORIA_UTILIZZO_UMA
                                                     AND    ID_LAVORAZIONI              = REC.ID_LAVORAZIONI
                                                     AND    ID_UNITA_MISURA             = REC.ID_UNITA_MISURA
                                                     AND    ID_TIPO_COLTURA_LAVORAZIONE = 2
                                                     AND    pAnnoCalcolo                BETWEEN TO_NUMBER(TO_CHAR(DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                                                TO_NUMBER(TO_CHAR(NVL(DATA_FINE_VALIDITA,SYSDATE),'YYYY')));

        IF nNumEsecEffLavCp > (nNumEsecPrevLavCP - REC.NUMERO_ESECUZIONI) THEN
          nNumEsEcc  := (nNumEsecEffLavCp - (nNumEsecPrevLavCP - REC.NUMERO_ESECUZIONI));
          pFattureCt := pFattureCt + LEAST(nTotCarbLavCP,REC.CARB_LAV_CT) / nNumEsEcc;

          UPDATE DB_LAVORAZIONE_CONTOTERZI
          SET    LAVORAZIONE_IN_ECCEDENZA_CP = 'S'
          WHERE  ID_LAVORAZIONE_CONTOTERZI   = REC.ID_LAVORAZIONE_CONTOTERZI;
        END IF;
      END IF;
    END IF;
  END LOOP;

  pFattureCt := CEIL(pFattureCt);
  pCodErr    := '0';
  pDescErr   := '';
EXCEPTION
  WHEN OTHERS THEN
    pCodErr  := '1';
    pDescErr := 'ERRORE GENERICO FATTURE CONTO TERZI = '||SQLERRM||' - RIGA = '||dbms_utility.FORMAT_ERROR_BACKTRACE;
END CalcoloFattureContoTerzi;


-- Procedura di calcolo dell'eccedenza di carburante per una determinata ditta Uma e per un determinato anno
-- di calcolo
PROCEDURE CalcoloEccedenza(pIdDittaUma       NUMBER,
                           pAnnoCalcolo      NUMBER,
                           pIdUtente         NUMBER,
                           pNoteCalcolo      VARCHAR2,
                           pCodErr       OUT VARCHAR2,
                           pDescErr      OUT VARCHAR2) IS

  nIdAzienda                   DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE;
  nFattureCt                   NUMBER;
  nConsumatoCp                 NUMBER;
  nIdDomandaAssegnazione       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
  nMaxAssegnabileCp            NUMBER;
  nAssegnatoSuppCp             NUMBER;
  nEccedenzaCp                 NUMBER;
  nTotaleContoProprioNoDecurt  DB_DETTAGLIO_CALCOLO.TOTALE_CONTO_PROPRIO%TYPE;
  nPercentualeRiduzione        DB_DETTAGLIO_CALCOLO.PERCENTUALE_RIDUZIONE%TYPE;
  nIdDomandaAssegnazioneSucc   DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
  nAnnoMin                     NUMBER;
  vNote                        DB_CALCOLO_ECCEDENZA.NOTE%TYPE;
  nAssegnatoCp                 NUMBER;
  nRimanenzeCp                 NUMBER;
  nMaxAssegnabileCpEcc         NUMBER;
  vMaxAssCpXMacchine           DB_CALCOLO_ECCEDENZA.MAX_ASS_CP_X_MACCHINE%TYPE;
  nCarbDiffColtMacc            NUMBER;
BEGIN
  pCodErr  := '0';
  pDescErr := '';

  IF pIdDittaUma  IS NULL OR
     pAnnoCalcolo IS NULL OR
     pIdUtente    IS NULL THEN

    pCodErr  := '1';
    pDescErr := 'Parametri di input obbligatori non valorizzati';
    RETURN;
  END IF;

  -- Consumato conto proprio
  SELECT MIN(TO_NUMBER(TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY')))
  INTO   nAnnoMin
  FROM   DB_DOMANDA_ASSEGNAZIONE DA
  WHERE  DA.ID_DITTA_UMA     = pIdDittaUma
  AND    DA.ID_STATO_DOMANDA IN (30,35);

  FOR anno IN REVERSE nAnnoMin..pAnnoCalcolo LOOP
    SELECT MIN(DA.ID_DOMANDA_ASSEGNAZIONE)
    INTO   nIdDomandaAssegnazione
    FROM   DB_DOMANDA_ASSEGNAZIONE DA
    WHERE  DA.ID_DITTA_UMA                                = pIdDittaUma
    AND    TO_NUMBER(TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY')) = anno
    AND    DA.TIPO_DOMANDA                                = 'B'
    AND    DA.ID_STATO_DOMANDA                            = 30;

    IF nIdDomandaAssegnazione IS NULL THEN
      SELECT MIN(DA.ID_DOMANDA_ASSEGNAZIONE)
      INTO   nIdDomandaAssegnazione
      FROM   DB_DOMANDA_ASSEGNAZIONE DA
      WHERE  DA.ID_DITTA_UMA                                = pIdDittaUma
      AND    TO_NUMBER(TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY')) = anno
      AND    DA.TIPO_DOMANDA                                = 'A'
      AND    DA.ID_STATO_DOMANDA                            = 35;
    END IF;

    IF nIdDomandaAssegnazione IS NOT NULL THEN
      EXIT;
    END IF;
  END LOOP;

  SELECT MIN(DA.ID_DOMANDA_ASSEGNAZIONE)
  INTO   nIdDomandaAssegnazioneSucc
  FROM   DB_DOMANDA_ASSEGNAZIONE DA
  WHERE  DA.ID_DITTA_UMA            = pIdDittaUma
  AND    DA.ID_STATO_DOMANDA        IN (30,35)
  AND    DA.ID_DOMANDA_ASSEGNAZIONE > nIdDomandaAssegnazione;

  IF nIdDomandaAssegnazioneSucc IS NULL THEN
    IF nIdDomandaAssegnazione IS NOT NULL THEN
      vNote := pNoteCalcolo||' - Eccedenza non calcolata per assenza della verifica dei consumi';
    ELSE
      vNote := pNoteCalcolo||' - Eccedenza non calcolata per assenza della domanda di assegnazione';
    END IF;

    UPDATE DB_CALCOLO_ECCEDENZA
    SET    DATA_FINE_VALIDITA = SYSDATE
    WHERE  ID_DITTA_UMA       = pIdDittaUma
    AND    ANNO_CALCOLO       = pAnnoCalcolo
    AND    DATA_FINE_VALIDITA IS NULL;

    INSERT INTO DB_CALCOLO_ECCEDENZA
    (ID_CALCOLO_ECCEDENZA, ID_DITTA_UMA, ANNO_CALCOLO, ECCEDENZA_CONTO_PROPRIO, CONSUMATO_CONTO_PROPRIO,
     CARBURANTE_FATTURE_CT, MAX_ASSEGNABILE_CP, PERCENTUALE_RIDUZIONE, ASSEGNATO_CP_SUPPLEMENTI,
     DATA_INIZIO_VALIDITA, EXT_ID_UTENTE_AGGIORNAMENTO, NOTE,MAX_ASS_CP_X_MACCHINE)
    VALUES
    (SEQ_DB_CALCOLO_ECCEDENZA.NEXTVAL,pIdDittaUma,pAnnoCalcolo,0,0,
     0,0,0,0,
     SYSDATE,pIdUtente,vNote,'N'); 

    RETURN;
  END IF;

  SELECT NVL(SUM(NVL(CR.CONSUMO_CONTO_PROPRIO,0)),0)
  INTO   nConsumatoCp
  FROM   DB_CONSUMO_RIMANENZA CR, DB_DOMANDA_ASSEGNAZIONE DA
  WHERE  DA.ID_DITTA_UMA            = pIdDittaUma
  AND    DA.ID_DOMANDA_ASSEGNAZIONE = CR.ID_DOMANDA_ASSEGNAZIONE
  AND    DA.ID_DOMANDA_ASSEGNAZIONE = nIdDomandaAssegnazioneSucc;

  SELECT EXT_ID_AZIENDA
  INTO   nIdAzienda
  FROM   DB_DITTA_UMA
  WHERE  ID_DITTA_UMA = pIdDittaUma;

  -- Fatture conto terzi
  CalcoloFattureContoTerzi(pIdDittaUma,
                           pAnnoCalcolo,
                           nIdAzienda,
                           nFattureCt,
                           pCodErr,
                           pDescErr);

  IF pCodErr = '1' THEN
    RETURN;
  END IF;

  --  Massimo assegnabile conto proprio
  BEGIN
    SELECT (TOTALE_CONTO_PROPRIO + DECURTAZIONE_LAV_BENZINA + DECURTAZIONE_LAV_GASOLIO) ,PERCENTUALE_RIDUZIONE,
           (TOT_CARB_COLTURA_ALLEV - CARBURANTE_MACCHINE),
           CASE WHEN CARBURANTE_MACCHINE < TOT_CARB_COLTURA_ALLEV THEN 'S'
           ELSE 'N' END
    INTO   nTotaleContoProprioNoDecurt,nPercentualeRiduzione,nCarbDiffColtMacc,vMaxAssCpXMacchine
    FROM   DB_DETTAGLIO_CALCOLO
    WHERE  ID_DOMANDA_ASSEGNAZIONE  = nIdDomandaAssegnazione
    AND    TIPO_ASSEGNAZIONE       != 'S'
    AND    NUMERO_SUPPLEMENTO       IS NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      nTotaleContoProprioNoDecurt := 0;
      nPercentualeRiduzione       := 0;
      vMaxAssCpXMacchine          := 'N';
      nCarbDiffColtMacc           := 0;
  END;

  nMaxAssegnabileCp := nTotaleContoProprioNoDecurt / ((100 - nPercentualeRiduzione) / 100);

  SELECT NVL(SUM(NVL(ASSEGNAZIONE_CONTO_PROPRIO,0)),0)
  INTO   nAssegnatoCp
  FROM   DB_QUANTITA_ASSEGNATA QA, DB_ASSEGNAZIONE_CARBURANTE AC
  WHERE  QA.ID_ASSEGNAZIONE_CARBURANTE  = AC.ID_ASSEGNAZIONE_CARBURANTE
  AND    AC.ID_DOMANDA_ASSEGNAZIONE     = nIdDomandaAssegnazione
  AND    AC.TIPO_ASSEGNAZIONE          != 'S'
  AND    AC.NUMERO_SUPPLEMENTO          IS NOT NULL;

  SELECT NVL(SUM(NVL(RIMANENZA_CONTO_PROPRIO,0)),0)
  INTO   nRimanenzeCp
  FROM   DB_CONSUMO_RIMANENZA CR,DB_DOMANDA_ASSEGNAZIONE DA
  WHERE  DA.ID_DOMANDA_ASSEGNAZIONE = nIdDomandaAssegnazione
  AND    CR.ID_DOMANDA_ASSEGNAZIONE = DA.ID_DOMANDA_ASSEGNAZIONE;

  nMaxAssegnabileCpEcc := GREATEST(nMaxAssegnabileCp,(nAssegnatoCp + nRimanenzeCp));

  --  Assegnato supplementare conto proprio
  SELECT NVL(SUM(ASSEGNAZIONE_CONTO_PROPRIO),0)
  INTO   nAssegnatoSuppCp
  FROM   DB_QUANTITA_ASSEGNATA QA,DB_ASSEGNAZIONE_CARBURANTE AC,DB_DOMANDA_ASSEGNAZIONE DA
  WHERE  AC.ID_ASSEGNAZIONE_CARBURANTE = QA.ID_ASSEGNAZIONE_CARBURANTE
  AND    DA.ID_DOMANDA_ASSEGNAZIONE    = AC.ID_DOMANDA_ASSEGNAZIONE
  AND    AC.ANNULLATO                  IS NULL
  AND    AC.TIPO_ASSEGNAZIONE          = 'S'
  AND    DA.ID_DOMANDA_ASSEGNAZIONE    = nIdDomandaAssegnazione;

  IF ((nFattureCt + nConsumatoCp) > (nMaxAssegnabileCpEcc + nAssegnatoSuppCp)) AND nFattureCt > 0 THEN
    nEccedenzaCp := (nFattureCt + nConsumatoCp) - (nMaxAssegnabileCpEcc + nAssegnatoSuppCp);

    IF vMaxAssCpXMacchine = 'S' THEN
      nEccedenzaCp := nEccedenzaCp - nCarbDiffColtMacc;

      IF nEccedenzaCp < 0 THEN
        nEccedenzaCp := 0;
      END IF;
    END IF;
  ELSE
    nEccedenzaCp := 0;
  END IF;



  UPDATE DB_CALCOLO_ECCEDENZA
  SET    DATA_FINE_VALIDITA = SYSDATE
  WHERE  ID_DITTA_UMA       = pIdDittaUma
  AND    ANNO_CALCOLO       = pAnnoCalcolo
  AND    DATA_FINE_VALIDITA IS NULL;

  INSERT INTO DB_CALCOLO_ECCEDENZA
  (ID_CALCOLO_ECCEDENZA, ID_DITTA_UMA, ANNO_CALCOLO, ECCEDENZA_CONTO_PROPRIO, CONSUMATO_CONTO_PROPRIO,
   CARBURANTE_FATTURE_CT, MAX_ASSEGNABILE_CP, PERCENTUALE_RIDUZIONE, ASSEGNATO_CP_SUPPLEMENTI,
   DATA_INIZIO_VALIDITA, EXT_ID_UTENTE_AGGIORNAMENTO, NOTE,ASSEGNATO_CONTO_PROPRIO, RIMANENZA_CONTO_PROPRIO,
   ID_DOMANDA_ASSEGNAZIONE, MAX_ASS_CP_X_MACCHINE)
  VALUES
  (SEQ_DB_CALCOLO_ECCEDENZA.NEXTVAL,pIdDittaUma,pAnnoCalcolo,nEccedenzaCp,nConsumatoCp,
   nFattureCt,nMaxAssegnabileCp,nPercentualeRiduzione,nAssegnatoSuppCp,
   SYSDATE,pIdUtente,pNoteCalcolo,nAssegnatoCp,nRimanenzeCp,
   nIdDomandaAssegnazione,vMaxAssCpXMacchine);  

EXCEPTION
  WHEN OTHERS THEN
    pCodErr  := '1';
    pDescErr := 'ERRORE GENERICO = '||SQLERRM||' - RIGA = '||dbms_utility.FORMAT_ERROR_BACKTRACE;
END CalcoloEccedenza;

-- Procedura di calcolo dell¿eccedenza per un determinato anno
FUNCTION Main RETURN NUMBER IS

  vNomeBatch        DB_NOME_BATCH.NOME_BATCH%TYPE := 'CALC_ECC';
  nIdProcessoBatch  DB_PROCESSO_BATCH.ID_PROCESSO_BATCH%TYPE := PCK_SMRUMA_UTILITY_BATCH.insprocbatch(vNomeBatch);
  nAnnoCalcolo      NUMBER;
  vCodErr           VARCHAR2(1);
  vDescErr          VARCHAR2(4000);
BEGIN
  SELECT TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - TO_NUMBER(VALORE)
  INTO   nAnnoCalcolo
  FROM   DB_PARAMETRO
  WHERE  ID_PARAMETRO = 'UMEC';

  UPDATE DB_CALCOLO_ECCEDENZA
  SET    DATA_FINE_VALIDITA = SYSDATE
  WHERE  ANNO_CALCOLO       = nAnnoCalcolo
  AND    DATA_FINE_VALIDITA IS NULL;

  FOR rec IN (SELECT DISTINCT DU.ID_DITTA_UMA
              FROM   DB_DITTA_UMA DU,DB_DATI_DITTA DD
              WHERE  DU.ID_DITTA_UMA                                     = DD.ID_DITTA_UMA
              AND    DD.ID_CONDUZIONE                                    IN (1,3)
              AND    TO_NUMBER(TO_CHAR(DD.DATA_INIZIO_VALIDITA,'YYYY')) <= nAnnoCalcolo
              AND    (DD.DATA_FINE_VALIDITA IS NULL OR TO_NUMBER(TO_CHAR(DD.DATA_FINE_VALIDITA,'YYYY')) >= nAnnoCalcolo)
              AND    (DU.DATA_CESSAZIONE IS NULL OR TO_NUMBER(TO_CHAR(DU.DATA_CESSAZIONE,'YYYY')) >= nAnnoCalcolo)
              AND    EXISTS (SELECT 'X'
                             FROM   DB_DOMANDA_ASSEGNAZIONE DA
                             WHERE  DA.ID_DITTA_UMA = DU.ID_DITTA_UMA
                             AND    TO_NUMBER(TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY')) <= nAnnoCalcolo
                             AND    DA.ID_STATO_DOMANDA                            IN (30,35))
              AND ROWNUM <= 100
              AND    EXISTS (SELECT 'X'
                             FROM   DB_LAVORAZIONE_CONTOTERZI LC, DB_CAMPAGNA_CONTOTERZISTI CC
                             WHERE  CC.ID_CAMPAGNA_CONTOTERZISTI = LC.ID_CAMPAGNA_CONTOTERZISTI
                             AND    CC.ANNO_CAMPAGNA             = nAnnoCalcolo
                             AND    CC.VERSO_LAVORAZIONI         = 'E'
                             AND    LC.EXT_ID_AZIENDA            = DU.EXT_ID_AZIENDA
                             AND    LC.DATA_CESSAZIONE           IS NULL
                             AND    LC.DATA_FINE_VALIDITA        IS NULL)) LOOP

    CalcoloEccedenza(rec.ID_DITTA_UMA,nAnnoCalcolo,9999999999,'Elaborazione massiva calcolo eccedenza - Anno '||nAnnoCalcolo,
                     vCodErr,   -- out
                     vDescErr); -- out

    IF vCodErr = '0' THEN
      COMMIT;
    ELSE
      ROLLBACK;
      PCK_SMRUMA_UTILITY_BATCH.inslogbatch(nIdProcessoBatch,'E001','DITTA UMA NON CALCOLATA = '||rec.ID_DITTA_UMA||
                                                                   ' - ERRORE = '||vDescErr);
    END IF;
  END LOOP;

  PCK_SMRUMA_UTILITY_BATCH.UpdFineProcBatch(nIdProcessoBatch,'OK');
  RETURN 0;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    PCK_SMRUMA_UTILITY_BATCH.UpdFineProcBatch(nIdProcessoBatch,'KO');
    PCK_SMRUMA_UTILITY_BATCH.inslogbatch(nIdProcessoBatch,'E001','ERRORE GENERICO = ' ||SQLERRM||' - RIGA = '||dbms_utility.FORMAT_ERROR_BACKTRACE);
    RETURN 1;
END Main;

END PCK_SMRUMA_CALCOLO_ECCEDENZA;
/
