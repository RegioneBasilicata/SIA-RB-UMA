CREATE OR REPLACE PACKAGE Pck_Calcolo_Bonus IS

-- Variabili Globali

    GlobalDittaUma             DB_DITTA_UMA.ID_DITTA_UMA%TYPE;
    GlobalDomanda             DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
    GlobalDataRif             DB_DOMANDA_ASSEGNAZIONE.DATA_RIFERIMENTO%TYPE;
    -- PER CULTURE
    GlobalIdGenere            DB_TIPO_GENERE_MACCHINA.ID_GENERE_MACCHINA%TYPE;
     GlobalIdFascia             DB_TIPO_FASCIA_POTENZA.ID_FASCIA_POTENZA%TYPE;
     GlobalIdASM004             DB_TIPO_FASCIA_POTENZA.ID_FASCIA_POTENZA%TYPE;
     GlobalIdASM006             DB_TIPO_FASCIA_POTENZA.ID_FASCIA_POTENZA%TYPE;
    GlobalIdEssicatore         DB_TIPO_GENERE_MACCHINA.ID_GENERE_MACCHINA%TYPE;
    GlobalIdFienagione         DB_TIPO_GENERE_MACCHINA.ID_GENERE_MACCHINA%TYPE;
    GlobalIdMietitrebbia    DB_TIPO_GENERE_MACCHINA.ID_GENERE_MACCHINA%TYPE;


    kTrattrice                VARCHAR2(1)    := 'T';
    kBruciatoreEssicatoio    VARCHAR2(3) := 'ASM';
    kMietitrebbiatrice        VARCHAR2(3) := 'MTS';
    kMotoAgricola            VARCHAR2(3) := 'MTA';
    kMotoColtivatore        VARCHAR2(2) := 'MC';
    kMotoFalciatrice        VARCHAR2(2) := 'MF';
    kMotoZappa                VARCHAR2(2) := 'MZ';
 kDerivate VARCHAR2(1)    := 'D';
 kMacchinaAgricolaOperatrice            VARCHAR2(3) := 'MAO';
 kMotoriVari VARCHAR2(1)    := 'V';

    kCatEssicatoio            VARCHAR2(3) := '004';
    KCatBruciatore            VARCHAR2(3) := '005';
 KCatFienagione            VARCHAR2(3) := '006';
 kBenzina NUMBER(3) := 1;
 kGasolio NUMBER(3) := 2;

    kBovini                    NUMBER(2)    := 1;
    kKwRiferimento            NUMBER(2)     := 10;
    kKwLimite                NUMBER(2)     := 10;
    kOreAnnualiSerra        NUMBER(4)    := 2000;
--    kCoefficenteSerre        NUMBER(2,1)    := 2.1; -- sg - decurtazione 10% 2013
 --kCoefficenteSerre NUMBER(2,1) := 1.9; -- sg - decurtazione 10% 2013

 kCoefficenteSerre NUMBER(2,1);

    kDomandaAnnullata        NUMBER(2)     := 40;
    kPianura                NUMBER(1)    := 5;


    nIntermediario            NUMBER(10);
    nUtente                    NUMBER(10);
    bCalcolo                BOOLEAN;
 bInsDomanda BOOLEAN;

--    GlobalErr                varchar2(1000);
--    GlobalDesErr             VARCHAR2(1000);
    nNobile                 BOOLEAN;

    ERR_PROCESSO             EXCEPTION;
 -- attualemente gestite : B = BASE , A = ACCONTO
 kvTipoDomandaBase DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE:= 'B';
 kvTipoDomandaAcconto DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE:= 'A';


 PROCEDURE MAIN (    pDittaUma         IN     NUMBER,
                 pIntermediario    IN NUMBER,
                    pUtente            IN NUMBER,
                      pIdDomanda        OUT NUMBER,
                    pErr             OUT     varchar2,
                    pDesErr            OUT     VARCHAR2);

/******************************************************************************
 NAME: SMRUMA.PCK_CALCOLO_BONUS
 PURPOSE: To calculate the desired information.
******************************************************************************/
END Pck_Calcolo_Bonus;
/


CREATE OR REPLACE PACKAGE BODY Pck_Calcolo_Bonus AS

FUNCTION RICERCA_DITTA (pErr              OUT varchar2,
                        pDesErr            OUT VARCHAR2) RETURN BOOLEAN IS

dDataRicalcCar DATE;

BEGIN
    -- RICERCA MAX DOMANDA

    SELECT ID_DOMANDA_ASSEGNAZIONE, DATA_RICALCOLO_CARBURANTE
      INTO GlobalDomanda, dDataRicalcCar
      FROM DB_DOMANDA_ASSEGNAZIONE
     WHERE ID_DITTA_UMA = GlobalDittaUma
       AND TO_CHAR(DATA_RIFERIMENTO,'YYYY') = TO_CHAR(GlobalDataRif,'YYYY')
       AND ID_STATO_DOMANDA <> kDomandaAnnullata
       AND TIPO_DOMANDA = kvTipoDomandaBase; 

    bCalcolo := TRUE;

    RETURN (TRUE);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT SEQ_DOMANDA_ASSEGNAZIONE.NEXTVAL INTO GlobalDomanda FROM DUAL;
        BEGIN
              INSERT INTO DB_DOMANDA_ASSEGNAZIONE (ID_DOMANDA_ASSEGNAZIONE, ID_DITTA_UMA, DATA_RIFERIMENTO,
                       ID_STATO_DOMANDA, EXT_ID_INTERMEDIARIO, DATA_AGGIORNAMENTO, EXT_ID_UTENTE_AGGIORNAMENTO,TIPO_DOMANDA)
              VALUES (GlobalDomanda,
                     GlobalDittaUma,
                     GlobalDataRif,
                     10,
                     nIntermediario,
                     GlobalDataRif,
                     nUtente,
                     kvTipoDomandaBase); 
        EXCEPTION WHEN OTHERS THEN
             PErr        :=    SQLCODE;
             PDesErr    :=    'ERRORE INSERIMENTO DOMANDA ASSEGNAZIONE: '||SQLERRM;
             RETURN (FALSE);
        END;
      bInsDomanda := TRUE;
      bCalcolo := TRUE;
      RETURN (TRUE);

   WHEN OTHERS THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE RICERCA DITTA: '|| SQLERRM;
        RETURN (FALSE);
END;


FUNCTION CARBURANTE_X_ALLEVAMENTI(pErr      OUT VARCHAR2,
                                  pDesErr OUT VARCHAR2) RETURN BOOLEAN IS

    CURSOR CUR_ALLEVAMENTI IS
    SELECT AA.ID_ALLEVAMENTO IDI,
           AA.QUANTITA QUANTITA,
           DD.LITRI_DI_CARBURANTE LITRI
      FROM DB_ALLEVAMENTO AA,
           DB_TIPO_LITRI_ALLEVAMENTO DD,
           DB_LAVORAZIONI_PRATICATE BB
     WHERE AA.ID_DITTA_UMA = GlobalDittaUma
       AND AA.DATA_INIZIO_VALIDITA <= GlobalDataRif
       AND (AA.DATA_FINE_VALIDITA > GlobalDataRif OR AA.DATA_FINE_VALIDITA IS NULL )
       AND AA.ID_ALLEVAMENTO = BB.ID_ALLEVAMENTO
       AND DD.ID_LITRI_ALLEVAMENTO = BB.ID_LITRI_ALLEVAMENTO
       AND DD.DATA_FINE_VALIDITA IS NULL 
  ORDER BY AA.ID_ALLEVAMENTO; 

    nUmaSostenibili     NUMBER;
    nUmaTotali             NUMBER;
    nCoefficiente         NUMBER;
    nCalcolo            NUMBER;
    nTotXAllevamento    NUMBER;
    nTotCarburante        NUMBER;
    nIdAllevamentoOld    DB_ALLEVAMENTO.ID_ALLEVAMENTO%TYPE;
    nCount                 NUMBER := 0;
BEGIN

    -- UBA SOSTENIBILI
    SELECT NVL(SUM(dd.uba_sostenibili_ha * bb.superficie_utilizzata),0)
    INTO nUmaSostenibili
    FROM     DB_SUPERFICIE_AZIENDA     aa,
            DB_COLTURA_PRATICATA     bb,
            DB_TIPO_COLTURA         cc,
            DB_TIPO_FASCIA_QUALITA     dd
    WHERE     AA.ID_DITTA_UMA             =     GlobalDittaUma
    AND     AA.DATA_INIZIO_VALIDITA        <=     GlobalDataRif
    AND     ( AA.DATA_FINE_VALIDITA        >     GlobalDataRif OR AA.DATA_FINE_VALIDITA IS NULL )
    AND     AA.ID_SUPERFICIE_AZIENDA     =     BB.ID_SUPERFICIE_AZIENDA
    AND     CC.ID_COLTURA                 =     BB.ID_COLTURA
    AND     DD.ID_FASCIA_QUALITA         =     CC.ID_FASCIA_QUALITA;

    --    TOT UBA
    SELECT NVL(SUM(AA.quantita * BB.coefficiente_uba),0)
    INTO nUmaTotali
    FROM    DB_ALLEVAMENTO aa,
            DB_TIPO_CATEGORIA_ANIMALE bb
    WHERE     AA.ID_DITTA_UMA             =     GlobalDittaUma
    AND     AA.DATA_INIZIO_VALIDITA        <=     GlobalDataRif
    AND     ( AA.DATA_FINE_VALIDITA        >     GlobalDataRif OR AA.DATA_FINE_VALIDITA IS NULL )
    AND     BB.ID_CATEGORIA_ANIMALE     =     AA.ID_CATEGORIA_ANIMALE;


    IF    nUmaTotali > nUmaSostenibili THEN
        -- nCoefficiente :=    nUmaSostenibili / nUmaTotali;
        nCoefficiente := 1;        
    ELSE
        nCoefficiente := 1;
    END IF;


    nCalcolo             := 0;
    nTotXAllevamento    := 0;
    nTotCarburante        := 0;
    nIdAllevamentoOld := NULL;

    FOR MY_REC IN CUR_ALLEVAMENTI LOOP
        nCount := ncount + 1;

        IF nIdAllevamentoOld != MY_REC.IDI AND nIdAllevamentoOld IS NOT NULL THEN
            BEGIN
               INSERT INTO DB_CARBURANTE_ALLEVAMENTO (ID_CARBURANTE_ALLEVAMENTO, ID_DOMANDA_ASSEGNAZIONE, ID_ALLEVAMENTO, QUANTITA_SOSTENIBILE, CARBURANTE_ALLEVAMENTO)
               VALUES (SEQ_CARBURANTE_ALLEVAMENTO.NEXTVAL, GlobalDomanda, nIdAllevamentoOld, nTotXAllevamento,nTotCarburante);
            EXCEPTION WHEN OTHERS THEN
                PErr        :=    SQLCODE;
                PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE ALLEVAMENTO: ' || SQLERRM;
                RETURN (FALSE);
            END;

            nTotCarburante     := 0;
            nTotXAllevamento := 0;
        END IF;

        nCalcolo := MY_REC.QUANTITA * nCoefficiente;

        nTotXAllevamento := /*TotXAllevamento +*/ nCalcolo;
        nTotCarburante     := nTotCarburante + (MY_REC.LITRI * nCalcolo);

        nIdAllevamentoOld := MY_REC.IDI;
    END LOOP;

    BEGIN
      INSERT INTO DB_CARBURANTE_ALLEVAMENTO (ID_CARBURANTE_ALLEVAMENTO, ID_DOMANDA_ASSEGNAZIONE, ID_ALLEVAMENTO, QUANTITA_SOSTENIBILE, CARBURANTE_ALLEVAMENTO)
      VALUES (SEQ_CARBURANTE_ALLEVAMENTO.NEXTVAL, GlobalDomanda, nIdAllevamentoOld, nTotXAllevamento,nTotCarburante);
    EXCEPTION
        WHEN OTHERS THEN
            PErr        :=    SQLCODE;
            PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE ALLEVAMENTO: '||SQLERRM;
            RETURN (FALSE);
    END;

    nTotXAllevamento := 0;
    nTotCarburante     := 0;

    RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE CARBURANTE_X_ALLEVAMENTI: '|| SQLERRM;
        RETURN (FALSE);
END CARBURANTE_X_ALLEVAMENTI;


FUNCTION CARBURANTE_X_MACCHINE (pCountBovini      NUMBER,
                                pErr          OUT VARCHAR2,
                                pDesErr       OUT VARCHAR2 ) RETURN BOOLEAN IS

  CURSOR CUR_MACCHINARI IS SELECT CC.id_macchina IDI,DD.id_genere_macchina ID_GENERE,DD.codifica_breve CODIFICA,
                                  EE.potenza_kw POTENZA,EE.ID_MATRICE MATRICE
                           FROM   DB_UTILIZZO BB,DB_MACCHINA CC,DB_TIPO_GENERE_MACCHINA DD,DB_MATRICE EE
                           WHERE  BB.ID_DITTA_UMA                 = GlobalDittaUma
                           AND    BB.DATA_CARICO                 <= GlobalDataRif
                           AND    (BB.DATA_SCARICO                > GlobalDataRif OR BB.DATA_SCARICO IS NULL)
                           AND    CC.ID_MACCHINA                  = BB.ID_MACCHINA
                           AND    DD.ID_GENERE_MACCHINA           = EE.ID_GENERE_MACCHINA
                           AND    LTRIM(RTRIM(DD.codifica_breve)) IN (kTrattrice,kMotoAgricola,kMotoColtivatore,
                                                                      kMotoFalciatrice,kMotoZappa,kDerivate,
                                                                      kMacchinaAgricolaOperatrice, kMotoriVari)
                           AND    EE.ID_MATRICE                   =  CC.ID_MATRICE
                           AND    EE.ID_ALIMENTAZIONE             IN (kBenzina, kGasolio)
                           AND    EE.POTENZA_KW                   IS NOT NULL
                           AND    EE.POTENZA_KW                   > 0
                           UNION
                           SELECT CC.id_macchina IDI,DD.id_genere_macchina ID_GENERE,DD.codifica_breve CODIFICA,
                                  EE.potenza POTENZA,NULL MATRICE
                           FROM   DB_UTILIZZO BB,DB_MACCHINA CC,DB_TIPO_GENERE_MACCHINA DD,DB_DATI_MACCHINA EE
                           WHERE  BB.ID_DITTA_UMA                 = GlobalDittaUma
                           AND    BB.DATA_CARICO                 <= GlobalDataRif
                           AND    (BB.DATA_SCARICO                > GlobalDataRif OR BB.DATA_SCARICO IS NULL)
                           AND    CC.ID_MACCHINA                  = BB.ID_MACCHINA
                           AND    DD.ID_GENERE_MACCHINA           = EE.ID_GENERE_MACCHINA
                           AND    LTRIM(RTRIM(DD.codifica_breve)) IN (kTrattrice,kMotoAgricola,kMotoColtivatore,
                                                                      kMotoFalciatrice,kMotoZappa,kDerivate,
                                                                      kMacchinaAgricolaOperatrice, kMotoriVari)
                           AND    EE.ID_MACCHINA                  =  CC.ID_MACCHINA
                           AND    EE.ID_ALIMENTAZIONE             IN (kBenzina, kGasolio);

  nCarburante  DB_CARBURANTE_MACCHINA.CARBURANTE_ASSEGNATO%TYPE;
BEGIN

  FOR MY_REC IN CUR_MACCHINARI LOOP

    
    IF MY_REC.POTENZA IS NOT NULL THEN
      SELECT TLM.LITRI_DI_CARBURANTE
      INTO   nCarburante
      FROM   DB_TIPO_FASCIA_POTENZA TFP,DB_TIPO_LITRI_MACCHINA TLM
      WHERE  MY_REC.POTENZA         BETWEEN TFP.POTENZA_MIN AND TFP.POTENZA_MAX
      AND    TLM.ID_FASCIA_POTENZA  = TFP.ID_FASCIA_POTENZA
      AND    TLM.ID_GENERE_MACCHINA = MY_REC.ID_GENERE
      AND    TLM.DATA_FINE_VALIDITA IS NULL; 
    ELSE
      SELECT TLM.LITRI_DI_CARBURANTE
      INTO   nCarburante
      FROM   DB_TIPO_LITRI_MACCHINA TLM
      WHERE  TLM.ID_FASCIA_POTENZA  = 12  -- fascia di potenza di default
      AND    TLM.ID_GENERE_MACCHINA = MY_REC.ID_GENERE
      AND    TLM.DATA_FINE_VALIDITA IS NULL;
    END IF;

    IF pCountBovini > 0 THEN
      SELECT TLM.LITRI_DI_CARBURANTE
      INTO   nCarburante
      FROM   DB_TIPO_LITRI_MACCHINA TLM
      WHERE  TLM.ID_FASCIA_POTENZA  = 5
      AND    DATA_FINE_VALIDITA     IS NULL 
      AND    TLM.ID_GENERE_MACCHINA = MY_REC.ID_GENERE;
    END IF;


    BEGIN
      INSERT INTO DB_CARBURANTE_MACCHINA
      (ID_CARBURANTE_MACCHINA, ID_DOMANDA_ASSEGNAZIONE, ID_MACCHINA, CARBURANTE_ASSEGNATO)
      VALUES
      (SEQ_CARBURANTE_MACCHINA.NEXTVAL, GlobalDomanda, MY_REC.IDI, nCarburante);
    EXCEPTION
      WHEN OTHERS THEN
        pErr    := SQLCODE;
        PDesErr := 'ERRORE INSERIMENTO CARBURANTE MACCHINA: '|| SQLERRM;
        RETURN FALSE;
    END;

  END LOOP;

  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    PErr    := SQLCODE;
    PDesErr := 'ERRORE CARBURANTE_X_MACCHINE: '|| SQLERRM;
    RETURN FALSE;
END CARBURANTE_X_MACCHINE;

FUNCTION CARBURANTE_X_COLTURE (pErr              OUT varchar2,
                               pDesErr        OUT VARCHAR2 ) RETURN BOOLEAN IS

    -- Modificato cursore per andare a sommare la superficie utilizzata
    -- per coltura, coltura pratica e zona altrimetrica UMA
    CURSOR CUR_CULTURE IS
    SELECT BB.ID_COLTURA IDI,
           BB.ID_COLTURA_PRATICATA IDI_PRAT,
           ZA.CODICE CODICE_ZONA,
           SUM(PC.SUPERFICIE_UTILIZZATA) AREA
      FROM DB_COLTURA_PRATICATA BB,
           DB_SUPERFICIE_AZIENDA AA,
           DB_PARTICELLA_COLTURA PC,
           DB_STORICO_PARTICELLA SP,
           DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,
           DB_ZONA_ALTIMETRICA ZA
     WHERE AA.ID_DITTA_UMA = GlobalDittaUma
       AND AA.DATA_INIZIO_VALIDITA  <= GlobalDataRif
       AND (AA.DATA_FINE_VALIDITA  >  GlobalDataRif OR AA.DATA_FINE_VALIDITA IS NULL )
       AND  AA.ID_SUPERFICIE_AZIENDA  =  BB.ID_SUPERFICIE_AZIENDA
       AND BB.ID_COLTURA_PRATICATA = PC.ID_COLTURA_PRATICATA
       AND PC.EX_ID_STORICO_PARTICELLA = SP.ID_STORICO_PARTICELLA
       AND SP.ID_ZONA_ALTIMETRICA = ZAUG.EXT_ID_ZONA_ALTIMETRICA
       AND ZAUG.DATA_INIZIO_VALIDITA  <= GlobalDataRif
       AND (ZAUG.DATA_FINE_VALIDITA  >  GlobalDataRif OR ZAUG.DATA_FINE_VALIDITA IS NULL )
       AND ZAUG.ID_ZONA_ALTIMETRICA = ZA.ID_ZONA_ALTIMETRICA
    GROUP BY BB.ID_COLTURA, BB.ID_COLTURA_PRATICATA, ZA.CODICE
    ORDER BY BB.ID_COLTURA, BB.ID_COLTURA_PRATICAta, ZA.CODICE;

    nCarburanteLavorazione  NUMBER:=0;
    nCarburanteEssicazione  NUMBER:=0;
    nCarburanteFienagione   NUMBER:=0;
    nCarburanteMietitrebbia NUMBER:=0;
    nAppCarbLavorazione     NUMBER:=0;
    nAppCarbEssicazione     NUMBER:=0;
    nAppCarbFienagione      NUMBER:=0;
    nAppCarbMietitrebbia    NUMBER:=0;

    nColturaPraticaApp      DB_COLTURA_PRATICATA.ID_COLTURA_PRATICATA%TYPE:=0;

BEGIN
    FOR MY_REC IN CUR_CULTURE LOOP
        nAppCarbLavorazione :=0;
        nAppCarbEssicazione :=0;
        nAppCarbFienagione  :=0;
        nAppCarbMietitrebbia :=0;

        IF nColturaPraticaApp <> MY_REC.IDI_PRAT THEN
           IF nColturaPraticaApp > 0 THEN
              IF (nCarburanteLavorazione + nCarburanteEssicazione + nCarburanteFienagione + nCarburanteMietitrebbia) > 0 THEN
                 begin
                    INSERT INTO DB_CARBURANTE_COLTURA (ID_CARBURANTE_COLTURA, ID_COLTURA_PRATICATA, ID_DOMANDA_ASSEGNAZIONE, CARBURANTE_LAVORAZIONE, CARBURANTE_MIETITREBBIATURA, CARBURANTE_ESSICAZIONE)
                    VALUES (SEQ_CARBURANTE_COLTURA.NEXTVAL, nColturaPraticaApp, GlobalDomanda, nCarburanteLavorazione, nCarburanteMietitrebbia, (nCarburanteEssicazione + nCarburanteFienagione));
                 exception
                    when others then
                        PErr        :=    sqlcode;
                        PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE COLTURA: ' || sqlerrm;
                        RETURN (FALSE);
                 end;
              END IF;
           END IF;
           nCarburanteLavorazione    := 0;
           nCarburanteEssicazione    := 0;
           nCarburanteFienagione    := 0;
           nCarburanteMietitrebbia    := 0;
        END IF;

        IF nNobile THEN
               BEGIN
                -- PER LAVORAZIONI
                SELECT NVL(TRUNC((LITRI_DI_CARBURANTE * MY_REC.AREA) + 0.9999),0)
                INTO nAppCarbLavorazione
                FROM DB_TIPO_LITRI_COLTURA
                WHERE ZONA_ALTIMETRICA        =    MY_REC.CODICE_ZONA 
                AND    ID_GENERE_MACCHINA        =   GlobalIdGenere
                AND    ID_COLTURA                =    MY_REC.IDI
                AND    (ID_FASCIA_POTENZA        =    GlobalIdFascia OR ID_FASCIA_POTENZA IS NULL)
                AND   DATA_FINE_VALIDITA IS NULL; 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    nAppCarbLavorazione := 0;
            END;
        END IF;


        IF GlobalIdEssicatore IS NOT NULL THEN
            BEGIN
                -- PER ESSICAZIONE
                SELECT NVL(TRUNC((LITRI_DI_CARBURANTE * MY_REC.AREA) + 0.9999),0)
                INTO nAppCarbEssicazione
                FROM DB_TIPO_LITRI_COLTURA
                WHERE ZONA_ALTIMETRICA        =    MY_REC.CODICE_ZONA 
                AND    ID_GENERE_MACCHINA        =      GlobalIdEssicatore
                AND    ID_COLTURA                =    MY_REC.IDI
                AND ID_FASCIA_POTENZA    =  GlobalIdASM004
                AND DATA_FINE_VALIDITA IS NULL; 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    nAppCarbEssicazione := 0;
            END;
        END IF;

-- ER-MOD inizio
        IF GlobalIdFienagione IS NOT NULL THEN
            BEGIN
                -- PER FIENAGIONE RAPIDA
                SELECT NVL(TRUNC((LITRI_DI_CARBURANTE * MY_REC.AREA) + 0.9999),0)
                INTO nAppCarbFienagione
                FROM DB_TIPO_LITRI_COLTURA
                WHERE ZONA_ALTIMETRICA        =    MY_REC.CODICE_ZONA 
                AND    ID_GENERE_MACCHINA        =      GlobalIdFienagione
                AND    ID_COLTURA                =    MY_REC.IDI
                AND ID_FASCIA_POTENZA    =  GlobalIdASM006
                AND DATA_FINE_VALIDITA IS NULL; 

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    nAppCarbFienagione := 0;
            END;
        END IF;
-- ER-MOD fine

        IF GlobalIdMietitrebbia IS NOT NULL THEN
            BEGIN

                -- PER MIETITREBBIATRICE
                SELECT NVL(TRUNC((LITRI_DI_CARBURANTE * MY_REC.AREA) + 0.9999),0)
                INTO nAppCarbMietitrebbia
                FROM DB_TIPO_LITRI_COLTURA
                WHERE     ZONA_ALTIMETRICA    =    MY_REC.CODICE_ZONA 
                AND        ID_GENERE_MACCHINA    =      GlobalIdMietitrebbia
                AND        ID_COLTURA            =    MY_REC.IDI
                AND DATA_FINE_VALIDITA IS NULL; 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    nAppCarbMietitrebbia := 0;
            END;
        END IF;

        nCarburanteLavorazione := nCarburanteLavorazione + nAppCarbLavorazione;
        nCarburanteEssicazione := nCarburanteEssicazione + nAppCarbEssicazione;
        nCarburanteFienagione := nCarburanteFienagione + nAppCarbFienagione;
        nCarburanteMietitrebbia := nCarburanteMietitrebbia + nAppCarbMietitrebbia;

        nColturaPraticaApp := MY_REC.IDI_PRAT;

    END LOOP;

    IF (nCarburanteLavorazione + nCarburanteEssicazione + nCarburanteFienagione + nCarburanteMietitrebbia) > 0 THEN
        begin
            INSERT INTO DB_CARBURANTE_COLTURA (ID_CARBURANTE_COLTURA, ID_COLTURA_PRATICATA, ID_DOMANDA_ASSEGNAZIONE, CARBURANTE_LAVORAZIONE, CARBURANTE_MIETITREBBIATURA, CARBURANTE_ESSICAZIONE)
            VALUES (SEQ_CARBURANTE_COLTURA.NEXTVAL, nColturaPraticaApp, GlobalDomanda, nCarburanteLavorazione, nCarburanteMietitrebbia, (nCarburanteEssicazione + nCarburanteFienagione));
        exception
            when others then
                PErr        :=    sqlcode;
                PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE COLTURA: ' || sqlerrm;
                RETURN (FALSE);
        end;

    END IF;

    RETURN (TRUE);

EXCEPTION
   WHEN OTHERS THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE CARBURANTE_X_COLTURE: '|| SQLERRM;
        RETURN (FALSE);
END CARBURANTE_X_COLTURE;

FUNCTION CARBURANTE_X_SERRE (pErr              OUT varchar2,
                            pDesErr            OUT VARCHAR2) RETURN BOOLEAN IS

    CURSOR CUR_SERRE IS SELECT     ID_SERRA                        IDI,
                                VOLUME_METRI_CUBI                VOLUME,
                                MESI_DI_RISCALDAMENTO            MESI,
                                ORE_DI_RISCALDAMENTO_ANNUALI    ORE,
                                ORE_MAX_SERRA                 ORE_MAX,
                                SER.ID_COLTURA ID_COLTURA,
                                SER.VOLUME_METRI_CUBI VOLUME_METRI_CUBI
                            FROM DB_SERRA SER, DB_TIPO_COLTURA TIP
                            WHERE SER.ID_DITTA_UMA             =     GlobalDittaUma
                            AND SER.DATA_INIZIO_VALIDITA     <=     GlobalDataRif
                            AND (SER.DATA_FINE_VALIDITA     >     GlobalDataRif OR SER.DATA_FINE_VALIDITA IS NULL)
                     AND SER.ID_COLTURA = TIP.ID_COLTURA;

    nLitriSerre NUMBER;
    nEsisteBruciatore NUMBER;

/*
nDeltaT_Ort  NUMBER;
nDeltaT_Flor NUMBER;
nTotCalorie  NUMBER;
nTot_M3_ORT  NUMBER;
nTot_M3_FLOR NUMBER;
nM3Ort       NUMBER;
nM3Flor      NUMBER;
nCoeffOrt    NUMBER;
nCoeffFlor   NUMBER;
nPotMaxOrt   NUMBER;
nPotMaxFlor  NUMBER;
nVolume      NUMBER;
*/

BEGIN

/*
  nTot_M3_Ort := 0;
  nTot_M3_Flor := 0;
  nDeltaT_Ort := 0;
  nDeltaT_Flor := 0;
  nCoeffOrt := 0;
  nCoeffFlor := 0;
  nPotMaxOrt := 0;
  nPotMaxFlor := 0;
  nVolume := 0;

  Select NVL(SUM(DM.CALORIE),0) Into nTotCalorie
  From DB_DATI_MACCHINA DM, DB_UTILIZZO U
  Where ID_GENERE_MACCHINA = 11
    And ID_CATEGORIA = 87
    And DM.ID_MACCHINA = U.ID_MACCHINA
    And U.DATA_SCARICO Is Null
    And U.ID_SCARICO Is Null
    And U.ID_DITTA_UMA = GlobalDittaUma
    And DM.DATA_AGGIORNAMENTO > to_Date('20/10/2007','dd/mm/yyyy');

  Select NVL(SUM(VOLUME_METRI_CUBI),0) Into nTot_M3_Ort
  From DB_SERRA S
  Where S.ID_DITTA_UMA = GlobalDittaUma
    And S.DATA_INIZIO_VALIDITA <= GlobalDataRif
    And (S.DATA_FINE_VALIDITA > GlobalDataRif Or S.DATA_FINE_VALIDITA Is Null)
    And S.ID_COLTURA = 37; -- SERRE ORTICOLE

  Select NVL(SUM(VOLUME_METRI_CUBI),0) Into nTot_M3_Flor
  From DB_SERRA S
  Where S.ID_DITTA_UMA = GlobalDittaUma
    And S.DATA_INIZIO_VALIDITA <= GlobalDataRif
    And (S.DATA_FINE_VALIDITA > GlobalDataRif Or S.DATA_FINE_VALIDITA Is Null)
    And S.ID_COLTURA = 36; -- SERRE FLORICOLE

  Select DT.DELTA_T_ORTICOLE, DT.DELTA_T_FLORICOLE Into nDeltaT_Ort, nDeltaT_Flor
  From DB_TIPO_DELTA_T DT
  Where DT.EXT_PROVINCIA = (Select decode(nvl(SUBSTR(EXT_COMUNE_PRINCIPALE_ATTIVITA,1,3), '076'), '077', '077', '076')
                           From DB_DATI_DITTA
                           Where ID_DITTA_UMA = GlobalDittaUma
                           And DATA_FINE_VALIDITA Is Null);

  If (nTotCalorie > 0) And (nTot_M3_Ort+nTot_M3_Flor > 0) Then
    -- Divido la potenza complessiva per i volumi
    nPotMaxOrt := (nTotCalorie/(nTot_M3_Ort*5+nTot_M3_Flor*7))*(nTot_M3_Ort*5);
    nPotMaxFlor := (nTotCalorie/(nTot_M3_Ort*5+nTot_M3_Flor*7))*(nTot_M3_Flor*7);

    -- Calcolo il volume Max riscaldabile (in Metri Cubi) = Potenza (kcal/h) / ( Delta T * 4)
    nM3Ort := ROUND(nPotMaxOrt/(nDeltaT_Ort*4),0);
    nM3Flor := ROUND(nPotMaxFlor/(nDeltaT_Flor*4),0);

    If nM3Ort < nTot_M3_Ort Then
      nCoeffOrt := nM3Ort/nTot_M3_Ort;
    Else
      nCoeffOrt := 1;
    End If;

    If nM3Flor < nTot_M3_Flor Then
      nCoeffFlor := nM3Flor/nTot_M3_Flor;
    Else
      nCoeffFlor := 1;
    End If;

    If nCoeffOrt > 1 Then
      nCoeffOrt := 1;
    End If;

    If nCoeffFlor > 1 Then
      nCoeffFlor := 1;
    End If;
  End If;
*/

    Select DECODE(COUNT(1),0, 0, 1) Into nEsisteBruciatore
    From DB_DATI_MACCHINA DM, DB_UTILIZZO U
    Where ID_GENERE_MACCHINA = 11
    And ID_CATEGORIA = 87
    And DM.ID_MACCHINA = U.ID_MACCHINA
    And U.DATA_SCARICO Is Null
    And U.ID_SCARICO Is Null
    And U.ID_DITTA_UMA = GlobalDittaUma
    And DM.DATA_AGGIORNAMENTO > to_Date('20/10/2007','dd/mm/yyyy');

    FOR MY_REC IN CUR_SERRE LOOP

/*
     If MY_REC.ID_COLTURA = 37 Then
       nVolume := ROUND(MY_REC.VOLUME*nCoeffOrt,0);
     Else
       nVolume := ROUND(MY_REC.VOLUME*nCoeffFlor,0);
     End If;

  SELECT VALORE -- TO_NUMBER(REPLACE(VALORE,'.',','))
  INTO   kCoefficenteSerre
  FROM   DB_TIPO_PARAMETRO
  WHERE  COD_PARAMETRO      = 'UMSR'
  AND    DATA_FINE_VALIDITA IS NULL;

        IF MY_REC.ORE < MY_REC.ORE_MAX THEN
            nLitriSerre := nVolume * MY_REC.MESI * (MY_REC.ORE / kOreAnnualiSerra) * kCoefficenteSerre;
        ELSE
            nLitriSerre := nVolume * MY_REC.MESI * (MY_REC.ORE_MAX / kOreAnnualiSerra) * kCoefficenteSerre;
        END IF;


          -- Se il coefficente � >= 1 non inserisco VOLUME_RIDOTTO
          If (MY_REC.ID_COLTURA = 37 And nCoeffOrt < 1) Or (MY_REC.ID_COLTURA = 36 And nCoeffFlor < 1) Then
            If MY_REC.ID_COLTURA = 37 Then
              BEGIN
                Insert Into DB_CARBURANTE_SERRA (
                ID_CARBURANTE_SERRA, ID_DOMANDA_ASSEGNAZIONE, ID_SERRA, CARBURANTE_RISCALDAMENTO,
                VOLUME_RIDOTTO
                ) Values (
                SEQ_CARBURANTE_SERRA.NEXTVAL, GlobalDomanda, MY_REC.IDI, nLitriSerre,
                (ROUND(MY_REC.VOLUME_METRI_CUBI*nCoeffOrt,0))
                );
              EXCEPTION WHEN OTHERS THEN
                PErr        :=    SQLCODE;
                PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE SERRA: '||SQLERRM;
                RETURN (FALSE);
              END;
            Else
              BEGIN
                Insert Into DB_CARBURANTE_SERRA (
                ID_CARBURANTE_SERRA, ID_DOMANDA_ASSEGNAZIONE, ID_SERRA, CARBURANTE_RISCALDAMENTO,
                VOLUME_RIDOTTO
                ) Values (
                SEQ_CARBURANTE_SERRA.NEXTVAL, GlobalDomanda, MY_REC.IDI, nLitriSerre,
                (ROUND(MY_REC.VOLUME_METRI_CUBI*nCoeffFlor,0))
                );
              EXCEPTION WHEN OTHERS THEN
                PErr        :=    SQLCODE;
                PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE SERRA: '||SQLERRM;
                RETURN (FALSE);
              END;
            End If;
          Else
            BEGIN
              INSERT INTO DB_CARBURANTE_SERRA (ID_CARBURANTE_SERRA, ID_DOMANDA_ASSEGNAZIONE, ID_SERRA, CARBURANTE_RISCALDAMENTO)
              VALUES ( SEQ_CARBURANTE_SERRA.NEXTVAL, GlobalDomanda, MY_REC.IDI, nLitriSerre);
            EXCEPTION WHEN OTHERS THEN
              PErr        :=    SQLCODE;
              PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE SERRA: '||SQLERRM;
              RETURN (FALSE);
            END;
          End If;
*/

        BEGIN
            -- nLitriSerre := round(1.1 * 8 * MY_REC.VOLUME, 0) * nEsisteBruciatore;
            --nLitriSerre := round(1.1 * 4 * MY_REC.VOLUME * 0.77, 0) * nEsisteBruciatore;
            select round(sum(1.1 * gg.giorni / decode(gg.mese, 'NOVEMBRE', 30, 'APRILE', 30, 'GIUGNO', 30, 'SETTEMBRE', 30, 'FEBBRAIO', 28, 31) * MY_REC.VOLUME * 0.77), 0) * nEsisteBruciatore
            into nLitriSerre
            from db_serra_riscaldamento gg
            where gg.id_serra = MY_REC.IDI;
            
            INSERT INTO DB_CARBURANTE_SERRA (ID_CARBURANTE_SERRA, ID_DOMANDA_ASSEGNAZIONE, ID_SERRA, CARBURANTE_RISCALDAMENTO)
            VALUES ( SEQ_CARBURANTE_SERRA.NEXTVAL, GlobalDomanda, MY_REC.IDI, nLitriSerre);
        EXCEPTION WHEN OTHERS THEN
            PErr        :=    SQLCODE;
            PDesErr    :=    'ERRORE INSERIMENTO CARBURANTE SERRA: '||SQLERRM;
            RETURN (FALSE);
        END;


    END LOOP;

    RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE CARBURANTE_X_SERRE: '|| SQLERRM;

        RETURN (FALSE);
END CARBURANTE_X_SERRE;


FUNCTION OPERAZIONI_PRELIMINARI (nCountBovini OUT NUMBER,
                                 pErr            OUT varchar2,
                                pDesErr          OUT VARCHAR2) RETURN BOOLEAN IS

    nCountEssicatoi         NUMBER(3);
-- ER-MOD inizio
   nCountFienagione         NUMBER(3);
-- ER-MOD fine
    nCountBruciatori        NUMBER(3);
    nCountMietitrebbie        NUMBER(3);

    nUno                    CHAR(3);
    nDue                    NUMBER(3);
   nTre              NUMBER(3);

  wID_Ditta db_ditta_uma.ext_id_azienda%type := '';
  wFlagBonifica varchar2(1)                  := '';
  wErrore   varchar2(255)                    := '';

BEGIN
  -- 1 SVUOTAMENTO TAVOLE

  BEGIN
    DELETE DB_CARBURANTE_MACCHINA
    WHERE  ID_DOMANDA_ASSEGNAZIONE = GlobalDomanda
    AND    TIPO_ASSEGNAZIONE       = 'B'
    AND    NUMERO_SUPPLEMENTO      IS NULL;
  EXCEPTION
    WHEN OTHERS THEN
      PErr    := SQLCODE;
      PDesErr := 'ERRORE CANCELLAZIONE CARBURANTE MACCHINA: '|| SQLERRM;
      RETURN FALSE;
  END;

  IF bCalcolo and NOT bInsDomanda THEN
    BEGIN
      DELETE DB_CARBURANTE_COLTURA
      WHERE  ID_DOMANDA_ASSEGNAZIONE = GlobalDomanda
      AND    TIPO_ASSEGNAZIONE       = 'B'
      AND    NUMERO_SUPPLEMENTO      IS NULL;
    EXCEPTION
      WHEN OTHERS THEN
        PErr    := SQLCODE;
        PDesErr := 'ERRORE CANCELLAZIONE CARBURANTE COLTURA: '|| SQLERRM;
        RETURN FALSE;
    END;

    BEGIN
      DELETE DB_CARBURANTE_SERRA
      WHERE  ID_DOMANDA_ASSEGNAZIONE = GlobalDomanda
      AND    TIPO_ASSEGNAZIONE       = 'B'
      AND    NUMERO_SUPPLEMENTO      IS NULL;
    EXCEPTION
      WHEN OTHERS THEN
        PErr    := SQLCODE;
        PDesErr := 'ERRORE CANCELLAZIONE CARBURANTE SERRA: '|| SQLERRM;
        RETURN FALSE;
    END;

    BEGIN
      DELETE DB_CARBURANTE_ALLEVAMENTO
      WHERE  ID_DOMANDA_ASSEGNAZIONE = GlobalDomanda
      AND    TIPO_ASSEGNAZIONE       = 'B'
      AND    NUMERO_SUPPLEMENTO      IS NULL;
    EXCEPTION
      WHEN OTHERS THEN
        PErr    := SQLCODE;
        PDesErr := 'ERRORE CANCELLAZIONE CARBURANTE ALLEVAMENTO: '|| SQLERRM;
        RETURN FALSE;
    END;
  END IF;


-- >>> Inizio Modifica Marco
-- 1b CONTROLLO DITTA (Update FlagBonifica)
  begin
    select ext_id_azienda,
           null,
           null
    into   wID_Ditta,
           wFlagBonifica,
           wErrore
    from   db_ditta_uma
    where  id_ditta_uma = GlobalDittaUma
    and    data_cessazione is null;
  exception
    when others then
      PErr        :=    '999';
      PDesErr    :=    'ERRORE CONTROLLI_PREVENTIVI - CONTROLLO DITTA 1b: '|| SQLERRM;
      RETURN (FALSE);
  end;

  /* TERRY - UMA - GESTIONE FASCICOLO AZIENDALE
  PACK_POST_MIGR.main( wID_Ditta, wFlagBonifica, wErrore);

  If wFlagBonifica != '0' then
      PErr        :=    '999';
      PDesErr    :=    wErrore;
      RETURN (FALSE);
  end if;
*/
-- <<< Fine Modifica Marco

  -- 2 RICERCA MACCHINARI E ALLEVAMENTI

   IF bCalcolo THEN

        --  A1 --> ESSICATOIO
          SELECT COUNT(*) INTO nCountEssicatoi
        FROM     DB_UTILIZZO                    BB,
                DB_MACCHINA                    CC,
                DB_DATI_MACCHINA              FF,
                DB_TIPO_GENERE_MACCHINA    DD,
                DB_TIPO_CATEGORIA            EE
        WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
        AND     CC.ID_MACCHINA          =     BB.ID_MACCHINA
        AND   CC.ID_MACCHINA          =    FF.ID_MACCHINA
      AND   EE.ID_CATEGORIA         =    FF.ID_CATEGORIA
      AND     EE.ID_GENERE_MACCHINA   =     DD.ID_GENERE_MACCHINA
        AND     BB.DATA_CARICO             <=     GlobalDataRif
        AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
        AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))       =     kBruciatoreEssicatoio
        AND     EE.CATEGORIA            =     kCatEssicatoio
      AND   FF.ID_ALIMENTAZIONE IN (kBenzina, kGasolio);

        IF nCountEssicatoi > 0 THEN
            SELECT ID_GENERE_MACCHINA INTO GlobalIdEssicatore
            FROM DB_TIPO_GENERE_MACCHINA
            WHERE LTRIM(RTRIM(CODIFICA_BREVE)) =     kBruciatoreEssicatoio;

-- ER-MOD inizio
          GlobalIdASM004  := 8;
-- ER-MOD fine

        END IF;

      -- ER-MOD inizio
        --  A1 --> CATENA FIENAGIONE RAPIDA
          SELECT COUNT(*) INTO nCountFienagione
        FROM     DB_UTILIZZO                    BB,
                DB_MACCHINA                    CC,
                DB_DATI_MACCHINA              FF,
                DB_TIPO_GENERE_MACCHINA    DD,
                DB_TIPO_CATEGORIA            EE
        WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
        AND     CC.ID_MACCHINA          =     BB.ID_MACCHINA
        AND   CC.ID_MACCHINA          =    FF.ID_MACCHINA
      AND   EE.ID_CATEGORIA         =    FF.ID_CATEGORIA
      AND     EE.ID_GENERE_MACCHINA   =     DD.ID_GENERE_MACCHINA
        AND     BB.DATA_CARICO             <=     GlobalDataRif
        AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
        AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))       =     kBruciatoreEssicatoio
        AND     EE.CATEGORIA            =     kCatFienagione
      AND   FF.ID_ALIMENTAZIONE IN (kBenzina, kGasolio);

        IF nCountFienagione > 0 THEN
            SELECT ID_GENERE_MACCHINA INTO GlobalIdFienagione
            FROM DB_TIPO_GENERE_MACCHINA
            WHERE LTRIM(RTRIM(CODIFICA_BREVE)) =     kBruciatoreEssicatoio;

          GlobalIdASM006  := 9;

        END IF;
      -- ER-MOD fine

          --  B --> BRUCIATORE
          SELECT COUNT(*) INTO nCountBruciatori
        FROM     DB_UTILIZZO                    BB,
                DB_MACCHINA                    CC,
                DB_DATI_MACCHINA              FF,
                DB_TIPO_GENERE_MACCHINA    DD,
                DB_TIPO_CATEGORIA            EE
        WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
        AND     CC.ID_MACCHINA          =     BB.ID_MACCHINA
        AND   CC.ID_MACCHINA          =    FF.ID_MACCHINA
      AND   EE.ID_CATEGORIA         =    FF.ID_CATEGORIA
      AND     EE.ID_GENERE_MACCHINA   =     DD.ID_GENERE_MACCHINA
        AND     BB.DATA_CARICO             <=     GlobalDataRif
        AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
        AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))       =     kBruciatoreEssicatoio
        AND     EE.CATEGORIA            =     KCatBruciatore
      AND   FF.ID_ALIMENTAZIONE IN (kBenzina, kGasolio);
    END IF;

          -- C --> MIETITREBBIATRICE
        select sum(num_rec)
            INTO nCountMietitrebbie
            from (  
          SELECT COUNT(*)  num_rec
        FROM     DB_UTILIZZO                    BB,
                DB_MACCHINA                    CC,
                DB_MATRICE                 EE,
                DB_TIPO_GENERE_MACCHINA    DD
        WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
        AND     CC.ID_MACCHINA          =     BB.ID_MACCHINA
        AND   CC.ID_MATRICE           =    EE.ID_MATRICE
        AND   DD.ID_GENERE_MACCHINA   =    EE.ID_GENERE_MACCHINA
        AND     BB.DATA_CARICO             <=     GlobalDataRif
        AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
        AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))  =     kMietitrebbiatrice
      AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
      UNION
      SELECT COUNT(*)  num_rec
        FROM     DB_UTILIZZO                    BB,
                DB_MACCHINA                    CC,
                DB_DATI_MACCHINA                 EE,
                DB_TIPO_GENERE_MACCHINA    DD
        WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
        AND     CC.ID_MACCHINA          =     BB.ID_MACCHINA
        AND   CC.ID_MACCHINA           =    EE.ID_MACCHINA
        AND   DD.ID_GENERE_MACCHINA   =    EE.ID_GENERE_MACCHINA
        AND     BB.DATA_CARICO             <=     GlobalDataRif
        AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
        AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))  =     kMietitrebbiatrice
      AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio));


        IF nCountMietitrebbie > 0 THEN
            SELECT ID_GENERE_MACCHINA INTO GlobalIdMietitrebbia
            FROM DB_TIPO_GENERE_MACCHINA
            WHERE LTRIM(RTRIM(CODIFICA_BREVE)) =    kMietitrebbiatrice;
        END IF;

  -- D --> ALLEVAMENTI BOVINI
      SELECT COUNT(*) INTO nCountBovini
    FROM    DB_ALLEVAMENTO    AA,
            DB_TIPO_CATEGORIA_ANIMALE BB
    WHERE     ID_DITTA_UMA                         =     GlobalDittaUma
    AND     DATA_INIZIO_VALIDITA                 <=     GlobalDataRif
    AND     ( DATA_FINE_VALIDITA                 >     GlobalDataRif OR DATA_FINE_VALIDITA IS NULL );
--    AND     BB.id_categoria_animale             =     AA.id_categoria_animale
--    AND     BB.id_specie_animale                =     kBovini;



  -- 3 RICERCA MACCHINA PIU' NOBILE DELLA DITTA
  BEGIN
    BEGIN

          SELECT     QUERI.CODIFICA,
                 QUERI.TOT, QUERI.POTENZA
                INTO nUno, nDue, nTre
        FROM     (
                SELECT 1 TIPO, DD.codifica_breve CODIFICA , COUNT(*)  TOT, 0 POTENZA
                    FROM    DB_UTILIZZO             BB,
                            DB_MACCHINA             CC,
                            DB_MATRICE              EE,
                            DB_TIPO_GENERE_MACCHINA DD
                    WHERE BB.id_ditta_uma             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO        >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                    AND DD.ID_GENERE_MACCHINA    = EE.ID_GENERE_MACCHINA
                    AND CC.ID_MATRICE  =  EE.ID_MATRICE
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        =     kTrattrice
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 2, DD.CODIFICA_BREVE CODIFICA, COUNT(*) TOT, 20 POTENZA
                    FROM  DB_UTILIZZO                BB,
                            DB_MACCHINA                CC,
                            DB_TIPO_GENERE_MACCHINA DD,
                            DB_MATRICE                 EE
                    WHERE BB.id_ditta_uma             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                    AND     DD.ID_GENERE_MACCHINA    =     EE.ID_GENERE_MACCHINA
                    AND     EE.ID_MATRICE             =     CC.ID_MATRICE
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        IN (kMotoAgricola,kMotoColtivatore)
                    AND     EE.POTENZA_KW             >     kKwRiferimento
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 3, DD.codifica_breve CODIFICA,COUNT(*) TOT, 10 POTENZA
                    FROM  DB_UTILIZZO                 BB,
                            DB_MACCHINA             CC,
                            DB_TIPO_GENERE_MACCHINA DD,
                            DB_MATRICE                 EE
                    WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                    AND     DD.ID_GENERE_MACCHINA    =     EE.ID_GENERE_MACCHINA
                    AND     EE.ID_MATRICE             =     CC.ID_MATRICE
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        IN (kMotoAgricola,kMotoColtivatore)
                    AND     EE.POTENZA_KW             <=     kKwRiferimento
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 4, DD.codifica_breve CODIFICA,COUNT(*) TOT, 0 POTENZA
                    FROM  DB_UTILIZZO                 BB,
                            DB_MACCHINA             CC,
                            DB_MATRICE                 EE,
                            DB_TIPO_GENERE_MACCHINA DD
                    WHERE    BB.ID_DITTA_UMA         =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.id_macchina             =     BB.id_macchina
                    AND DD.ID_GENERE_MACCHINA    = EE.ID_GENERE_MACCHINA
                    AND CC.ID_MATRICE  =  EE.ID_MATRICE
                    AND     LTRIM(RTRIM(DD.codifica_breve))        =     kMotoFalciatrice
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 5, DD.codifica_breve CODIFICA ,COUNT(*) TOT, 0 POTENZA
                    FROM  DB_UTILIZZO                 BB,
                            DB_MACCHINA             CC,
                            DB_MATRICE                 EE,
                            DB_TIPO_GENERE_MACCHINA DD
                    WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL)
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                AND DD.ID_GENERE_MACCHINA    = EE.ID_GENERE_MACCHINA
                AND CC.ID_MATRICE  =  EE.ID_MATRICE
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        =     kMotoZappa
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.CODIFICA_BREVE
            ORDER BY 1 ) QUERI
        WHERE QUERI.TOT > 0
        AND ROWNUM < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SELECT     QUERI.CODIFICA,
                 QUERI.TOT, QUERI.POTENZA
                INTO nUno, nDue, nTre
        FROM     (
                SELECT 1 TIPO, DD.codifica_breve CODIFICA , COUNT(*)  TOT, 0 POTENZA
                    FROM    DB_UTILIZZO             BB,
                            DB_MACCHINA             CC,
                            DB_DATI_MACCHINA              EE,
                            DB_TIPO_GENERE_MACCHINA DD
                    WHERE BB.id_ditta_uma             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO        >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                    AND DD.ID_GENERE_MACCHINA    = EE.ID_GENERE_MACCHINA
                    AND CC.ID_MACCHINA  =  EE.ID_MACCHINA
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        =     kTrattrice
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 2, DD.CODIFICA_BREVE CODIFICA, COUNT(*) TOT, 20 POTENZA
                    FROM  DB_UTILIZZO                BB,
                            DB_MACCHINA                CC,
                            DB_TIPO_GENERE_MACCHINA DD,
                            DB_DATI_MACCHINA                 EE
                    WHERE BB.id_ditta_uma             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                    AND     DD.ID_GENERE_MACCHINA    =     EE.ID_GENERE_MACCHINA
                    AND     EE.ID_MACCHINA             =     CC.ID_MACCHINA
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        IN (kMotoAgricola,kMotoColtivatore)
                    AND     EE.POTENZA             >     kKwRiferimento
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 3, DD.codifica_breve CODIFICA,COUNT(*) TOT, 10 POTENZA
                    FROM  DB_UTILIZZO                 BB,
                            DB_MACCHINA             CC,
                            DB_TIPO_GENERE_MACCHINA DD,
                            DB_DATI_MACCHINA                 EE
                    WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                    AND     DD.ID_GENERE_MACCHINA    =     EE.ID_GENERE_MACCHINA
                    AND     EE.ID_MACCHINA             =     CC.ID_MACCHINA
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        IN (kMotoAgricola,kMotoColtivatore)
                    AND     EE.POTENZA             <=     kKwRiferimento
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 4, DD.codifica_breve CODIFICA,COUNT(*) TOT, 0 POTENZA
                    FROM  DB_UTILIZZO                 BB,
                            DB_MACCHINA             CC,
                            DB_DATI_MACCHINA                 EE,
                            DB_TIPO_GENERE_MACCHINA DD
                    WHERE    BB.ID_DITTA_UMA         =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL )
                    AND     CC.id_macchina             =     BB.id_macchina
                    AND DD.ID_GENERE_MACCHINA    = EE.ID_GENERE_MACCHINA
                    AND CC.ID_MACCHINA  =  EE.ID_MACCHINA
                    AND     LTRIM(RTRIM(DD.codifica_breve))        =     kMotoFalciatrice
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.codifica_breve
                UNION
                SELECT 5, DD.codifica_breve CODIFICA ,COUNT(*) TOT, 0 POTENZA
                    FROM  DB_UTILIZZO                 BB,
                            DB_MACCHINA             CC,
                            DB_DATI_MACCHINA                 EE,
                            DB_TIPO_GENERE_MACCHINA DD
                    WHERE BB.ID_DITTA_UMA             =     GlobalDittaUma
                    AND     BB.DATA_CARICO             <=     GlobalDataRif
                    AND     ( BB.DATA_SCARICO         >     GlobalDataRif OR BB.DATA_SCARICO IS NULL)
                    AND     CC.ID_MACCHINA             =     BB.ID_MACCHINA
                AND DD.ID_GENERE_MACCHINA    = EE.ID_GENERE_MACCHINA
                AND CC.ID_MACCHINA  =  EE.ID_MACCHINA
                    AND     LTRIM(RTRIM(DD.CODIFICA_BREVE))        =     kMotoZappa
               AND   EE.ID_ALIMENTAZIONE IN (kBenzina, kGasolio)
                GROUP BY DD.CODIFICA_BREVE
            ORDER BY 1 ) QUERI
        WHERE QUERI.TOT > 0
        AND ROWNUM < 2;
    END;

    SELECT ID_GENERE_MACCHINA INTO GlobalIdGenere
    FROM DB_TIPO_GENERE_MACCHINA
    WHERE CODIFICA_BREVE = nUno;

   -- metto la fascia potenza se ho trovato una MTA o MC a seconda dei Kw
   IF nTre = 10 THEN
         GlobalIdFascia := 6;
     END IF;
   IF nTre = 20 THEN
         GlobalIdFascia := 7;
     END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            nNobile := FALSE;
    END;

    RETURN (TRUE);

EXCEPTION
   WHEN OTHERS THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE OPERAZIONI_PRELIMINARI: '||SQLERRM;
        RETURN (FALSE);
END OPERAZIONI_PRELIMINARI;

FUNCTION OPERAZIONI_DI_CHIUSURA (pDittaUma         IN NUMBER,
                                  pErr            OUT varchar2,
                                 pDesErr      OUT VARCHAR2) RETURN BOOLEAN IS

nIdConsistenza        NUMBER(10);
dDataConsistenza    DATE;

BEGIN
    BEGIN
        SELECT SA.EXT_ID_CONSISTENZA, SA.DATA_CONSISTENZA
          INTO nIdConsistenza, dDataConsistenza
          FROM DB_SUPERFICIE_AZIENDA SA,DB_DITTA_UMA DU
         WHERE DU.ID_DITTA_UMA = pDittaUma
         AND   DU.EXT_ID_AZIENDA = SA.EXT_ID_AZIENDA
         AND   SA.ID_DITTA_UMA = DU.ID_DITTA_UMA
           and SA.data_fine_validita is null
           and SA.data_scarico is null
         GROUP BY SA.EXT_ID_CONSISTENZA, SA.DATA_CONSISTENZA;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
         nIdConsistenza := NULL;
         dDataConsistenza := NULL;
    WHEN OTHERS        THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE OPERAZIONI_DI_CHIUSURA: '||SQLERRM;
        RETURN (FALSE);
    END;

    IF nIdConsistenza IS NULL THEN -- Possono non esserci terreni
        BEGIN
            SELECT EXT_ID_CONSISTENZA, DATA_CONSISTENZA
              INTO nIdConsistenza, dDataConsistenza
              FROM DB_ALLEVAMENTO
             WHERE ID_DITTA_UMA = pDittaUma
               and data_fine_validita is null
               and data_scarico is null
             GROUP BY EXT_ID_CONSISTENZA, DATA_CONSISTENZA;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             nIdConsistenza := NULL;
             dDataConsistenza := NULL;
        WHEN OTHERS        THEN
            PErr        :=    SQLCODE;
            PDesErr    :=    'ERRORE OPERAZIONI_DI_CHIUSURA: '||SQLERRM;
            RETURN (FALSE);
        END;
    END IF;

    UPDATE DB_DOMANDA_ASSEGNAZIONE
    SET DATA_RICALCOLO_CARBURANTE = NULL, DATA_RIFERIMENTO = GlobalDataRif,
        EXT_ID_INTERMEDIARIO = nIntermediario,
        EXT_ID_CONSISTENZA = nIdConsistenza,
        DATA_CONSISTENZA   = dDataConsistenza
    WHERE ID_DOMANDA_ASSEGNAZIONE = GlobalDomanda;

    RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
        PErr        :=    SQLCODE;
        PDesErr    :=    'ERRORE OPERAZIONI_DI_CHIUSURA: '||SQLERRM;
        RETURN (FALSE);
END OPERAZIONI_DI_CHIUSURA;


PROCEDURE MAIN(pDittaUma           NUMBER,
               pIntermediario      NUMBER,
               pUtente             NUMBER,
               pIdDomanda      OUT NUMBER,
               pErr            OUT VARCHAR2,
               pDesErr         OUT VARCHAR2) IS

  nBovini NUMBER;
BEGIN

  pIdDomanda           := 0;
  GlobalDittaUma       := pDittaUma;
  GlobalDataRif        := SYSDATE;
  nIntermediario       := pIntermediario;
  nUtente              := pUtente;
  nNobile              := TRUE;
  GlobalDomanda        := NULL;
  GlobalIdGenere       := NULL;
  GlobalIdFascia       := NULL;
  GlobalIdEssicatore   := NULL;
  GlobalIdFienagione   := NULL;
  GlobalIdMietitrebbia := NULL;
  bCalcolo             := FALSE;
  bInsDomanda          := FALSE;

  IF NOT RICERCA_DITTA(PERR, PDESERR) THEN
    RAISE ERR_PROCESSO;
  END IF;

  IF NOT OPERAZIONI_PRELIMINARI(nBovini,PERR, PDESERR) THEN
    RAISE ERR_PROCESSO;
  END IF;

  IF bCalcolo THEN
    IF NOT CARBURANTE_X_COLTURE(PERR, PDESERR) THEN
      RAISE ERR_PROCESSO;
    END IF;
  END IF;

  IF NOT CARBURANTE_X_MACCHINE(nBovini,PERR, PDESERR) THEN
    RAISE ERR_PROCESSO;
  END IF;

  IF bCalcolo THEN
    IF NOT CARBURANTE_X_SERRE(PERR, PDESERR) THEN
      RAISE ERR_PROCESSO;
    END IF;

    IF NOT CARBURANTE_X_ALLEVAMENTI(PERR, PDESERR) THEN
      RAISE ERR_PROCESSO;
    END IF;
  END IF;

  IF NOT OPERAZIONI_DI_CHIUSURA(pDittaUma, PERR, PDESERR) THEN
    RAISE ERR_PROCESSO;
  END IF;

  PCK_SMRUMA_ASSEGNAZ_CARB.CALCOLO_ASSEGNAZIONE_CARB(GlobalDomanda,'B',NULL,pUtente,PDesErr,PErr);

  IF PErr IS NOT NULL THEN
    RAISE ERR_PROCESSO;
  END IF;

  pIdDomanda := GlobalDomanda;

  COMMIT;

EXCEPTION
  WHEN ERR_PROCESSO THEN
    ROLLBACK;
  WHEN OTHERS THEN
    PErr    := SQLCODE;
    PDesErr := SUBSTR(SQLERRM,1,100);
END MAIN;

END Pck_Calcolo_Bonus;
/
