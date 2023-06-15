CREATE OR REPLACE package PACK_CONTROLLI is

    -- id tipo conduzione conto proprio
    knIdContoProprio                    CONSTANT DB_TIPO_CONDUZIONE.ID_CONDUZIONE%TYPE:=1;
    -- id tipo conduzione conto terzi
    knIdContoTerzi                      CONSTANT DB_TIPO_CONDUZIONE.ID_CONDUZIONE%TYPE:=2;
    -- id tipo conduzione conto proprio / terzi
    knIdContoProprioTerzi               CONSTANT DB_TIPO_CONDUZIONE.ID_CONDUZIONE%TYPE:=3;
    -- parametro contenente giorno e mese da cui la dichiarazione di consistenza
    -- può essere considerata valida (da associare all'anno di SYSDATE)
    kvCodGiornoMeseDataValidaz          CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE := 'UMDV';
    -- id_regione basilicata
    kvIdRegioneBasilicata                 CONSTANT REGIONE.ID_REGIONE%TYPE:='17';
    -- id titolo possesso asservimento
    knIdTitoloPossessoAsservimento      CONSTANT DB_CONDUZIONE_DICHIARATA.ID_TITOLO_POSSESSO%TYPE:= 5;
    -- codice del parametro che contiene l'hint per il controllo UMA15
    kvCodHintUma15                      CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE := 'UMHI';
    -- identificativo tipo procedimento UMA
    knIdProcedimentoUMA                 CONSTANT DB_TIPO_PROCEDIMENTO.ID_PROCEDIMENTO%TYPE:=1;
    -- identificativo tipo procedimento NEWMA
    knIdProcedimentoNEWMA               CONSTANT DB_TIPO_PROCEDIMENTO.ID_PROCEDIMENTO%TYPE:=18;
    -- codice lavorazione effettuata
    kvCodLavorazioneEffettuata          CONSTANT DB_CAMPAGNA_CONTOTERZISTI.VERSO_LAVORAZIONI%TYPE:='E';
    -- codice lavorazione subita
    kvCodLavorazioneSubita              CONSTANT DB_CAMPAGNA_CONTOTERZISTI.VERSO_LAVORAZIONI%TYPE:='S';
    -- codice parametro percentuale massima possibile tra superficie ore in fattura e superficie ore lavorate
    kvCodParametroPercMassima           CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE:='UM27';
    -- ritorno a capo HTMLPL
    kvACapoHTMLPL                       CONSTANT VARCHAR2(5):='<br/>';
    -- id tipologia azienda cooperativa
    knIdTipoAziendaCooperativa          CONSTANT DB_TIPO_TIPOLOGIA_AZIENDA.ID_TIPOLOGIA_AZIENDA%TYPE:=4;
    -- id tipologia azienda consorzio
    knIdTipoAziendaConsorzio            CONSTANT DB_TIPO_TIPOLOGIA_AZIENDA.ID_TIPOLOGIA_AZIENDA%TYPE:=5;
    -- identificativo tipo fase cessazione ditta uma
    knIdTipoFaseCessazioneDittaUma      CONSTANT DB_TIPO_FASE.ID_TIPO_FASE%TYPE:='S';
    -- identificativo stato domanda di assegnazione validata
    knIdStatoDomandaValidata            CONSTANT DB_TIPO_STATO_DOMANDA.ID_STATO_DOMANDA%TYPE:=30;
    -- identificativo stato domanda di acconto validata
    knIdStatoDomAccontoValidato         CONSTANT DB_TIPO_STATO_DOMANDA.ID_STATO_DOMANDA%TYPE:=35;

    -- tipo record di appoggio per il reperimento di alcuni
    -- dati della macchina
    Type TypDatiMacchina IS RECORD
    (vDescCategoriaMacchina DB_TIPO_CATEGORIA.DESCRIZIONE%TYPE, -- tipologia
     vTarga                 DB_NUMERO_TARGA.NUMERO_TARGA%TYPE,
     vTipoMacchina          DB_MATRICE.TIPO_MACCHINA%TYPE,
     vDescMarca             DB_TIPO_MARCA.DESCRIZIONE%TYPE);  -- marca

    PROCEDURE  ESEGUI_CONTROLLI(P_ID_DITTA_UMA      IN     DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                                   P_ANNO_ASSEGNAZIONE IN  NUMBER,
                                   P_TIPO_CONTROLLO IN        DB_CONTROLLO.BLOCCANTE%TYPE,
                                P_TIPO_FASE         IN        VARCHAR2,
                                   P_ESITO_OUT       IN OUT    VARCHAR2,
                                   P_MESSAGGIO       IN OUT    VARCHAR2);


END;
/


CREATE OR REPLACE package body PACK_CONTROLLI is
EsciRountine       exception;
N_ID_AZIENDA      DB_AZIENDA.ID_AZIENDA%TYPE;
S_FLAG_AZIENDA_PROVVISORIA  VARCHAR2(1);
N_ID_FORMA_GIURIDICA        DB_TIPO_FORMA_GIURIDICA.ID_FORMA_GIURIDICA%TYPE;
N_ID_CONDUZIONE                DB_TIPO_CONDUZIONE.ID_CONDUZIONE%TYPE;


RET_OK        constant char(1) := '0';      -- Elaborazione terminata correttamente
RET_ERR_PROC  constant char(1) := '1';      -- Errore gestito dalla stored procedure (Eccezione es. record mancante, errore oracle)
RET_ERR_BLOC  constant char(1) := '2';      -- Elaborazione terminata correttamente, ma con errori bloccanti/gravi  (non va avanti)
RET_ERR_WARN  constant char(1) := '3';      -- Elaborazione terminata correttamente, ma con errori warning (si può andare avanti)
P_ESITO          VARCHAR2(1);
S_CUAA          DB_ANAGRAFICA_AZIENDA.CUAA%TYPE;
GlobalDataRif DATE;
nGlobalConduzione               DB_DATI_DITTA.ID_CONDUZIONE%TYPE;
S_PARTITA_IVA                   DB_ANAGRAFICA_AZIENDA.PARTITA_IVA%TYPE;
vGlProvReaCCIA                 DB_ANAGRAFICA_AZIENDA.CCIAA_PROVINCIA_REA%TYPE;
B_SERRE                           BOOLEAN;

/*
P_TIPO_CONTROLLO          =    'G'            GRAVE
                                 'B'            BLOCCANTE
                               'T'            TUTTI

P_TIPO_FASE                 =       'I'            IMPORTA DATI
                                'A'            ASSEGNAZIONE BASE E SUPPLEMENTARE (SIA TRASMISSIONE CHE PRESA IN CARICO)
                               'C'            CONTROLLI
*/


    /*********************************************************************
    Controlla se per la ditta uma data in input c'è stata un'assegnazione
    di carburante nell'anno dato in input
    Tipo: function
    input: pIdDittaUma, pAnnoRif
    output: nessuno
    ritorno: TRUE / FALSE
    *********************************************************************/
    FUNCTION ExistsFullOfFuelForDittaAnno (pIdDittaUma IN DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
                                           pAnnoRif    IN INTEGER
                                           ) RETURN BOOLEAN IS
        nRec INTEGER:=0;
        bRet BOOLEAN:=FALSE;
    BEGIN
        SELECT COUNT(QA.ID_QUANTITA_ASSEGNATA)
          INTO nRec
          FROM DB_DOMANDA_ASSEGNAZIONE DA,
               DB_ASSEGNAZIONE_CARBURANTE AC,
               DB_QUANTITA_ASSEGNATA QA
         WHERE DA.ID_DITTA_UMA = pIdDittaUma
           AND DA.ID_STATO_DOMANDA IN (knIdStatoDomandaValidata, knIdStatoDomAccontoValidato)
           AND TO_CHAR(DA.DATA_VALIDAZIONE,'YYYY') = pAnnoRif
           AND DA.ID_DOMANDA_ASSEGNAZIONE = AC.ID_DOMANDA_ASSEGNAZIONE
           AND AC.ANNULLATO IS NULL
           AND AC.ID_ASSEGNAZIONE_CARBURANTE = QA.ID_ASSEGNAZIONE_CARBURANTE
           AND QA.ASSEGNAZIONE_CONTO_TERZI > 0;

        IF nRec > 0 THEN
           bRet := TRUE;
        END IF;

        RETURN bRet;

    END ExistsFullOfFuelForDittaAnno;

    /*********************************************************************
    Controlla se per l'azienda data in input sono presenti soci collegati
    validi alla data data in input
    Tipo:   function
    input:  pIdAzienda, pDataRif
    output: nessuno
    ritorno: TRUE / FALSE
    *********************************************************************/
    FUNCTION EsisteSocioPerAziendaEData (pIdAzienda    IN DB_AZIENDA_COLLEGATA.ID_AZIENDA%TYPE,
                                         pDataRif      IN DATE) RETURN BOOLEAN IS
         nNumRec    INTEGER:=0;
         bRet       BOOLEAN:=FALSE;
    BEGIN
         SELECT COUNT(ID_AZIENDA_COLLEGATA)
           INTO nNumRec
           FROM DB_AZIENDA_COLLEGATA
          WHERE ID_AZIENDA = pIdAzienda
            AND DATA_INGRESSO <= pDataRif
            AND NVL(DATA_USCITA,pDataRif) >= pDataRif
            AND NVL(DATA_FINE_VALIDITA,pDataRif) >= pDataRif;

          IF nNumRec > 0 THEN
             bRet := TRUE;
          END IF;

          RETURN bRet;
    END EsisteSocioPerAziendaEData;

    /*********************************************************************
    Se sono presenti records su DITTA_FORZATA per la ditta uma e
    l'anno passati in input mi restituisce TRUE altrimenti FALSE
    Tipo:   function
    input:  pIdDittaUma, pAnnoRif
    output: nessuno
    ritorno: TRUE / FALSE
    *********************************************************************/
     FUNCTION IsDittaUmaForzata (pIdDittaUma IN DB_CONTROLLO_DOMANDA.ID_DITTA_UMA%TYPE,
                                 pAnnoRif    IN DB_CONTROLLO_DOMANDA.ANNO_ASSEGNAZIONE%TYPE
                                ) RETURN BOOLEAN IS
        nNumRec INTEGER:=0;
        bRet    BOOLEAN:=FALSE;
     BEGIN

        SELECT COUNT(ID_DITTA_FORZATA)
          INTO nNumRec
          FROM DITTA_FORZATA
         WHERE ID_DITTA_UMA = pIdDittaUma
           AND ANNO_RIFERIMENTO = pAnnoRif;

        IF nNumRec > 0 THEN
           bRet := TRUE;
        END IF;

        RETURN bRet;

     END IsDittaUmaForzata;

    /*********************************************************************
    Dato un identificativo di macchina seleziona alcune informazioni
    quali la tipologia il numero di targa e la descrizione della categoria
    e della marca
    Tipo:   function
    input:  pIdMacchina
    output: nessuno
    ritorno: TypDatiMacchina
    *********************************************************************/
     FUNCTION SelectTDatiMacchinaById(pIdMacchina IN DB_MACCHINA.ID_MACCHINA%TYPE)
     RETURN TypDatiMacchina IS
          recDatiMacchina TypDatiMacchina;
     BEGIN

          SELECT TC.DESCRIZIONE,
                 NT.NUMERO_TARGA,
                 MA.TIPO_MACCHINA,
                 TM.DESCRIZIONE
            INTO recDatiMacchina
            FROM DB_MACCHINA M,
                 DB_MATRICE MA,
                 DB_TIPO_CATEGORIA TC,
                 DB_TIPO_MARCA TM,
                 DB_NUMERO_TARGA NT
           WHERE M.ID_MACCHINA = pIdMacchina
             AND M.ID_MATRICE = MA.ID_MATRICE
             AND MA.ID_CATEGORIA = TC.ID_CATEGORIA
             AND MA.ID_MARCA = TM.ID_MARCA
             AND M.ID_MACCHINA = NT.ID_MACCHINA (+);

          RETURN recDatiMacchina;

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
             BEGIN
              SELECT TC.DESCRIZIONE,
                     NT.NUMERO_TARGA,
                     DM.MARCA,
                     NULL
                INTO recDatiMacchina
                FROM DB_MACCHINA M,
                     DB_DATI_MACCHINA DM,
                     DB_TIPO_CATEGORIA TC,
                     DB_NUMERO_TARGA NT
               WHERE M.ID_MACCHINA = pIdMacchina
                 AND M.ID_MACCHINA = DM.ID_MACCHINA
                 AND DM.ID_CATEGORIA = TC.ID_CATEGORIA
                 AND M.ID_MACCHINA = NT.ID_MACCHINA (+);

              RETURN recDatiMacchina;

             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     RETURN NULL;
             END;
     END SelectTDatiMacchinaById;

    /*********************************************************************
    Accoda al messaggio dato in input / output la stringa data in input se
    essa non provoca un supero della dimensione massima
    Tipo:    procedure
    Input:   pMessaggio, vStringa
    Output:  pMessaggio
    Return:  nessuno
    ********************************************************************/
    PROCEDURE AccodaMessaggioAnomalia ( pMessaggio IN OUT DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE,
                                        vStringa   IN VARCHAR2) IS

        nMaxLenght  INTEGER:=0; -- conterra la lunghezza massima delle colonna MESSAGGIO_ESTESO
        nLengthPMsg INTEGER:=0; -- conterra la lunghezza del messaggio attuale
        nLengthStr  INTEGER:=0; -- conterra la lunghezza della stringa che si vuole aggiungere al messaggio attuale
        nLengthRim  INTEGER:=0; -- conterra la lunghezza ancora disponibili prima di raggiungere la lunghezza massima

    BEGIN
        -- mi cerco la lunghezza
        -- massima per la colonna messaggio_esteso
        SELECT DATA_LENGTH
          INTO nMaxLenght
          FROM USER_TAB_COLUMNS
         WHERE TABLE_NAME = 'DB_CONTROLLO_DOMANDA'
           AND COLUMN_NAME = 'ULTERIORE_DESCRIZIONE';
        -- setto la lunghezza del messaggio attuale
        nLengthPMsg := NVL(LENGTH(pMessaggio),0);
        -- setto la lunghezza della stringa da aggiungere al messaggio attuale
        nLengthStr := NVL(LENGTH(vStringa),0);
        -- se la somma della lunghezza del messagio attuale + la stringa da aggiungere
        -- e minore della lunghezza massima disponibile
        IF nLengthPMsg + nLengthStr <= nMaxLenght THEN
           -- accoda la stringa nel messaggio
           pMessaggio := pMessaggio || vStringa;
        ELSE
           -- altrimenti mi calcolo la rimanenza disponibile
           nLengthRim := nMaxLenght - nLengthPMsg;
           IF nLengthRim > 0 THEN
              -- e se e maggiore di zero accodo solamente un pezzo della stringa
              pMessaggio := pMessaggio || substr(vStringa,1,nLengthRim);
           END IF;
        END IF;

    END AccodaMessaggioAnomalia;

   /*********************************************************************
    Dato l'id_azienda mi preleva l'ultima dichiarazione di consistenza
    disponibile per il procedimento di UMA
    Tipo:   function
    input:  pIdAzienda
    output: nessuno
    ritorno: DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE
    *********************************************************************/
    FUNCTION SelLastDichConsistByIdAzienda (pIdAzienda IN DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE)
    RETURN DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE IS
        recTDichCons DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE;
    BEGIN
       SELECT *
       INTO recTDichCons
          FROM db_dichiarazione_consistenza DC
         WHERE id_azienda = pIdAzienda
          and data_protocollo = (select max(dc1.data_protocollo)
                                  from   db_dichiarazione_consistenza DC1
                                  WHERE dc1.id_azienda = dc.id_azienda
                                   AND dc1.data_protocollo IS NOT NULL
                                   AND dc1.numero_protocollo IS NOT NULL
                                   AND NOT EXISTS (SELECT MEP.ID_MOTIVO_ESCLUSO_PROCEDIMENTO
                                       FROM DB_MOTIVO_ESCLUSO_PROCEDIMENTO MEP
                                      WHERE DC1.ID_MOTIVO_DICHIARAZIONE = MEP.ID_MOTIVO_DICHIARAZIONE
                                        AND MEP.ID_PROCEDIMENTO = knIdProcedimentoUma ));

        RETURN recTDichCons;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
             RETURN NULL;
    END SelLastDichConsistByIdAzienda;

   /*********************************************************************
    Ricerca il codice parametro nella tavola DB_PARAMENTRO e ne
    espone il valore
    Tipo:    function
    input:  pCodParamentro
    output: nessuno
    ritorno: VARCHAR2
    *********************************************************************/
    FUNCTION SelectValoreParametro (pCodParametro IN VARCHAR2) RETURN VARCHAR2 IS
        vValParametro DB_PARAMETRO.VALORE%TYPE;
    BEGIN

        SELECT VALORE
          INTO vValParametro
          FROM DB_PARAMETRO
         WHERE ID_PARAMETRO = pCodParametro;

        RETURN vValParametro;

    END SelectValoreParametro;

   /*********************************************************************
    Data una SIGLA_PROVNCIA ed un ID_REGIONE controlla se la provincia
    è nella regione
    Tipo:    function
    input:  pSiglaProv, pIdRegione
    output: nessuno
    ritorno: TRUE / FALSE
    *********************************************************************/
    FUNCTION IsSiglaProvinciaInRegione (pSiglaProv IN PROVINCIA.SIGLA_PROVINCIA%TYPE,
                                        pIdRegione IN PROVINCIA.ID_REGIONE%TYPE ) RETURN BOOLEAN IS
        bRet        BOOLEAN:=FALSE;
        nContIdProv INTEGER:=0;
    BEGIN

        SELECT COUNT(ISTAT_PROVINCIA)
          INTO nContIdProv
          FROM PROVINCIA
         WHERE ID_REGIONE = pIdRegione
           AND SIGLA_PROVINCIA = pSiglaProv;

        IF nContIdProv > 0 THEN
           bRet := TRUE;
        END IF;

        RETURN bRet;
    END IsSiglaProvinciaInRegione;

   /*********************************************************************
    Dato un ISTAT_PROVINCIA ed un ID_REGIONE controllo se la provincia
    ricade nella regione
    è nella regione
    Tipo:    function
    input:  pIstatProv , pIdRegione
    output: nessuno
    ritorno: VARCHAR2
    *********************************************************************/
    FUNCTION IsIstatProvinciaInRegione (pIstatProv IN PROVINCIA.ISTAT_PROVINCIA%TYPE,
                                        pIdRegione IN PROVINCIA.ID_REGIONE%TYPE ) RETURN BOOLEAN IS
        bRet        BOOLEAN:=FALSE;
        nContIdProv INTEGER:=0;
    BEGIN

        SELECT COUNT(ISTAT_PROVINCIA)
          INTO nContIdProv
          FROM PROVINCIA
         WHERE ID_REGIONE = pIdRegione
           AND ISTAT_PROVINCIA = pIstatProv;

        IF nContIdProv > 0 THEN
           bRet := TRUE;
        END IF;

        RETURN bRet;
    END IsIstatProvinciaInRegione;

   /*********************************************************************
    Dato un identificativo azienda mi restrituisce TRUE se la tipologia
    di azienda a cui è associato ha il FLAG_FORMA_ASSOCIATA ad 'S'
    altrimenti FALSE (controllo anche che la tipologia azienda sia cooperativa o consorzio)
    Tipo:   function
    input:  pIdAzienda
    output: nessuno
    ritorno: TRUE / FALSE
    *********************************************************************/
    FUNCTION IsAziendaConsorzio (pIdAzienda IN DB_ANAGRAFICA_AZIENDA.ID_AZIENDA%TYPE)
    RETURN BOOLEAN IS
        nCount INTEGER:=0;
        bRet   BOOLEAN:=FALSE;
    BEGIN

        SELECT COUNT(AZ.ID_ANAGRAFICA_AZIENDA)
          INTO nCount
          FROM DB_ANAGRAFICA_AZIENDA AZ,
               DB_TIPO_TIPOLOGIA_AZIENDA TTA
         WHERE AZ.ID_AZIENDA = pIdAzienda
           AND AZ.DATA_FINE_VALIDITA IS NULL
           AND AZ.ID_TIPOLOGIA_AZIENDA = TTA.ID_TIPOLOGIA_AZIENDA
           AND TTA.FLAG_FORMA_ASSOCIATA = 'S'
           AND TTA.ID_TIPOLOGIA_AZIENDA IN (knIdTipoAziendaCooperativa,
                                            knIdTipoAziendaConsorzio);

        IF nCount > 0 THEN
           bRet:=TRUE;
        END IF;

        RETURN bRet;

    END IsAziendaConsorzio;

FUNCTION SCRIVI_SEGNALAZIONE (P_ID_DITTA_UMA   IN   DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                               P_ANNO_ASSEGNAZIONE IN  NUMBER,
                               P_ID_CONTROLLO   IN     DB_CONTROLLO.ID_CONTROLLO%TYPE,
                              P_DESCRIZIONE       IN     DB_CONTROLLO_DOMANDA.EXT_ID_MESSAGGIO_ERRORE%TYPE,
                              P_DESCRIZIONE_ULTERIORE IN DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE,
                                  P_MESSAGGIO      IN OUT varchar2,
                              P_ESITO             IN OUT Varchar2) return boolean IS

BEGIN

      INSERT INTO DB_CONTROLLO_DOMANDA (ID_CONTROLLO_DOMANDA, ID_CONTROLLO, EXT_ID_MESSAGGIO_ERRORE,
             ULTERIORE_DESCRIZIONE, ID_DITTA_UMA, ANNO_ASSEGNAZIONE) VALUES
             (SEQ_CONTROLLO_DOMANDA.NEXTVAL, P_ID_CONTROLLO, P_DESCRIZIONE, P_DESCRIZIONE_ULTERIORE,
             P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE);

     RETURN (TRUE);

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO   := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: PROCEDURA SCRIVI_SEGNALAZIONE - ' || sqlerrm;
    P_ESITO         := RET_ERR_PROC;
    RETURN (FALSE);
END SCRIVI_SEGNALAZIONE;

PROCEDURE ESTRAI_ERRORE_COMUNE (P_ID_ERR     IN        DB_CONTROLLO_DOMANDA.EXT_ID_MESSAGGIO_ERRORE%TYPE,
                                    P_MESSAGGIO  IN OUT varchar2,
                                  P_ESITO           IN OUT Varchar2) IS

BEGIN
         SELECT DESCRIZIONE
        INTO  P_MESSAGGIO
        FROM DB_MESSAGGIO_ERRORE
       WHERE ID_MESSAGGIO_ERRORE = P_ID_ERR;
EXCEPTION
WHEN NO_DATA_FOUND THEN
     P_MESSAGGIO   := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: PROCEDURA GESTIONE_ERRORE - ' ||
                    'ERRORE NON CODIFICATO ['||TO_CHAR(P_ID_ERR)||'].';
     P_ESITO         := RET_ERR_PROC;
WHEN OTHERS then
    P_MESSAGGIO   := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: PROCEDURA ESTRAI_ERRORE_COMUNE - ' || sqlerrm;
    P_ESITO         := RET_ERR_PROC;
END ESTRAI_ERRORE_COMUNE;

FUNCTION ControlliGiustificati(P_ID_DITTA_UMA  DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                               P_ID_CONTROLLO  DB_CONTROLLO.ID_CONTROLLO%TYPE) RETURN BOOLEAN IS

  nCont  PLS_INTEGER;
BEGIN

  SELECT COUNT(*)
  INTO   nCont
  FROM   SMRGAA.DB_TIPO_CONTROLLO_FASE TCF, SMRGAA.DB_TIPO_CONTROLLO TC
  WHERE  TCF.ID_CONTROLLO                  = TC.ID_CONTROLLO
  AND    TC.CODICE_CONTROLLO               = P_ID_CONTROLLO
  AND    TCF.FASE                          = 1 -- Fase = dichiarazione di consistenza per ANAG
  AND    TCF.FLAG_DOCUMENTO_GIUSTIFICATIVO IS NOT NULL;
    
  IF nCont != 0 THEN
    SELECT COUNT(*)
    INTO   nCont
    FROM   DB_DICHIARAZIONE_CORREZIONE DC, DB_DICHIARAZIONE_CONSISTENZA DCO, SMRGAA.DB_TIPO_CONTROLLO TC
    WHERE  DC.ID_DICHIARAZIONE_CONSISTENZA = DCO.ID_DICHIARAZIONE_CONSISTENZA
    AND    DCO.ID_AZIENDA                  = DC.ID_AZIENDA
    AND    DC.ID_AZIENDA                   = N_ID_AZIENDA
    AND    DCO.DATA                        = (SELECT MAX(DATA) 
                                              FROM   DB_DICHIARAZIONE_CONSISTENZA 
                                              WHERE  ID_AZIENDA              = DC.ID_AZIENDA 
                                              AND    ID_MOTIVO_DICHIARAZIONE NOT IN (SELECT ID_MOTIVO_DICHIARAZIONE 
                                                                                     FROM   DB_MOTIVO_ESCLUSO_PROCEDIMENTO 
                                                                                     WHERE  ID_PROCEDIMENTO = 1))
    AND    DC.ID_CONTROLLO                 = TC.ID_CONTROLLO
    AND    TC.CODICE_CONTROLLO             = P_ID_CONTROLLO;
  END IF;
  
  IF nCont = 0 THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END ControlliGiustificati;
  
PROCEDURE GESTIONE_ERRORE(P_ID_DITTA_UMA                DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                            P_ANNO_ASSEGNAZIONE         NUMBER,
                            P_ID_CONTROLLO                   DB_CONTROLLO.ID_CONTROLLO%TYPE,
                          P_TIPO_CONTROLLO            DB_CONTROLLO.BLOCCANTE%TYPE,
                          P_ID_ERR                       DB_CONTROLLO_DOMANDA.EXT_ID_MESSAGGIO_ERRORE%TYPE,
                          P_MESSAGGIO_ESTESO           DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE,
                          P_MESSAGGIO           IN OUT VARCHAR2,
                          P_ESITO               IN OUT VARCHAR2) IS
  
  bFn           BOOLEAN := FALSE;
  nLast         PLS_INTEGER;
  vIdControllo  DB_CONTROLLO.ID_CONTROLLO%TYPE;
BEGIN
  IF P_ESITO <> '0' THEN
    
    P_ESITO := RET_ERR_WARN;
    
    IF P_ID_CONTROLLO = 'AEP02' THEN
      nLast := 2;
    ELSE
      nLast := 1;
    END IF;
    
    FOR i IN 1..nLast LOOP
      IF nLast = 2 THEN
        IF i = 1 THEN
          vIdControllo := 'AEP02';
        ELSE
          IF NOT bFn THEN
            vIdControllo := 'AEP01';
          ELSE
            vIdControllo := NULL;
          END IF;
        END IF;
      ELSE
        vIdControllo := P_ID_CONTROLLO;
      END IF;
      
      IF vIdControllo IS NOT NULL THEN
        bFn := ControlliGiustificati(P_ID_DITTA_UMA,vIdControllo);
      END IF;
    END LOOP;
    
    IF NOT bFn THEN
      IF NOT SCRIVI_SEGNALAZIONE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, p_id_err, P_MESSAGGIO_ESTESO,
                                    P_MESSAGGIO, P_ESITO) THEN
      
        P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: PROCEDURA GESTIONE_ERRORE - ' || sqlerrm;
        P_ESITO     := RET_ERR_PROC;
        END IF;
    END IF;
  END IF;
END GESTIONE_ERRORE;

PROCEDURE UMA00(P_ID_DITTA_UMA           DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE      NUMBER,
                P_ID_CONTROLLO           DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO         DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO          OUT VARCHAR2,
                P_ESITO              OUT VARCHAR2) IS
BEGIN
  P_ESITO := RET_ERR_WARN;
  GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 3746, NULL, P_MESSAGGIO, P_ESITO);
END UMA00; 

PROCEDURE UMA01 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
BEGIN
     SELECT COUNT(*)
     INTO    N_CONTATORE
     FROM   DB_BLOCCO_DITTA
     WHERE  ID_DITTA_UMA = P_ID_DITTA_UMA
       AND  DATA_SBLOCCO IS NULL;

     IF N_CONTATORE > 0 THEN
         P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1039, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA01 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA01;

PROCEDURE UMA02(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN  NUMBER,
                P_ID_CONTROLLO               IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                 IN OUT varchar2,
                P_ESITO                      IN OUT Varchar2) IS

     DataUltimaDichiarazione     date;
     DataConsistenzaPratica      date;
     vGiornoMese                 DB_PARAMETRO.VALORE%TYPE;
begin
   cerco il parametro contenente il giorno ed il mese
   vGiornoMese := SelectValoreParametro(kvCodGiornoMeseDataValidaz);
   -- calcolo la data dalla quale la dichiarazione di consistenza può essere considerata validita per uma
   DataConsistenzaPratica := TO_DATE(vGiornoMese || '/' || to_number(to_char(sysdate, 'yyyy')),'DD/MM/YYYY');  
   -- Preleva la data della dichiarazione di consistenza collegata alla pratica

        SELECT max(data_protocollo) --data_inserimento_dichiarazione
          INTO dataultimadichiarazione
          FROM db_dichiarazione_consistenza DC
         WHERE id_azienda = n_id_azienda
           /*AND data =
                 (SELECT MAX (DC.DATA)  
                    FROM DB_DICHIARAZIONE_CONSISTENZA DC -- per evitare certe tipologie di motivo dichiarazione
                   WHERE DC.ID_AZIENDA = n_id_azienda
                     AND NOT EXISTS (SELECT MEP.ID_MOTIVO_ESCLUSO_PROCEDIMENTO
                                       FROM DB_MOTIVO_ESCLUSO_PROCEDIMENTO MEP
                                      WHERE DC.ID_MOTIVO_DICHIARAZIONE = MEP.ID_MOTIVO_DICHIARAZIONE
                                        AND MEP.ID_PROCEDIMENTO = knIdProcedimentoUma ))*/
           AND data_protocollo IS NOT NULL      
           AND numero_protocollo IS NOT NULL   -- protocollazione dichiarazione di consistenza
           AND NOT EXISTS (SELECT MEP.ID_MOTIVO_ESCLUSO_PROCEDIMENTO
                                       FROM DB_MOTIVO_ESCLUSO_PROCEDIMENTO MEP
                                      WHERE DC.ID_MOTIVO_DICHIARAZIONE = MEP.ID_MOTIVO_DICHIARAZIONE
                                        AND MEP.ID_PROCEDIMENTO = knIdProcedimentoUma );

   -- nel contronto utilizzo la DataConsistenzaPratica
   IF DataUltimaDichiarazione is null or DataUltimaDichiarazione < DataConsistenzaPratica then
      P_ESITO := RET_ERR_WARN;
      --[UMA02] Per l'azienda in esame non è presente alcuna validazione di consistenza sull'Anagrafe delle Imprese Agricole ed Agro-alimentari
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1044, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (1044, P_MESSAGGIO,P_ESITO);
   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA02 ' || SQLERRM;
END UMA02;

PROCEDURE UMA03 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN  NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
BEGIN
     SELECT COUNT(*)
       INTO N_CONTATORE
        FROM DB_ALLEVAMENTO A
        WHERE A.ID_DITTA_UMA     = P_ID_DITTA_UMA
          AND A.DATA_FINE_VALIDITA IS NULL
          AND A.DATA_SCARICO         IS NULL
           AND A.ID_ALLEVAMENTO NOT IN
            (SELECT B.ID_ALLEVAMENTO
               FROM DB_LAVORAZIONI_PRATICATE B);

      IF N_CONTATORE > 0 THEN
         P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1041, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA03 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA03;

PROCEDURE UMA04 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE            IN  NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
S_COMUNE_PRINCIPALE_ATTIVITA DB_DATI_DITTA.EXT_COMUNE_PRINCIPALE_ATTIVITA%TYPE;
BEGIN
     SELECT EXT_COMUNE_PRINCIPALE_ATTIVITA
       INTO S_COMUNE_PRINCIPALE_ATTIVITA
       FROM DB_DITTA_UMA A, DB_DATI_DITTA B
      WHERE A.ID_DITTA_UMA = B.ID_DITTA_UMA
        AND B.DATA_FINE_VALIDITA IS NULL
        AND A.ID_DITTA_UMA = P_ID_DITTA_UMA;

     SELECT COUNT(*)
       INTO N_CONTATORE
       FROM DB_UTE
      WHERE COMUNE        = S_COMUNE_PRINCIPALE_ATTIVITA
        AND DATA_FINE_ATTIVITA IS NULL
        AND ID_AZIENDA = N_ID_AZIENDA;

     IF N_CONTATORE <= 0 THEN
         IF N_ID_FORMA_GIURIDICA <> 49 AND -- SE NON E' UN CONSORZIO IRRIGUO
            N_ID_CONDUZIONE <> 2 THEN -- SE NON E' UN CONTO TERZI
           -- se il comune di principale attività non coincide con una ute in anagrafe,
           -- controllo che vi sia almeno un terreno in conduzione
             SELECT COUNT(*)
               INTO N_CONTATORE
               FROM DB_SUPERFICIE_AZIENDA A, DB_COMUNI_TERRENI B
              WHERE A.ID_SUPERFICIE_AZIENDA = B.ID_SUPERFICIE_AZIENDA
                 AND B.EXT_COMUNE_ISTAT            = S_COMUNE_PRINCIPALE_ATTIVITA
                AND A.DATA_FINE_VALIDITA IS NULL
                AND A.DATA_SCARICO IS NULL
                AND A.ID_DITTA_UMA = P_ID_DITTA_UMA;
        END IF;
     END IF;

     IF N_CONTATORE <= 0 THEN
         P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1042, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA04 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA04;

PROCEDURE UMA05 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN  NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
BEGIN
     SELECT COUNT(*)
     INTO    N_CONTATORE
     FROM   DITTA_FORZATA
     WHERE  ID_DITTA_UMA = P_ID_DITTA_UMA
       AND  ANNO_RIFERIMENTO = P_ANNO_ASSEGNAZIONE;

     IF N_CONTATORE > 0 THEN
         P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1043, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA05 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA05;

PROCEDURE UMA06 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
nTipoAltitudine           DB_TIPO_ZONA_ALTIMETRICA.ID_ZONA_ALTIMETRICA%TYPE;
BEGIN
         SELECT     NVL(ZONAALT,5), NVL( ID_CONDUZIONE,0 )
        INTO     nTipoAltitudine, nGlobalConduzione
         FROM     COMUNE            AA,
                DB_DATI_DITTA     BB
         WHERE     BB.ID_DITTA_UMA         =     P_ID_DITTA_UMA
        AND        AA.ISTAT_COMUNE         =     BB.EXT_COMUNE_PRINCIPALE_ATTIVITA
         AND     DATA_INIZIO_VALIDITA     <=     GlobalDataRif
        AND     ( DATA_FINE_VALIDITA     >     GlobalDataRif OR DATA_FINE_VALIDITA IS NULL );

        IF nTipoAltitudine IS NULL THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1058, NULL, P_MESSAGGIO, P_ESITO);
        END IF;

        IF nGlobalConduzione = 0 THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1059, NULL, P_MESSAGGIO, P_ESITO);
        END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    P_ESITO := RET_ERR_WARN;
    GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1057, NULL, P_MESSAGGIO, P_ESITO);
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA06 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA06;

PROCEDURE UMA07 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
BEGIN
    IF nGlobalConduzione IN (1,3) THEN
        SELECT COUNT(1) INTO N_CONTATORE
        FROM     DB_COLTURA_PRATICATA  BB,
                DB_SUPERFICIE_AZIENDA AA
        WHERE     AA.ID_DITTA_UMA             =     P_ID_DITTA_UMA
        AND     AA.DATA_INIZIO_VALIDITA     <=     GlobalDataRif
        AND     ( AA.DATA_FINE_VALIDITA        >      GlobalDataRif OR AA.DATA_FINE_VALIDITA IS NULL )
        AND     BB.ID_SUPERFICIE_AZIENDA     =      AA.ID_SUPERFICIE_AZIENDA;

        IF N_CONTATORE = 0 THEN
           P_ESITO := RET_ERR_WARN;
           GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1060, NULL, P_MESSAGGIO, P_ESITO);
        END IF;
    END IF;
EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA07 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA07;

PROCEDURE UMA08 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
BEGIN
    SELECT COUNT( 1 ) INTO N_CONTATORE
    FROM     DB_TIPO_TITOLO_POSSESSO  TIT,
            DB_SUPERFICIE_AZIENDA      SUP
    WHERE     SUP.ID_DITTA_UMA             =     P_ID_DITTA_UMA
    AND     SUP.DATA_INIZIO_VALIDITA    <=     GlobalDataRif
    AND     ( SUP.DATA_FINE_VALIDITA    >      GlobalDataRif OR SUP.DATA_FINE_VALIDITA IS NULL )
    AND     TIT.ID_TITOLO_POSSESSO         =      SUP.ID_TITOLO_POSSESSO
    AND     UPPER( TIT.DESCRIZIONE )     IN     ( 'AFFITTO','COMODATO SCRITTO','COMODATO VERBALE' )
    AND     SUP.DATA_SCADENZA_AFFITTO     <=     GlobalDataRif;

    IF N_CONTATORE > 0 THEN  -- TROVATI CONTRATTI CON DATA SCADENZA NON VALIDA
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1061, NULL, P_MESSAGGIO, P_ESITO);
    END IF;

EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA08 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA08;

PROCEDURE UMA09 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
BEGIN
       SELECT COUNT( 1 ) INTO N_CONTATORE
        FROM     DB_UTILIZZO             UTI,
                DB_POSSESSO             POS
        WHERE UTI.ID_DITTA_UMA             =     P_ID_DITTA_UMA
        AND     UTI.DATA_CARICO         <=    GlobalDataRif
        AND     ( UTI.DATA_SCARICO         >     GlobalDataRif OR UTI.DATA_SCARICO IS NULL )
      AND   UTI.ID_UTILIZZO             = POS.ID_UTILIZZO
      AND   POS.DATA_INIZIO_VALIDITA     <=    GlobalDataRif
        AND     ( POS.DATA_FINE_VALIDITA >     GlobalDataRif OR POS.DATA_FINE_VALIDITA IS NULL )
      AND   POS.ID_FORMA_POSSESSO IN (2, 4)
      AND   POS.DATA_SCADENZA_LEASING < GlobalDataRif;

    IF N_CONTATORE > 0 THEN
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1062, NULL, P_MESSAGGIO, P_ESITO);
    END IF;

EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA09 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA09;

PROCEDURE UMA10 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);
B_TROVATO    BOOLEAN;
CURSOR C_SUPERFICI IS
       SELECT DATA_REGISTRAZIONE, NUMERO_REGISTRAZIONE, ID_CONTRATTO, ID_SCADENZA,
                 DATA_SCADENZA_AFFITTO
       FROM   DB_SUPERFICIE_AZIENDA
       WHERE  ID_DITTA_UMA = P_ID_DITTA_UMA
         AND  DATA_SCARICO IS NULL
         AND  DATA_FINE_VALIDITA IS NULL
         AND  ID_TITOLO_POSSESSO = 1;    -- AFFITTO
BEGIN
     B_TROVATO    := FALSE;
     FOR REC_SUPERFICI IN C_SUPERFICI LOOP
          IF REC_SUPERFICI.DATA_SCADENZA_AFFITTO IS NULL THEN
             B_TROVATO := TRUE;
              EXIT;
         END IF;
     END LOOP;

    IF B_TROVATO THEN
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1063, NULL,P_MESSAGGIO, P_ESITO);
    END IF;

EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA10 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA10;

PROCEDURE UMA11(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN  NUMBER,
                P_ID_CONTROLLO               IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                 IN OUT varchar2,
                P_ESITO                      IN OUT Varchar2) IS

   recTDichConsistenza     DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE;
   DataConsistenzaPratica  date;
   dDataConfronto          date;
   vGiornoMese             DB_PARAMETRO.VALORE%TYPE;
   nContCoop               PLS_INTEGER := 0 ;
begin
   -- cerco il parametro contenente il giorno ed il mese
   vGiornoMese := SelectValoreParametro(kvCodGiornoMeseDataValidaz);
   -- calcolo la data dalla quale la dichiarazione di consistenza può essere considerata validita per uma
   dDataConfronto := TO_DATE(vGiornoMese || '/' || to_number(to_char(sysdate, 'yyyy')),'DD/MM/YYYY'); 

  SELECT MAX(DATA_CONSISTENZA)
  INTO   DataConsistenzaPratica
  FROM   DB_SUPERFICIE_AZIENDA SA,DB_DITTA_UMA DU  
  WHERE  DU.ID_DITTA_UMA       = P_ID_DITTA_UMA
  AND    SA.EXT_ID_AZIENDA     = DU.EXT_ID_AZIENDA
  AND    SA.DATA_FINE_VALIDITA IS NULL
  AND    SA.DATA_SCARICO       IS NULL;

   IF DataConsistenzaPratica IS NULL THEN
          select max(DATA_CONSISTENZA)
           into DataConsistenzaPratica
          from  DB_ALLEVAMENTO
          where ID_DITTA_UMA = P_ID_DITTA_UMA
            AND DATA_FINE_VALIDITA IS NULL
            AND DATA_SCARICO IS NULL;
   END IF;

   IF DataConsistenzaPratica IS NULL THEN
     SELECT COUNT(*)
     INTO   nContCoop
     FROM   DB_DITTA_UMA DU,DB_ANAGRAFICA_AZIENDA AA,DB_TIPO_TIPOLOGIA_AZIENDA TTA
     WHERE  DU.ID_DITTA_UMA          = P_ID_DITTA_UMA
     AND    AA.ID_AZIENDA            = DU.EXT_ID_AZIENDA
     AND    AA.DATA_FINE_VALIDITA    IS NULL
     AND    AA.ID_TIPOLOGIA_AZIENDA  = TTA.ID_TIPOLOGIA_AZIENDA
     AND    TTA.FLAG_FORMA_ASSOCIATA = 'S'
     AND    TTA.ID_TIPOLOGIA_AZIENDA IN (4,5);

     IF nContCoop != 0 THEN
       SELECT MAX(DATA_INIZIO_VALIDITA)
       INTO   DataConsistenzaPratica
       FROM   DB_SUPERFICIE_AZIENDA SA
       WHERE  SA.ID_DITTA_UMA       = P_ID_DITTA_UMA
       AND    SA.DATA_FINE_VALIDITA IS NULL
       AND    SA.DATA_SCARICO       IS NULL;
     ELSE
       DataConsistenzaPratica := NULL;
     END IF;
   END IF;

   -- Preleva la data dell'ultima dichiarazione di
   -- consistenza in anagrafe collegata all'azienda
   if DataConsistenzaPratica IS NOT NULL then
       -- uso la funziona generica per prelevare l'ultima dichiarazione
       -- di consistenza
       recTDichConsistenza := SelLastDichConsistByIdAzienda (N_ID_AZIENDA);
   end if;

   if DataConsistenzaPratica is null then
      P_ESITO := RET_ERR_WARN;
      -- [UMA02] Non sono ancora stati importati i dati dall'Anagrafe delle Imprese Agricole ed Agro-Alimentari
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1088, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (1088, P_MESSAGGIO,P_ESITO);
   elsif recTDichConsistenza.DATA_PROTOCOLLO is null or recTDichConsistenza.DATA_PROTOCOLLO < dDataConfronto then 
      P_ESITO := RET_ERR_WARN;
      --[UMA02] Per l'azienda in esame non è presente alcuna validazione di consistenza sull'Anagrafe delle Imprese Agricole ed Agro-alimentari
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1040, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (1040, P_MESSAGGIO,P_ESITO);
   elsif recTDichConsistenza.DATA_PROTOCOLLO > DataConsistenzaPratica  then
      P_ESITO := RET_ERR_WARN;
      --[UMA02] Sull'Anagrafe delle imprese Agricole ed Agro-Alimentari è presente una validazione più recente di quella usata per l'importazione
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1045, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (1045, P_MESSAGGIO,P_ESITO);
   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA11 ' || SQLERRM;
END UMA11;

PROCEDURE UMA12 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE            NUMBER(10);
N_CONTATORE_MACCHINE  NUMBER(10);
BEGIN
     N_CONTATORE              := 0;
     N_CONTATORE_MACCHINE    := 0;

     SELECT COUNT(*)
       INTO N_CONTATORE
       FROM DB_ALLEVAMENTO A, DB_LAVORAZIONI_PRATICATE B, DB_TIPO_LITRI_ALLEVAMENTO C
      WHERE A.ID_DITTA_UMA              = P_ID_DITTA_UMA
        AND B.ID_ALLEVAMENTO        = A.ID_ALLEVAMENTO
        AND C.ID_LITRI_ALLEVAMENTO = B.ID_LITRI_ALLEVAMENTO
        AND C.DATA_FINE_VALIDITA IS NULL 
        AND A.DATA_FINE_VALIDITA   IS NULL
        AND C.ID_LAVORAZIONI        = 4;  -- CARRO UNIFEED

     IF N_CONTATORE > 0 THEN -- ESISTE UNA LAVORAZIONE CARRO UNIFEED
         SELECT COUNT(*)
           INTO N_CONTATORE_MACCHINE
          FROM DB_UTILIZZO A, DB_MACCHINA B, DB_DATI_MACCHINA C
          WHERE DATA_SCARICO IS NULL
            AND ID_DITTA_UMA = P_ID_DITTA_UMA
            AND A.ID_MACCHINA = B.ID_MACCHINA
            AND B.ID_MACCHINA = C.ID_MACCHINA
            AND C.ID_GENERE_MACCHINA = 10     -- RIMORCHIO
            AND C.ID_CATEGORIA = 8;           -- CARRO UNIFEED
     END IF;

   -- SE NON ESISTE IL RIMORCHIO CARRO UNIFEED CONTROLLO SE ESITE UNA MAO DI CATEGORIA:
   -- 60 = Miscelatore
   --.94 = Carro Miscelatore
   -- 95 = Carro Unifeed
   -- 41 = macchina Dessilatrice
   IF N_CONTATORE > 0 AND N_CONTATORE_MACCHINE <= 0 THEN
         select sum(num_rec)
           INTO N_CONTATORE_MACCHINE
         from (SELECT COUNT(*) num_rec
          FROM DB_UTILIZZO A, DB_MACCHINA B, DB_MATRICE C
          WHERE DATA_SCARICO IS NULL
            AND ID_DITTA_UMA = P_ID_DITTA_UMA
            AND A.ID_MACCHINA = B.ID_MACCHINA
            AND B.ID_MATRICE = C.ID_MATRICE
            AND C.ID_GENERE_MACCHINA = 3     -- MAO
            AND C.ID_CATEGORIA IN (60, 94, 95,41) 
            union
            SELECT COUNT(*) num_rec
          FROM DB_UTILIZZO A, DB_MACCHINA B, DB_DATI_MACCHINA C
          WHERE DATA_SCARICO IS NULL
            AND ID_DITTA_UMA = P_ID_DITTA_UMA
            AND A.ID_MACCHINA = B.ID_MACCHINA
            AND b.ID_MACCHINA = c.ID_MACCHINA
            AND C.ID_GENERE_MACCHINA = 3     -- MAO
            AND C.ID_CATEGORIA IN (60, 94, 95,41)); 
   END IF;


    IF N_CONTATORE > 0 AND N_CONTATORE_MACCHINE <= 0 THEN
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, 1098, NULL, P_MESSAGGIO, P_ESITO);
    END IF;

EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA12 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA12;

PROCEDURE UMA13 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE            NUMBER(10);
N_CONTATORE_MACCHINE  NUMBER(10);
BEGIN
     N_CONTATORE              := 0;
     N_CONTATORE_MACCHINE    := 0;

     SELECT COUNT(*)
       INTO N_CONTATORE
       FROM DB_ALLEVAMENTO A, DB_LAVORAZIONI_PRATICATE B, DB_TIPO_LITRI_ALLEVAMENTO C
      WHERE A.ID_DITTA_UMA              = P_ID_DITTA_UMA
        AND B.ID_ALLEVAMENTO        = A.ID_ALLEVAMENTO
        AND C.ID_LITRI_ALLEVAMENTO = B.ID_LITRI_ALLEVAMENTO
        AND A.DATA_FINE_VALIDITA   IS NULL
        AND C.DATA_FINE_VALIDITA IS NULL 
        AND C.ID_LAVORAZIONI        = 6;  -- AMBIENTE RISCALDATO

     IF N_CONTATORE > 0 THEN -- ESISTE UNA LAVORAZIONE AMBIENTE RISCALDATO
         SELECT COUNT(*)
           INTO N_CONTATORE_MACCHINE
          FROM DB_UTILIZZO A, DB_MACCHINA B, DB_DATI_MACCHINA C
          WHERE DATA_SCARICO IS NULL
            AND ID_DITTA_UMA = P_ID_DITTA_UMA
            AND A.ID_MACCHINA = B.ID_MACCHINA
            AND B.ID_MACCHINA = C.ID_MACCHINA
            AND C.ID_GENERE_MACCHINA = 11     -- ASM
            AND C.ID_CATEGORIA = 89;           -- Riscaldamento ricoveri zootecnici
     END IF;

    IF N_CONTATORE > 0 AND N_CONTATORE_MACCHINE <= 0 THEN
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, 1099, NULL, P_MESSAGGIO, P_ESITO);
    END IF;

EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA13 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA13;

PROCEDURE UMA15 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS
-- CONTROLLO SUPERO
N_ID_PARTICELLA     DB_STORICO_PARTICELLA.ID_PARTICELLA%TYPE;
S_MESSAGGIO            VARCHAR2(2000);
N_CONTATORE            NUMBER(10):=0;
vHint               DB_PARAMETRO.VALORE%TYPE;
vStrSql             VARCHAR2(4000);
TYPE TypRefCursor IS REF CURSOR; -- ref cursor per cursore dinamico
C_SUPERO            TypRefCursor; -- cursore dinamico
recDichConsistenza  DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE;
CURSOR curTypeCSupero IS
SELECT C.Id_particella,
       D.Sup_catastale,
       L.Descom,
       D.Sezione,
       D.Foglio,
       D.Particella,
       D.Id_storico_particella,
       D.Subalterno,
       SUM(C.Superficie_condotta)
  FROM DB_CONDUZIONE_DICHIARATA C,
       DB_STORICO_PARTICELLA D,
       COMUNE L
 WHERE C.ID_PARTICELLA = D.ID_PARTICELLA
   AND D.DATA_FINE_VALIDITA IS NULL
   AND D.COMUNE = L.ISTAT_COMUNE
GROUP BY C.ID_PARTICELLA,
       D.SUP_CATASTALE,
       L.DESCOM,
       D.SEZIONE,
       D.FOGLIO,
       D.PARTICELLA,
       D.ID_STORICO_PARTICELLA,
       D.SUBALTERNO
HAVING D.SUP_CATASTALE < SUM(C.SUPERFICIE_CONDOTTA);
-- record di appoggio per fetch da cursore C_SUPERO
REC_SUPERO  curTypeCSupero%ROWTYPE;

CURSOR C_PARTICELLE_SUPERO IS
 SELECT A.Id_azienda,
       A.Cuaa,
       G.Descom,
       D.Sezione,
       D.Foglio,
       D.Particella,
       D.Sup_catastale,
       C.Superficie_condotta,
       A.Denominazione,
       DECODE(F.Codice_fiscale, NULL, 'ASSENTE', F.Codice_fiscale) Codice_fiscale
   FROM Db_anagrafica_azienda A,
        Db_dichiarazione_consistenza B,
        Db_conduzione_dichiarata C,
        Db_storico_particella D,
        Db_delega E,
        Db_intermediario F,
        Comune G
  WHERE A.Data_cessazione IS NULL
    AND A.Data_fine_validita IS NULL
    AND A.Id_azienda = B.Id_azienda
    AND B.DATA = ( SELECT MAX(K.DATA)   
                     FROM Db_dichiarazione_consistenza K 
                    WHERE K.Id_azienda = A.Id_azienda
                      AND NOT EXISTS (SELECT MEP.ID_MOTIVO_ESCLUSO_PROCEDIMENTO
                                        FROM DB_MOTIVO_ESCLUSO_PROCEDIMENTO MEP
                                       WHERE MEP.ID_MOTIVO_DICHIARAZIONE = K.ID_MOTIVO_DICHIARAZIONE
                                         AND MEP.ID_PROCEDIMENTO = knIdProcedimentoUma ))
    AND B.Codice_fotografia_terreni = C.Codice_fotografia_terreni
    AND C.Id_particella = N_id_particella    
    AND C.Id_titolo_possesso <> Knidtitolopossessoasservimento   
    AND C.Id_particella = D.Id_particella
    AND D.Data_fine_validita IS NULL
    AND A.Id_azienda = E.Id_azienda(+)
    AND E.Data_fine(+) IS NULL
    AND E.Id_intermediario = F.Id_intermediario(+)
    --  AND A.ID_AZIENDA <> N_ID_AZIENDA
    AND G.Istat_comune = D.Comune
ORDER BY D.Comune, D.Sezione, D.Foglio, D.Particella;

BEGIN

     BEGIN
        vHint := SelectValoreParametro (kvCodHintUma15);
     EXCEPTION
        WHEN OTHERS THEN
            vHint := NULL;
     END;
     -- la select del cursore cambia a seconda del fatto
     -- che su DB_PARAMETRO per il parametro UMHI sia stato
     -- specificato un HINT per l'ottimizzatore o meno
     vStrSql := 'SELECT ';
     IF vHint IS NOT NULL THEN
        vStrSql := vStrSql || vHint || ' ';
     END IF;
     vStrSql := vStrSql || 'C.Id_particella,
                            D.Sup_catastale,
                            L.Descom,
                            D.Sezione,
                            D.Foglio,
                            D.Particella,
                            D.Id_storico_particella,
                            D.Subalterno,
                            SUM(C.Superficie_condotta)
                       FROM Db_anagrafica_azienda A,
                            Db_dichiarazione_consistenza B,
                            Db_conduzione_dichiarata C,
                            Db_storico_particella D,
                            Db_storico_particella E,
                            Db_azienda F,
                            Comune L
                      WHERE E.Id_storico_particella IN
                            (SELECT G.Ex_id_storico_particella
                               FROM Db_particella_coltura G, Db_superficie_azienda H, Db_coltura_praticata I
                              WHERE H.Id_ditta_uma = :pIdDittaUma
                                AND H.Id_superficie_azienda = I.Id_superficie_azienda
                                AND H.Data_fine_validita IS NULL
                                AND I.Id_coltura_praticata = G.Id_coltura_praticata)
                        AND E.Comune = L.Istat_comune
                        AND L.Flag_estero = ''N''
                        AND A.Data_cessazione IS NULL
                        AND A.Data_fine_validita IS NULL
                        AND A.Id_azienda = B.Id_azienda
                        AND A.Id_azienda = F.Id_azienda
                        AND NVL(F.Flag_azienda_provvisoria,''N'') = ''N''
                        AND B.Id_dichiarazione_consistenza = ( SELECT MAX(K.DATA)
                                                                 FROM Db_dichiarazione_consistenza K
                                                                WHERE K.Id_azienda = A.Id_azienda
                                                                  AND NOT EXISTS (SELECT MEP.ID_MOTIVO_ESCLUSO_PROCEDIMENTO
                                                                                    FROM DB_MOTIVO_ESCLUSO_PROCEDIMENTO MEP
                                                                                   WHERE MEP.ID_MOTIVO_DICHIARAZIONE = K.ID_MOTIVO_DICHIARAZIONE
                                                                                     AND MEP.ID_PROCEDIMENTO = :knIdProcedimentoUma ))
                        AND B.Codice_fotografia_terreni = C.Codice_fotografia_terreni
                        AND E.Id_particella = C.Id_particella
                        AND C.Id_titolo_possesso <> :pIdTitPossessoAsservimento
                        AND C.Id_particella = D.Id_particella
                        AND D.Data_fine_validita IS NULL
                   GROUP BY C.Id_particella,
                            D.Sup_catastale,
                            L.Descom,
                            D.Sezione,
                            D.Foglio,
                            D.Particella,
                            D.Id_storico_particella,
                            D.Subalterno
                    HAVING D.Sup_catastale < SUM(C.Superficie_condotta)';
     recDichConsistenza :=  SelLastDichConsistByIdAzienda (N_ID_AZIENDA);

     OPEN C_SUPERO FOR vStrSql
     USING P_ID_DITTA_UMA, knIdProcedimentoUMA, knIdTitoloPossessoAsservimento;

     LOOP
     FETCH C_SUPERO INTO REC_SUPERO;
     EXIT WHEN C_SUPERO%NOTFOUND;
          N_ID_PARTICELLA := REC_SUPERO.ID_PARTICELLA;
         IF REC_SUPERO.SEZIONE IS NULL THEN
             IF REC_SUPERO.SUBALTERNO IS NULL THEN
               S_MESSAGGIO := '['|| REC_SUPERO.DESCOM ||
                ' Fg:' || REC_SUPERO.FOGLIO || ' Part:' ||    REC_SUPERO.PARTICELLA ||
                 '] ' || 'Sup.cat.:' ||  TRIM(TO_CHAR(NVL(REC_SUPERO.SUP_CATASTALE,0),'999G990D9999')) || '(ha) ';
            ELSE
                 S_MESSAGGIO := '['|| REC_SUPERO.DESCOM || ' Fg:' || REC_SUPERO.FOGLIO ||
                 ' Part:' ||    REC_SUPERO.PARTICELLA || ' Sub:' || REC_SUPERO.SUBALTERNO ||
                  '] ' || 'Sup.cat.:' ||  TRIM(TO_CHAR(NVL(REC_SUPERO.SUP_CATASTALE,0),'999G990D9999')) || '(ha) ';
            END IF;
         ELSE
             IF REC_SUPERO.SUBALTERNO IS NULL THEN
                 S_MESSAGGIO := '['|| REC_SUPERO.DESCOM || ' Sz:' || REC_SUPERO.SEZIONE ||
                 ' Fg:' || REC_SUPERO.FOGLIO || ' Part:' ||    REC_SUPERO.PARTICELLA ||
                 'Sup.cat.:' ||  TRIM(TO_CHAR(NVL(REC_SUPERO.SUP_CATASTALE,0),'999G990D9999')) || '(ha)';
            ELSE
                 S_MESSAGGIO := '['|| REC_SUPERO.DESCOM || ' Sz:' || REC_SUPERO.SEZIONE ||
                 ' Fg:' || REC_SUPERO.FOGLIO || ' Part:' ||    REC_SUPERO.PARTICELLA ||
                 ' Sub:' || REC_SUPERO.SUBALTERNO || '] ' || 'Sup.cat.:' ||  TRIM(TO_CHAR(NVL(REC_SUPERO.SUP_CATASTALE,0),'999G990D9999')) || '(ha) ';
            END IF;
         END IF;

          FOR REC_PARTICELLE_SUPERO IN C_PARTICELLE_SUPERO LOOP
            P_ESITO := RET_ERR_WARN;
            S_MESSAGGIO := S_MESSAGGIO || 'Azienda: ' || rec_particelle_supero.cuaa || ' - ' ||
            SUBSTR(REC_PARTICELLE_SUPERO.DENOMINAZIONE,1,20) || '(CAA: ' ||    REC_PARTICELLE_SUPERO.CODICE_FISCALE || ') ' ||
             'Conduce.:' || TRIM(TO_CHAR(NVL(REC_PARTICELLE_SUPERO.SUPERFICIE_CONDOTTA,0),'999G990D9999')) || '(ha) ';
         END LOOP;
         IF recDichConsistenza.ID_DICHIARAZIONE_CONSISTENZA IS NOT NULL THEN
               SELECT COUNT(*) INTO N_CONTATORE
                FROM DB_DICHIARAZIONE_CORREZIONE
               WHERE ID_AZIENDA = N_ID_AZIENDA
                 AND ID_DICHIARAZIONE_CONSISTENZA = recDichConsistenza.ID_DICHIARAZIONE_CONSISTENZA
                 AND ID_CONTROLLO = 202 -- CONTROLLO SUPERO
                 AND ID_STORICO_PARTICELLA = REC_SUPERO.ID_STORICO_PARTICELLA;
         ELSE
            N_CONTATORE := 0;
         END IF;

         IF N_CONTATORE <= 0 THEN -- SE NON E' GIA' STATA CORRETTA IN ANAGRAFE SEGNALO L'ANOMALIA DEL SUPERO
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, 1201, S_MESSAGGIO, P_MESSAGGIO, P_ESITO);
         END IF;
     END LOOP;

     CLOSE C_SUPERO;

EXCEPTION
WHEN OTHERS then
    IF C_SUPERO%ISOPEN THEN
       CLOSE C_SUPERO;
    END IF;

    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA15 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA15;

PROCEDURE UMA17 (P_ID_DITTA_UMA             IN       DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                   P_ANNO_ASSEGNAZIONE        IN        NUMBER,
                 P_ID_CONTROLLO                IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                 P_TIPO_CONTROLLO            IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                   P_MESSAGGIO                 IN OUT varchar2,
                 P_ESITO                      IN OUT Varchar2) IS

N_CONTATORE            NUMBER(10);
BEGIN
     N_CONTATORE              := 0;

     SELECT COUNT(*)
       INTO N_CONTATORE
       FROM DB_ALLEVAMENTO A, DB_LAVORAZIONI_PRATICATE B, DB_TIPO_LITRI_ALLEVAMENTO C
      WHERE A.ID_DITTA_UMA              = P_ID_DITTA_UMA
        AND B.ID_ALLEVAMENTO        = A.ID_ALLEVAMENTO
        AND C.ID_LITRI_ALLEVAMENTO = B.ID_LITRI_ALLEVAMENTO
        AND A.DATA_FINE_VALIDITA   IS NULL
        AND C.DATA_FINE_VALIDITA IS NULL 
        AND C.ID_LAVORAZIONI        = 5 -- Ciclo Chiuso
        AND A.ID_ALLEVAMENTO IN
        (SELECT AA.ID_ALLEVAMENTO
         FROM DB_ALLEVAMENTO AA, DB_LAVORAZIONI_PRATICATE BB, DB_TIPO_LITRI_ALLEVAMENTO CC
         WHERE AA.ID_DITTA_UMA              = P_ID_DITTA_UMA
          AND BB.ID_ALLEVAMENTO        = AA.ID_ALLEVAMENTO
          AND CC.ID_LITRI_ALLEVAMENTO  = BB.ID_LITRI_ALLEVAMENTO
          AND AA.DATA_FINE_VALIDITA   IS NULL
          AND CC.DATA_FINE_VALIDITA IS NULL 
          AND CC.ID_LAVORAZIONI       IN (1,3)); -- Alimentazione, Movimentazione letame;

     IF N_CONTATORE > 0 THEN -- ESISTE UNA LAVORAZIONE Ciclo Chiuso in contemporanea con Alimentazione e/o Movimentazione letame
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, 1493, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

EXCEPTION
WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA17 ' || SQLERRM;
    P_ESITO         := RET_ERR_PROC;
END UMA17;

PROCEDURE UMA18(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN  NUMBER,
                P_ID_CONTROLLO               IN       DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN      DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                 IN OUT varchar2,
                P_ESITO                      IN OUT Varchar2) IS

     DataConsistenzaPratica     date;
     dDataConfronto             date;
     b_controllo                boolean;
     recTDichConsistenza        DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE;
     vGiornoMese                DB_PARAMETRO.VALORE%TYPE;
begin

   vGiornoMese := SelectValoreParametro(kvCodGiornoMeseDataValidaz);
   -- calcolo la data dalla quale la dichiarazione di consistenza può essere considerata validita per uma
   dDataConfronto := TO_DATE(vGiornoMese || '/' || to_number(to_char(sysdate, 'yyyy')),'DD/MM/YYYY'); 

   -- Preleva la data della dichiarazione di consistenza
   -- collegata alla pratica
   b_controllo    := true;

   begin
      select max(DATA_CONSISTENZA)
       into DataConsistenzaPratica
      from  DB_SUPERFICIE_AZIENDA
      where ID_DITTA_UMA = P_ID_DITTA_UMA
        AND DATA_FINE_VALIDITA IS NULL
        AND DATA_SCARICO IS NULL;
   exception
         when no_data_found then
             b_controllo := false;
           DataConsistenzaPratica := null;
      when others then
           raise;
   end;

   IF DataConsistenzaPratica IS NULL THEN
         b_controllo    := true;
       begin
          select max(DATA_CONSISTENZA)
           into DataConsistenzaPratica
          from  DB_ALLEVAMENTO
          where ID_DITTA_UMA = P_ID_DITTA_UMA
            AND DATA_FINE_VALIDITA IS NULL
            AND DATA_SCARICO IS NULL;
       exception
             when no_data_found then
                 b_controllo := false;
               DataConsistenzaPratica := null;
          when others then
               raise;
       end;
   END IF;

   -- Preleva la data dell'ultima dichiarazione di
   -- consistenza in anagrafe collegata all'azienda

   if b_controllo then
       recTDichConsistenza := SelLastDichConsistByIdAzienda (N_ID_AZIENDA);

   end if;

   if recTDichConsistenza.DATA_PROTOCOLLO is null OR recTDichConsistenza.DATA_PROTOCOLLO < dDataConfronto then 
      P_ESITO := RET_ERR_WARN;
      -- [UMA18] Non è presente alcuna dichiarazione di consistenza in Anagrafe successiva al 01/09 dell'anno precedente
      -- L'assegnazione non deve superare il 50% del massimo assegnabile
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1494, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (1494, P_MESSAGGIO,P_ESITO);
   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA18 ' || SQLERRM;
END UMA18;

PROCEDURE UMA19(P_ID_DITTA_UMA            IN     DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN    NUMBER,
                P_ID_CONTROLLO               IN     DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN    DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                IN OUT varchar2,
                P_ESITO                         IN OUT Varchar2) IS

    recTDichConsistenza         DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE;
    DataConsistenzaPratica      date;
    dDataConfronto              date;
    vGiornoMese                 DB_PARAMETRO.VALORE%TYPE;
    nContCoop                   PLS_INTEGER;
begin

   cerco il parametro contenente il giorno ed il mese
   vGiornoMese := SelectValoreParametro(kvCodGiornoMeseDataValidaz);
   -- calcolo la data dalla quale la dichiarazione di consistenza può essere considerata validita per uma
   dDataConfronto := TO_DATE(vGiornoMese || '/' || to_number(to_char(sysdate, 'yyyy')),'DD/MM/YYYY'); 

   -- Preleva la data della dichiarazione di consistenza
   -- collegata alla pratica
   SELECT MAX(DATA_CONSISTENZA)
   INTO   DataConsistenzaPratica
   FROM   DB_SUPERFICIE_AZIENDA SA,DB_DITTA_UMA DU  
   WHERE  DU.ID_DITTA_UMA       = P_ID_DITTA_UMA
   AND    SA.EXT_ID_AZIENDA     = DU.EXT_ID_AZIENDA
   AND    SA.DATA_FINE_VALIDITA IS NULL
   AND    SA.DATA_SCARICO       IS NULL;

   IF DataConsistenzaPratica IS NULL THEN
          select max(DATA_CONSISTENZA)
           into DataConsistenzaPratica
          from  DB_ALLEVAMENTO
          where ID_DITTA_UMA = P_ID_DITTA_UMA
            AND DATA_FINE_VALIDITA IS NULL
            AND DATA_SCARICO IS NULL;
   END IF;

   IF DataConsistenzaPratica IS NULL THEN
     SELECT COUNT(*)
     INTO   nContCoop
     FROM   DB_DITTA_UMA DU,DB_ANAGRAFICA_AZIENDA AA,DB_TIPO_TIPOLOGIA_AZIENDA TTA
     WHERE  DU.ID_DITTA_UMA          = P_ID_DITTA_UMA
     AND    AA.ID_AZIENDA            = DU.EXT_ID_AZIENDA
     AND    AA.DATA_FINE_VALIDITA    IS NULL
     AND    AA.ID_TIPOLOGIA_AZIENDA  = TTA.ID_TIPOLOGIA_AZIENDA
     AND    TTA.FLAG_FORMA_ASSOCIATA = 'S'
     AND    TTA.ID_TIPOLOGIA_AZIENDA IN (4,5);

     IF nContCoop != 0 THEN
       SELECT MAX(DATA_INIZIO_VALIDITA)
       INTO   DataConsistenzaPratica
       FROM   DB_SUPERFICIE_AZIENDA SA
       WHERE  SA.ID_DITTA_UMA       = P_ID_DITTA_UMA
       AND    SA.DATA_FINE_VALIDITA IS NULL
       AND    SA.DATA_SCARICO       IS NULL;
     ELSE
       DataConsistenzaPratica := NULL;
     END IF;
   END IF;

   -- Preleva la data dell'ultima dichiarazione di
   -- consistenza in anagrafe collegata all'azienda

   if DataConsistenzaPratica IS NOT NULL then
       recTDichConsistenza := SelLastDichConsistByIdAzienda (N_ID_AZIENDA);
   end if;

   if recTDichConsistenza.DATA_PROTOCOLLO is not null and
      recTDichConsistenza.DATA_PROTOCOLLO >= dDataConfronto and 
      (DataConsistenzaPratica is null or DataConsistenzaPratica < recTDichConsistenza.DATA_PROTOCOLLO ) then
      P_ESITO := RET_ERR_WARN;
      -- [UMA19] E' presente una dichiarazione di consistenza in Anagrafe successiva al 1/9 dell'anno precednte
      -- E' obbligatorio effettuare l'importazione dei dati
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 1495, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (1495, P_MESSAGGIO,P_ESITO);
   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA19 ' || SQLERRM;
END UMA19;

PROCEDURE UMA20(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN     NUMBER,
                P_ID_CONTROLLO               IN      DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN     DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                IN OUT varchar2,
                P_ESITO                         IN OUT Varchar2) IS

 DataRestituzioneBuono     date;
 N_CONTATORE               number;
 b_controllo            boolean;

begin
   -- Imposta la data limite oltre la quale deve essere indicata sulla restituzione del buono
   DataRestituzioneBuono := to_date('30-11-2007 23:59:59', 'dd-mm-yyyy hh24:mi_ss');

   begin
     select count(1)
     into   N_CONTATORE
     from   db_domanda_assegnazione A, db_buono_prelievo B, DB_BUONO_CARBURANTE C, db_prelievo D
     where  A.ID_DITTA_UMA = P_ID_DITTA_UMA
     AND    A.ID_DOMANDA_ASSEGNAZIONE = B.ID_DOMANDA_ASSEGNAZIONE
     AND    B.ID_BUONO_PRELIEVO = C.ID_BUONO_PRELIEVO
     AND    C.ID_BUONO_CARBURANTE = D.ID_BUONO_CARBURANTE
     AND    D.QUANTITA_PRELEVATA > 0 AND D.DATA_AGGIORNAMENTO > DataRestituzioneBuono
     AND    D.DATA_ULTIMO_PRELIEVO IS NULL
     And    B.NUMERO_BLOCCO <> 99999
     And    B.NUMERO_BUONO <> 999;
   exception
     when others then
          raise;
   end;

   IF N_CONTATORE > 0 THEN
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, 2043, NULL, P_MESSAGGIO, P_ESITO);
        ESTRAI_ERRORE_COMUNE (2043, P_MESSAGGIO,P_ESITO);
   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA20 ' || SQLERRM;
END UMA20;

PROCEDURE UMA21(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN     NUMBER,
                P_ID_CONTROLLO               IN      DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN     DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                IN OUT varchar2,
                P_ESITO                         IN OUT Varchar2) IS

 recTDichConsistenza    DB_DICHIARAZIONE_CONSISTENZA%ROWTYPE;
 N_ID_CONSISTENZA       DB_STAMPE_VARIE.EXT_ID_CONSISTENZA%TYPE;

begin

   recTDichConsistenza := SelLastDichConsistByIdAzienda (N_ID_AZIENDA);

   IF recTDichConsistenza.DATA_PROTOCOLLO is not null and recTDichConsistenza.DATA_PROTOCOLLO < to_date(to_char(sysdate, 'yyyy')||'0101', 'yyyymmdd') then
      -- Se la data dell'ultima dichiarazione di consistenza presente in anagrafe è anteriore al 1/1 dell'anno in corso
      -- deve essere stato stampato il documento di autocertificazione
      N_ID_CONSISTENZA := null;

      begin
         select a.EXT_ID_CONSISTENZA
         into N_ID_CONSISTENZA
         from DB_STAMPE_VARIE A
        where A.ID_DITTA_UMA = P_ID_DITTA_UMA AND A.CODICE_MODELLO = 'AUTD'
          AND TO_CHAR(A.DATA_STAMPA, 'YYYY') = to_char(sysdate, 'yyyy');
      exception
        when no_data_found then
         -- Non è presente il documento di autocertificxazione di validità della dichiarazione
         -- di consistenza dell'anno precedente
              P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2044, NULL, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2044, P_MESSAGGIO,P_ESITO);
        when others then
          RAISE;
      end;

      IF N_ID_CONSISTENZA IS NOT NULL AND N_ID_CONSISTENZA <> recTDichConsistenza.ID_DICHIARAZIONE_CONSISTENZA THEN
         -- Il documento di autocertificxazione di validità della dichiarazione di consistenza
         -- dell'anno precedente si riferisca ad una dichiarazione di consistenza diversa
         P_ESITO := RET_ERR_WARN;
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2045, NULL, P_MESSAGGIO, P_ESITO);
         ESTRAI_ERRORE_COMUNE (2045, P_MESSAGGIO,P_ESITO);
      else
           P_ESITO       := RET_OK;
         P_MESSAGGIO  := NULL;
      end if;

   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA21 ' || SQLERRM;
END UMA21;

PROCEDURE UMA22(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN     NUMBER,
                P_ID_CONTROLLO               IN      DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN     DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                IN OUT varchar2,
                P_ESITO                         IN OUT Varchar2) IS

N_CONTATORE NUMBER(10);

begin
   -- Legge se ci sono ASM "Impianti/Bruciatori serre" in carico con data ultimo aggiornamento

   select COUNT(1)
   into   N_CONTATORE
   from DB_UTILIZZO A, DB_DATI_MACCHINA B
   where A.ID_DITTA_UMA = P_ID_DITTA_UMA AND A.DATA_SCARICO is null
   AND   A.ID_MACCHINA = B.ID_MACCHINA   AND B.ID_GENERE_MACCHINA = 11
   AND   B.ID_CATEGORIA = 87 AND B.DATA_AGGIORNAMENTO < TO_DATE ('20/10/2007', 'dd/mm/yyyy');

   if N_CONTATORE > 0 then
        P_ESITO := RET_ERR_WARN;
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2049, NULL, P_MESSAGGIO, P_ESITO);
   ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
   end if;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA22 ' || SQLERRM;
END UMA22;

/*********************************************************************
Verifica che l'azienda non sia del tipo Conto Terzi o Conto Proprio/Terzi
ed emette la relativa segnalazione d'errore
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA23(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN     NUMBER,
                P_ID_CONTROLLO               IN      DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN     DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                IN OUT varchar2,
                P_ESITO                         IN OUT Varchar2) IS

begin
    -- se il tipo conduzione è conto terzi
    IF N_ID_CONDUZIONE = knIdContoTerzi THEN 
        P_ESITO := RET_ERR_WARN;
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2318, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (2318, P_MESSAGGIO,P_ESITO);
    ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
    END IF;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA23 ' || SQLERRM;
END UMA23;

/*********************************************************************
Verifica della presenza in anagrafe di una dichiarazione di
consistenza dell'anno precedente (da verificare)
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA24(P_ID_DITTA_UMA            IN      DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                  P_ANNO_ASSEGNAZIONE       IN     NUMBER,
                P_ID_CONTROLLO               IN      DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO           IN     DB_CONTROLLO.BLOCCANTE%TYPE,
                  P_MESSAGGIO                IN OUT varchar2,
                P_ESITO                         IN OUT Varchar2) IS

    nNumDichiarazioni NUMBER:=0;

begin
    -- cerco se ci sono dichiarazioni per l'anno precedente
    -- a quello di SYSDATE
    SELECT COUNT(*)
      INTO nNumDichiarazioni
      FROM DB_DITTA_UMA A,
           DB_DICHIARAZIONE_CONSISTENZA B
     WHERE A.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND A.EXT_ID_AZIENDA = B.ID_AZIENDA
       AND B.ANNO = TO_CHAR(SYSDATE,'YYYY') - 1 
       AND B.DATA_PROTOCOLLO IS NOT NULL    
       AND B.NUMERO_PROTOCOLLO IS NOT NULL; 

    -- se non ce ne sono segnalo il warning
    IF nNumDichiarazioni = 0 THEN
        P_ESITO := RET_ERR_WARN;
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2319, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (2319, P_MESSAGGIO,P_ESITO);
    ELSE
        P_ESITO       := RET_OK;
      P_MESSAGGIO := NULL;
    END IF;

exception when others then
    P_ESITO := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA24 ' || SQLERRM;
END UMA24;

/*********************************************************************
Verifica presenza di almeno una lavorazione effettuata nell'anno precedente
per l'azienda contoterzista
Tipo:   procedure
input:  P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA25(P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS

    nNumLavorazioni INTEGER:=0;
BEGIN
    -- se il tipo conduzione è conto terzi o conto proprio terzi
    IF N_ID_CONDUZIONE IN (knIdContoTerzi, knIdContoProprioTerzi) THEN
       IF ExistsFullOfFuelForDittaAnno (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE - 1) THEN
           -- controllo che abbia effettuato pure delle lavorazioni
           SELECT COUNT(LC.ID_LAVORAZIONE_CONTOTERZI)
             INTO nNumLavorazioni
             FROM DB_LAVORAZIONE_CONTOTERZI LC,
                  DB_CAMPAGNA_CONTOTERZISTI  CC
            WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
              AND CC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE - 1
              AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneEffettuata
              AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
              AND LC.DATA_CESSAZIONE IS NULL
              AND LC.DATA_FINE_VALIDITA IS NULL;

            IF nNumLavorazioni = 0 THEN
               P_ESITO := RET_ERR_WARN;
               GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2671, NULL, P_MESSAGGIO, P_ESITO);
               ESTRAI_ERRORE_COMUNE (2671, P_MESSAGGIO,P_ESITO);
            ELSE
               P_ESITO := RET_OK;
               P_MESSAGGIO := NULL;
            END IF;
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;
    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA25 ' || SQLERRM;
END UMA25;

/*********************************************************************
Verifica presenza di almeno una richiesta di lavorazione da evadere
nell'anno precedente per l'azienda conto proprio
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA26(P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS
    nNumLavorazioni INTEGER:=0;
BEGIN

    -- se il tipo conduzione è conto proprio
    IF N_ID_CONDUZIONE = knIdContoProprio THEN

       SELECT COUNT(LC.ID_LAVORAZIONE_CONTOTERZI)
         INTO nNumLavorazioni
         FROM DB_LAVORAZIONE_CONTOTERZI LC,
              DB_CAMPAGNA_CONTOTERZISTI  CC
        WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
          AND CC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE 
          AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneSubita
          AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
          AND LC.DATA_CESSAZIONE IS NULL
          AND LC.DATA_FINE_VALIDITA IS NULL;

        IF nNumLavorazioni = 0 THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2672, NULL, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2672, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;

    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA26 ' || SQLERRM;
END UMA26;

/*********************************************************************
Verifica scostamento tra superficie / ore in fattura e superficie / ore
lavorate inferiore al 120%
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA27(P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS


    CURSOR curLavorazioneEffettuata IS
    SELECT LC.*,
           CC.ANNO_CAMPAGNA,
           TL.DESCRIZIONE,
           UM.DESCRIZIONE AS UNITA_MISURA,
           UM.TIPO
      FROM DB_LAVORAZIONE_CONTOTERZI LC,
           DB_CAMPAGNA_CONTOTERZISTI  CC,
           DB_TIPO_LAVORAZIONI TL,
           DB_UNITA_MISURA UM
     WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND CC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE - 1
       AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneEffettuata
       AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
       AND LC.ID_LAVORAZIONI = TL.ID_LAVORAZIONI
       AND LC.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL;

    nPercMassima    NUMBER(3):=0;
    nPercOttenuta   NUMBER(7,2):=0;
    vMessaggio      DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE;

BEGIN
    -- se il tipo conduzione è conto terzi o conto proprio terzi
    IF N_ID_CONDUZIONE IN (knIdContoTerzi, knIdContoProprioTerzi) THEN
        nPercMassima := SelectValoreParametro (kvCodParametroPercMassima);

        FOR recLavorazioneEffettuata IN curLavorazioneEffettuata LOOP
            IF recLavorazioneEffettuata.SUP_ORE > 0 THEN
               nPercOttenuta := (recLavorazioneEffettuata.SUP_ORE_FATTURA / recLavorazioneEffettuata.SUP_ORE) * 100;
               IF nPercOttenuta > nPercMassima THEN
                  AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Lavorazione : ' || recLavorazioneEffettuata.DESCRIZIONE);
                  AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Anno Campagna : ' || recLavorazioneEffettuata.ANNO_CAMPAGNA);
                  AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Numero Fattura : ' || NVL(recLavorazioneEffettuata.NUMERO_FATTURE,'N.P.'));
                  AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'risulta avere : ');
                  IF recLavorazioneEffettuata.TIPO = 'S' THEN
                     AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'superficie fatturata di : ' || TO_CHAR(recLavorazioneEffettuata.SUP_ORE_FATTURA,'999990D9999') || ' ' || recLavorazioneEffettuata.UNITA_MISURA);
                     AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'superiore al ' || nPercMassima || '% di');
                     AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'superficie lavorata : ' || recLavorazioneEffettuata.UNITA_MISURA || ' ' || TO_CHAR(recLavorazioneEffettuata.SUP_ORE,'999990D9999'));
                  ELSE
                     AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'numero ore fatturate di : ' || recLavorazioneEffettuata.SUP_ORE_FATTURA);
                     AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'superiore al ' || nPercMassima || '% del');
                     AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'numero ore lavorate : ' || recLavorazioneEffettuata.SUP_ORE);
                  END IF;

               END IF;
            END IF;
        END LOOP;

        IF vMessaggio IS NOT NULL THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2676, vMessaggio, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2676, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;

    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA27 ' || SQLERRM;
END UMA27;

/*********************************************************************
Verifica che la ditta uma non abbia inserito se stessa come contoterzista
nelle lavorazioni
Tipo:   procedure
input: P_ID_AZIENDA,P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA28(P_ID_AZIENDA        IN DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS

    nNumLavorazioni INTEGER:=0;
BEGIN

    SELECT COUNT(LC.ID_LAVORAZIONE_CONTOTERZI)
      INTO nNumLavorazioni
      FROM DB_LAVORAZIONE_CONTOTERZI LC,
           DB_CAMPAGNA_CONTOTERZISTI  CC
     WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND CC.ANNO_CAMPAGNA in (P_ANNO_ASSEGNAZIONE, P_ANNO_ASSEGNAZIONE - 1) 
       AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL
       AND LC.EXT_ID_AZIENDA = P_ID_AZIENDA;

    IF nNumLavorazioni > 0 THEN
       P_ESITO := RET_ERR_WARN;
       GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2673, NULL, P_MESSAGGIO, P_ESITO);
       ESTRAI_ERRORE_COMUNE (2673, P_MESSAGGIO,P_ESITO);
    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA28 ' || SQLERRM;
END UMA28;

/*********************************************************************
Verifica che le lavorazioni richieste da aziende contoproprio siano
effettuate da aziende contoterzi
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA29(P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS

    vMessaggio  DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE;

    CURSOR curDitteUmaNoContoTerzi IS
    SELECT AZ.CUAA
      FROM DB_LAVORAZIONE_CONTOTERZI LC,
           DB_CAMPAGNA_CONTOTERZISTI  CC,
           DB_DITTA_UMA DU,
           DB_DATI_DITTA DD,
           DB_ANAGRAFICA_AZIENDA AZ
     WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND CC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE - 1
       AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneSubita
       AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL
       AND DU.EXT_ID_AZIENDA = LC.EXT_ID_AZIENDA
       AND DU.ID_DITTA_UMA = DD.ID_DITTA_UMA
       AND DD.ID_CONDUZIONE NOT IN (knIdContoTerzi,knIdContoProprioTerzi)
       AND LC.DATA_INIZIO_VALIDITA BETWEEN DD.DATA_INIZIO_VALIDITA AND NVL(DD.DATA_FINE_VALIDITA, LC.DATA_INIZIO_VALIDITA) 
       AND AZ.ID_AZIENDA = DU.EXT_ID_AZIENDA
       AND AZ.DATA_FINE_VALIDITA IS NULL
       AND DU.ID_DITTA_UMA = (SELECT MAX(ID_DITTA_UMA)  
                              FROM   DB_DITTA_UMA DU1
                              WHERE  DU1.EXT_ID_AZIENDA = DU.EXT_ID_AZIENDA
                              AND    TO_NUMBER(TO_CHAR(DU1.DATA_ISCRIZIONE,'YYYY')) <= CC.ANNO_CAMPAGNA);

BEGIN

    -- se il tipo conduzione è conto proprio
    IF N_ID_CONDUZIONE = knIdContoProprio THEN

        FOR recDitteUmaNoContoTerzi IN curDitteUmaNoContoTerzi LOOP
            AccodaMessaggioAnomalia (vMessaggio, ' - ' || recDitteUmaNoContoTerzi.CUAA);
        END LOOP;

        IF vMessaggio IS NOT NULL THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2674, vMessaggio, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2674, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;

    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA29 ' || SQLERRM;
END UMA29;

/*********************************************************************
Verifica presenza di almeno una lavorazione compilata per l'azienda di tipo consorzio
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA30(P_ID_AZIENDA        IN DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS
    nNumLavorazioni INTEGER:=0;
BEGIN
    -- aggiunto controllo sul fatto che la ditta uma non
    -- sia forzata per l'anno assegnazione
    IF IsAziendaConsorzio (P_ID_AZIENDA) AND NOT
       IsDittaUmaForzata(P_ID_DITTA_UMA,
                         P_ANNO_ASSEGNAZIONE) THEN

       SELECT COUNT(LC.ID_LAVORAZIONE_CONSORZI)
         INTO nNumLavorazioni
         FROM DB_LAVORAZIONE_CONSORZI LC
        WHERE LC.ID_DITTA_UMA = P_ID_DITTA_UMA
          AND LC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE 
          AND LC.VERSO_LAVORAZIONE = kvCodLavorazioneEffettuata 
          AND LC.DATA_CESSAZIONE IS NULL
          AND LC.DATA_FINE_VALIDITA IS NULL;

        IF nNumLavorazioni = 0 THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2675, NULL, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2675, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;
    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA30 ' || SQLERRM;
END UMA30;

/*********************************************************************
Verifica, solamente in caso di azienda conto terzi o conto proprio terzi,
che per eventuali lavorazioni derivate da import di preventivi, nel
caso siano relative a misure di tipo temporale, la macchina sia sempre
specificata
Tipo:    procedure
input:  P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA31(P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS


    CURSOR curLavorazioneEffettuata IS
    SELECT LC.*,
           CC.ANNO_CAMPAGNA,
           TL.DESCRIZIONE,
           UM.DESCRIZIONE AS UNITA_MISURA
      FROM DB_LAVORAZIONE_CONTOTERZI LC,
           DB_CAMPAGNA_CONTOTERZISTI  CC,
           DB_TIPO_LAVORAZIONI TL,
           DB_UNITA_MISURA UM
     WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND CC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE - 1
       AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneEffettuata
       AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
       AND LC.ID_LAVORAZIONI = TL.ID_LAVORAZIONI
       AND LC.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
       AND UM.TIPO = 'T'
       AND LC.ID_LAVORAZIONE_ORIGINARIA IS NOT NULL
       AND LC.ID_MACCHINA IS NULL
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL;

    vMessaggio      DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE;

BEGIN
    -- se il tipo conduzione è conto terzi o conto proprio terzi
    IF N_ID_CONDUZIONE IN (knIdContoTerzi, knIdContoProprioTerzi) THEN

        FOR recLavorazioneEffettuata IN curLavorazioneEffettuata LOOP
            AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Lavorazione : ' || recLavorazioneEffettuata.DESCRIZIONE);
            AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Di ore : ' || recLavorazioneEffettuata.SUP_ORE);
            AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Anno Campagna : ' || recLavorazioneEffettuata.ANNO_CAMPAGNA);
            AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Numero Fattura : ' || NVL(recLavorazioneEffettuata.NUMERO_FATTURE,'N.P.'));
            AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || ' macchina non specificata!'); 
        END LOOP;

        IF vMessaggio IS NOT NULL THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2680, vMessaggio, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2680, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;

    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA31 ' || SQLERRM;
END UMA31;

/*********************************************************************
Per l'azienda conto terzi verifica per ogni lavorazione attività
ed effettuata nell'anno precedente che la macchina sia congruente
con la coltura
Tipo:    procedure
input:  P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA32(P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS

    CURSOR curLavorazioneEffettuata IS
    SELECT LC.*,
           CC.ANNO_CAMPAGNA,
           TL.DESCRIZIONE,
           CTUM.DESCRIZIONE AS DESCRIZ_CATEGORIA
      FROM DB_LAVORAZIONE_CONTOTERZI LC,
           DB_CAMPAGNA_CONTOTERZISTI  CC,
           DB_TIPO_LAVORAZIONI TL,
           DB_CATEGORIA_UTILIZZO_UMA CTUM
     WHERE CC.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND CC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE - 1
       AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneEffettuata
       AND LC.ID_CAMPAGNA_CONTOTERZISTI = CC.ID_CAMPAGNA_CONTOTERZISTI
       AND LC.ID_LAVORAZIONI = TL.ID_LAVORAZIONI
       AND LC.ID_CATEGORIA_UTILIZZO_UMA = CTUM.ID_CATEGORIA_UTILIZZO_UMA
       AND LC.ID_MACCHINA IS NOT NULL
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL
       AND NOT EXISTS (SELECT CML.ID_CATEG_MACCHINA_LAVORAZIONI
                         FROM DB_CATEG_MACCHINE_LAVORAZIONI CML,
                              DB_MACCHINA M,
                              DB_MATRICE MA
                        WHERE M.ID_MACCHINA = LC.ID_MACCHINA
                          AND M.ID_MATRICE = MA.ID_MATRICE
                          AND MA.ID_GENERE_MACCHINA = CML.ID_GENERE_MACCHINA
                          AND NVL(MA.ID_CATEGORIA,-1) = NVL(CML.ID_CATEGORIA,-1)
                          AND CML.ID_CATEGORIA_UTILIZZO_UMA = LC.ID_CATEGORIA_UTILIZZO_UMA
                          AND TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY') <= CC.ANNO_CAMPAGNA
                          AND NVL(TO_CHAR(CML.DATA_FINE_VALIDITA,'YYYY'),CC.ANNO_CAMPAGNA) >= CC.ANNO_CAMPAGNA)
       AND NOT EXISTS (SELECT CML.ID_CATEG_MACCHINA_LAVORAZIONI
                         FROM DB_CATEG_MACCHINE_LAVORAZIONI CML,
                              DB_DATI_MACCHINA DM
                        WHERE DM.ID_MACCHINA = LC.ID_MACCHINA
                          AND DM.ID_GENERE_MACCHINA = CML.ID_GENERE_MACCHINA
                          AND DM.ID_CATEGORIA = CML.ID_CATEGORIA
                          AND CML.ID_CATEGORIA_UTILIZZO_UMA = LC.ID_CATEGORIA_UTILIZZO_UMA
                          AND TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY') <= CC.ANNO_CAMPAGNA
                          AND NVL(TO_CHAR(CML.DATA_FINE_VALIDITA,'YYYY'),CC.ANNO_CAMPAGNA) >= CC.ANNO_CAMPAGNA);

    recDatiMacchina TypDatiMacchina;
    vMessaggio      DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE;

BEGIN

    -- se il tipo conduzione è conto terzi o conto proprio terzi
    IF N_ID_CONDUZIONE IN (knIdContoTerzi, knIdContoProprioTerzi) THEN
        FOR recLavorazioneEffettuata IN curLavorazioneEffettuata LOOP
           recDatiMacchina := SelectTDatiMacchinaById (recLavorazioneEffettuata.ID_MACCHINA);

           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Lavorazione : ' || recLavorazioneEffettuata.DESCRIZIONE);
           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Anno campagna  : ' || recLavorazioneEffettuata.ANNO_CAMPAGNA);
           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Uso del suolo : ' || recLavorazioneEffettuata.DESCRIZ_CATEGORIA);
           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Macchina : ' || recDatiMacchina.vDescCategoriaMacchina || ' ' || recDatiMacchina.vTipoMacchina || ' ' || recDatiMacchina.vDescMarca);
           IF recDatiMacchina.vTarga IS NOT NULL THEN
              AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'con targa : ' || recDatiMacchina.vTarga);
           END IF;

        END LOOP;

        IF vMessaggio IS NOT NULL THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2682, vMessaggio, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2682, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;
    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA32 ' || SQLERRM;
END UMA32;

/*********************************************************************
Per l'azienda di tipo consorzio verifica per ogni lavorazione attività ed effettuata
nell'anno precedente che la macchina sia congruente con la coltura
input:  P_ID_AZIENDA, P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA33(P_ID_AZIENDA        IN DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS

    CURSOR curLavorazioneEffettuata IS
    SELECT LC.*,
           TL.DESCRIZIONE,
           CTUM.DESCRIZIONE AS DESCRIZ_CATEGORIA
      FROM DB_LAVORAZIONE_CONSORZI LC,
           DB_TIPO_LAVORAZIONI TL,
           DB_CATEGORIA_UTILIZZO_UMA CTUM
     WHERE LC.ID_DITTA_UMA = P_ID_DITTA_UMA
       AND LC.ANNO_CAMPAGNA = P_ANNO_ASSEGNAZIONE
       AND LC.VERSO_LAVORAZIONE = kvCodLavorazioneEffettuata
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL
       AND LC.ID_LAVORAZIONI = TL.ID_LAVORAZIONI
       AND LC.ID_CATEGORIA_UTILIZZO_UMA = CTUM.ID_CATEGORIA_UTILIZZO_UMA
       AND LC.ID_MACCHINA IS NOT NULL
       AND LC.DATA_CESSAZIONE IS NULL
       AND LC.DATA_FINE_VALIDITA IS NULL
       AND NOT EXISTS (SELECT CML.ID_CATEG_MACCHINA_LAVORAZIONI
                         FROM DB_CATEG_MACCHINE_LAVORAZIONI CML,
                              DB_MACCHINA M,
                              DB_MATRICE MA
                        WHERE M.ID_MACCHINA = LC.ID_MACCHINA
                          AND M.ID_MATRICE = MA.ID_MATRICE
                          AND MA.ID_GENERE_MACCHINA = CML.ID_GENERE_MACCHINA
                          AND NVL(MA.ID_CATEGORIA,-1) = NVL(CML.ID_CATEGORIA,-1)
                          AND CML.ID_CATEGORIA_UTILIZZO_UMA = LC.ID_CATEGORIA_UTILIZZO_UMA
                          AND TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY') <= LC.ANNO_CAMPAGNA
                          AND NVL(TO_CHAR(CML.DATA_FINE_VALIDITA,'YYYY'),LC.ANNO_CAMPAGNA) >= LC.ANNO_CAMPAGNA)
       AND NOT EXISTS (SELECT CML.ID_CATEG_MACCHINA_LAVORAZIONI
                         FROM DB_CATEG_MACCHINE_LAVORAZIONI CML,
                              DB_DATI_MACCHINA DM
                        WHERE DM.ID_MACCHINA = LC.ID_MACCHINA
                          AND DM.ID_GENERE_MACCHINA = CML.ID_GENERE_MACCHINA
                          AND DM.ID_CATEGORIA = CML.ID_CATEGORIA
                          AND CML.ID_CATEGORIA_UTILIZZO_UMA = LC.ID_CATEGORIA_UTILIZZO_UMA
                          AND TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY') <= LC.ANNO_CAMPAGNA
                          AND NVL(TO_CHAR(CML.DATA_FINE_VALIDITA,'YYYY'),LC.ANNO_CAMPAGNA) >= LC.ANNO_CAMPAGNA);

    recDatiMacchina TypDatiMacchina;
    vMessaggio      DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE;

BEGIN

    IF IsAziendaConsorzio (P_ID_AZIENDA) THEN
        FOR recLavorazioneEffettuata IN curLavorazioneEffettuata LOOP
           recDatiMacchina := SelectTDatiMacchinaById (recLavorazioneEffettuata.ID_MACCHINA);

           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Lavorazione : ' || recLavorazioneEffettuata.DESCRIZIONE);
           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Anno campagna  : ' || recLavorazioneEffettuata.ANNO_CAMPAGNA);
           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- uso del suolo : ' || recLavorazioneEffettuata.DESCRIZ_CATEGORIA);
           AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || '- Macchina : ' || recDatiMacchina.vDescCategoriaMacchina || ' ' || recDatiMacchina.vTipoMacchina || ' ' || recDatiMacchina.vDescMarca);
           IF recDatiMacchina.vTarga IS NOT NULL THEN
              AccodaMessaggioAnomalia (vMessaggio,kvACapoHTMLPL || 'con targa : ' || recDatiMacchina.vTarga);
           END IF;

        END LOOP;

        IF vMessaggio IS NOT NULL THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2683, vMessaggio, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2683, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;
    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA33 ' || SQLERRM;
END UMA33;

/*********************************************************************
Verifica per le aziende di tipo consorzio / cooperativa (non ditte forzate)
che nell'elenco soci di SMRGAA sia presente almeno un socio
Tipo:    procedure
input:    P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO,P_TIPO_CONTROLLO
output: P_MESSAGGIO, P_ESITO
ritorno: RET_OK / RET_ERR_WARN / RET_ERR_PROC
*********************************************************************/
PROCEDURE UMA34(P_ID_AZIENDA        IN DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                P_ID_DITTA_UMA      IN DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE IN NUMBER,
                P_ID_CONTROLLO      IN DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO    IN DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO         IN OUT VARCHAR2,
                P_ESITO             IN OUT VARCHAR2) IS
    nNumLavorazioni INTEGER:=0;
BEGIN

    IF IsAziendaConsorzio (P_ID_AZIENDA) AND NOT IsDittaUmaForzata (P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE) THEN
        IF NOT EsisteSocioPerAziendaEData (P_ID_AZIENDA,SYSDATE) THEN
            P_ESITO := RET_ERR_WARN;
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 2696, NULL, P_MESSAGGIO, P_ESITO);
            ESTRAI_ERRORE_COMUNE (2696, P_MESSAGGIO,P_ESITO);
        ELSE
            P_ESITO := RET_OK;
            P_MESSAGGIO := NULL;
        END IF;
    ELSE
        P_ESITO := RET_OK;
        P_MESSAGGIO := NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ESITO := RET_ERR_PROC;
        P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA34 ' || SQLERRM;
END UMA34;

PROCEDURE UMA35(P_ID_DITTA_UMA        DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE   NUMBER,
                P_ID_CONTROLLO        DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO      DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO       OUT VARCHAR2,
                P_ESITO           OUT VARCHAR2) IS

  nCont       PLS_INTEGER;
  bErr        BOOLEAN := FALSE;
  vMessaggio  DB_CONTROLLO_DOMANDA.ULTERIORE_DESCRIZIONE%TYPE;
BEGIN
  FOR rec IN (SELECT DISTINCT CLL.ID_CATEGORIA_UTILIZZO_UMA,CUU.DESCRIZIONE
              FROM   DB_COLTURA_LINEA_LAVORAZIONE CLL,DB_LAVORAZIONE_CONTO_PROPRIO LCP,DB_LAVORAZIONI_LINEA_LAVORAZIO LLL,
                     DB_CATEGORIA_UTILIZZO_UMA CUU
              WHERE  CLL.ID_COLTURA_LINEA_LAVORAZIONE = LLL.ID_COLTURA_LINEA_LAVORAZIONE
              AND    LCP.ID_CATEGORIA_UTILIZZO_UMA    = CLL.ID_CATEGORIA_UTILIZZO_UMA
              AND    CLL.DATA_INIZIO_VALIDITA        <= SYSDATE
              AND    (CLL.DATA_FINE_VALIDITA IS NULL OR CLL.DATA_FINE_VALIDITA <= SYSDATE)
              AND    LLL.DATA_INIZIO_VALIDITA        <= SYSDATE
              AND    (LLL.DATA_FINE_VALIDITA IS NULL OR LLL.DATA_FINE_VALIDITA <= SYSDATE)
              AND    LCP.ANNO_CAMPAGNA                = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
              AND    LCP.ID_DITTA_UMA                 = P_ID_DITTA_UMA
              AND    LCP.DATA_CESSAZIONE              IS NULL
              AND    LCP.DATA_FINE_VALIDITA           IS NULL
              AND    CUU.ID_CATEGORIA_UTILIZZO_UMA    = CLL.ID_CATEGORIA_UTILIZZO_UMA
              AND    LCP.ID_ASSEGNAZIONE_CARBURANTE   IS NULL) LOOP

    nCont := 0;

    FOR recLinLav IN (SELECT ID_COLTURA_LINEA_LAVORAZIONE
                      FROM   DB_COLTURA_LINEA_LAVORAZIONE
                      WHERE  ID_CATEGORIA_UTILIZZO_UMA = rec.ID_CATEGORIA_UTILIZZO_UMA) LOOP

      SELECT COUNT(*)
      INTO   nCont
      FROM   DB_LAVORAZIONE_CONTO_PROPRIO LCP,DB_LAVORAZIONI_LINEA_LAVORAZIO LLL
      WHERE  LCP.ID_CATEGORIA_UTILIZZO_UMA    = rec.ID_CATEGORIA_UTILIZZO_UMA
      AND    LCP.ID_DITTA_UMA                 = P_ID_DITTA_UMA
      AND    LCP.ANNO_CAMPAGNA                = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
      AND    LCP.DATA_CESSAZIONE              IS NULL
      AND    LCP.DATA_FINE_VALIDITA           IS NULL
      AND    LCP.ID_LAVORAZIONI               = LLL.ID_LAVORAZIONI
      AND    LLL.ID_COLTURA_LINEA_LAVORAZIONE = recLinLav.ID_COLTURA_LINEA_LAVORAZIONE
      AND    LLL.DATA_INIZIO_VALIDITA        <= SYSDATE
      AND    (LLL.DATA_FINE_VALIDITA IS NULL OR LLL.DATA_FINE_VALIDITA <= SYSDATE)
      AND    LCP.NUMERO_ESECUZIONI            > LLL.MAX_ESECUZIONI_LINEA_LAVORAZ
      AND    LCP.ID_ASSEGNAZIONE_CARBURANTE   IS NULL;  

      IF nCont = 0 THEN
        EXIT;
      END IF;
    END LOOP;

    IF nCont > 0 THEN
      bErr := TRUE;
      AccodaMessaggioAnomalia(vMessaggio,kvACapoHTMLPL || '- Per la coltura : ' ||rec.DESCRIZIONE|| ' le lavorazioni inserite non rispettano alcuna linea di lavorazione della coltura');
    END IF;
  END LOOP;

  IF bErr THEN
    P_ESITO := RET_ERR_WARN;
    GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 3595, vMessaggio, P_MESSAGGIO, P_ESITO);
    ESTRAI_ERRORE_COMUNE (3595, P_MESSAGGIO,P_ESITO);
  ELSE
    P_ESITO     := RET_OK;
    P_MESSAGGIO := NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    P_ESITO      := RET_ERR_PROC;
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA35 ' || SQLERRM;
END UMA35;

PROCEDURE UMA36(P_ID_DITTA_UMA        DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE   NUMBER,
                P_ID_CONTROLLO        DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO      DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO       OUT VARCHAR2,
                P_ESITO           OUT VARCHAR2) IS

  nAssegnazioneContoProprio  NUMBER;
  nAssegnazioneContoTerzi    NUMBER;
  nIdConduzione              DB_DATI_DITTA.ID_CONDUZIONE%TYPE;
  bErr                       BOOLEAN := FALSE;
BEGIN
  IF IsDittaUmaForzata(P_ID_DITTA_UMA,P_ANNO_ASSEGNAZIONE) THEN
    P_ESITO     := RET_OK;
    P_MESSAGGIO := NULL;
  ELSE
    SELECT NVL(SUM(NVL(QA.ASSEGNAZIONE_CONTO_PROPRIO,0)),0),NVL(SUM(NVL(QA.ASSEGNAZIONE_CONTO_TERZI,0)),0)
    INTO   nAssegnazioneContoProprio,nAssegnazioneContoTerzi
    FROM   DB_DOMANDA_ASSEGNAZIONE DA,DB_ASSEGNAZIONE_CARBURANTE AC,DB_QUANTITA_ASSEGNATA QA
    WHERE  DA.ID_DOMANDA_ASSEGNAZIONE                     = AC.ID_DOMANDA_ASSEGNAZIONE
    AND    AC.ID_ASSEGNAZIONE_CARBURANTE                  = QA.ID_ASSEGNAZIONE_CARBURANTE
    AND    DA.ID_DITTA_UMA                                = P_ID_DITTA_UMA
    AND    TO_NUMBER(TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY')) = P_ANNO_ASSEGNAZIONE
    AND    DA.TIPO_DOMANDA                                = 'B'
    AND    DA.ID_STATO_DOMANDA                            = 30
    AND    AC.TIPO_ASSEGNAZIONE                           = 'B'
    AND    AC.ANNULLATO                                   IS NULL;
    
    SELECT NVL(DD.ID_CONDUZIONE,0)
    INTO   nIdConduzione
    FROM   DB_DATI_DITTA DD
    WHERE  DD.ID_DITTA_UMA       = P_ID_DITTA_UMA
    AND    DD.DATA_FINE_VALIDITA IS NULL;
    
    IF nIdConduzione = 1 AND nAssegnazioneContoProprio <= 0 THEN
      bErr := TRUE;
    ELSIF nIdConduzione = 2 AND nAssegnazioneContoTerzi <= 0 THEN
      bErr := TRUE;
    ELSIF nIdConduzione = 3 AND ((nAssegnazioneContoProprio + nAssegnazioneContoTerzi) <= 0) THEN
      bErr := TRUE;
    ELSE
      bErr := FALSE;
    END IF;
    
    IF bErr THEN
      P_ESITO := RET_ERR_WARN;
      GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 3751, NULL, P_MESSAGGIO, P_ESITO);
      ESTRAI_ERRORE_COMUNE (3751, P_MESSAGGIO,P_ESITO);
    ELSE
      P_ESITO     := RET_OK;
      P_MESSAGGIO := NULL;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    P_ESITO     := RET_ERR_PROC;
    P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA36 ' || SQLERRM;
END UMA36;

PROCEDURE UMA37(P_ID_AZIENDA          DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                P_ID_DITTA_UMA        DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE   NUMBER,
                P_ID_CONTROLLO        DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO      DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO       OUT VARCHAR2,
                P_ESITO           OUT VARCHAR2) IS

  nIdConduzione  DB_DATI_DITTA.ID_CONDUZIONE%TYPE;
  nCont          PLS_INTEGER := 0;
BEGIN

  IF isAziendaConsorzio(P_ID_AZIENDA) THEN 
    P_ESITO     := RET_OK;
    P_MESSAGGIO := NULL;
  ELSE
    SELECT ID_CONDUZIONE
    INTO   nIdConduzione
    FROM   DB_DATI_DITTA
    WHERE  ID_DITTA_UMA = P_ID_DITTA_UMA
    AND    DATA_FINE_VALIDITA IS NULL;
  
    IF nIdConduzione IN (1,3) THEN
      SELECT COUNT(*)
      INTO   nCont 
      FROM   DB_LAVORAZIONE_CONTO_PROPRIO
      WHERE  ID_DITTA_UMA               = P_ID_DITTA_UMA
      AND    ANNO_CAMPAGNA              = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
      AND    DATA_FINE_VALIDITA         IS NULL
      AND    DATA_CESSAZIONE            IS NULL
      AND    (ID_ASSEGNAZIONE_CARBURANTE IS NULL OR 
              ID_ASSEGNAZIONE_CARBURANTE IN (SELECT AC.ID_ASSEGNAZIONE_CARBURANTE 
                                             FROM   DB_DOMANDA_ASSEGNAZIONE DA,DB_ASSEGNAZIONE_CARBURANTE AC
                                             WHERE  DA.ID_DITTA_UMA                     = P_ID_DITTA_UMA
                                             AND    TO_CHAR(DA.DATA_RIFERIMENTO,'YYYY') = TO_CHAR(SYSDATE,'YYYY')
                                             AND    DA.ID_STATO_DOMANDA                 = 20
                                             AND    AC.ID_DOMANDA_ASSEGNAZIONE          = DA.ID_DOMANDA_ASSEGNAZIONE
                                             AND    AC.ANNULLATO                        IS NULL)); 
    
      IF nCont = 0 THEN
        P_ESITO := RET_ERR_WARN;
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 3756, NULL, P_MESSAGGIO, P_ESITO);
        ESTRAI_ERRORE_COMUNE (3756, P_MESSAGGIO,P_ESITO);
      ELSE
        P_ESITO     := RET_OK;
        P_MESSAGGIO := NULL;
      END IF;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    P_ESITO     := RET_ERR_PROC;
    P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA37 ' || SQLERRM;
END UMA37;

PROCEDURE UMA38(P_ID_AZIENDA             DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                P_ID_DITTA_UMA           DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE      NUMBER,
                P_ID_CONTROLLO           DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO         DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO          OUT VARCHAR2,
                P_ESITO              OUT VARCHAR2) IS

  vListaConduzione  DB_TIPO_PARAMETRO.VALORE%TYPE;
  nCont             SIMPLE_INTEGER := 0;
BEGIN
  SELECT VALORE
  INTO   vListaConduzione
  FROM   DB_TIPO_PARAMETRO
  WHERE  COD_PARAMETRO = 'UMCD'
  AND    DATA_FINE_VALIDITA IS NULL;
  
  EXECUTE IMMEDIATE ('SELECT COUNT(*)
                      FROM   DB_DATI_DITTA DD
                      WHERE  DD.ID_DITTA_UMA = '||P_ID_DITTA_UMA||' 
                      AND    DD.DATA_FINE_VALIDITA IS NULL
                      AND    DD.ID_CONDUZIONE      IN ('||vListaConduzione||')') INTO nCont;
                      
  IF nCont != 0 THEN
    P_ESITO := RET_ERR_WARN;
    GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 3835, NULL, P_MESSAGGIO, P_ESITO);
    ESTRAI_ERRORE_COMUNE (3835, P_MESSAGGIO,P_ESITO);
  ELSE
    P_ESITO     := RET_OK;
    P_MESSAGGIO := NULL;
  END IF;                      
EXCEPTION
  WHEN OTHERS THEN
    P_ESITO     := RET_ERR_PROC;
    P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA38 ' || SQLERRM;
END UMA38;

PROCEDURE UMA39(P_ID_DITTA_UMA           DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE      NUMBER,
                P_ID_CONTROLLO           DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO         DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO          OUT VARCHAR2,
                P_ESITO              OUT VARCHAR2) IS

  nCont  SIMPLE_INTEGER := 0;
BEGIN
  P_ESITO     := RET_OK;
  P_MESSAGGIO := NULL;
  
  SELECT COUNT(*)
  INTO   nCont
  FROM   DB_DOMANDA_ASSEGNAZIONE
  WHERE  ID_STATO_DOMANDA        = 35
  AND    ID_DOMANDA_ASSEGNAZIONE IN (SELECT MAX(ID_DOMANDA_ASSEGNAZIONE)
                                     FROM   DB_DOMANDA_ASSEGNAZIONE
                                     WHERE  ID_DITTA_UMA                        = P_ID_DITTA_UMA
                                     AND    ID_STATO_DOMANDA                    IN (30,35)
                                     AND    EXTRACT(YEAR FROM DATA_RIFERIMENTO) < EXTRACT(YEAR FROM SYSDATE));
  
  IF nCont != 0 THEN
    P_ESITO := RET_ERR_WARN;
    GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, 3962, NULL, P_MESSAGGIO, P_ESITO);
    ESTRAI_ERRORE_COMUNE (3962, P_MESSAGGIO,P_ESITO);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    P_ESITO     := RET_ERR_PROC;
    P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA39 ' || SQLERRM;
END UMA39;

PROCEDURE UMA40(P_ID_DITTA_UMA           DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                P_ANNO_ASSEGNAZIONE      NUMBER,
                P_ID_CONTROLLO           DB_CONTROLLO.ID_CONTROLLO%TYPE,
                P_TIPO_CONTROLLO         DB_CONTROLLO.BLOCCANTE%TYPE,
                P_MESSAGGIO          OUT VARCHAR2,
                P_ESITO              OUT VARCHAR2) IS
                
  nCont   SIMPLE_INTEGER := 0;
  ERRORE  EXCEPTION;
  nIdErr  NUMBER;  
BEGIN
  P_ESITO     := RET_OK;
  P_MESSAGGIO := NULL;
  
  -- Verifica lavorazioni conto proprio e lavorazioni consorzi
  SELECT COUNT(*)
  INTO   nCont
  FROM   DB_LAVORAZIONE_CONTO_PROPRIO LCP
  WHERE  LCP.ID_DITTA_UMA       = P_ID_DITTA_UMA
  AND    LCP.ANNO_CAMPAGNA      = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
  AND    LCP.DATA_CESSAZIONE    IS NULL
  AND    LCP.DATA_FINE_VALIDITA IS NULL
  AND    EXISTS                 (SELECT 'X'
                                 FROM   DB_CATEG_MACCHINE_LAVORAZIONI CML,DB_TIPO_GENERE_MACCHINA TGM
                                 WHERE  CML.ID_GENERE_MACCHINA        = TGM.ID_GENERE_MACCHINA
                                 AND    CML.ID_CATEGORIA_UTILIZZO_UMA = LCP.ID_CATEGORIA_UTILIZZO_UMA
                                 AND    CML.ID_LAVORAZIONI            = LCP.ID_LAVORAZIONI
                                 AND    TGM.CODIFICA_BREVE            = 'ATT'
                                 AND    LCP.ANNO_CAMPAGNA             BETWEEN TO_NUMBER(TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                              TO_NUMBER(TO_CHAR(NVL(CML.DATA_FINE_VALIDITA,SYSDATE),'YYYY'))); 

  IF nCont = 0 THEN
    SELECT COUNT(*)
    INTO   nCont
    FROM   DB_LAVORAZIONE_CONSORZI LC
    WHERE  LC.ID_DITTA_UMA       = P_ID_DITTA_UMA
    AND    LC.ANNO_CAMPAGNA      = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))
    AND    LC.DATA_CESSAZIONE    IS NULL
    AND    LC.DATA_FINE_VALIDITA IS NULL
    AND    EXISTS                (SELECT 'X'
                                  FROM   DB_CATEG_MACCHINE_LAVORAZIONI CML,DB_TIPO_GENERE_MACCHINA TGM
                                  WHERE  CML.ID_GENERE_MACCHINA        = TGM.ID_GENERE_MACCHINA
                                  AND    CML.ID_CATEGORIA_UTILIZZO_UMA = LC.ID_CATEGORIA_UTILIZZO_UMA
                                  AND    CML.ID_LAVORAZIONI            = LC.ID_LAVORAZIONI
                                  AND    TGM.CODIFICA_BREVE            = 'ATT'
                                  AND    LC.ANNO_CAMPAGNA              BETWEEN TO_NUMBER(TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                              TO_NUMBER(TO_CHAR(NVL(CML.DATA_FINE_VALIDITA,SYSDATE),'YYYY')));
  END IF;
  
  IF nCont != 0 THEN
    select sum(num_rec)
    INTO nCont FROM (SELECT COUNT(*) num_rec
    FROM   DB_UTILIZZO U,DB_MACCHINA M,DB_MATRICE MA,DB_TIPO_GENERE_MACCHINA TGM
    WHERE  M.ID_MACCHINA                      = U.ID_MACCHINA
    AND    MA.ID_MATRICE                      = M.ID_MATRICE
    AND    TGM.ID_GENERE_MACCHINA             = MA.ID_GENERE_MACCHINA
    AND    U.ID_DITTA_UMA                     = P_ID_DITTA_UMA
    AND    TGM.CODIFICA_BREVE                 = 'T'
    AND    TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) BETWEEN TO_NUMBER(TO_CHAR(U.DATA_CARICO,'YYYY')) AND
                                                      TO_NUMBER(TO_CHAR(NVL(U.DATA_SCARICO,SYSDATE),'YYYY'))
    UNION
    SELECT COUNT(*) num_rec
    FROM   DB_UTILIZZO U,DB_MACCHINA M,DB_DATI_MACCHINA MA,DB_TIPO_GENERE_MACCHINA TGM
    WHERE  M.ID_MACCHINA                      = U.ID_MACCHINA
    AND    MA.ID_MACCHINA                     = M.ID_MACCHINA
    AND    TGM.ID_GENERE_MACCHINA             = MA.ID_GENERE_MACCHINA
    AND    U.ID_DITTA_UMA                     = P_ID_DITTA_UMA
    AND    TGM.CODIFICA_BREVE                 = 'T'
    AND    TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) BETWEEN TO_NUMBER(TO_CHAR(U.DATA_CARICO,'YYYY')) AND
                                                      TO_NUMBER(TO_CHAR(NVL(U.DATA_SCARICO,SYSDATE),'YYYY')));
    
    IF nCont = 0 THEN
      nIdErr := 3963;
      RAISE ERRORE;
    END IF;
  END IF;
  
  -- Verifica lavorazioni conto terzi
  SELECT COUNT(*)
  INTO   nCont
  FROM   DB_LAVORAZIONE_CONTOTERZI LC, DB_CAMPAGNA_CONTOTERZISTI CC
  WHERE  CC.ID_CAMPAGNA_CONTOTERZISTI = LC.ID_CAMPAGNA_CONTOTERZISTI
  AND    CC.ID_DITTA_UMA              = P_ID_DITTA_UMA
  AND    CC.ANNO_CAMPAGNA             = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - 1
  AND    CC.VERSO_LAVORAZIONI         = 'E'
  AND    LC.DATA_CESSAZIONE           IS NULL
  AND    LC.DATA_FINE_VALIDITA        IS NULL
  AND    EXISTS                       (SELECT 'X'
                                       FROM   DB_CATEG_MACCHINE_LAVORAZIONI CML,DB_TIPO_GENERE_MACCHINA TGM
                                       WHERE  CML.ID_GENERE_MACCHINA        = TGM.ID_GENERE_MACCHINA
                                       AND    CML.ID_CATEGORIA_UTILIZZO_UMA = LC.ID_CATEGORIA_UTILIZZO_UMA
                                       AND    CML.ID_LAVORAZIONI            = LC.ID_LAVORAZIONI
                                       AND    TGM.CODIFICA_BREVE            = 'ATT'
                                       AND    CC.ANNO_CAMPAGNA              BETWEEN TO_NUMBER(TO_CHAR(CML.DATA_INIZIO_VALIDITA,'YYYY')) AND
                                                                            TO_NUMBER(TO_CHAR(NVL(CML.DATA_FINE_VALIDITA,SYSDATE),'YYYY')));
  IF nCont != 0 THEN
    select sum(num_rec)
    INTO nCont FROM (SELECT COUNT(*) num_rec
    FROM   DB_UTILIZZO U,DB_MACCHINA M,DB_MATRICE MA,DB_TIPO_GENERE_MACCHINA TGM
    WHERE  M.ID_MACCHINA                      = U.ID_MACCHINA
    AND    MA.ID_MATRICE                      = M.ID_MATRICE
    AND    TGM.ID_GENERE_MACCHINA             = MA.ID_GENERE_MACCHINA
    AND    U.ID_DITTA_UMA                     = P_ID_DITTA_UMA
    AND    TGM.CODIFICA_BREVE                 = 'T'
    AND    (TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - 1) BETWEEN TO_NUMBER(TO_CHAR(U.DATA_CARICO,'YYYY')) AND
                                                            TO_NUMBER(TO_CHAR(NVL(U.DATA_SCARICO,SYSDATE),'YYYY'))
    UNION
    SELECT COUNT(*) num_rec
    FROM   DB_UTILIZZO U,DB_MACCHINA M,DB_DATI_MACCHINA MA,DB_TIPO_GENERE_MACCHINA TGM
    WHERE  M.ID_MACCHINA                      = U.ID_MACCHINA
    AND    MA.ID_MACCHINA                     = M.ID_MACCHINA
    AND    TGM.ID_GENERE_MACCHINA             = MA.ID_GENERE_MACCHINA
    AND    U.ID_DITTA_UMA                     = P_ID_DITTA_UMA
    AND    TGM.CODIFICA_BREVE                 = 'T'
    AND    (TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - 1) BETWEEN TO_NUMBER(TO_CHAR(U.DATA_CARICO,'YYYY')) AND
                                                            TO_NUMBER(TO_CHAR(NVL(U.DATA_SCARICO,SYSDATE),'YYYY')));
    IF nCont = 0 THEN
      nIdErr := 3963;
      RAISE ERRORE;
    END IF;
  END IF;  
EXCEPTION
  WHEN ERRORE THEN
    P_ESITO := RET_ERR_WARN;
    GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO , P_TIPO_CONTROLLO, nIdErr, NULL, P_MESSAGGIO, P_ESITO);
    ESTRAI_ERRORE_COMUNE (nIdErr, P_MESSAGGIO,P_ESITO);
  WHEN OTHERS THEN
    P_ESITO     := RET_ERR_PROC;
    P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA UMA40 ' || SQLERRM;
END UMA40;  

FUNCTION ELABORA_CONTROLLI (P_ID_AZIENDA      IN     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                            P_ID_DITTA_UMA   IN     DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                            P_ANNO_ASSEGNAZIONE IN  NUMBER,
                               P_TIPO_CONTROLLO IN        DB_CONTROLLO.BLOCCANTE%TYPE,
                            P_TIPO_FASE         IN        VARCHAR2,
                            P_ID_CONTROLLO     IN     DB_CONTROLLO.ID_CONTROLLO%TYPE,
                            P_ESITO             IN OUT    VARCHAR2,
                            P_ESITO_OUT         IN OUT    VARCHAR2,
                            P_MESSAGGIO         IN OUT    VARCHAR2)  return boolean IS



N_ID_ERR         DB_CONTROLLO_DOMANDA.EXT_ID_MESSAGGIO_ERRORE%TYPE;
C_FLAG_CCIAA     CHAR(1);

BEGIN

     /* cerco informazioni sulla forma giuridica */
     SELECT Z.FLAG_CCIAA
     INTO C_FLAG_CCIAA
     FROM SMRGAA.DB_TIPO_FORMA_GIURIDICA Z
     WHERE Z.ID_FORMA_GIURIDICA=N_ID_FORMA_GIURIDICA;

/*     CONTROLLI SU STATO AZIENDA */
     IF P_ID_CONTROLLO = 'ANA08' THEN
         smrgaa.PACK_CONTROLLI.ANA08(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

      IF P_ID_CONTROLLO = 'ANA14' THEN
         smrgaa.PACK_CONTROLLI.ANA14(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

/*     CONTROLLI SU  DATI FISCALI IDENTIFICATIVI AZIENDA */
     IF P_ID_CONTROLLO = 'ANA03' THEN
         smrgaa.PACK_CONTROLLI.ANA03(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

      IF P_ID_CONTROLLO = 'ANA05' AND
         (S_FLAG_AZIENDA_PROVVISORIA IS NULL OR S_FLAG_AZIENDA_PROVVISORIA = 'N') AND
        ((N_ID_FORMA_GIURIDICA = 52 AND S_PARTITA_IVA IS NOT NULL) OR
          N_ID_FORMA_GIURIDICA <> 52)THEN
        ---CONTROLLO SOLO SE NON è UN'AZIENDA PROVVISORIA
          smrgaa.PACK_CONTROLLI.ANA05(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

/*     CONTROLLI SULLA FORMA GIURIDICA */
       IF P_ID_CONTROLLO = 'ANA15' THEN
        --- CONTROLLO CHE LA FORMA GIURIDICA SIA ATTIVA
          smrgaa.PACK_CONTROLLI.ANA15(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'ANA19' THEN
       -- CONTROLLO recapiti mail
        smrgaa.PACK_CONTROLLI.ANA19(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'ANA20' THEN
       -- CONTROLLO pec valorizzata
        smrgaa.PACK_CONTROLLI.ANA20(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'ANA22' THEN
       -- CONTROLLO recapiti telefonici
        smrgaa.PACK_CONTROLLI.ANA22(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_TIPO_FASE <> 'I' THEN --DIVERSO DA IMPORTAZIONE
         IF P_ID_CONTROLLO = 'ADE06' THEN
            --- CONTROLLO CHE NON SIA UNA PERSONA FISICA
              smrgaa.PACK_CONTROLLI.ADE06(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;
     END IF;

     IF P_ID_CONTROLLO = 'ADE05' THEN
        ---CONTROLLO SE ESISTE UNA DICHIARAZIONE DI CONSISTENZA
         IF N_ID_FORMA_GIURIDICA <> 49 -- SE NON E' UN CONSORZIO IRRIGUO
             and N_ID_CONDUZIONE <> 2 -- NON E' DI TIPO CONTO TERZI
            --and NOT B_SERRE                 -- non richiede carburante solo per le serre
            then
                smrgaa.PACK_CONTROLLI.ADE05(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
              GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;
     END IF;

/*     CONTROLLI SU ISCRIZIONE CAMERA DI COMMERCIO */
     -- NON CONTROLLO SE E' ISCRITTO ALLA CAMERA DI COMMERCIO PER LE PERS. FISICHE
     IF P_ID_CONTROLLO = 'ANA13'
     AND N_ID_FORMA_GIURIDICA NOT IN (52,26,27,29,30,31,40,41,42,43,44,45,48,49,50,65,66,67,68,69,70,71,72,78,
                                          79,80,81,82,83,84,85,86,87) THEN
         smrgaa.PACK_CONTROLLI.ANA13(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

/*     CONTROLLI SU FONTE INFOCAMERE (AAEP) */
     IF IsSiglaProvinciaInRegione (vGlProvReaCCIA,kvIdRegioneBasilicata) THEN

         IF P_ID_CONTROLLO = 'AEP01' THEN
            smrgaa.PACK_CONTROLLI.AEP01(S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP02' THEN
            smrgaa.PACK_CONTROLLI.AEP02(S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP03' THEN
            smrgaa.PACK_CONTROLLI.AEP03(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP04' THEN
            smrgaa.PACK_CONTROLLI.AEP04(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP05' THEN
            smrgaa.PACK_CONTROLLI.AEP05(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP06' THEN
            smrgaa.PACK_CONTROLLI.AEP06(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP07' THEN
            smrgaa.PACK_CONTROLLI.AEP07(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'AEP08'/* AND C_FLAG_CCIAA='S' */
         AND N_ID_FORMA_GIURIDICA NOT IN (52,26,27,29,30,31,40,41,42,43,44,45,48,49,50,65,66,67,68,69,70,71,72,78,
                                          79,80,81,82,83,84,85,86,87) THEN
            smrgaa.PACK_CONTROLLI.AEP08(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
            GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
         END IF;
     END IF;
/*      CONTROLLISU ANAGRAFE TRIBUTARIA */

     IF P_ID_CONTROLLO = 'TRB05' THEN
         smrgaa.PACK_CONTROLLI.TRB05(S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TRB01' THEN
         smrgaa.PACK_CONTROLLI.TRB01(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TRB02' THEN
         smrgaa.PACK_CONTROLLI.TRB02(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TRB03' THEN
         smrgaa.PACK_CONTROLLI.TRB03(S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TRB04' THEN
         smrgaa.PACK_CONTROLLI.TRB04(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

      IF P_ID_CONTROLLO = 'TRB06' THEN
         smrgaa.PACK_CONTROLLI.TRB06(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TRB07' THEN
         smrgaa.PACK_CONTROLLI.TRB07(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'TRB08' THEN
         smrgaa.PACK_CONTROLLI.TRB08(p_id_azienda, S_CUAA, p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TRB09' THEN
         smrgaa.PACK_CONTROLLI.TRB09(p_id_azienda,p_ESITO, p_MESSAGGIO, N_id_err);
         GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

/*     CONTROLLI SU TITOLARE/RAPPR.LEGALE */
      IF P_ID_CONTROLLO = 'TIT01' THEN
         smrgaa.PACK_CONTROLLI.TIT01(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL,  P_MESSAGGIO, P_ESITO);
     END IF;

      IF P_ID_CONTROLLO = 'TIT02' THEN
         smrgaa.PACK_CONTROLLI.TIT02(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'TIT04' THEN
         smrgaa.PACK_CONTROLLI.TIT04(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;

/*     CONTROLLI SU SEDE LEGALE AZIENDA */
     IF P_ID_CONTROLLO = 'ANA07' THEN
         smrgaa.PACK_CONTROLLI.ANA07(p_id_azienda, p_ESITO, p_MESSAGGIO, N_id_err);
        GESTIONE_ERRORE(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, N_id_err, NULL, P_MESSAGGIO, P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'UMA00' THEN
       UMA00(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
      
     IF P_ID_CONTROLLO = 'UMA01' THEN
          UMA01 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF N_ID_FORMA_GIURIDICA <> 49  -- SE NON E' UN CONSORZIO IRRIGUO
         and N_ID_CONDUZIONE     <>  2  -- NON E' DI TIPO CONTO TERZI
        --and NOT B_SERRE             -- non richiede carburante solo per le serre
        then
        -- VERIFICO LA CONSISTENZA
        IF P_ID_CONTROLLO = 'UMA02' THEN
              UMA02(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
             IF P_TIPO_FASE <> 'I' THEN
                 UMA11(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, 'UMA11', P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
             END IF;
         END IF;
     END IF;

     IF P_ID_CONTROLLO = 'UMA18' and B_SERRE THEN   -- l'azienda ha serre
        -- VERIFICO LA CONSISTENZA
        IF P_TIPO_FASE <> 'I' THEN
           UMA18(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
        END IF;
     END IF;


     IF P_ID_CONTROLLO = 'UMA19' and B_SERRE THEN   -- l'azienda ha serre
        -- VERIFICO LA CONSISTENZA
        IF P_TIPO_FASE <> 'I' THEN
           UMA19(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
        END IF;
     END IF;

      IF P_ID_CONTROLLO = 'UMA20' THEN -- verifica su restituzione buoni
        -- VERIFICO LA CONSISTENZA
        IF P_TIPO_FASE <> 'I' THEN
           UMA20(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
        END IF;
     END IF;

     IF P_ID_CONTROLLO = 'UMA21'
        and  N_ID_FORMA_GIURIDICA <> 49  -- SE NON E' UN CONSORZIO IRRIGUO
        and N_ID_CONDUZIONE         <>  2  -- NON E' DI TIPO CONTO TERZI
        THEN
        -- se non è presente una dichiarazione di consistenza dell'anno in corso
        -- deve essere stampata l'auto certificatzione che vale quella dell'anno precedente
        IF P_TIPO_FASE <> 'I' THEN
           UMA21(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
        END IF;
     END IF;


     IF P_ID_CONTROLLO = 'UMA22' THEN
        -- verifica la presenza di ASM "Impianti/bruciatori serra" non aggiornati dagli uffici UMA
        IF P_TIPO_FASE <> 'I' THEN
           UMA22(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
        END IF;
     END IF;

     IF P_TIPO_FASE <> 'I' THEN --DIVERSO DA IMPORTAZIONE
         IF P_ID_CONTROLLO = 'UMA03' THEN
              UMA03 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
         END IF;
     END IF;

     IF P_ID_CONTROLLO = 'UMA04' THEN
          UMA04 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'UMA05' THEN
          UMA05 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'UMA06' THEN
         UMA06 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'UMA07' AND B_SERRE = FALSE THEN
         UMA07 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'UMA09' THEN
         UMA09 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     -- se si tratta di consorzio irriguo
     IF N_ID_FORMA_GIURIDICA = 49 THEN
         IF P_ID_CONTROLLO = 'UMA08' THEN
             UMA08(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
         END IF;
         IF P_ID_CONTROLLO = 'UMA10' THEN
             UMA10 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
         END IF;
     END IF;

     IF P_TIPO_FASE <> 'I' THEN --DIVERSO DA IMPORTAZIONE
         IF P_ID_CONTROLLO = 'UMA12' THEN -- CONTROLLO PRESENZA CARRO UNIFEED
             UMA12(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'UMA13' THEN --CONTROLLO PRESENZA ASM- RISCALDAMENTO RICOVERI ZOOTECNICI
             UMA13(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
         END IF;

         IF P_ID_CONTROLLO = 'UMA17' THEN --CONTROLLO che non sia presente la lavorazione Ciclo Chiuso con altre non compatibili
             UMA17(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
         END IF;
     END IF;

     IF P_ID_CONTROLLO = 'UMA15' THEN
        UMA15 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'UMA16' THEN
        UMA15 (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA23' THEN
        UMA23(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA24' AND
        N_ID_FORMA_GIURIDICA <> 49 AND -- SE NON E' UN CONSORZIO IRRIGUO
        N_ID_CONDUZIONE <> 2 THEN  -- NON E' DI TIPO CONTO TERZI
        UMA24(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA25' THEN
        UMA25(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA26' THEN
        UMA26(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA27' THEN
        UMA27(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA28' THEN
        UMA28(P_ID_AZIENDA,P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA29' THEN
        UMA29(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA30' THEN
        UMA30(P_ID_AZIENDA,P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA31' THEN
        UMA31(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA32' THEN
        UMA32(P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA33' THEN
        UMA33(P_ID_AZIENDA,P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;
     IF P_ID_CONTROLLO = 'UMA34' THEN
        UMA34(P_ID_AZIENDA,P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_ID_CONTROLLO, P_TIPO_CONTROLLO, P_MESSAGGIO, P_ESITO);
     END IF;

     IF P_ID_CONTROLLO = 'UMA35' THEN
       UMA35(P_ID_DITTA_UMA ,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO ,P_TIPO_CONTROLLO ,P_MESSAGGIO,P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'UMA36' THEN
       UMA36(P_ID_DITTA_UMA ,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO ,P_TIPO_CONTROLLO ,P_MESSAGGIO,P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'UMA37' THEN
       UMA37(P_ID_AZIENDA,P_ID_DITTA_UMA ,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO ,P_TIPO_CONTROLLO ,P_MESSAGGIO,P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'UMA38' THEN
       UMA38(P_ID_AZIENDA,P_ID_DITTA_UMA ,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO ,P_TIPO_CONTROLLO ,P_MESSAGGIO,P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'UMA39' THEN
       UMA39(P_ID_DITTA_UMA ,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO ,P_TIPO_CONTROLLO ,P_MESSAGGIO,P_ESITO);
     END IF;
     
     IF P_ID_CONTROLLO = 'UMA40' THEN
       UMA40(P_ID_DITTA_UMA ,P_ANNO_ASSEGNAZIONE,P_ID_CONTROLLO ,P_TIPO_CONTROLLO ,P_MESSAGGIO,P_ESITO);
     END IF;

     IF P_ESITO_OUT = '0' AND P_ESITO <> '0' THEN
         P_ESITO_OUT := P_ESITO;
     END IF;

     RETURN (TRUE);

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA ELABORA_CONTROLLI ' || SQLERRM||' RIGA = '||dbms_utility.FORMAT_ERROR_BACKTRACE;
    P_ESITO         := RET_ERR_PROC;
    RETURN (FALSE);
END ELABORA_CONTROLLI;

FUNCTION CONTROLLO_PARAMETRI (P_ID_DITTA_UMA   IN     DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                              P_TIPO_CONTROLLO IN        DB_CONTROLLO.BLOCCANTE%TYPE,
                                 P_TIPO_FASE       IN        VARCHAR2,
                              P_ESITO           IN OUT    VARCHAR2,
                              P_MESSAGGIO       IN OUT    VARCHAR2)  return boolean IS
BEGIN
     --- SONO ERRORI GRAVI CHE NON FANNO NEMMENO INSERIRE UNA RICHIESTA
     IF P_ID_DITTA_UMA IS NULL THEN
       P_ESITO        := RET_ERR_PROC;
       P_MESSAGGIO  := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA CONTROLLO_PARAMETRI (IDENTIFICATIVO AZIENDA NON IMPOSTATO)';
       RETURN (TRUE);
    END IF;

    RETURN (TRUE);

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO   := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE ERRORE: PROCEDURA CONTROLLO_PARAMETRI: ' || sqlerrm;
    P_ESITO         := RET_ERR_PROC;
    RETURN (FALSE);
END CONTROLLO_PARAMETRI;

FUNCTION CANCELLA_ANOMALIE (P_ID_DITTA_UMA      IN     DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                             P_ANNO_ASSEGNAZIONE IN  NUMBER,
                            P_ESITO                   IN OUT    VARCHAR2,
                               P_MESSAGGIO               IN OUT    VARCHAR2) return boolean IS
BEGIN

     DELETE
       FROM DB_CONTROLLO_DOMANDA
      WHERE ID_DITTA_UMA = P_ID_DITTA_UMA
        AND ANNO_ASSEGNAZIONE = P_ANNO_ASSEGNAZIONE;

     RETURN (TRUE);

EXCEPTION WHEN OTHERS then
    P_MESSAGGIO   := 'ERRORE CANCELLA_ANOMALIE: ' || sqlerrm;
    P_ESITO         := RET_ERR_PROC;
    RETURN (FALSE);
END CANCELLA_ANOMALIE;

PROCEDURE ESEGUI_CONTROLLI(P_ID_DITTA_UMA                  IN     DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                             P_ANNO_ASSEGNAZIONE            IN   NUMBER,
                           P_TIPO_CONTROLLO            IN    DB_CONTROLLO.BLOCCANTE%TYPE,
                           P_TIPO_FASE                   IN    VARCHAR2,
                           P_ESITO_OUT                      IN OUT    VARCHAR2,
                           P_MESSAGGIO                      IN OUT    VARCHAR2) IS

    N_TERRENI        NUMBER(10);
    N_SERRE          NUMBER(10);
    N_ALLEVAMENTI  NUMBER(10);
    N_CONTATORE       NUMBER(10);

    -- Cursore di tutti i controlli eseguibili per il tipo fase
    -- dato in input
    CURSOR curControlli (pIdTipoFase IN DB_TIPO_FASE.ID_TIPO_FASE%TYPE) IS
    SELECT C.ID_CONTROLLO, C.ID_GRUPPO_CONTROLLO, TC.BLOCCANTE, C.DB_SCHEMA,
           TF.INTERROMPI_SE_CONTROLLO_KO
      FROM DB_CONTROLLO C, DB_R_CONTROLLO_TIPO_FASE TC, DB_TIPO_FASE TF
     WHERE TF.ID_TIPO_FASE = pIdTipoFase
       AND TC.ID_TIPO_FASE = TF.ID_TIPO_FASE
       AND TC.DA_ESEGUIRE = 'S'
       AND TC.ID_CONTROLLO = C.ID_CONTROLLO;

BEGIN

     N_TERRENI       := '0';
     N_SERRE         := '0';
     P_ESITO           := '0';
     P_ESITO_OUT      := '0';
     P_MESSAGGIO      := NULL;
     N_ID_FORMA_GIURIDICA := NULL;
     GlobalDataRif          := SYSDATE;
     N_ID_CONDUZIONE      := NULL;
     S_PARTITA_IVA          := NULL;
     vGlProvReaCCIA       := NULL;

     BEGIN
         SELECT EXT_ID_AZIENDA, B.CUAA, B.ID_FORMA_GIURIDICA, B.PARTITA_IVA, B.CCIAA_PROVINCIA_REA
           INTO N_ID_AZIENDA, S_CUAA, N_ID_FORMA_GIURIDICA, S_PARTITA_IVA, vGlProvReaCCIA
           FROM DB_DITTA_UMA A, DB_ANAGRAFICA_AZIENDA B, DB_AZIENDA C
          WHERE ID_DITTA_UMA = P_ID_DITTA_UMA
            AND A.EXT_ID_AZIENDA = B.ID_AZIENDA
            AND B.ID_AZIENDA = C.ID_AZIENDA
            AND B.DATA_INIZIO_VALIDITA = C.DATA_INIZIO_VALIDITA;

         -- controllo se la provincia d'iscrizione al REA è stata specificata
         -- altrimenti do apposita anomalia solamente se non sono nel tipo fase
         -- di cessazione ditta uma
         IF P_TIPO_FASE <> knIdTipoFaseCessazioneDittaUma THEN 
            IF vGlProvReaCCIA IS NULL THEN
                P_MESSAGGIO := 'La Provincia d''iscrizione al REA (Repertorio economico e amministrativo) non è stata specificata';
                P_ESITO := RET_ERR_PROC;
            END IF;
         END IF;

     EXCEPTION
        WHEN OTHERS THEN
            P_MESSAGGIO   := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: ' || sqlerrm;
            P_ESITO         := RET_ERR_PROC;
     END;
     -- se la select precedente non è andata in when others e se la provincia REA è valorizzata
     -- P_ESITO = 0 (RET_OK)
     IF P_ESITO = RET_OK THEN

         BEGIN
             SELECT B.ID_CONDUZIONE
               INTO N_ID_CONDUZIONE
               FROM DB_DITTA_UMA A, DB_DATI_DITTA B
              WHERE A.ID_DITTA_UMA = P_ID_DITTA_UMA
                AND A.ID_DITTA_UMA = B.ID_DITTA_UMA
                AND    B.DATA_FINE_VALIDITA IS NULL;
         EXCEPTION
            WHEN OTHERS THEN
                P_MESSAGGIO   := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: ' || sqlerrm;
                P_ESITO         := RET_ERR_PROC;
         END;

     END IF;

     -- se la select precedente non è andata in when others
     -- P_ESITO = 0 (RET_OK)
     IF P_ESITO = RET_OK THEN

        select count(*)
        into N_TERRENI
        from db_ditta_uma a, db_superficie_azienda b
        where A.ID_DITTA_UMA = P_ID_DITTA_UMA and a.ID_DITTA_UMA = b.ID_DITTA_UMA
        and b.DATA_FINE_VALIDITA is null;

        select count(*)
        into N_SERRE
        from db_ditta_uma a, db_serra b
        where A.ID_DITTA_UMA = P_ID_DITTA_UMA and a.ID_DITTA_UMA = b.ID_DITTA_UMA
        and b.DATA_FINE_VALIDITA is null;

        IF N_SERRE > 0 THEN
           B_SERRE := TRUE;
        ELSE
           B_SERRE := FALSE;
        END IF;

     END IF;
     -- effettuo la cancellazione delle anomalie solamente se non
     -- si tratta del tipo fase di cessazione ditta UMA
     IF P_TIPO_FASE <> knIdTipoFaseCessazioneDittaUma THEN
        -- in ogni caso richiamo la function CANCELLA_ANOMALIE (anche se P_ESITO ha un valore che identifica errori o anomalie)
        IF NOT CANCELLA_ANOMALIE (P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_MESSAGGIO, P_ESITO) THEN
            RAISE EsciRountine;
        END IF;
     END IF;
     -- in ogni caso richiamo la function CONTROLLO_PARAMETRI (anche se P_ESITO ha un valore che identifica errori o anomalie)
      IF NOT CONTROLLO_PARAMETRI(P_ID_DITTA_UMA, P_TIPO_CONTROLLO, P_TIPO_FASE, P_ESITO ,P_MESSAGGIO ) THEN
           RAISE EsciRountine;
     END IF;
     -- effettuo i controlli veri e propri solo
     -- se P_ESITO = 0 (RET_OK)
     IF P_ESITO = RET_OK THEN
        -- scorro il cursore
        FOR recControlli IN curControlli (P_TIPO_FASE) LOOP
            -- ed eseguo ogni controllo associato al tipo fase
            IF NOT ELABORA_CONTROLLI(N_ID_AZIENDA, P_ID_DITTA_UMA, P_ANNO_ASSEGNAZIONE, P_TIPO_CONTROLLO,
                                     P_TIPO_FASE, recControlli.ID_CONTROLLO, P_ESITO, P_ESITO_OUT, P_MESSAGGIO ) THEN
               RAISE EsciRountine;
            END IF;
            -- se l'esito è diverso da zero
            IF P_ESITO <> '0' THEN
               -- ed il tipo controllo è GRAVE e BLOCCANTE

               IF P_TIPO_CONTROLLO = 'G' OR -- GRAVE
                  P_TIPO_CONTROLLO = 'B' THEN -- BLOCCANTE
                  P_ESITO := RET_ERR_BLOC;     -- PROCEDURA OK, MA CON ERRORE BLOCCANTE
               END IF;
               -- se è il tipo fase dice che in caso di controllo
               -- errato l'esecuzione degli altri deve interrompersi
               -- faccio la exit
               IF recControlli.INTERROMPI_SE_CONTROLLO_KO = 'S' THEN
                  EXIT;
               END IF;
            END IF;
        END LOOP;
     END IF;

     P_ESITO_OUT := P_ESITO;

     COMMIT;

exception
 when EsciRountine then
     if P_ESITO = '0' then
       P_ESITO_OUT := RET_ERR_PROC;
       P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: ' || sqlerrm||' RIGA = '||dbms_utility.FORMAT_ERROR_BACKTRACE;
    end if;
 when others then
     if P_ESITO = '0' then
       P_ESITO_OUT := RET_ERR_PROC;
       P_MESSAGGIO := 'ERRORE GRAVE. CONTATTARE L''ASSISTENZA COMUNICANDO IL SEGUENTE MESSAGGIO: ' || sqlerrm||' RIGA = '||dbms_utility.FORMAT_ERROR_BACKTRACE;
    end if;
END ESEGUI_CONTROLLI;


END PACK_CONTROLLI;          -- Package
/
