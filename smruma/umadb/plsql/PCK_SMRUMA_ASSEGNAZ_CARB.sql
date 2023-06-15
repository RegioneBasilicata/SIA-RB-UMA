CREATE OR REPLACE PACKAGE PCK_SMRUMA_ASSEGNAZ_CARB is
  -- identificativo tipo domanda di acconto
  kvIdTipoDomandaAcconto              CONSTANT DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE:='A';
  -- identificativo stato domanda in attesa di validazione
  knIdStatoDomandaInAttesa            CONSTANT DB_DOMANDA_ASSEGNAZIONE.ID_STATO_DOMANDA%TYPE:=20;
  -- identificativo stato domanda acconto validita
  knIdStatoDomAccontoValidita         CONSTANT DB_DOMANDA_ASSEGNAZIONE.ID_STATO_DOMANDA%TYPE:=30;
  -- identificativo stato domanda base validata
  knIdStatoDomandaValidita            CONSTANT DB_DOMANDA_ASSEGNAZIONE.ID_STATO_DOMANDA%TYPE:=35;
  -- Data massima in cui si può dichiarare la ricezione della documentazione per assegnazioni post 30/06 (non viene applicata riduzione)
  kvCodParDtMaxConsDocument           CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE:='DTMX';
  -- Data limite oltre la quale viene applicata la riduzione carburante in base alla domanda di assegnazione
  kvCodParDtLimiteRiduzione           CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE:='DTHI';
  -- Data avvio calcolo rimanenze carburante per lavorazioni non effettuate
  kvCodParDtAvvioCalcRimanPerLav      CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE:='DTRL';
  -- id tipo conduzione conto proprio
  knIdContoProprio                    CONSTANT DB_TIPO_CONDUZIONE.ID_CONDUZIONE%TYPE:=1;
  -- id tipo conduzione conto proprio / terzi
  knIdContoProprioTerzi               CONSTANT DB_TIPO_CONDUZIONE.ID_CONDUZIONE%TYPE:=3;
  -- codice lavorazione effettuata
  kvCodLavorazioneEffettuata          CONSTANT DB_CAMPAGNA_CONTOTERZISTI.VERSO_LAVORAZIONI%TYPE:='E';
  -- id tipologia azienda cooperativa
  knIdTipoAziendaCooperativa          CONSTANT DB_TIPO_TIPOLOGIA_AZIENDA.ID_TIPOLOGIA_AZIENDA%TYPE:=4;
  -- id tipologia azienda consorzio
  knIdTipoAziendaConsorzio            CONSTANT DB_TIPO_TIPOLOGIA_AZIENDA.ID_TIPOLOGIA_AZIENDA%TYPE:=5;
  -- costante che identifica l'identificativo titolo possesso di asservimento
  knIdTitoloPossessoAsservimento      CONSTANT NUMBER(1):=5;
  -- costante che identifica l'identificativo titolo possesso proprietà
  knIdTitoloPossessoProprieta         CONSTANT NUMBER(1):=1;
  -- costante che identifica l'identificativo titolo possesso affitto
  knIdTitoloPossessoAffitto           CONSTANT NUMBER(1):=2;
  -- costante che identifica l'identificativo titolo possesso mezzadria
  knIdTitoloPossessoMezzadria         CONSTANT NUMBER(1):=3;
  -- costante che identifica l'identificativo titolo possesso altre forme
  knIdTitoloPossessoAltreForme        CONSTANT NUMBER(1):=4;
  -- costante identificativo procedimento UMA
  knIdProcedimentoUma                 CONSTANT NUMBER(1):=1;
  -- codice per reperimento parametrolitri di carburante assegnabili x ettaro
  kvCodParametroLitriCarbXEttaro      CONSTANT DB_PARAMETRO.ID_PARAMETRO%TYPE:='UMAS';

  FUNCTION TOTALE_CARBURANTE_CONTOTERZI(pIdDittaUma           DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
                                      pAnnoRiferimento      NUMBER,
                                      pCarburanteLavCT  OUT NUMBER,
                                      pAssegnatoPrecCT  OUT NUMBER,
                                      pRimanenzePrecCT  OUT NUMBER,
                                      pMsgErr           OUT VARCHAR2,
                                      pCodErr           OUT VARCHAR2) RETURN BOOLEAN;

  /*********************************************************************
  Effettua il calcolo del quantitativo massimo di carburante assegnabile
  per conto proprio
  *********************************************************************/
  PROCEDURE CALCOLO_ASSEGNAZIONE_CARB(P_ID_DOMANDA_ASSEGNAZIONE      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
                                      P_TIPO_ASSEGNAZIONE            DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
                                      P_NUMERO_SUPPLEMENTO           DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
                                      P_ID_UTENTE                    DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
                                      P_MSGERR                   OUT VARCHAR2,
                                      P_CODERR                   OUT VARCHAR2);


  /*********************************************************************
  Effettua il calcolo del quantitativo massimo di carburante assegnabile
  per conto proprio richiamato da PCK_CALCOLO_SUPPLEMENTO
  *********************************************************************/
  PROCEDURE CALCOLO_ASSEGNAZIONE_SUPPL(P_ID_DOMANDA_ASSEGNAZIONE      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
                                       P_TIPO_ASSEGNAZIONE            DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
                                       P_NUMERO_SUPPLEMENTO           DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
                                       P_ID_UTENTE                    DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
                                       P_MSGERR                   OUT VARCHAR2,
                                       P_CODERR                   OUT VARCHAR2);


  /*********************************************************************
  Effettua il calcolo del quantitativo massimo di carburante assegnabile
  nel caso di maggiorazioni
  per conto proprio richiamato da PCK_CALCOLO_SUPPLEMENTO
  *********************************************************************/
  PROCEDURE CALCOLO_ASSEGNAZIONE_MAGG(P_ID_DOMANDA_ASSEGNAZIONE      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
                                       P_TIPO_ASSEGNAZIONE            DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
                                       P_NUMERO_SUPPLEMENTO           DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
                                       P_ID_UTENTE                    DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
                                       P_MSGERR                   OUT VARCHAR2,
                                       P_CODERR                   OUT VARCHAR2);


  /*********************************************************************
  Effettua il calcolo delle rimanenze di carburante per le lavorazioni
  non effettuate (solamente conto proprio e conto proprio/terzi)
  Tipo:  procedure
  input:  pIdDittaUma --> Identificativo della ditta uma in elaborazione
          pIdAzienda --> Identificativo dell'azienda in elaborazione
          pAnnoRif --> anno campagna per il quale si vogliono calcolare le rimanenze
  output: pRimLavBenzina --> Totale rimanenza di benzina per lavorazioni non effettuate
          pRimLavGasolio --> Totale rimanenza di gasolio per lavorazioni non effettuate
          pMsgErr --> Eventuale messaggio di errore avvenuto durante il calcolo
          pCodErr --> Codice del messaggio di errore
  ritorno: nessuno
  *********************************************************************/
  PROCEDURE CalcolaRimanenzaLavorazioni(pIdDittaUma         DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
                                        pIdAzienda          DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
                                        pAnnoRif            DB_CAMPAGNA_CONTOTERZISTI.ANNO_CAMPAGNA%TYPE,
                                        pRimLavBenzina  OUT NUMBER,
                                        pRimLavGasolio  OUT NUMBER,
                                        pMsgErr         OUT VARCHAR2,
                                        pCodErr         OUT VARCHAR2);

  FUNCTION TOTALE_CARBURANTE_COLTURA(P_ID_DOMANDA_ASSEGNAZIONE          DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
                                     pAnnoUmlc                          NUMBER, 
                                     pIdDittaUma                        DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,  
                                     pDataRif                           DATE, 
                                     P_TIPO_ASSEGNAZIONE                DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
                                     P_NUMERO_SUPPLEMENTO               DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
                                     P_FLAG_COLTURA_SECONDARIA          DB_COLTURA_PRATICATA.FLAG_COLTURA_SECONDARIA%TYPE,
                                     P_COD_MOTIVO_LAVORAZIONE           DB_TIPO_MOTIVO_LAVORAZIONE.CODICE_MOTIVO_LAVORAZIONE%TYPE,
                                     P_CARBURANTE_LAVORAZIONE       OUT NUMBER,
                                     P_CARBURANTE_MIETITREBBIATURA  OUT NUMBER,
                                     P_CARBURANTE_ESSICAZIONE       OUT NUMBER,
                                     P_MSGERR                       OUT VARCHAR2,
                                     P_CODERR                       OUT VARCHAR2) RETURN BOOLEAN;

  PROCEDURE CALCOLO_ASSEGNAZIONE_ACCONTO(pIdDomandaAssegnazione      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
                                         pTipoAssegnazione           DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
                                         pNumeroSupplemento          DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
                                         pIdUtente                   DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
                                         pMsgErr                 OUT VARCHAR2,
                                         pCodErr                 OUT VARCHAR2);

END PCK_SMRUMA_ASSEGNAZ_CARB;
/


CREATE OR REPLACE PACKAGE BODY PCK_SMRUMA_ASSEGNAZ_CARB
IS
   /*********************************************************************
   Data una dichiarazione di consistenza reperisce la somma
   della superficie condotta dall'azienda col titolo possesso dato in input
   Tipo: function
   input: pIdDichConsistenza, pIdTitPossesso
   output: nessuno
   ritorno: DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA
   *********************************************************************/
    
   FUNCTION SelTSupCondByIdDichEIdTitPos (
      pIdDichConsistenza   IN DB_DICHIARAZIONE_CONSISTENZA.ID_DICHIARAZIONE_CONSISTENZA%TYPE,
      pIdTitPossesso       IN DB_CONDUZIONE_DICHIARATA.ID_TITOLO_POSSESSO%TYPE)
      RETURN DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE
   IS
      nSumSupCondotta   DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE;
   BEGIN
      SELECT NVL (SUM (CD.SUPERFICIE_CONDOTTA), 0)
        INTO nSumSupCondotta
        FROM DB_DICHIARAZIONE_CONSISTENZA DC, DB_CONDUZIONE_DICHIARATA CD
       WHERE     DC.ID_DICHIARAZIONE_CONSISTENZA = pIdDichConsistenza
             AND DC.CODICE_FOTOGRAFIA_TERRENI = CD.CODICE_FOTOGRAFIA_TERRENI
             AND CD.ID_TITOLO_POSSESSO = pIdTitPossesso;

      RETURN nSumSupCondotta;
   END SelTSupCondByIdDichEIdTitPos;

   /*********************************************************************
   Dato un identificativo azienda mi restrituisce TRUE se la tipologia
   di azienda a cui è associato ha il FLAG_FORMA_ASSOCIATA ad 'S'
   altrimenti FALSE (controllo anche che la tipologia azienda sia cooperativa o consorzio)
   Tipo: function
   input: pIdAzienda
   output: nessuno
   ritorno: TRUE / FALSE
   *********************************************************************/
   FUNCTION IsAziendaConsorzio (
      pIdAzienda IN DB_ANAGRAFICA_AZIENDA.ID_AZIENDA%TYPE)
      RETURN BOOLEAN
   IS
      nCount   INTEGER := 0;
      bRet     BOOLEAN := FALSE;
   BEGIN
      SELECT COUNT (AZ.ID_ANAGRAFICA_AZIENDA)
        INTO nCount
        FROM DB_ANAGRAFICA_AZIENDA AZ, DB_TIPO_TIPOLOGIA_AZIENDA TTA
       WHERE     AZ.ID_AZIENDA = pIdAzienda
             AND AZ.DATA_FINE_VALIDITA IS NULL
             AND AZ.ID_TIPOLOGIA_AZIENDA = TTA.ID_TIPOLOGIA_AZIENDA
             AND TTA.FLAG_FORMA_ASSOCIATA = 'S'
             AND TTA.ID_TIPOLOGIA_AZIENDA IN
                    (knIdTipoAziendaCooperativa, knIdTipoAziendaConsorzio);

      IF nCount > 0
      THEN
         bRet := TRUE;
      END IF;

      RETURN bRet;
   END IsAziendaConsorzio;

   /*****************************************************************************
   Dato un identificativo utente restrituisce TRUE se si tratta di un utente PA
   altrimenti FALSE
   Tipo: function
   input: pIdUtente
   output: nessuno
   ritorno: TRUE / FALSE
   *****************************************************************************/
   FUNCTION IsUtentePA (pIdUtente IN DB_UTENTE_IRIDE2.ID_UTENTE_IRIDE2%TYPE)
      RETURN BOOLEAN
   IS
      nCount   INTEGER := 0;
      bRet     BOOLEAN := FALSE;
   BEGIN
      SELECT COUNT (UI2.ID_UTENTE_IRIDE2)
        INTO nCount
        FROM DB_UTENTE_IRIDE2 UI2
       WHERE     UI2.ID_UTENTE_IRIDE2 = pIdutente
             AND UI2.RUOLO IN
                    ('FUNZIONARIO@PROVINCIA_AGRI', 'FUNZIONARIO@REG_PMN_AGRI');

      IF nCount > 0
      THEN
         bRet := TRUE;
      END IF;

      RETURN bRet;
   END IsUtentePA;

   /*********************************************************************
   Ricerca il codice parametro nella tavola DB_PARAMENTRO e ne
   espone il valore
   Tipo: function
   input: pCodParamentro
   output: nessuno
   ritorno: VARCHAR2
   *********************************************************************/
   FUNCTION SelectValoreParametro (pCodParametro IN VARCHAR2)
      RETURN VARCHAR2
   IS
      vValParametro   DB_PARAMETRO.VALORE%TYPE;
   BEGIN
      SELECT VALORE
        INTO vValParametro
        FROM DB_PARAMETRO
       WHERE ID_PARAMETRO = pCodParametro;

      RETURN vValParametro;
   END SelectValoreParametro;

   /*********************************************************************
   Dato un id_domanda_assegnazione recupera il corrispettivo ID_DITTA_UMA
   da DB_DOMANDA_ASSEGNAZIONE ed andando in join con DB_DATI_DITTA per questa
   colonna recupera il record con data_fine_validita a NULL (se esiste)
   espone il valore
   Tipo: function
   input: pIdDomandaAssegnazione
   output: nessuno
   ritorno: DB_DATI_DITTA%ROWTYPE
   *********************************************************************/
   FUNCTION SelectTDatiDittaByIdDomAssegn (
      pIdDomandaAssegnazione IN DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE)
      RETURN DB_DATI_DITTA%ROWTYPE
   IS
      recTDatiDitta   DB_DATI_DITTA%ROWTYPE;
   BEGIN
      SELECT DD.*
        INTO recTDatiDitta
        FROM DB_DOMANDA_ASSEGNAZIONE DA, DB_DATI_DITTA DD
       WHERE     DA.ID_DOMANDA_ASSEGNAZIONE = pIdDomandaAssegnazione
             AND DA.ID_DITTA_UMA = DD.ID_DITTA_UMA
             AND DD.DATA_FINE_VALIDITA IS NULL;

      RETURN recTDatiDitta;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END SelectTDatiDittaByIdDomAssegn;

   FUNCTION TOTALE_CARBURANTE_COLTURA (
      P_ID_DOMANDA_ASSEGNAZIONE           DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      pAnnoUmlc                           NUMBER,    
      pIdDittaUma                         DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE, 
      pDataRif                            DATE,      
      P_TIPO_ASSEGNAZIONE                 DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO                DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_FLAG_COLTURA_SECONDARIA           DB_COLTURA_PRATICATA.FLAG_COLTURA_SECONDARIA%TYPE,
      P_COD_MOTIVO_LAVORAZIONE            DB_TIPO_MOTIVO_LAVORAZIONE.CODICE_MOTIVO_LAVORAZIONE%TYPE,
      P_CARBURANTE_LAVORAZIONE        OUT NUMBER,
      P_CARBURANTE_MIETITREBBIATURA   OUT NUMBER,
      P_CARBURANTE_ESSICAZIONE        OUT NUMBER,
      P_MSGERR                        OUT VARCHAR2,
      P_CODERR                        OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      nContTrattice                 PLS_INTEGER;
      nSupCollMont                  NUMBER;
      nLitriBase                    NUMBER := 0;
      nLitriMedioImpasto            NUMBER := 0;
      nLitriAcclivita               NUMBER := 0;
      nPotMax                       NUMBER := 0;
      nFramm                        NUMBER := 0;
      bFoundLav                     BOOLEAN := FALSE;
      nPotMaxTot                    NUMBER := 0;
      nCarburanteLavorazione        NUMBER := 0;
      nCarburanteMietitrebbiatura   NUMBER := 0;
      nCarburanteEssicazione        NUMBER := 0;
      nCarbLavNoPot                 NUMBER := 0;
      nSupOre                       NUMBER := 0;
      nContNonPot                   PLS_INTEGER;
      nCarbLavPot                   NUMBER := 0;
      nPotMaxColt                   NUMBER := 0;
   BEGIN


      SELECT NVL (SUM (CARBURANTE_LAVORAZIONE), 0),
             NVL (SUM (CARBURANTE_MIETITREBBIATURA), 0),
             NVL (SUM (CARBURANTE_ESSICAZIONE), 0)
        INTO nCarburanteLavorazione,
             nCarburanteMietitrebbiatura,
             nCarburanteEssicazione
        FROM DB_CARBURANTE_COLTURA CC, DB_COLTURA_PRATICATA CP
       WHERE     CC.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND CC.TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (CC.NUMERO_SUPPLEMENTO, 0) =
                    NVL (P_NUMERO_SUPPLEMENTO, 0)
             AND CP.ID_COLTURA_PRATICATA = CC.ID_COLTURA_PRATICATA
             AND CP.FLAG_COLTURA_SECONDARIA = P_FLAG_COLTURA_SECONDARIA; 


      P_CARBURANTE_MIETITREBBIATURA := nCarburanteMietitrebbiatura;
      P_CARBURANTE_ESSICAZIONE := nCarburanteEssicazione;

      BEGIN
         IF TO_NUMBER (TO_CHAR (pDataRif, 'YYYY')) < pAnnoUmlc
         THEN
            P_CARBURANTE_LAVORAZIONE := nCarburanteLavorazione;
         ELSE
            BEGIN
               -- ditta uma ha una trattrice
            select sum(num_rec)
            INTO nContTrattice
            from (
               SELECT COUNT (*) num_rec
                 FROM DB_UTILIZZO U,
                      DB_MACCHINA M,
                      DB_MATRICE MA,
                      DB_TIPO_GENERE_MACCHINA TGM
                WHERE     M.ID_MACCHINA = U.ID_MACCHINA
                      AND TGM.ID_GENERE_MACCHINA = MA.ID_GENERE_MACCHINA
                      AND MA.ID_MATRICE = M.ID_MATRICE
                      AND U.ID_DITTA_UMA = pIdDittaUma
                      AND U.DATA_CARICO <= pDataRif
                      AND (   U.DATA_SCARICO IS NULL
                           OR U.DATA_SCARICO >= pDataRif)
                      AND MA.ID_ALIMENTAZIONE IN (1, 2)
                      AND TRIM (TGM.CODIFICA_BREVE) = 'T'
                union
                SELECT COUNT (*) num_rec
                    FROM DB_UTILIZZO U,
                         DB_MACCHINA M,
                         DB_DATI_MACCHINA DM,
                         DB_TIPO_GENERE_MACCHINA TGM
                   WHERE     M.ID_MACCHINA = U.ID_MACCHINA
                         AND TGM.ID_GENERE_MACCHINA = DM.ID_GENERE_MACCHINA
                         AND M.ID_MACCHINA = DM.ID_MACCHINA
                         AND U.ID_DITTA_UMA = pIdDittaUma
                         AND U.DATA_CARICO <= pDataRif
                         AND (   U.DATA_SCARICO IS NULL
                              OR U.DATA_SCARICO >= pDataRif)
                         AND DM.ID_ALIMENTAZIONE IN (1, 2)
                         AND TRIM (TGM.CODIFICA_BREVE) = 'T');
               
               SELECT TO_NUMBER (VALORE)
                 INTO nFramm
                 FROM DB_PARAMETRO
                WHERE ID_PARAMETRO = 'UMFR';
                
            EXCEPTION
               WHEN OTHERS
               THEN
                  P_MSGERR :=
                        'ERRORE TOTALE CARBURANTE_COLTURA -2 interno1 '
                     || SQLERRM;
                  P_CODERR := SQLCODE;
                  RETURN FALSE;
            END;

            BEGIN
               FOR rec
                  IN (  SELECT CUU.ID_CATEGORIA_UTILIZZO_UMA,
                               NVL (SUM (CP.SUPERFICIE_UTILIZZATA), 0)
                                  SUP_COMPLES,
                               (  NVL (SUM (CP.SUPERFICIE_UTILIZZATA), 0)
                                * nFramm)
                                  SUP_FRAMM
                          FROM DB_CATEGORIA_UTILIZZO_UMA CUU,
                               DB_CATEGORIA_COLTURA CC,
                               DB_SUPERFICIE_AZIENDA SA,
                               DB_COLTURA_PRATICATA CP
                         WHERE     CUU.ID_CATEGORIA_UTILIZZO_UMA =
                                      CC.ID_CATEGORIA_UTILIZZO_UMA
                               AND SA.ID_SUPERFICIE_AZIENDA =
                                      CP.ID_SUPERFICIE_AZIENDA
                               AND CP.ID_COLTURA = CC.ID_COLTURA
                               AND SA.ID_DITTA_UMA = pIdDittaUma
                               AND SA.DATA_FINE_VALIDITA IS NULL
                               AND SA.DATA_SCARICO IS NULL
                               AND CC.DATA_FINE_VALIDITA IS NULL
                               AND CUU.DATA_FINE_VALIDITA IS NULL
                               AND CP.FLAG_COLTURA_SECONDARIA =
                                      P_FLAG_COLTURA_SECONDARIA 
                      GROUP BY CUU.ID_CATEGORIA_UTILIZZO_UMA)
               LOOP
                  BEGIN
                     SELECT NVL (SUM (PC.SUPERFICIE_UTILIZZATA), 0)
                       INTO nSupCollMont
                       FROM DB_SUPERFICIE_AZIENDA SA,
                            DB_COLTURA_PRATICATA CP,
                            DB_PARTICELLA_COLTURA PC,
                            DB_STORICO_PARTICELLA SP,
                            DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,
                            DB_ZONA_ALTIMETRICA ZA,
                            DB_CATEGORIA_COLTURA CC
                      WHERE     CC.ID_CATEGORIA_UTILIZZO_UMA =
                                   rec.ID_CATEGORIA_UTILIZZO_UMA
                            AND SA.ID_SUPERFICIE_AZIENDA =
                                   CP.ID_SUPERFICIE_AZIENDA
                            AND CP.ID_COLTURA_PRATICATA =
                                   PC.ID_COLTURA_PRATICATA
                            AND PC.EX_ID_STORICO_PARTICELLA =
                                   SP.ID_STORICO_PARTICELLA
                            AND SP.ID_ZONA_ALTIMETRICA =
                                   ZAUG.EXT_ID_ZONA_ALTIMETRICA
                            AND ZAUG.ID_ZONA_ALTIMETRICA =
                                   ZA.ID_ZONA_ALTIMETRICA
                            AND ZAUG.DATA_FINE_VALIDITA IS NULL
                            AND ZA.CODICE = 'M'
                            AND SA.ID_DITTA_UMA = pIdDittaUma
                            AND SA.DATA_SCARICO IS NULL
                            AND SA.DATA_FINE_VALIDITA IS NULL
                            AND CP.ID_COLTURA = CC.ID_COLTURA
                            AND CP.FLAG_COLTURA_SECONDARIA =
                                   P_FLAG_COLTURA_SECONDARIA; 

                     bFoundLav := FALSE;
                     nPotMaxColt := 0;
                     nCarbLavNoPot := 0;
                     nLitriBase := 0;
                     nLitriMedioImpasto := 0;
                     nLitriAcclivita := 0;

                     FOR recLav
                        IN (SELECT CCL.ID_LAVORAZIONI,
                                   CCL.ID_UNITA_MISURA,
                                   NVL (LINEA.MAX_ESECUZIONI_LINEA_LAVORAZ,
                                        CCL.MAX_ESECUZIONI)
                                      NUM_ESEC,
                                   CCL.LITRI_BASE,
                                   CCL.LITRI_MEDIO_IMPASTO,
                                   CCL.LITRI_TERRENI_DECLIVI
                              FROM DB_CATEG_COLTURA_LAVORAZIONI CCL,
                                   DB_UNITA_MISURA UM,
                                   DB_TIPO_LAVORAZIONI TL,
                                   (SELECT LLL.MAX_ESECUZIONI_LINEA_LAVORAZ,
                                           LLL.ID_LAVORAZIONI,
                                           CLL.LINEA_LAVORAZIONE_PRIMARIA
                                      FROM DB_COLTURA_LINEA_LAVORAZIONE CLL,
                                           DB_LAVORAZIONI_LINEA_LAVORAZIO LLL
                                     WHERE     (   LLL.DATA_FINE_VALIDITA
                                                      IS NULL
                                                OR TRUNC (
                                                      LLL.DATA_FINE_VALIDITA) >=
                                                      TRUNC (SYSDATE))
                                           AND TRUNC (
                                                  LLL.DATA_INIZIO_VALIDITA) <=
                                                  TRUNC (SYSDATE)
                                           AND (   CLL.DATA_FINE_VALIDITA
                                                      IS NULL
                                                OR TRUNC (
                                                      CLL.DATA_FINE_VALIDITA) >=
                                                      TRUNC (SYSDATE))
                                           AND TRUNC (
                                                  CLL.DATA_INIZIO_VALIDITA) <=
                                                  TRUNC (SYSDATE)
                                           AND CLL.ID_CATEGORIA_UTILIZZO_UMA =
                                                  rec.ID_CATEGORIA_UTILIZZO_UMA
                                           AND CLL.ID_COLTURA_LINEA_LAVORAZIONE =
                                                  LLL.ID_COLTURA_LINEA_LAVORAZIONE) LINEA
                             WHERE     UM.ID_UNITA_MISURA =
                                          CCL.ID_UNITA_MISURA
                                   AND CCL.ID_CATEGORIA_UTILIZZO_UMA =
                                          rec.ID_CATEGORIA_UTILIZZO_UMA
                                   AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                                   AND CCL.ID_LAVORAZIONI =
                                          LINEA.ID_LAVORAZIONI(+)
                                   AND TL.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                                   AND TL.FLAG_ASSERVIMENTO = 'N'
                                   --AND UM.TIPO = 'S'
                                   AND TRUNC (CCL.DATA_INIZIO_VALIDITA) <=
                                          TRUNC (SYSDATE)
                                   AND (   CCL.DATA_FINE_VALIDITA IS NULL
                                        OR TRUNC (CCL.DATA_FINE_VALIDITA) >=
                                              TRUNC (SYSDATE))
                                   AND LAVORAZIONE_STRAORDINARIA = 'N'
                                   --AND LAVORAZIONE_DEFAULT = 'S'
                                   AND NVL (LINEA.LINEA_LAVORAZIONE_PRIMARIA,
                                            'S') = 'S'
                                   AND EXISTS
                                          (SELECT 'X'
                                             FROM DB_CATEG_MACCHINE_LAVORAZIONI CML,
                                                  DB_TIPO_GENERE_MACCHINA TGM,
                                                  DB_UTILIZZO U,
                                                  DB_MACCHINA M
                                            WHERE     TGM.ID_GENERE_MACCHINA =
                                                         CML.ID_GENERE_MACCHINA
                                                  AND M.ID_MACCHINA =
                                                         U.ID_MACCHINA
                                                  AND CML.ID_CATEGORIA_UTILIZZO_UMA =
                                                         rec.ID_CATEGORIA_UTILIZZO_UMA
                                                  AND CML.ID_LAVORAZIONI =
                                                         CCL.ID_LAVORAZIONI
                                                  AND CML.DATA_FINE_VALIDITA
                                                         IS NULL
                                                  AND U.ID_DITTA_UMA =
                                                         pIdDittaUma
                                                  AND U.DATA_SCARICO IS NULL
                                                  AND TGM.ID_GENERE_MACCHINA IN
                                                         (SELECT DM.ID_GENERE_MACCHINA
                                                            FROM DB_DATI_MACCHINA DM
                                                           WHERE     DM.ID_MACCHINA =
                                                                        M.ID_MACCHINA
                                                                 AND NVL (
                                                                        CML.ID_CATEGORIA,
                                                                        -1) =
                                                                        NVL (
                                                                           DM.ID_CATEGORIA,
                                                                           -1)
                                                          UNION
                                                          SELECT MAT.ID_GENERE_MACCHINA
                                                            FROM DB_MATRICE MAT
                                                           WHERE     MAT.ID_MATRICE =
                                                                        M.ID_MATRICE
                                                                 AND NVL (
                                                                        CML.ID_CATEGORIA,
                                                                        -1) =
                                                                        NVL (
                                                                           MAT.ID_CATEGORIA,
                                                                           -1))))
                     LOOP
                        nLitriBase :=
                             nLitriBase
                           + (  rec.SUP_COMPLES
                              * recLav.NUM_ESEC
                              * recLav.LITRI_BASE);
                        nLitriMedioImpasto :=
                             nLitriMedioImpasto
                           + (  rec.SUP_COMPLES
                              * recLav.NUM_ESEC
                              * recLav.LITRI_MEDIO_IMPASTO);
                        nLitriAcclivita :=
                             nLitriAcclivita
                           + (  nSupCollMont
                              * recLav.NUM_ESEC
                              * recLav.LITRI_TERRENI_DECLIVI);
                        bFoundLav := TRUE;
                     END LOOP;



                     IF bFoundLav
                     THEN
                        nPotMaxColt :=
                             nLitriBase
                           + nLitriMedioImpasto
                           + nLitriAcclivita
                           + rec.SUP_FRAMM;
                     ELSE
                        nPotMaxColt :=
                           nLitriBase + nLitriMedioImpasto + nLitriAcclivita;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        P_MSGERR :=
                              'ERRORE TOTALE CARBURANTE_COLTURA -2 interno2 '
                           || SQLERRM;
                        P_CODERR := SQLCODE;
                        RETURN FALSE;
                  END;

                  BEGIN
                     -- Calcolo carburante lavorazioni NON oltre la potenzialità caricate su ditta Uma
                     FOR recLavCp
                        IN (  SELECT LCP.ID_CATEGORIA_UTILIZZO_UMA,
                                     NVL (SUM (LCP.TOT_LITRI_LAVORAZIONE), 0)
                                        TOT_LIT_LAV
                                FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                                     DB_CATEG_COLTURA_LAVORAZIONI CCL
                               WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                            CCL.ID_CATEGORIA_UTILIZZO_UMA
                                     AND CCL.ID_CATEGORIA_UTILIZZO_UMA =
                                            rec.ID_CATEGORIA_UTILIZZO_UMA --EB
                                     AND LCP.ID_LAVORAZIONI =
                                            CCL.ID_LAVORAZIONI
                                     AND LCP.ID_DITTA_UMA = pIdDittaUma
                                     AND LCP.ANNO_CAMPAGNA =
                                            TO_NUMBER (
                                               TO_CHAR (pDataRif, 'YYYY'))
                                     AND LCP.DATA_FINE_VALIDITA IS NULL
                                     AND LCP.DATA_CESSAZIONE IS NULL
                                     AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                                     AND CCL.DATA_FINE_VALIDITA IS NULL
                                     AND CCL.INCREMENTO_OLTRE_POTENZIALITA =
                                            'N'
                                     AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                                     AND LCP.ID_MOTIVO_LAVORAZIONE =
                                            PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                               P_COD_MOTIVO_LAVORAZIONE)
                            GROUP BY LCP.ID_CATEGORIA_UTILIZZO_UMA)
                     LOOP
                        SELECT NVL (MIN (LCP.SUP_ORE), 0) * nFramm
                          INTO nSupOre
                          FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                               DB_CATEG_COLTURA_LAVORAZIONI CCL,
                               DB_UNITA_MISURA UM
                         WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                      recLavCp.ID_CATEGORIA_UTILIZZO_UMA
                               AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                      CCL.ID_CATEGORIA_UTILIZZO_UMA
                               AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                               AND LCP.ID_DITTA_UMA = pIdDittaUma
                               AND LCP.ANNO_CAMPAGNA =
                                      TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                               AND LCP.DATA_FINE_VALIDITA IS NULL
                               AND LCP.DATA_CESSAZIONE IS NULL
                               AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                               AND CCL.DATA_FINE_VALIDITA IS NULL
                               AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
                               AND CCL.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
                               AND UM.TIPO = 'S'
                               AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                               AND LCP.ID_MOTIVO_LAVORAZIONE =
                                      PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                         P_COD_MOTIVO_LAVORAZIONE);

                        nCarbLavNoPot := recLavCp.TOT_LIT_LAV + nSupOre;
                     END LOOP;

                     --nPotMax := nPotMax + LEAST (nPotMaxColt, nCarbLavNoPot);
                     nPotMax := nPotMax + nCarbLavNoPot;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        P_MSGERR :=
                              'ERRORE TOTALE CARBURANTE_COLTURA -2 interno 3 '
                           || SQLERRM;
                        P_CODERR := SQLCODE;
                        RETURN FALSE;
                  END;
               END LOOP;
            EXCEPTION
               WHEN OTHERS
               THEN
                  P_MSGERR :=
                        'ERRORE TOTALE CARBURANTE_COLTURA -2 interno 4 '
                     || SQLERRM;
                  P_CODERR := SQLCODE;
                  RETURN FALSE;
            END;


            BEGIN
               IF nContTrattice != 0
               THEN
                  nPotMaxTot := nPotMax;
               ELSE
                  nPotMaxTot := nPotMax;
/*
                  nPotMaxTot :=
                     LEAST (
                        nPotMax,
                        (  nCarburanteLavorazione
                         + nCarburanteMietitrebbiatura
                         + nCarburanteEssicazione));
*/
               END IF;

               -- Calcolo carburante lavorazioni oltre la potenzialità caricate su ditta Uma
               FOR recLavCpPot
                  IN (  SELECT LCP.ID_CATEGORIA_UTILIZZO_UMA,
                               NVL (SUM (LCP.TOT_LITRI_LAVORAZIONE), 0)
                                  TOT_LIT_LAV
                          FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                               DB_CATEG_COLTURA_LAVORAZIONI CCL
                         WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                      CCL.ID_CATEGORIA_UTILIZZO_UMA
                               AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                               AND LCP.ID_DITTA_UMA = pIdDittaUma
                               AND LCP.ANNO_CAMPAGNA =
                                      TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                               AND LCP.DATA_FINE_VALIDITA IS NULL
                               AND LCP.DATA_CESSAZIONE IS NULL
                               AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                               AND CCL.DATA_FINE_VALIDITA IS NULL
                               AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'S'
                               AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                               AND LCP.ID_MOTIVO_LAVORAZIONE =
                                      PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                         P_COD_MOTIVO_LAVORAZIONE)
                      GROUP BY LCP.ID_CATEGORIA_UTILIZZO_UMA)
               LOOP
                  SELECT COUNT (*)
                    INTO nContNonPot
                    FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                         DB_CATEG_COLTURA_LAVORAZIONI CCL
                   WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                recLavCpPot.ID_CATEGORIA_UTILIZZO_UMA
                         AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                CCL.ID_CATEGORIA_UTILIZZO_UMA
                         AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                         AND LCP.ID_DITTA_UMA = pIdDittaUma
                         AND LCP.ANNO_CAMPAGNA =
                                TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                         AND LCP.DATA_FINE_VALIDITA IS NULL
                         AND LCP.DATA_CESSAZIONE IS NULL
                         AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                         AND CCL.DATA_FINE_VALIDITA IS NULL
                         AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
                         AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                         AND LCP.ID_MOTIVO_LAVORAZIONE =
                                PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                   P_COD_MOTIVO_LAVORAZIONE);

                  IF nContNonPot = 0
                  THEN
                     SELECT NVL (MIN (LCP.SUP_ORE), 0) * nFramm
                       INTO nSupOre
                       FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                            DB_CATEG_COLTURA_LAVORAZIONI CCL,
                            DB_UNITA_MISURA UM
                      WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                   recLavCpPot.ID_CATEGORIA_UTILIZZO_UMA
                            AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                   CCL.ID_CATEGORIA_UTILIZZO_UMA
                            AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                            AND LCP.ID_DITTA_UMA = pIdDittaUma
                            AND LCP.ANNO_CAMPAGNA =
                                   TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                            AND LCP.DATA_FINE_VALIDITA IS NULL
                            AND LCP.DATA_CESSAZIONE IS NULL
                            AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                            AND CCL.DATA_FINE_VALIDITA IS NULL
                            AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'S'
                            AND CCL.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
                            AND UM.TIPO = 'S'
                            AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                            AND LCP.ID_MOTIVO_LAVORAZIONE =
                                   PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                      P_COD_MOTIVO_LAVORAZIONE);
                  ELSE
                     nSupOre := 0;
                  END IF;

                  nCarbLavPot :=
                     nCarbLavPot + recLavCpPot.TOT_LIT_LAV + nSupOre;
               END LOOP;

               P_CARBURANTE_LAVORAZIONE := CEIL (nPotMaxTot + nCarbLavPot);
            EXCEPTION
               WHEN OTHERS
               THEN
                  P_MSGERR :=
                        'ERRORE TOTALE CARBURANTE_COLTURA -2 interno 5 '
                     || SQLERRM;
                  P_CODERR := SQLCODE;
                  RETURN FALSE;
            END;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            P_MSGERR :=
               'ERRORE TOTALE CARBURANTE_COLTURA -2esterno ' || SQLERRM;
            P_CODERR := SQLCODE;
            RETURN FALSE;
      END;

      RETURN TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         P_CARBURANTE_LAVORAZIONE := NULL;
         P_CARBURANTE_MIETITREBBIATURA := NULL;
         P_CARBURANTE_ESSICAZIONE := NULL;
         RETURN TRUE;
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE TOTALE CARBURANTE_COLTURA: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN FALSE;
   END TOTALE_CARBURANTE_COLTURA;

   FUNCTION TOTALE_CARBURANTE_ALLEVAMENTO (
      P_ID_DOMANDA_ASSEGNAZIONE       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE             DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO            DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_CARBURANTE_ALLEVAMENTO    OUT NUMBER,
      P_MSGERR                    OUT VARCHAR2,
      P_CODERR                    OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT NVL (SUM (NVL (CARBURANTE_ALLEVAMENTO, 0)), 0)
        INTO P_CARBURANTE_ALLEVAMENTO
        FROM DB_CARBURANTE_ALLEVAMENTO
       WHERE     ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (NUMERO_SUPPLEMENTO, 0) = NVL (P_NUMERO_SUPPLEMENTO, 0);

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE TOTALE CARBURANTE_ALLEVAMENTO: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN FALSE;
   END TOTALE_CARBURANTE_ALLEVAMENTO;

   FUNCTION TOTALE_CARBURANTE_MACCHINA (
      P_ID_DOMANDA_ASSEGNAZIONE       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE             DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO            DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_CARBURANTE_ASSEGNATO      OUT NUMBER,
      P_MSGERR                    OUT VARCHAR2,
      P_CODERR                    OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT NVL (SUM (NVL (CARBURANTE_ASSEGNATO, 0)), 0)
        INTO P_CARBURANTE_ASSEGNATO
        FROM DB_CARBURANTE_MACCHINA
       WHERE     ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (NUMERO_SUPPLEMENTO, 0) = NVL (P_NUMERO_SUPPLEMENTO, 0);

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE TOTALE CARBURANTE_MACCHINA: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN FALSE;
   END TOTALE_CARBURANTE_MACCHINA;

   FUNCTION TOTALE_CARBURANTE_CONTOTERZI (
      pIdDittaUma            DB_DITTA_UMA.ID_DITTA_UMA%TYPE,
      pAnnoRiferimento       NUMBER,
      pCarburanteLavCT   OUT NUMBER,
      pAssegnatoPrecCT   OUT NUMBER,
      pRimanenzePrecCT   OUT NUMBER,
      pMsgErr            OUT VARCHAR2,
      pCodErr            OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      nCont                          SIMPLE_INTEGER := 0;
      bMaggiorazioneAcclivita        BOOLEAN := FALSE;
      nIdCategoriaColturaLavorazio   DB_CATEG_COLTURA_LAVORAZIONI.ID_CATEGORIA_COLTURA_LAVORAZIO%TYPE;
      nKw                            DB_MATRICE.POTENZA_KW%TYPE := 0;
      nCoefficiente                  NUMBER;
      recCategColturaLav             DB_CATEG_COLTURA_LAVORAZIONI%ROWTYPE;
      nMaxIdDomandaAssegnazione      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
   BEGIN
      pCarburanteLavCT := 0;
      pAssegnatoPrecCT := 0;
      pRimanenzePrecCT := 0;

      SELECT MAX (DA.ID_DOMANDA_ASSEGNAZIONE)
        INTO nMaxIdDomandaAssegnazione
        FROM DB_QUANTITA_ASSEGNATA QA,
             DB_ASSEGNAZIONE_CARBURANTE AC,
             DB_DOMANDA_ASSEGNAZIONE DA
       WHERE     AC.ID_ASSEGNAZIONE_CARBURANTE =
                    QA.ID_ASSEGNAZIONE_CARBURANTE
             AND AC.ANNULLATO IS NULL
             AND AC.ID_DOMANDA_ASSEGNAZIONE = DA.ID_DOMANDA_ASSEGNAZIONE
             AND DA.ID_DITTA_UMA = pIdDittaUma
             AND DA.ID_STATO_DOMANDA IN (30, 35)
             AND TO_NUMBER (TO_CHAR (DA.DATA_RIFERIMENTO, 'YYYY')) <
                    pAnnoRiferimento;

      SELECT NVL (SUM (NVL (QA.ASSEGNAZIONE_CONTO_TERZI, 0)), 0)
        INTO pAssegnatoPrecCT
        FROM DB_QUANTITA_ASSEGNATA QA,
             DB_ASSEGNAZIONE_CARBURANTE AC,
             DB_DOMANDA_ASSEGNAZIONE DA
       WHERE     AC.ID_ASSEGNAZIONE_CARBURANTE =
                    QA.ID_ASSEGNAZIONE_CARBURANTE
             AND AC.ANNULLATO IS NULL
             AND AC.ID_DOMANDA_ASSEGNAZIONE = DA.ID_DOMANDA_ASSEGNAZIONE
             AND DA.ID_DOMANDA_ASSEGNAZIONE = nMaxIdDomandaAssegnazione
             AND DA.ID_DITTA_UMA = pIdDittaUma
             AND DA.ID_STATO_DOMANDA IN (30, 35)
             AND TO_NUMBER (TO_CHAR (DA.DATA_RIFERIMENTO, 'YYYY')) <
                    pAnnoRiferimento;

      SELECT NVL (SUM (NVL (RIMANENZA_CONTO_TERZI, 0)), 0)
        INTO pRimanenzePrecCT
        FROM DB_CONSUMO_RIMANENZA
       WHERE ID_DOMANDA_ASSEGNAZIONE = nMaxIdDomandaAssegnazione;

      SELECT COUNT (*)
        INTO nCont
        FROM DB_DATI_DITTA DD
       WHERE     DD.ID_DITTA_UMA = pIdDittaUma
             AND DD.DATA_FINE_VALIDITA IS NULL
             AND DD.ID_CONDUZIONE = 1;

      IF nCont != 0
      THEN
         pCarburanteLavCT := 0;
      ELSE
         FOR rec
            IN (SELECT LC.EXT_ID_AZIENDA,
                       LC.ID_CATEGORIA_UTILIZZO_UMA,
                       LC.ID_LAVORAZIONI,
                       UM.TIPO,
                       LC.CONSUMO_DICHIARATO,
                       LC.CONSUMO_AMMISSIBILE,
                       LC.ID_MACCHINA,
                       LC.SUP_ORE,
                       LC.SUP_ORE_FATTURA,
                       LC.NUMERO_ESECUZIONI
                  FROM DB_LAVORAZIONE_CONTOTERZI LC,
                       DB_CAMPAGNA_CONTOTERZISTI CC,
                       DB_UNITA_MISURA UM
                 WHERE     CC.ID_CAMPAGNA_CONTOTERZISTI =
                              LC.ID_CAMPAGNA_CONTOTERZISTI
                       AND UM.ID_UNITA_MISURA = LC.ID_UNITA_MISURA
                       AND CC.ID_DITTA_UMA = pIdDittaUma
                       AND CC.ANNO_CAMPAGNA = (pAnnoRiferimento - 1)
                       AND LC.DATA_FINE_VALIDITA IS NULL
                       AND LC.DATA_CESSAZIONE IS NULL
                       AND CC.VERSO_LAVORAZIONI = 'E')
         LOOP
            bMaggiorazioneAcclivita := FALSE;

            SELECT COUNT (*)
              INTO nCont
              FROM DB_DATI_DITTA DD,
                   COMUNE C,
                   DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,
                   DB_ZONA_ALTIMETRICA ZA
             WHERE     DD.ID_DITTA_UMA =
                          (SELECT MAX (DU.ID_DITTA_UMA)
                             FROM DB_DITTA_UMA DU
                            WHERE DU.EXT_ID_AZIENDA = rec.EXT_ID_AZIENDA)
                   AND DD.EXT_COMUNE_PRINCIPALE_ATTIVITA = C.ISTAT_COMUNE
                   AND ZAUG.EXT_ID_ZONA_ALTIMETRICA = C.ZONAALT
                   AND DD.DATA_FINE_VALIDITA IS NULL
                   AND ZAUG.DATA_FINE_VALIDITA IS NULL
                   AND ZA.ID_ZONA_ALTIMETRICA = ZAUG.ID_ZONA_ALTIMETRICA
                   AND ZA.CODICE = 'M';

            IF nCont != 0
            THEN
               bMaggiorazioneAcclivita := TRUE;
            END IF;

            SELECT MAX (CCL.ID_CATEGORIA_COLTURA_LAVORAZIO)
              INTO nIdCategoriaColturaLavorazio
              FROM DB_CATEG_COLTURA_LAVORAZIONI CCL
             WHERE     CCL.ID_CATEGORIA_UTILIZZO_UMA =
                          rec.ID_CATEGORIA_UTILIZZO_UMA
                   AND CCL.ID_LAVORAZIONI = rec.ID_LAVORAZIONI
                   AND TO_NUMBER (TO_CHAR (CCL.DATA_INIZIO_VALIDITA, 'YYYY')) <=
                          pAnnoRiferimento
                   AND (   CCL.DATA_FINE_VALIDITA IS NULL
                        OR TO_NUMBER (
                              TO_CHAR (CCL.DATA_FINE_VALIDITA, 'YYYY')) >=
                              pAnnoRiferimento)
                   AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 1;

            IF nIdCategoriaColturaLavorazio IS NULL
            THEN
               SELECT MAX (CCL.ID_CATEGORIA_COLTURA_LAVORAZIO)
                 INTO nIdCategoriaColturaLavorazio
                 FROM DB_CATEG_COLTURA_LAVORAZIONI CCL
                WHERE (CCL.ID_CATEGORIA_UTILIZZO_UMA, CCL.ID_LAVORAZIONI) =
                         (SELECT ID_CATEGORIA_UTILIZZO_UMA, ID_LAVORAZIONI
                            FROM DB_R_COLTURA_LAVORAZ_ORIGINE
                           WHERE     ID_CATEGORIA_UTIL_UMA_ORIGINE =
                                        rec.ID_CATEGORIA_UTILIZZO_UMA
                                 AND ID_LAVORAZIONI_ORIGINE =
                                        rec.ID_LAVORAZIONI
                                 AND ANNO_RIFERIMENTO = pAnnoRiferimento
                                 AND DATA_FINE_VALIDITA IS NULL);
            END IF;

            IF nIdCategoriaColturaLavorazio IS NULL
            THEN
               pCarburanteLavCT :=
                    pCarburanteLavCT
                  + CEIL (
                       LEAST (rec.CONSUMO_DICHIARATO,
                              rec.CONSUMO_AMMISSIBILE));
            ELSE
               SELECT *
                 INTO recCategColturaLav
                 FROM DB_CATEG_COLTURA_LAVORAZIONI
                WHERE ID_CATEGORIA_COLTURA_LAVORAZIO =
                         nIdCategoriaColturaLavorazio;

/*
               IF rec.TIPO = 'T'
               THEN
                  BEGIN
                     SELECT MA.POTENZA_KW
                       INTO nKw
                       FROM DB_MACCHINA M, DB_MATRICE MA
                      WHERE     M.ID_MACCHINA = rec.ID_MACCHINA
                            AND MA.ID_MATRICE = M.ID_MATRICE;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        SELECT DM.POTENZA
                          INTO nKw
                          FROM DB_DATI_MACCHINA DM, DB_MACCHINA M
                         WHERE     DM.ID_MACCHINA = rec.ID_MACCHINA
                               AND DM.ID_MACCHINA = M.ID_MACCHINA
                               AND M.ID_MATRICE IS NULL;
                  END;

                  SELECT TO_NUMBER (VALORE)
                    INTO nCoefficiente
                    FROM DB_TIPO_PARAMETRO
                   WHERE     COD_PARAMETRO = 'UMKW'
                         AND TO_NUMBER (
                                TO_CHAR (DATA_INIZIO_VALIDITA, 'YYYY')) <=
                                pAnnoRiferimento
                         AND (   DATA_FINE_VALIDITA IS NULL
                              OR TO_NUMBER (
                                    TO_CHAR (DATA_FINE_VALIDITA, 'YYYY')) >=
                                    pAnnoRiferimento);

                  pCarburanteLavCT :=
                       pCarburanteLavCT
                     + CEIL (
                          (  LEAST (rec.SUP_ORE, rec.SUP_ORE_FATTURA)
                           * nKw
                           * nCoefficiente));
               END IF;
*/

               IF rec.TIPO IN ('P', 'K')
               THEN
                  pCarburanteLavCT :=
                       pCarburanteLavCT
                     + CEIL (
                          (  LEAST (rec.SUP_ORE, rec.SUP_ORE_FATTURA)
                           * recCategColturaLav.LITRI_BASE));
               END IF;

               IF rec.TIPO = 'S'
               THEN
                  IF bMaggiorazioneAcclivita
                  THEN
                     pCarburanteLavCT :=
                          pCarburanteLavCT
                        + CEIL (
                               (  (    (  recCategColturaLav.LITRI_BASE
                                        + recCategColturaLav.LITRI_MEDIO_IMPASTO)
                                     * rec.NUMERO_ESECUZIONI
                                   + recCategColturaLav.LITRI_MAGGIORAZIONE_CONTO3)
                                * LEAST (rec.SUP_ORE, rec.SUP_ORE_FATTURA))
                             + (  recCategColturaLav.LITRI_TERRENI_DECLIVI
                                * LEAST (rec.SUP_ORE, rec.SUP_ORE_FATTURA)));
                  ELSE
                     pCarburanteLavCT :=
                          pCarburanteLavCT
                        + CEIL (
                             (  (    (  recCategColturaLav.LITRI_BASE
                                      + recCategColturaLav.LITRI_MEDIO_IMPASTO)
                                   * rec.NUMERO_ESECUZIONI
                                 + recCategColturaLav.LITRI_MAGGIORAZIONE_CONTO3)
                              * LEAST (rec.SUP_ORE, rec.SUP_ORE_FATTURA)));
                  END IF;
               END IF;
            END IF;
         END LOOP;
      END IF;

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         pMsgErr :=
               'ERRORE TOTALE_CARBURANTE_CONTOTERZI: '
            || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
         pCodErr := SQLCODE;
         RETURN FALSE;
   END TOTALE_CARBURANTE_CONTOTERZI;

   /*********************************************************************
   Dati in input :
    - l'id_domanda_assegnazione
    - il parametro data massima di consegna della documentazione per domanda di assegnazione
    - il parametro data limite per l'applicazione della riduzione sul carbuarante
    - la data di ricezione del documento di assegnazione presa da DB_DATI_DITTA
   mi ricavo la data di riferimento per ricerca la riduzione su DB_TIPO_RIDUZIONE
   Tipo: function
   input: pIdDomandaAssegnazione, pDtMaxConsegnaDoc, pDtLimRidCarb, pDtRicDocAssegnaz
   output: pAnnoRif
   ritorno: DATE
   *********************************************************************/
   FUNCTION IMPOSTA_DATA_RIF_RIDUZIONE (
      pIdDomandaAssegnazione   IN     DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      pDtMaxConsegnaDoc        IN     DATE,
      pDtLimRidCarb            IN     DATE,
      pDtRicDocAssegnaz        IN     DATE,
      pAnnoRif                    OUT NUMBER)
      RETURN DATE
   IS
      -- conterrà la data di riferimento della domanda passata in input o della
      -- corrispettiva domanda di acconto
      dDataRiferimento   DATE;
      -- variabile che conterrà la ditta uma della domanda di assegnazione
      nIdDittaUma        DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE;
   BEGIN
      -- seleziono data riferimento, data validazione ed anno riferimento
      -- della domanda passata in input
      SELECT ID_DITTA_UMA,
             DATA_RIFERIMENTO,
             TO_CHAR (DATA_RIFERIMENTO, 'YYYY')
        INTO nIdDittaUma, dDataRiferimento, pAnnoRif
        FROM DB_DOMANDA_ASSEGNAZIONE
       WHERE ID_DOMANDA_ASSEGNAZIONE = pIdDomandaAssegnazione;

      -- seleziono la data riferimento dell'eventuale domanda di acconto
      BEGIN
         SELECT DATA_RIFERIMENTO
           INTO dDataRiferimento
           FROM DB_DOMANDA_ASSEGNAZIONE
          WHERE     ID_DITTA_UMA = nIdDittaUma
                AND TIPO_DOMANDA = kvIdTipoDomandaAcconto
                AND ID_STATO_DOMANDA = knIdStatoDomandaValidita
                AND TO_CHAR (DATA_RIFERIMENTO, 'YYYY') = pAnnoRif
                AND DATA_RIFERIMENTO <= dDataRiferimento;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL; -- se non trovo la domanda di acconto pazienza uso la data di riferimento della domanda passata in input
      END;

      -- se la data DATA_RICEZ_DOCUM_ASSEGNAZ è valorizzata
      IF pDtRicDocAssegnaz IS NOT NULL
      THEN
         -- se è dell'anno di sysdate
         IF TO_CHAR (pDtRicDocAssegnaz, 'YYYY') = TO_CHAR (SYSDATE, 'YYYY')
         THEN
            -- se la data di riferimento è compresa tra la data
            -- massima in cui si può dichiarare la ricezione della documentazione per assegnazioni
            -- e la data limite oltre la quale viene applicata la riduzione carburante
            -- in base alla domanda di assegnazione
            IF     dDataRiferimento > pDtMaxConsegnaDoc
               AND dDataRiferimento <= pDtLimRidCarb
            THEN
               dDataRiferimento :=
                  TO_DATE ('30/06/' || TO_CHAR (SYSDATE, 'YYYY'),
                           'DD/MM/YYYY');
            END IF;
         END IF;
      END IF;

      RETURN dDataRiferimento;
   END IMPOSTA_DATA_RIF_RIDUZIONE;

   /*********************************************************************
   Effettua il calcolo delle rimanenze di carburante per le lavorazioni
   non effettuate per le aziende di tipo consorzio / cooperativa
   Tipo: procedure
   input: pIdDittaUma --> Identificativo della ditta uma in elaborazione
    pIdAzienda --> Identificativo dell'azienda in elaborazione
    pAnnoRif --> anno campagna per il quale si vogliono calcolare le rimanenze
   output: pRimLavBenzina --> Totale rimanenza di benzina per lavorazioni non effettuate
    pRimLavGasolio --> Totale rimanenza di gasolio per lavorazioni non effettuate
    pMsgErr --> Eventuale messaggio di errore avvenuto durante il calcolo
    pCodErr --> Codice del messaggio di errore
   ritorno: nessuno
   *********************************************************************/
   PROCEDURE CalcolaRimanenzaLavConsorzi (
      pIdDittaUma      IN     DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
      pIdAzienda       IN     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
      pAnnoRif         IN     DB_CAMPAGNA_CONTOTERZISTI.ANNO_CAMPAGNA%TYPE,
      pRimLavBenzina      OUT NUMBER,
      pRimLavGasolio      OUT NUMBER,
      pMsgErr             OUT VARCHAR2,
      pCodErr             OUT VARCHAR2)
   IS
      dDtAvvCalcRimCarbLav   DATE;
      ERRORE_GESTITO         EXCEPTION;

      vValore                DB_TIPO_PARAMETRO.VALORE%TYPE;
   BEGIN
      -- recupero la data dalla quale si deve effettuare questo calcolo
      BEGIN
         dDtAvvCalcRimCarbLav :=
            TO_DATE (SelectValoreParametro (kvCodParDtAvvioCalcRimanPerLav),
                     'DD/MM/YYYY');
      EXCEPTION
         WHEN OTHERS
         THEN
            pCodErr := SQLCODE;
            pMsgErr :=
               'Parametro data avvio calcolo rimanenze carburante per lavorazioni non effettuate non trovato od in formato erroneo (<> DD/MM/YYYY) !!';
            RAISE ERRORE_GESTITO;
      END;

      SELECT VALORE
        INTO vValore
        FROM DB_TIPO_PARAMETRO
       WHERE COD_PARAMETRO = 'UMDE' AND DATA_FINE_VALIDITA IS NULL;

      IF SYSDATE >= dDtAvvCalcRimCarbLav AND vValore = 'S'
      THEN
         SELECT NVL (SUM (decu_gas), 0), NVL (SUM (decu_benz), 0)
           INTO pRimLavGasolio, pRimLavBenzina
           FROM (WITH VERE_MACCHINE
                      AS (SELECT MAC.ID_MACCHINA,
                                 DM.ID_CATEGORIA,
                                 DM.ID_GENERE_MACCHINA
                            FROM DB_DATI_MACCHINA DM,
                                 DB_MACCHINA MAC,
                                 DB_UTILIZZO U
                           WHERE     MAC.ID_MACCHINA = DM.ID_MACCHINA
                                 AND MAC.ID_MATRICE IS NULL
                                 AND MAC.ID_MACCHINA = U.ID_MACCHINA
                                 AND U.ID_DITTA_UMA = pIdDittaUma
                          UNION
                          SELECT MAC.ID_MACCHINA,
                                 MAT.ID_CATEGORIA,
                                 MAT.ID_GENERE_MACCHINA
                            FROM DB_MACCHINA MAC,
                                 DB_MATRICE MAT,
                                 DB_UTILIZZO U
                           WHERE     MAC.ID_MATRICE = MAT.ID_MATRICE
                                 AND MAC.ID_MATRICE IS NOT NULL
                                 AND MAC.ID_MACCHINA = U.ID_MACCHINA
                                 AND U.ID_DITTA_UMA = pIdDittaUma)
                 SELECT CASE
                           WHEN TRUNC (
                                   DECODE (
                                      NVL (LC.GASOLIO, 0),
                                      0, 0,
                                        LC.GASOLIO
                                      - (NVL (
                                              CCL.LITRI_MAGGIORAZIONE_CONTO3
                                            * LC.SUP_ORE,
                                            0)))) < 0
                           THEN
                              0
                           ELSE
                              TRUNC (
                                 DECODE (
                                    NVL (LC.GASOLIO, 0),
                                    0, 0,
                                      LC.GASOLIO
                                    - (NVL (
                                            CCL.LITRI_MAGGIORAZIONE_CONTO3
                                          * LC.SUP_ORE,
                                          0))))
                        END
                           decu_gas,
                        CASE
                           WHEN TRUNC (
                                   DECODE (
                                      NVL (LC.BENZINA, 0),
                                      0, 0,
                                        LC.BENZINA
                                      - (NVL (
                                              CCL.LITRI_MAGGIORAZIONE_CONTO3
                                            * LC.SUP_ORE,
                                            0)))) < 0
                           THEN
                              0
                           ELSE
                              TRUNC (
                                 DECODE (
                                    NVL (LC.BENZINA, 0),
                                    0, 0,
                                      LC.BENZINA
                                    - (NVL (
                                            CCL.LITRI_MAGGIORAZIONE_CONTO3
                                          * LC.SUP_ORE,
                                          0))))
                        END
                           decu_benz
                   FROM DB_LAVORAZIONE_CONSORZI LC,
                        DB_CATEG_COLTURA_LAVORAZIONI CCL
                  WHERE     LC.ANNO_CAMPAGNA = pAnnoRif - 2
                        AND LC.EXT_ID_AZIENDA = pIdAzienda
                        AND LC.DATA_CESSAZIONE IS NULL
                        AND LC.DATA_FINE_VALIDITA IS NULL
                        AND LC.ID_CATEGORIA_UTILIZZO_UMA =
                               CCL.ID_CATEGORIA_UTILIZZO_UMA
                        AND LC.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                        AND CCL.LAVORAZIONE_STRAORDINARIA = 'N'
                        AND ID_TIPO_COLTURA_LAVORAZIONE = 1 
                        AND CCL.ID_CATEGORIA_COLTURA_LAVORAZIO =
                               (SELECT MAX (
                                          CCL2.ID_CATEGORIA_COLTURA_LAVORAZIO)
                                  FROM DB_CATEG_COLTURA_LAVORAZIONI ccl2
                                 WHERE     CCL2.ID_CATEGORIA_UTILIZZO_UMA =
                                              CCL.ID_CATEGORIA_UTILIZZO_UMA
                                       AND CCL2.ID_LAVORAZIONI =
                                              CCL.ID_LAVORAZIONI
                                       AND CCL2.ID_UNITA_MISURA =
                                              CCL.ID_UNITA_MISURA
                                       AND ID_TIPO_COLTURA_LAVORAZIONE = 1 
                                       AND TO_CHAR (
                                              CCL2.DATA_INIZIO_VALIDITA,
                                              'YYYY') <= LC.ANNO_CAMPAGNA
                                       AND NVL (
                                              TO_CHAR (
                                                 CCL2.DATA_FINE_VALIDITA,
                                                 'YYYY'),
                                              LC.ANNO_CAMPAGNA) >=
                                              LC.ANNO_CAMPAGNA)
                        AND EXISTS
                               (SELECT U.ID_MACCHINA
                                  FROM DB_UTILIZZO U,
                                       VERE_MACCHINE VM,
                                       DB_CATEG_MACCHINE_LAVORAZIONI CML
                                 WHERE     CML.ID_LAVORAZIONI =
                                              LC.ID_LAVORAZIONI
                                       AND CML.ID_CATEGORIA_UTILIZZO_UMA =
                                              LC.ID_CATEGORIA_UTILIZZO_UMA
                                       AND NVL (VM.ID_CATEGORIA, -1) =
                                              NVL (CML.ID_CATEGORIA, -1)
                                       AND VM.ID_GENERE_MACCHINA =
                                              CML.ID_GENERE_MACCHINA
                                       AND U.ID_DITTA_UMA = pIdDittaUma
                                       AND TO_CHAR (U.DATA_CARICO, 'YYYY') <=
                                              LC.ANNO_CAMPAGNA
                                       AND NVL (
                                              TO_CHAR (U.DATA_SCARICO,
                                                       'YYYY'),
                                              LC.ANNO_CAMPAGNA) >=
                                              LC.ANNO_CAMPAGNA
                                       AND U.ID_MACCHINA = VM.ID_MACCHINA
                                       AND CML.ID_CATEG_MACCHINA_LAVORAZIONI =
                                              (SELECT MAX (
                                                         CML2.ID_CATEG_MACCHINA_LAVORAZIONI)
                                                 FROM DB_CATEG_MACCHINE_LAVORAZIONI cml2
                                                WHERE     CML2.ID_CATEGORIA_UTILIZZO_UMA =
                                                             CML.ID_CATEGORIA_UTILIZZO_UMA
                                                      AND CML2.ID_LAVORAZIONI =
                                                             CML.ID_LAVORAZIONI
                                                      AND CML2.ID_GENERE_MACCHINA =
                                                             CML.ID_GENERE_MACCHINA
                                                      AND NVL (
                                                             CML2.ID_CATEGORIA,
                                                             -999) =
                                                             NVL (
                                                                CML.ID_CATEGORIA,
                                                                -999)
                                                      AND CML2.ID_CARBURANTE =
                                                             CML.ID_CARBURANTE
                                                      AND TO_CHAR (
                                                             CML2.DATA_INIZIO_VALIDITA,
                                                             'YYYY') <=
                                                             LC.ANNO_CAMPAGNA
                                                      AND NVL (
                                                             TO_CHAR (
                                                                CML2.DATA_FINE_VALIDITA,
                                                                'YYYY'),
                                                             LC.ANNO_CAMPAGNA) >=
                                                             LC.ANNO_CAMPAGNA)));
      ELSE
         pRimLavBenzina := 0;
         pRimLavGasolio := 0;
      END IF;
   EXCEPTION
      WHEN ERRORE_GESTITO
      THEN
         NULL;
      WHEN OTHERS
      THEN
         pMsgErr := 'ERRORE CalcolaRimanenzaLavConsorzi : ' || SQLERRM;
         pCodErr := SQLCODE;
   END CalcolaRimanenzaLavConsorzi;

   /*********************************************************************
   Effettua il calcolo delle rimanenze di carburante per le lavorazioni
   non effettuate (solamente conto proprio e conto proprio/terzi)
   Tipo: procedure
   input: pIdDittaUma --> Identificativo della ditta uma in elaborazione
    pIdAzienda --> Identificativo dell'azienda in elaborazione
    pAnnoRif --> anno campagna per il quale si vogliono calcolare le rimanenze
   output: pRimLavBenzina --> Totale rimanenza di benzina per lavorazioni non effettuate
    pRimLavGasolio --> Totale rimanenza di gasolio per lavorazioni non effettuate
    pMsgErr --> Eventuale messaggio di errore avvenuto durante il calcolo
    pCodErr --> Codice del messaggio di errore
   ritorno: nessuno
   *********************************************************************/
   PROCEDURE CalcolaRimanenzaLavorazioni (
      pIdDittaUma      IN     DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
      pIdAzienda       IN     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
      pAnnoRif         IN     DB_CAMPAGNA_CONTOTERZISTI.ANNO_CAMPAGNA%TYPE,
      pRimLavBenzina      OUT NUMBER,
      pRimLavGasolio      OUT NUMBER,
      pMsgErr             OUT VARCHAR2,
      pCodErr             OUT VARCHAR2)
   IS
      dDtAvvCalcRimCarbLav   DATE;
      ERRORE_GESTITO         EXCEPTION;
      vValore                DB_TIPO_PARAMETRO.VALORE%TYPE;
   BEGIN
      pCodErr := '';
      pMsgErr := '';

      -- recupero la data dalla quale si deve effettuare questo calcolo
      BEGIN
         dDtAvvCalcRimCarbLav :=
            TO_DATE (SelectValoreParametro (kvCodParDtAvvioCalcRimanPerLav),
                     'DD/MM/YYYY');
      EXCEPTION
         WHEN OTHERS
         THEN
            pCodErr := SQLCODE;
            pMsgErr :=
               'Parametro data avvio calcolo rimanenze carburante per lavorazioni non effettuate non trovato od in formato erroneo (<> DD/MM/YYYY) !!';
            RAISE ERRORE_GESTITO;
      END;

      SELECT VALORE
        INTO vValore
        FROM DB_TIPO_PARAMETRO
       WHERE COD_PARAMETRO = 'UMDE' AND DATA_FINE_VALIDITA IS NULL;

      IF SYSDATE >= dDtAvvCalcRimCarbLav AND vValore = 'S'
      THEN
         SELECT NVL (SUM (DECU_GAS), 0), NVL (SUM (DECU_BENZ), 0)
           INTO pRimLavGasolio, pRimLavBenzina
           FROM (WITH VERE_MACCHINE
                      AS (SELECT MAC.ID_MACCHINA,
                                 DM.ID_CATEGORIA,
                                 DM.ID_GENERE_MACCHINA
                            FROM DB_DATI_MACCHINA DM,
                                 DB_MACCHINA MAC,
                                 DB_UTILIZZO U
                           WHERE     MAC.ID_MACCHINA = DM.ID_MACCHINA
                                 AND MAC.ID_MATRICE IS NULL
                                 AND MAC.ID_MACCHINA = U.ID_MACCHINA
                                 AND U.ID_DITTA_UMA = pIdDittaUma
                          UNION
                          SELECT MAC.ID_MACCHINA,
                                 MAT.ID_CATEGORIA,
                                 MAT.ID_GENERE_MACCHINA
                            FROM DB_MACCHINA MAC,
                                 DB_MATRICE MAT,
                                 DB_UTILIZZO U
                           WHERE     MAC.ID_MATRICE = MAT.ID_MATRICE
                                 AND MAC.ID_MATRICE IS NOT NULL
                                 AND MAC.ID_MACCHINA = U.ID_MACCHINA
                                 AND U.ID_DITTA_UMA = pIdDittaUma)
                 SELECT CASE
                           WHEN TRUNC (
                                   DECODE (
                                      NVL (
                                         LEAST (LC.CONSUMO_AMMISSIBILE,
                                                LC.CONSUMO_DICHIARATO),
                                         0),
                                      0, 0,
                                        LEAST (LC.CONSUMO_AMMISSIBILE,
                                               LC.CONSUMO_DICHIARATO)
                                      - (NVL (
                                              CCL.LITRI_MAGGIORAZIONE_CONTO3
                                            * LC.SUP_ORE,
                                            0)))) < 0
                           THEN
                              0
                           ELSE
                              TRUNC (
                                 DECODE (
                                    NVL (
                                       LEAST (LC.CONSUMO_AMMISSIBILE,
                                              LC.CONSUMO_DICHIARATO),
                                       0),
                                    0, 0,
                                      LEAST (LC.CONSUMO_AMMISSIBILE,
                                             LC.CONSUMO_DICHIARATO)
                                    - (NVL (
                                            CCL.LITRI_MAGGIORAZIONE_CONTO3
                                          * LC.SUP_ORE,
                                          0))))
                        END
                           DECU_GAS,
                        CASE
                           WHEN TRUNC (
                                   DECODE (
                                      NVL (LC.BENZINA, 0),
                                      0, 0,
                                        LC.BENZINA
                                      - (NVL (
                                              CCL.LITRI_MAGGIORAZIONE_CONTO3
                                            * LC.SUP_ORE,
                                            0)))) < 0
                           THEN
                              0
                           ELSE
                              TRUNC (
                                 DECODE (
                                    NVL (LC.BENZINA, 0),
                                    0, 0,
                                      LC.BENZINA
                                    - (NVL (
                                            CCL.LITRI_MAGGIORAZIONE_CONTO3
                                          * LC.SUP_ORE,
                                          0))))
                        END
                           DECU_BENZ
                   FROM DB_CAMPAGNA_CONTOTERZISTI CC,
                        DB_LAVORAZIONE_CONTOTERZI LC,
                        DB_CATEG_COLTURA_LAVORAZIONI CCL
                  WHERE     CC.ANNO_CAMPAGNA = pAnnoRif
                        AND CC.VERSO_LAVORAZIONI = kvCodLavorazioneEffettuata
                        AND CC.ID_CAMPAGNA_CONTOTERZISTI =
                               LC.ID_CAMPAGNA_CONTOTERZISTI
                        AND LC.EXT_ID_AZIENDA = pIdAzienda
                        AND LC.DATA_CESSAZIONE IS NULL
                        AND LC.DATA_FINE_VALIDITA IS NULL
                        AND LC.ID_CATEGORIA_UTILIZZO_UMA =
                               CCL.ID_CATEGORIA_UTILIZZO_UMA
                        AND LC.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                        AND CCL.LAVORAZIONE_STRAORDINARIA = 'N' 
                        AND ID_TIPO_COLTURA_LAVORAZIONE = 1 
                        AND CCL.ID_CATEGORIA_COLTURA_LAVORAZIO =
                               (SELECT MAX (
                                          CCL2.ID_CATEGORIA_COLTURA_LAVORAZIO)
                                  FROM DB_CATEG_COLTURA_LAVORAZIONI CCL2
                                 WHERE     CCL2.ID_CATEGORIA_UTILIZZO_UMA =
                                              CCL.ID_CATEGORIA_UTILIZZO_UMA
                                       AND CCL2.ID_LAVORAZIONI =
                                              CCL.ID_LAVORAZIONI
                                       AND CCL2.ID_UNITA_MISURA =
                                              CCL.ID_UNITA_MISURA
                                       AND ID_TIPO_COLTURA_LAVORAZIONE = 1 
                                       AND TO_CHAR (
                                              CCL2.DATA_INIZIO_VALIDITA,
                                              'YYYY') <= CC.ANNO_CAMPAGNA
                                       AND NVL (
                                              TO_CHAR (
                                                 CCL2.DATA_FINE_VALIDITA,
                                                 'YYYY'),
                                              CC.ANNO_CAMPAGNA) >=
                                              CC.ANNO_CAMPAGNA)
                        AND EXISTS
                               (SELECT U.ID_MACCHINA
                                  FROM DB_UTILIZZO U,
                                       VERE_MACCHINE VM,
                                       DB_CATEG_MACCHINE_LAVORAZIONI CML
                                 WHERE     CML.ID_LAVORAZIONI =
                                              LC.ID_LAVORAZIONI
                                       AND CML.ID_CATEGORIA_UTILIZZO_UMA =
                                              LC.ID_CATEGORIA_UTILIZZO_UMA
                                       AND CML.ID_CATEG_MACCHINA_LAVORAZIONI =
                                              (SELECT MAX (
                                                         CML2.ID_CATEG_MACCHINA_LAVORAZIONI)
                                                 FROM DB_CATEG_MACCHINE_LAVORAZIONI cml2
                                                WHERE     CML2.ID_CATEGORIA_UTILIZZO_UMA =
                                                             CML.ID_CATEGORIA_UTILIZZO_UMA
                                                      AND CML2.ID_LAVORAZIONI =
                                                             CML.ID_LAVORAZIONI
                                                      AND CML2.ID_GENERE_MACCHINA =
                                                             CML.ID_GENERE_MACCHINA
                                                      AND NVL (
                                                             CML2.ID_CATEGORIA,
                                                             -999) =
                                                             NVL (
                                                                CML.ID_CATEGORIA,
                                                                -999)
                                                      AND CML2.ID_CARBURANTE =
                                                             CML.ID_CARBURANTE
                                                      AND TO_CHAR (
                                                             CML2.DATA_INIZIO_VALIDITA,
                                                             'YYYY') <=
                                                             CC.ANNO_CAMPAGNA
                                                      AND NVL (
                                                             TO_CHAR (
                                                                CML2.DATA_FINE_VALIDITA,
                                                                'YYYY'),
                                                             CC.ANNO_CAMPAGNA) >=
                                                             CC.ANNO_CAMPAGNA)
                                       AND NVL (VM.ID_CATEGORIA, -1) =
                                              NVL (CML.ID_CATEGORIA, -1)
                                       AND VM.ID_GENERE_MACCHINA =
                                              CML.ID_GENERE_MACCHINA
                                       AND U.ID_DITTA_UMA = pIdDittaUma
                                       AND TO_CHAR (U.DATA_CARICO, 'YYYY') <=
                                              CC.ANNO_CAMPAGNA
                                       AND NVL (
                                              TO_CHAR (U.DATA_SCARICO,
                                                       'YYYY'),
                                              CC.ANNO_CAMPAGNA) >=
                                              CC.ANNO_CAMPAGNA
                                       AND U.ID_MACCHINA = VM.ID_MACCHINA));
      ELSE
         pRimLavBenzina := 0;
         pRimLavGasolio := 0;
      END IF;
   EXCEPTION
      WHEN ERRORE_GESTITO
      THEN
         NULL;
      WHEN OTHERS
      THEN
         pMsgErr := 'ERRORE CalcolaRimanenzaLavorazioni : ' || SQLERRM;
         pCodErr := SQLCODE;
   END CalcolaRimanenzaLavorazioni;

   /*********************************************************************
   Data una ditta uma ed una data di riferimento conta il numero
   di macchine abilitate ad effettuare lavorazioni del tipo
   dato in input
   Tipo: function
   input : pIdDittaUma --> Identificativo della ditta uma in elaborazione
    pDataRif --> data di riferimento della domanda di assegnazione
    pTipoLav --> tipo lavorazione per il quale contare le macchine
   ritorno: nNumMacchine
   *********************************************************************/
   FUNCTION CountMacchinePerLavTipo (
      pIdDittaUma   IN DB_UTILIZZO.ID_DITTA_UMA%TYPE,
      pDataRif      IN DATE,
      pTipoLav      IN DB_TIPO_LAVORAZIONI.TIPO_LAVORAZIONE%TYPE)
      RETURN INTEGER
   IS
      nNumMacchine   INTEGER := 0;
   BEGIN
      SELECT COUNT (*)
        INTO nNumMacchine
        FROM (SELECT MA.ID_MACCHINA
                FROM DB_UTILIZZO U,
                     DB_MACCHINA MA,
                     DB_MATRICE MT,
                     DB_TIPO_LAVORAZIONI TL,
                     DB_CATEG_MACCHINE_LAVORAZIONI CML
               WHERE     U.ID_DITTA_UMA = pIdDittaUma
                     AND U.DATA_CARICO <= pDataRif
                     AND NVL (U.DATA_SCARICO, pDataRif) >= pDataRif
                     AND U.ID_MACCHINA = MA.ID_MACCHINA
                     AND MA.ID_MATRICE IS NOT NULL
                     AND MA.ID_MATRICE = MT.ID_MATRICE
                     AND MT.ID_GENERE_MACCHINA = CML.ID_GENERE_MACCHINA
                     AND CML.ID_LAVORAZIONI = TL.ID_LAVORAZIONI
                     AND CML.DATA_INIZIO_VALIDITA <= pDataRif
                     AND NVL (CML.DATA_FINE_VALIDITA, pDataRif) >= pDataRif
                     AND TL.TIPO_LAVORAZIONE = pTipoLav
                     AND NVL (MT.ID_CATEGORIA, -1) =
                            NVL (CML.ID_CATEGORIA, -1)
              UNION
              SELECT MA.ID_MACCHINA
                FROM DB_UTILIZZO U,
                     DB_MACCHINA MA,
                     DB_DATI_MACCHINA DM,
                     DB_TIPO_LAVORAZIONI TL,
                     DB_CATEG_MACCHINE_LAVORAZIONI CML
               WHERE     U.ID_DITTA_UMA = pIdDittaUma
                     AND U.DATA_CARICO <= pDataRif
                     AND NVL (U.DATA_SCARICO, pDataRif) >= pDataRif
                     AND U.ID_MACCHINA = MA.ID_MACCHINA
                     AND MA.ID_MATRICE IS NULL
                     AND MA.ID_MACCHINA = DM.ID_MACCHINA
                     AND DM.ID_GENERE_MACCHINA = CML.ID_GENERE_MACCHINA
                     AND CML.ID_LAVORAZIONI = TL.ID_LAVORAZIONI
                     AND CML.DATA_INIZIO_VALIDITA <= pDataRif
                     AND NVL (CML.DATA_FINE_VALIDITA, pDataRif) >= pDataRif
                     AND TL.TIPO_LAVORAZIONE = pTipoLav
                     AND NVL (DM.ID_CATEGORIA, -1) =
                            NVL (CML.ID_CATEGORIA, -1));

      RETURN nNumMacchine;
   END CountMacchinePerLavTipo;

   /*********************************************************************
   Calcola la somma della superficie agronomica e la somma
   della superficie condotta per le altre aziende diverse da quella
   della domanda di assegnazione in elaborazione che sussistono
   sulle stesse particelle in asservimento all'azienda in elaborazione
   (utilizza l'id_dichiarazione consistenza della domanda di assegnazione
    per l'azienda in elaborazione e quella con MAX(DATA) per le altre aziende)
   Tipo: procedure
   input: pIdDichConsistenza --> Identificativo della ditta uma in elaborazione
    pIdAzienda --> Identificativo dell'azienda in elaborazione
   output: pSumSupAgro --> Eventuale messaggio di errore avvenuto durante il calcolo
    pSumSupCond --> Codice del messaggio di errore
   ritorno: nessuno
   *********************************************************************/
   PROCEDURE CalcolaSuperficiAltAziende (
      pIdDichConsistenza   IN     DB_DICHIARAZIONE_CONSISTENZA.ID_DICHIARAZIONE_CONSISTENZA%TYPE,
      pIdAzienda           IN     DB_DICHIARAZIONE_CONSISTENZA.ID_AZIENDA%TYPE,
      pSumSupAgro             OUT DB_CONDUZIONE_DICHIARATA.SUPERFICIE_AGRONOMICA%TYPE,
      pSumSupCond             OUT DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE)
   IS
   BEGIN
      WITH PARTICELLE_ASSERVIMENTO
           AS (SELECT CD.ID_PARTICELLA
                 FROM DB_DICHIARAZIONE_CONSISTENZA DC,
                      DB_CONDUZIONE_DICHIARATA CD
                WHERE     DC.ID_DICHIARAZIONE_CONSISTENZA =
                             pIdDichConsistenza
                      AND DC.CODICE_FOTOGRAFIA_TERRENI =
                             CD.CODICE_FOTOGRAFIA_TERRENI
                      AND CD.ID_TITOLO_POSSESSO =
                             knIdTitoloPossessoAsservimento)
      SELECT /*+rule*/
            SUM (
                CASE
                   WHEN CON.ID_TITOLO_POSSESSO !=
                           knIdTitoloPossessoAsservimento 
                   THEN
                      CON.SUPERFICIE_AGRONOMICA
                   ELSE
                      0
                END)
                AS SUM_SUP_AGRONOMICA,
             SUM (
                CASE CON.ID_TITOLO_POSSESSO
                   WHEN knIdTitoloPossessoAsservimento
                   THEN
                      CON.SUPERFICIE_CONDOTTA
                   ELSE
                      0
                END)
                AS SUM_SUP_CONDOTTA
        INTO pSumSupAgro, pSumSupCond
        FROM DB_DICHIARAZIONE_CONSISTENZA DIC,
             DB_CONDUZIONE_DICHIARATA CON,
             PARTICELLE_ASSERVIMENTO PA
       WHERE     CON.ID_PARTICELLA = PA.ID_PARTICELLA
             /*AND CON.ID_TITOLO_POSSESSO IN (knIdTitoloPossessoProprieta,
             knIdTitoloPossessoAffitto,
             knIdTitoloPossessoMezzadria,
             knIdTitoloPossessoAltreForme,
             knIdTitoloPossessoAsservimento
             )*/
             AND CON.CODICE_FOTOGRAFIA_TERRENI =
                    DIC.CODICE_FOTOGRAFIA_TERRENI
             AND DIC.ID_AZIENDA <> pIdAzienda
             AND DIC.DATA =
                    (SELECT MAX (DC.DATA)
                       FROM DB_DICHIARAZIONE_CONSISTENZA DC
                      WHERE     DC.ID_AZIENDA = DIC.ID_AZIENDA
                            AND NOT EXISTS
                                       (SELECT MEP.ID_MOTIVO_ESCLUSO_PROCEDIMENTO
                                          FROM DB_MOTIVO_ESCLUSO_PROCEDIMENTO MEP
                                         WHERE     DC.ID_MOTIVO_DICHIARAZIONE =
                                                      MEP.ID_MOTIVO_DICHIARAZIONE
                                               AND MEP.ID_PROCEDIMENTO =
                                                      knIdProcedimentoUma));
   END CalcolaSuperficiAltAziende;

   /*********************************************************************
   Effettua il calcolo del carburante assegnabile per la superficie in
   asservimento dell'azienda in elaborazione legato alla dichiarazione
   di consistenza presente nella domanda di assegnazione
   Tipo: procedure
   input: pIdDittaUma --> Identificativo della ditta uma in elaborazione
    pIdAzienda --> Identificativo dell'azienda in elaborazione
    pDataRif --> data di riferimento della domanda di assegnazione
    pIdConsistenza --> dichiarazione di consistenza della domanda
    pSumSupAsserv --> Somma della superficie condotta in asservimento per la domanda
   output: pCarbAsserv --> Carburante assegnabile per la superficie in asservimento
    pMsgErr --> Eventuale messaggio di errore avvenuto durante il calcolo
    pCodErr --> Codice del messaggio di errore
   ritorno: nessuno
   *********************************************************************/
   PROCEDURE CalcolaCarburanteAsservimento (
      pIdDittaUma     IN     DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
      pIdAzienda      IN     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
      pDataRif        IN     DATE,
      pIdConsitenza   IN     DB_DOMANDA_ASSEGNAZIONE.EXT_ID_CONSISTENZA%TYPE,
      pSumSupAsserv   IN     DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE,
      pCarbAsserv        OUT NUMBER,
      pMsgErr            OUT VARCHAR2,
      pCodErr            OUT VARCHAR2)
   IS
      LITRI_KO                    EXCEPTION;
      nSumSupAgroAltreAzienda     DB_CONDUZIONE_DICHIARATA.SUPERFICIE_AGRONOMICA%TYPE;
      nSumSupAsservAltreAzienda   DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE;
      nTotSuperficie              DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE;
      nLitriCarbXEttaro           INTEGER := 0;
   BEGIN
      -- ricerco il parametro contenente il numero di litri assegnabile x ettaro
      BEGIN
         nLitriCarbXEttaro :=
            SelectValoreParametro (kvCodParametroLitriCarbXEttaro);
      EXCEPTION
         WHEN OTHERS
         THEN
            pCodErr := SQLCODE;
            pMsgErr :=
               'Parametro litri carburanete per ettaro non trovato od in formato erroneo !!!';
            RAISE LITRI_KO;
      END;

      -- se questo valore è maggiore di zero
      IF nLitriCarbXEttaro > 0
      THEN
         -- controllo se per la ditta uma ci sono macchine abilitate
         -- a lavorazioni di tipo = 'S' alla attive alla data riferimento
         -- della domanda di assegnazione
         IF CountMacchinePerLavTipo (pIdDittaUma, pDataRif, 'S') > 0
         THEN
            -- se esistono delle macchine con queste caratteristiche
            -- calcolo la somma della superficie agronomica
            -- per conduzioni diverse da asservimento e conferimento
            -- presenti sull'ultima dichiarazione di consistenza di
            -- aziende diverse da quella in elaborazione contando
            -- però solamente le particelle che sono anche in asservimento
            -- sull'azienda attuale.Inoltre calcolo anche la somma
            -- delle eventuali particelle che sono in asservimento
            -- anche su altre aziende oltre a quella attuale
            CalcolaSuperficiAltAziende (pIdConsitenza,
                                        pIdAzienda,
                                        nSumSupAgroAltreAzienda,
                                        nSumSupAsservAltreAzienda);
            -- il totale della superficie a cui moltiplicherò il parametro
            -- dei litri di carburante per ettaro è quindi dato da :
            -- superficie in asservimento azienda attuale -
            -- (superficie agronomica altre azienda + supercie in asservimento altre aziende)
            nTotSuperficie :=
                 pSumSupAsserv
               - (  NVL (nSumSupAgroAltreAzienda, 0)
                  + NVL (nSumSupAsservAltreAzienda, 0));

            -- se questa superficie è maggiore di zero
            IF nTotSuperficie > 0
            THEN
               -- ricavo il carburante dovuto
               pCarbAsserv := nTotSuperficie * nLitriCarbXEttaro;
            ELSE
               -- altrimenti assegno zero
               pCarbAsserv := 0;
            END IF;
         ELSE
            -- se non ce ne sono il carburante asservimento è zero
            pCarbAsserv := 0;
         END IF;
      ELSE
         -- se il parametro litri di carburante x ettaro è a zero
         pCarbAsserv := 0;
      END IF;
   EXCEPTION
      WHEN LITRI_KO
      THEN
         NULL;
      WHEN OTHERS
      THEN
         pCarbAsserv := 0;
         pMsgErr := 'ERRORE CalcolaCarburanteAsservimento : ' || SQLERRM;
         pCodErr := SQLCODE;
   END CalcolaCarburanteAsservimento;


   FUNCTION ASSEGNAZIONE_SUCCESSIVA (
      P_ID_DOMANDA_ASSEGNAZIONE   IN     DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_QUANT_MAX_CONTO_PROPRIO   IN     NUMBER,
      P_DT_MAX_CONSEGNADOC        IN     DATE,
      P_DT_LIM_RID_CARB           IN     DATE,
      P_DT_RIC_DOC_ASSEGNAZ       IN     DATE,
      P_ASSEGNAZIONE_SUCCESS         OUT NUMBER,
      P_PERCENTUALE                  OUT NUMBER,
      P_DATA_RIF                     OUT DB_DOMANDA_ASSEGNAZIONE.DATA_RIFERIMENTO%TYPE,
      P_MSGERR                       OUT VARCHAR2,
      P_CODERR                       OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      -- conterrà l'anno di riferimento della domanda passata in input
      nAnnoRiferimento   NUMBER (4);
      -- conterrà la data di riferimento della domanda passata in input o della
      -- corrispettiva domanda di acconto
      dDataRiferimento   DATE;
   BEGIN
      -- mi ricavo la data e l'anno di riferimento x i quali cercare la percentuale
      -- di riduzione
      dDataRiferimento :=
         IMPOSTA_DATA_RIF_RIDUZIONE (P_ID_DOMANDA_ASSEGNAZIONE,
                                     P_DT_MAX_CONSEGNADOC,
                                     P_DT_LIM_RID_CARB,
                                     P_DT_RIC_DOC_ASSEGNAZ,
                                     nAnnoRiferimento);

      -- cerco se su DB_TIPO_RIDUZIONE
      -- esistono riduzione con decorrenza inferiore a quella
      -- della data di riferimento e se si mi prendo l'ultima
      BEGIN
         SELECT DATA_DECORRENZA, PERCENTUALE_RIDUZIONE
           INTO P_DATA_RIF, P_PERCENTUALE
           FROM DB_TIPO_RIDUZIONE
          WHERE DATA_DECORRENZA =
                   (SELECT MAX (DATA_DECORRENZA)
                      FROM DB_TIPO_RIDUZIONE
                     WHERE     TO_CHAR (DATA_DECORRENZA, 'YYYY') =
                                  nAnnoRiferimento
                           AND DATA_DECORRENZA <= dDataRiferimento);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            P_ASSEGNAZIONE_SUCCESS := NULL;
            P_PERCENTUALE := NULL;
            P_DATA_RIF := NULL;
            RETURN (TRUE);
         WHEN OTHERS
         THEN
            P_MSGERR :=
                  'ERRORE REPERIMENTO PERCENTUALE SU DB_TIPO_RIDUZIONE: '
               || SQLERRM;
            P_CODERR := SQLCODE;
            RETURN (FALSE);
      END;

      -- applico la riduzione al quantitativo di carburante assegnato
      P_ASSEGNAZIONE_SUCCESS :=
           P_QUANT_MAX_CONTO_PROPRIO
         - (P_QUANT_MAX_CONTO_PROPRIO * P_PERCENTUALE / 100);

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE TOTALE CARBURANTE_MACCHINA: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN (FALSE);
   END ASSEGNAZIONE_SUCCESSIVA;

   FUNCTION TOTALE_CARBURANTE_SERRA (
      P_ID_DOMANDA_ASSEGNAZIONE        DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE              DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO             DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_CARBURANTE_RISCALDAMENTO   OUT NUMBER,
      P_MSGERR                     OUT VARCHAR2,
      P_CODERR                     OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT NVL (SUM (NVL (CARBURANTE_RISCALDAMENTO, 0)), 0)
        INTO P_CARBURANTE_RISCALDAMENTO
        FROM DB_CARBURANTE_SERRA
       WHERE     ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (NUMERO_SUPPLEMENTO, 0) = NVL (P_NUMERO_SUPPLEMENTO, 0);

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE TOTALE CARBURANTE_SERRA: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN FALSE;
   END TOTALE_CARBURANTE_SERRA;

   FUNCTION RICERCA_MAO_V_D (
      P_ID_DOMANDA_ASSEGNAZIONE   IN     DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_CONTA_MAO_V_D                OUT NUMBER,
      P_MSGERR                       OUT VARCHAR2,
      P_CODERR                       OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      P_CONTA_MAO_V_D := 0;
      /*
       select count(*)
       INTO P_CONTA_MAO_V_D
       from db_domanda_assegnazione dom, db_utilizzo uti, db_macchina mac,
       db_matrice mat, db_tipo_genere_macchina gen
       where dom.id_domanda_assegnazione = P_ID_DOMANDA_ASSEGNAZIONE
       and dom.id_ditta_uma = uti.id_ditta_uma
       and uti.data_carico <= dom.data_riferimento
       and (uti.data_scarico > dom.data_riferimento or uti.data_scarico is null)
       and uti.id_macchina = mac.id_macchina
       and mac.id_matrice = mat.id_matrice
       and mat.id_genere_macchina = gen.id_genere_macchina
       and gen.codifica_breve in ('D', 'MAO', 'V');
      */
      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE RICERCA_MAO_V_D: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN (FALSE);
   END RICERCA_MAO_V_D;

   FUNCTION RICERCA_ASM (
      P_ID_DOMANDA_ASSEGNAZIONE   IN     DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_CONTA_ASM                    OUT NUMBER,
      P_MSGERR                       OUT VARCHAR2,
      P_CODERR                       OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT COUNT (*)
        INTO P_CONTA_ASM
        FROM db_domanda_assegnazione dom,
             db_utilizzo uti,
             db_dati_macchina mac,
             db_tipo_genere_macchina gen,
             db_tipo_categoria cat
       WHERE     dom.id_domanda_assegnazione = P_ID_DOMANDA_ASSEGNAZIONE
             AND dom.id_ditta_uma = uti.id_ditta_uma
             AND uti.data_carico <= dom.data_riferimento
             AND (   uti.data_scarico > dom.data_riferimento
                  OR uti.data_scarico IS NULL)
             AND uti.id_macchina = mac.id_macchina
             AND mac.id_categoria = cat.id_categoria
             AND cat.id_genere_macchina = gen.id_genere_macchina
             AND gen.codifica_breve = 'ASM'
             -- ER MOD inizio
             AND cat.categoria NOT IN ('004', '005', '006');

      -- ER MOD fine

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE RICERCA_ASM: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN (FALSE);
   END RICERCA_ASM;

   FUNCTION REPERISCI_ANNO_RIFERIMENTO (
      P_ID_DOMANDA_ASSEGNAZIONE   IN     DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_ANNO_RIFERIMENTO             OUT NUMBER,
      P_ID_DITTA_UMA                 OUT DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
      P_ID_AZIENDA                   OUT DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE,
      P_ID_CONSISTENZA               OUT DB_DOMANDA_ASSEGNAZIONE.EXT_ID_CONSISTENZA%TYPE,
      P_DATA_RIF                     OUT DATE,
      P_MSGERR                       OUT VARCHAR2,
      P_CODERR                       OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT TO_NUMBER (TO_CHAR (DA.DATA_RIFERIMENTO, 'YYYY')),
             DA.ID_DITTA_UMA,
             DU.EXT_ID_AZIENDA,
             DA.EXT_ID_CONSISTENZA,
             DA.DATA_RIFERIMENTO
        INTO P_ANNO_RIFERIMENTO,
             P_ID_DITTA_UMA,
             P_ID_AZIENDA,
             P_ID_CONSISTENZA,
             P_DATA_RIF
        FROM DB_DOMANDA_ASSEGNAZIONE DA, DB_DITTA_UMA DU
       WHERE     DA.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND DA.ID_DITTA_UMA = DU.ID_DITTA_UMA;

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE REPERISCI_ANNO_RIFERIMENTO: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN (FALSE);
   END REPERISCI_ANNO_RIFERIMENTO;

   FUNCTION CONTROLLA_DITTA_FORZATA (
      P_ID_DITTA_UMA       IN     DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
      P_ANNO_RIFERIMENTO   IN     NUMBER,
      P_COUNT_DITTA_FORZ      OUT NUMBER,
      P_MSGERR                OUT VARCHAR2,
      P_CODERR                OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT COUNT (*)
        INTO P_COUNT_DITTA_FORZ
        FROM DITTA_FORZATA
       WHERE     ID_DITTA_UMA = P_ID_DITTA_UMA
             AND ANNO_RIFERIMENTO = P_ANNO_RIFERIMENTO;

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE CONTROLLA_DITTA_FORZATA: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN (FALSE);
   END CONTROLLA_DITTA_FORZATA;

   /*********************************************************************
   Effettua il calcolo del quantitativo massimo di carburante assegnabile
   per conto proprio
   viene richiamata dal package PCK_CALCOLO_BONUS
   Tipo: procedure
   input: P_ID_DOMANDA_ASSEGNAZIONE --> Identificativo domanda assegnazione base in elaborazione
   output: P_CARBURANTE_LAVORAZIONE --> SUM(CARBURANTE_LAVORAZIONE) della tabella DB_CARBURANTE_COLTURA
    P_CARBURANTE_ALLEVAMENTO --> SUM(CARBURANTE_ALLEVAMENTO) della tabella DB_CARBURANTE_ALLEVAMENTO
    P_SOMMA_A_B --> Somma di P_CARBURANTE_LAVORAZIONE + P_CARBURANTE_ALLEVAMENTO
    P_CARBURANTE_ASSEGNATO --> SUM(CARBURANTE_ASSEGNATO) della tabella DB_CARBURANTE_MACCHINA
    P_QUANTITATIVO_MASSIMO --> Minore tra P_SOMMA_A_B e P_CARBURANTE_ASSEGNATO
    P_CARBURANTE_MIETITREBB --> SUM(CARBURANTE_MIETITREBBIATURA) della tabella DB_CARBURANTE_COLTURA
    P_CARBURANTE_ESSICAZIONE --> SUM(CARBURANTE_ESSICAZIONE) della tabella DB_CARBURANTE_COLTURA
    P_QUANT_MAX_CONTO_PROPRIO --> Somma di (P_QUANTITATIVO_MASSIMO + P_CARBURANTE_MIETITREBB + P_CARBURANTE_ESSICAZIONE) meno somma di (P_RIMANENZA_LAV_BENZINA + P_RIMANENZA_LAV_GASOLIO)
    P_ASSEGNAZIONE_SUCCESS --> P_QUANT_MAX_CONTO_PROPRIO - (P_QUANT_MAX_CONTO_PROPRIO * P_PERCENTUALE / 100)
    P_DATA_RIF --> Data di decorrenza per la presentazione della domanda nell'anno campagna
    P_PERCENTUALE --> Percentuale di riduzione relativa alla data di decorrenza
    P_TOTALE_CONTO_PROPRIO --> Arrotondamento di P_QUANT_MAX_CONTO_PROPRIO o P_ASSEGNAZIONE_SUCCESS ai 10 litri superiori
    P_CARBURANTE_RISCALDAMENTO --> SUM(CARBURANTE_RISCALDAMENTO) della tabella DB_CARBURANTE_SERRA
    P_TOTALE_SERRA --> Arrotondamento di P_CARBURANTE_RISCALDAMENTO ai 10 litri superiori
    P_ALTRE_MACCHINE --> 1 se la ditta è presente su DITTA_FORZATA per ID_DITTA_UMA ed ANNO_RIFERIMENTO
    P_RIMANENZA_LAV_BENZINA --> Totale rimanenza di benzina per lavorazioni non effettuate (valorizzato solo per ditte conto proprio e conto proprio terzi)
    P_RIMANENZA_LAV_GASOLIO --> Totale rimanenza di gasolio per lavorazioni non effettuate (valorizzato solo per ditte conto proprio e conto proprio terzi)
    P_MSGERR --> Eventuale messaggio di errore avvenuto durante il calcolo
    P_CODERR --> Codice del messaggio di errore
    P_CARBURANTE_ASSERVIMENTO --> Carburante assegnabile per la superficie in asservimento dell'azienda relativa
    alla dichiarazione di consistenza della domanda assegnazione in elaborazione
   ritorno: nessuno
   *********************************************************************/
   PROCEDURE CALCOLO_ASSEGNAZIONE_CARB (
      P_ID_DOMANDA_ASSEGNAZIONE       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE             DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO            DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_ID_UTENTE                     DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
      P_MSGERR                    OUT VARCHAR2,
      P_CODERR                    OUT VARCHAR2)
   IS
      SCARTO                         EXCEPTION;
      nComodo                        NUMBER;
      nContaAsm                      NUMBER (3);
      nContaMaoVD                    NUMBER (3);
      nAnnoRiferimento               NUMBER (4);
      nIdDittaUma                    NUMBER (10);
      nIdAzienda                     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE;
      nIdConsistenza                 DB_DOMANDA_ASSEGNAZIONE.EXT_ID_CONSISTENZA%TYPE;
      nCountDittaForz                NUMBER (3);
      recTDatiDitta                  DB_DATI_DITTA%ROWTYPE;
      dDataRif                       DATE;
      dDtMaxConsegnaDoc              DATE;
      dDtLimRidCarb                  DATE;
      nSumSupAsservimento            DB_CONDUZIONE_DICHIARATA.SUPERFICIE_CONDOTTA%TYPE;
      nRimanenzaBenzinaLav           NUMBER;
      nRimanenzaBenzinaLavCons       NUMBER;
      nRimanenzaGasolioLav           NUMBER;
      nRimanenzaGasolioLavCons       NUMBER;
      nQuantitaPrelevata             NUMBER;
      vAnno                          VARCHAR2 (4);
      nMaxAssegnabileContoProprio    NUMBER;
      nDecurtazione                  NUMBER;
      nAssegnazioneContoTerzi        NUMBER;
      nAssegnazioneContoProprioSup   NUMBER;
      nAnnoUmlc                      NUMBER;
      nCarburanteLavorazione         NUMBER;
      nCarburanteAllevamento         NUMBER := 0;
      nSommaAB                       NUMBER;
      nCarburanteAssegnato           NUMBER;
      nQuantitativoMassimo           NUMBER;
      nCarburanteMietitrebb          NUMBER;
      nCarburanteEssicazione         NUMBER;
      nQuantMaxContoProprio          NUMBER;
      nAssegnazioneSuccess           NUMBER;
      dDataDecorrenza                DB_DOMANDA_ASSEGNAZIONE.DATA_RIFERIMENTO%TYPE;
      nPercentuale                   NUMBER;
      nTotaleContoProprio            NUMBER;
      nCarburanteRiscaldamento       NUMBER;
      nTotaleSerra                   NUMBER;
      nAltreMacchine                 NUMBER;
      nRimanenzaLavBenzina           NUMBER;
      nRimanenzaLavGasolio           NUMBER;
      nCarburanteAsservimento        NUMBER;
      vAltreMacchineDittaForzata     DB_DETTAGLIO_CALCOLO.ALTRE_MACCHINE_DITTA_FORZATA%TYPE;
      nCarburanteLavCtDaCp           DB_DETTAGLIO_CALCOLO.CARBURANTE_LAV_CT_DA_CP%TYPE;
      nCarburanteContoTerziLav       NUMBER;
      nAssegnatoPrecContoTerzi       NUMBER;
      nMaxContoTerzi                 NUMBER;
      nTotaleContoTerzi              NUMBER;
      nRimanenzePrecCT               NUMBER;
   BEGIN
          
      SELECT TO_NUMBER (VALORE)
        INTO nAnnoUmlc
        FROM DB_PARAMETRO
       WHERE ID_PARAMETRO = 'UMLC';

      -- spostato reperimento dell'anno di riferimento in testa
      IF NOT REPERISCI_ANNO_RIFERIMENTO (P_ID_DOMANDA_ASSEGNAZIONE,
                                         nAnnoRiferimento,
                                         nIdDittaUma,
                                         nIdAzienda,
                                         nIdConsistenza,
                                         dDataRif,
                                         P_MSGERR,
                                         P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      -- mi serve per capire se il consorzio / cooperativa è
      -- una ditta forzata se si non lo considero come tale
      -- e faccio la gestione del carbuarante come azienda normale
      IF NOT CONTROLLA_DITTA_FORZATA (nIdDittaUma,
                                      nAnnoRiferimento,
                                      nCountDittaForz,
                                      P_MSGERR,
                                      P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      -- mi cerco su DB_DATI_DITTA la data della ricevuta del documento
      -- di assegnazione
      recTDatiDitta :=
         SelectTDatiDittaByIdDomAssegn (P_ID_DOMANDA_ASSEGNAZIONE);

      -- se l'azienda è un consorzio il calcolo del quantitativo massimo assegnabile
      -- per conto proprio è molto semplice
      IF IsAziendaConsorzio (nIdAzienda) AND nCountDittaForz = 0
      THEN
         -- basta sommare il gasolio e la benzia presenti per la ditta uma
         -- su DB_LAVORAZIONE_CONSORZI per l'anno precedente a quello della domanda
         SELECT NVL (SUM (GASOLIO), 0) + NVL (SUM (BENZINA), 0)
           INTO nCarburanteLavorazione
           FROM DB_LAVORAZIONE_CONSORZI
          WHERE     ID_DITTA_UMA = nIdDittaUma
                AND ANNO_CAMPAGNA = nAnnoRiferimento -- lavoro sull'anno della domanda e non su quello precedente
                AND DATA_FINE_VALIDITA IS NULL
                AND DATA_CESSAZIONE IS NULL;

         IF recTDatiDitta.ID_CONDUZIONE IN
               (knIdContoProprio, knIdContoProprioTerzi)
         THEN
            CalcolaRimanenzaLavorazioni (nIdDittaUma,
                                         nIdAzienda,
                                         (nAnnoRiferimento - 2),
                                         nRimanenzaLavBenzina,
                                         nRimanenzaLavGasolio,
                                         P_MSGERR,
                                         P_CODERR);

            -- se il codice errore è valorizzato interrompo l'elaborazione
            IF P_CODERR IS NOT NULL
            THEN
               RAISE SCARTO;
            END IF;
         ELSE
            nRimanenzaLavBenzina := 0;
            nRimanenzaLavGasolio := 0;
         END IF;

         nCarburanteMietitrebb := 0;
         nCarburanteEssicazione := 0;
         nCarburanteLavCtDaCp := 0;
      ELSE
         IF NOT TOTALE_CARBURANTE_COLTURA (P_ID_DOMANDA_ASSEGNAZIONE,
                                           nAnnoUmlc,
                                           nIdDittaUma,
                                           dDataRif,
                                           P_TIPO_ASSEGNAZIONE,
                                           P_NUMERO_SUPPLEMENTO,
                                           'N',
                                           'LB',
                                           nCarburanteLavorazione,
                                           nCarburanteMietitrebb,
                                           nCarburanteEssicazione,
                                           P_MSGERR,
                                           P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         SELECT NVL (SUM (decu_gas), 0) + NVL (SUM (decu_benz), 0)
           INTO nCarburanteLavCtDaCp
           FROM (SELECT CASE
                           WHEN TRUNC (
                                   DECODE (
                                      NVL (LC.CONSUMO_DICHIARATO, 0),
                                      0, 0,
                                        LC.CONSUMO_DICHIARATO
                                      - (NVL (
                                              CCL.LITRI_MAGGIORAZIONE_CONTO3
                                            * LC.SUP_ORE,
                                            0)))) < 0
                           THEN
                              0
                           ELSE
                              TRUNC (
                                 DECODE (
                                    NVL (LC.CONSUMO_DICHIARATO, 0),
                                    0, 0,
                                      LC.CONSUMO_DICHIARATO
                                    - (NVL (
                                            CCL.LITRI_MAGGIORAZIONE_CONTO3
                                          * LC.SUP_ORE,
                                          0))))
                        END
                           decu_gas,
                        CASE
                           WHEN TRUNC (
                                   DECODE (
                                      NVL (LC.BENZINA, 0),
                                      0, 0,
                                        LC.BENZINA
                                      - (NVL (
                                              CCL.LITRI_MAGGIORAZIONE_CONTO3
                                            * LC.SUP_ORE,
                                            0)))) < 0
                           THEN
                              0
                           ELSE
                              TRUNC (
                                 DECODE (
                                    NVL (LC.BENZINA, 0),
                                    0, 0,
                                      LC.BENZINA
                                    - (NVL (
                                            CCL.LITRI_MAGGIORAZIONE_CONTO3
                                          * LC.SUP_ORE,
                                          0))))
                        END
                           decu_benz
                   FROM DB_CAMPAGNA_CONTOTERZISTI CC,
                        DB_LAVORAZIONE_CONTOTERZI LC,
                        DB_CATEG_COLTURA_LAVORAZIONI CCL
                  WHERE     CC.ANNO_CAMPAGNA = nAnnoRiferimento
                        AND CC.VERSO_LAVORAZIONI = 'S'
                        AND CC.ID_CAMPAGNA_CONTOTERZISTI =
                               LC.ID_CAMPAGNA_CONTOTERZISTI
                        AND CC.ID_DITTA_UMA = nIdDittaUma
                        AND LC.DATA_CESSAZIONE IS NULL
                        AND LC.DATA_FINE_VALIDITA IS NULL
                        AND LC.ID_CATEGORIA_UTILIZZO_UMA =
                               CCL.ID_CATEGORIA_UTILIZZO_UMA
                        AND LC.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                        AND CCL.LAVORAZIONE_STRAORDINARIA = 'N'
                        AND ID_TIPO_COLTURA_LAVORAZIONE = 1
                        AND CCL.ID_CATEGORIA_COLTURA_LAVORAZIO =
                               (SELECT MAX (
                                          CCL2.ID_CATEGORIA_COLTURA_LAVORAZIO)
                                  FROM DB_CATEG_COLTURA_LAVORAZIONI ccl2
                                 WHERE     CCL2.ID_CATEGORIA_UTILIZZO_UMA =
                                              CCL.ID_CATEGORIA_UTILIZZO_UMA
                                       AND CCL2.ID_LAVORAZIONI =
                                              CCL.ID_LAVORAZIONI
                                       AND CCL2.ID_UNITA_MISURA =
                                              CCL.ID_UNITA_MISURA
                                       AND ID_TIPO_COLTURA_LAVORAZIONE = 1
                                       AND TO_CHAR (
                                              CCL2.DATA_INIZIO_VALIDITA,
                                              'YYYY') <= CC.ANNO_CAMPAGNA
                                       AND NVL (
                                              TO_CHAR (
                                                 CCL2.DATA_FINE_VALIDITA,
                                                 'YYYY'),
                                              CC.ANNO_CAMPAGNA) >=
                                              CC.ANNO_CAMPAGNA)
                        AND EXISTS
                               (SELECT 'X'
                                  FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                                       DB_CATEG_COLTURA_LAVORAZIONI CCL3
                                 WHERE     LCP.ID_DITTA_UMA = CC.ID_DITTA_UMA
                                       AND LCP.ANNO_CAMPAGNA =
                                              CC.ANNO_CAMPAGNA
                                       AND LCP.ID_ASSEGNAZIONE_CARBURANTE
                                              IS NULL
                                       AND LCP.ID_MOTIVO_LAVORAZIONE =
                                              PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                                 'LB')
                                       AND CCL3.ID_CATEGORIA_UTILIZZO_UMA =
                                              LCP.ID_CATEGORIA_UTILIZZO_UMA
                                       AND CCL3.ID_LAVORAZIONI =
                                              LCP.ID_LAVORAZIONI
                                       AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                              LC.ID_CATEGORIA_UTILIZZO_UMA
                                       AND LCP.ID_LAVORAZIONI =
                                              LC.ID_LAVORAZIONI
                                       AND CCL3.ID_TIPO_COLTURA_LAVORAZIONE =
                                              2
                                       AND LCP.DATA_FINE_VALIDITA IS NULL
                                       AND LCP.DATA_CESSAZIONE IS NULL
                                       AND CCL3.DATA_FINE_VALIDITA IS NULL));

         -- Calcolo rimanenze per lavorazioni a benzina e gasolio non effettuate
         IF recTDatiDitta.ID_CONDUZIONE IN
               (knIdContoProprio, knIdContoProprioTerzi)
         THEN
            -- solamente se la ditta è conto proprio o contoproprio terzi
            CalcolaRimanenzaLavorazioni (nIdDittaUma,
                                         nIdAzienda,
                                         (nAnnoRiferimento - 2),
                                         nRimanenzaBenzinaLav,
                                         nRimanenzaGasolioLav,
                                         P_MSGERR,
                                         P_CODERR);

            -- se il codice errore è valorizzato interrompo l'elaborazione
            IF P_CODERR IS NOT NULL
            THEN
               RAISE SCARTO;
            END IF;

            -- calcolo delle rimanenze per lavorazioni a benzina e gasolio non effettuate
            CalcolaRimanenzaLavConsorzi (nIdDittaUma,
                                         nIdAzienda,
                                         nAnnoRiferimento,
                                         nRimanenzaBenzinaLavCons,
                                         nRimanenzaGasolioLavCons,
                                         P_MSGERR,
                                         P_CODERR);

            -- se il codice errore è valorizzato interrompo l'elaborazione
            IF P_CODERR IS NOT NULL
            THEN
               RAISE SCARTO;
            END IF;

            nRimanenzaLavBenzina :=
               nRimanenzaBenzinaLav + nRimanenzaBenzinaLavCons;
            nRimanenzaLavGasolio :=
               nRimanenzaGasolioLav + nRimanenzaGasolioLavCons;
         ELSE
            nRimanenzaLavBenzina := 0;
            nRimanenzaLavGasolio := 0;
         END IF;
      END IF;

      IF NOT TOTALE_CARBURANTE_ALLEVAMENTO (P_ID_DOMANDA_ASSEGNAZIONE,
                                            P_TIPO_ASSEGNAZIONE,
                                            P_NUMERO_SUPPLEMENTO,
                                            nCarburanteAllevamento,
                                            P_MSGERR,
                                            P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      IF TO_NUMBER (TO_CHAR (dDataRif, 'YYYY')) < nAnnoUmlc
      THEN
         -- se il carburanete lavorazione è maggiore di zero
         -- calcolo il carburante asservimento
         IF NVL (nCarburanteLavorazione, 0) > 0
         THEN
            nSumSupAsservimento :=
               SelTSupCondByIdDichEIdTitPos (nIdConsistenza,
                                             knIdTitoloPossessoAsservimento);

            IF nSumSupAsservimento > 0
            THEN
               -- calcolo se ha diritto a del carburante per questa superficie
               CalcolaCarburanteAsservimento (nIdDittaUma,
                                              nIdAzienda,
                                              dDataRif,
                                              nIdConsistenza,
                                              nSumSupAsservimento,
                                              nCarburanteAsservimento,
                                              P_MSGERR,
                                              P_CODERR);

               -- se il codice errore è valorizzato interrompo l'elaborazione
               IF P_CODERR IS NOT NULL
               THEN
                  RAISE SCARTO;
               END IF;
            ELSE
               nCarburanteAsservimento := 0;
            END IF;
         ELSE
            -- altrimenti è zero di default
            nCarburanteAsservimento := 0;
         END IF;
      ELSE
         nCarburanteAsservimento := 0;
      END IF;

      -- aggiunta somma Carburante in asservimento
      nSommaAB :=
           NVL (nCarburanteLavorazione, 0)
         + NVL (nCarburanteAllevamento, 0)
         + nCarburanteAsservimento;

      IF NOT TOTALE_CARBURANTE_MACCHINA (P_ID_DOMANDA_ASSEGNAZIONE,
                                         P_TIPO_ASSEGNAZIONE,
                                         P_NUMERO_SUPPLEMENTO,
                                         nCarburanteAssegnato,
                                         P_MSGERR,
                                         P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      IF TO_NUMBER (TO_CHAR (dDataRif, 'YYYY')) < nAnnoUmlc
      THEN
         IF nSommaAB < NVL (nCarburanteAssegnato, 0)
         THEN
            nQuantitativoMassimo := nSommaAB;
         ELSE
            nQuantitativoMassimo := nCarburanteAssegnato;
         END IF;

         nQuantMaxContoProprio :=
              NVL (nQuantitativoMassimo, 0)
            + NVL (nCarburanteMietitrebb, 0)
            + NVL (nCarburanteEssicazione, 0);
      ELSE
         nQuantitativoMassimo :=
            LEAST (
               nSommaAB,
               (  NVL (nCarburanteAssegnato, 0)
                + NVL (nCarburanteMietitrebb, 0)
                + NVL (nCarburanteEssicazione, 0)));

         nQuantMaxContoProprio := nQuantitativoMassimo;

         IF nSommaAB <=
               (  NVL (nCarburanteAssegnato, 0)
                + NVL (nCarburanteMietitrebb, 0)
                + NVL (nCarburanteEssicazione, 0))
         THEN
            nCarburanteMietitrebb := 0;
            nCarburanteEssicazione := 0;
         END IF;
      END IF;

      IF nQuantMaxContoProprio < 0
      THEN
         nQuantMaxContoProprio := 0;
      END IF;


      BEGIN
         dDtMaxConsegnaDoc :=
            TO_DATE (SelectValoreParametro (kvCodParDtMaxConsDocument),
                     'DD/MM/YYYY');
      EXCEPTION
         WHEN OTHERS
         THEN
            P_CODERR := SQLCODE;
            P_MSGERR :=
               'Parametro data massima consegna documentazione per assegnazione non trovato od in formato erroneo (<> DD/MM/YYYY) !!';
            RAISE SCARTO;
      END;


      BEGIN
         dDtLimRidCarb :=
            TO_DATE (SelectValoreParametro (kvCodParDtLimiteRiduzione),
                     'DD/MM/YYYY');
      EXCEPTION
         WHEN OTHERS
         THEN
            P_CODERR := SQLCODE;
            P_MSGERR :=
               'Parametro data limite applicazione riduzione carburante in base alla domanda di assegnazione non trovato od in formato erroneo (<> DD/MM/YYYY) !!';
            RAISE SCARTO;
      END;

      -- richiamo la function assegnazione_successiva per applicare eventualmente
      -- la riduzione
      IF NOT ASSEGNAZIONE_SUCCESSIVA (
                P_ID_DOMANDA_ASSEGNAZIONE,
                nQuantMaxContoProprio,
                dDtMaxConsegnaDoc,                            
                dDtLimRidCarb,                                
                recTDatiDitta.DATA_RICEZ_DOCUM_ASSEGNAZ,      
                nAssegnazioneSuccess,
                nPercentuale,
                dDataDecorrenza,
                P_MSGERR,
                P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      IF nRimanenzaLavBenzina + nRimanenzaLavGasolio > 0
      THEN
         SELECT TO_CHAR (DATA_RIFERIMENTO, 'YYYY') - 2
           INTO vAnno
           FROM DB_DOMANDA_ASSEGNAZIONE
          WHERE ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE;

         SELECT NVL (SUM (P.QUANTITA_PRELEVATA), 0)
           INTO nQuantitaPrelevata
           FROM DB_PRELIEVO P,
                NEWMA_R_STATO_PRELIEVO SP,
                NEWMA_D_CAUSALE_STATO CS,
                DB_BUONO_CARBURANTE BC,
                DB_BUONO_PRELIEVO BP,
                DB_DOMANDA_ASSEGNAZIONE DA
          WHERE     P.ID_PRELIEVO = SP.ID_PRELIEVO
                AND CS.ID_CAUSALE_STATO = SP.ID_CAUSALE_STATO
                AND BC.ID_BUONO_CARBURANTE = P.ID_BUONO_CARBURANTE
                AND BP.ID_BUONO_PRELIEVO = BC.ID_BUONO_PRELIEVO
                AND DA.ID_DOMANDA_ASSEGNAZIONE = BP.ID_DOMANDA_ASSEGNAZIONE
                AND DA.ID_STATO_DOMANDA != 40
                AND BP.CARBURANTE_PER_SERRA IS NULL
                AND BP.ANNULLATO IS NULL
                AND SP.DATA_FINE_VALIDITA IS NULL
                AND CS.ID_CODICE_STATO_PRELIEVO != 40
                AND TO_CHAR (DA.DATA_RIFERIMENTO, 'YYYY') = vAnno
                AND DA.ID_DITTA_UMA = nIdDittaUma;

         BEGIN
            SELECT NVL (TOTALE_CONTO_PROPRIO, 0)
              INTO nMaxAssegnabileContoProprio
              FROM DB_DETTAGLIO_CALCOLO DC
             WHERE     DC.ID_DOMANDA_ASSEGNAZIONE =
                          (SELECT MAX (DA1.ID_DOMANDA_ASSEGNAZIONE)
                             FROM DB_DOMANDA_ASSEGNAZIONE DA1
                            WHERE     TO_CHAR (DA1.DATA_RIFERIMENTO, 'YYYY') =
                                         vAnno
                                  AND DA1.ID_STATO_DOMANDA IN (30, 35)
                                  AND DA1.ID_DITTA_UMA = nIdDittaUma)
                   AND TIPO_ASSEGNAZIONE IN ('A', 'B')
                   AND NUMERO_SUPPLEMENTO IS NULL;
         EXCEPTION
            WHEN OTHERS
            THEN
               nMaxAssegnabileContoProprio := 0;
         END;

         SELECT NVL (SUM (ASSEGNAZIONE_CONTO_TERZI), 0)
           INTO nAssegnazioneContoTerzi
           FROM DB_QUANTITA_ASSEGNATA QA,
                DB_ASSEGNAZIONE_CARBURANTE AC,
                DB_DOMANDA_ASSEGNAZIONE DA
          WHERE     AC.ID_ASSEGNAZIONE_CARBURANTE =
                       QA.ID_ASSEGNAZIONE_CARBURANTE
                AND DA.ID_DOMANDA_ASSEGNAZIONE = AC.ID_DOMANDA_ASSEGNAZIONE
                AND AC.ANNULLATO IS NULL
                AND DA.ID_DOMANDA_ASSEGNAZIONE =
                       (SELECT MAX (DA1.ID_DOMANDA_ASSEGNAZIONE)
                          FROM DB_DOMANDA_ASSEGNAZIONE DA1
                         WHERE     TO_CHAR (DA1.DATA_RIFERIMENTO, 'YYYY') =
                                      vAnno
                               AND DA1.ID_STATO_DOMANDA IN (30, 35)
                               AND DA1.ID_DITTA_UMA = nIdDittaUma);

         SELECT NVL (SUM (ASSEGNAZIONE_CONTO_PROPRIO), 0)
           INTO nAssegnazioneContoProprioSup
           FROM DB_QUANTITA_ASSEGNATA QA,
                DB_ASSEGNAZIONE_CARBURANTE AC,
                DB_DOMANDA_ASSEGNAZIONE DA
          WHERE     AC.ID_ASSEGNAZIONE_CARBURANTE =
                       QA.ID_ASSEGNAZIONE_CARBURANTE
                AND DA.ID_DOMANDA_ASSEGNAZIONE = AC.ID_DOMANDA_ASSEGNAZIONE
                AND AC.ANNULLATO IS NULL
                AND AC.TIPO_ASSEGNAZIONE = 'S'
                AND DA.ID_DOMANDA_ASSEGNAZIONE IN
                       (SELECT DA1.ID_DOMANDA_ASSEGNAZIONE
                          FROM DB_DOMANDA_ASSEGNAZIONE DA1
                         WHERE     TO_CHAR (DA1.DATA_RIFERIMENTO, 'YYYY') =
                                      vAnno
                               AND DA1.ID_STATO_DOMANDA IN (30)
                               AND DA1.ID_DITTA_UMA = nIdDittaUma);

         IF   (  nQuantitaPrelevata
               - nAssegnazioneContoTerzi
               - nAssegnazioneContoProprioSup)
            + nRimanenzaLavBenzina
            + nRimanenzaLavGasolio > nMaxAssegnabileContoProprio
         THEN
            nDecurtazione :=
                 (  nQuantitaPrelevata
                  - nAssegnazioneContoTerzi
                  - nAssegnazioneContoProprioSup)
               + nRimanenzaLavBenzina
               + nRimanenzaLavGasolio
               - nMaxAssegnabileContoProprio;
         ELSE
            nDecurtazione := 0;
         END IF;
      ELSE
         nDecurtazione := 0;
      END IF;

      IF nPercentuale IS NULL
      THEN
         nComodo := nQuantMaxContoProprio - nDecurtazione; 
      ELSE
         nComodo := nAssegnazioneSuccess - nDecurtazione; 
      END IF;

      nComodo := nComodo - nCarburanteLavCtDaCp;

      IF nComodo > 0
      THEN
         nComodo := (nComodo + 4.99) / 10;
      ELSE
         nComodo := 0;
      END IF;

      nComodo := ROUND (nComodo, 0);
      nTotaleContoProprio := nComodo * 10;

      IF nTotaleContoProprio = 0
      THEN
         nTotaleContoProprio := NULL;
      END IF;

      IF NOT TOTALE_CARBURANTE_SERRA (P_ID_DOMANDA_ASSEGNAZIONE,
                                      P_TIPO_ASSEGNAZIONE,
                                      P_NUMERO_SUPPLEMENTO,
                                      nCarburanteRiscaldamento,
                                      P_MSGERR,
                                      P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      nComodo := (NVL (nCarburanteRiscaldamento, 0) + 4.99) / 10;
      nComodo := ROUND (nComodo, 0);
      nTotaleSerra := nComodo * 10;

      IF nTotaleSerra = 0
      THEN
         nTotaleSerra := NULL;
      END IF;

      IF NOT TOTALE_CARBURANTE_CONTOTERZI (nIdDittaUma,
                                           nAnnoRiferimento,
                                           nCarburanteContoTerziLav,
                                           nAssegnatoPrecContoTerzi,
                                           nRimanenzePrecCT,
                                           P_MSGERR,
                                           P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      IF nCarburanteContoTerziLav <=
            (nAssegnatoPrecContoTerzi + nRimanenzePrecCT)
      THEN                                           
         nMaxContoTerzi := nCarburanteContoTerziLav;
      ELSE
         nMaxContoTerzi := nAssegnatoPrecContoTerzi + nRimanenzePrecCT; 
      END IF;

      nTotaleContoTerzi :=
         ROUND ( (NVL (nMaxContoTerzi, 0) + 4.99) / 10, 0) * 10;

      IF nCountDittaForz IS NOT NULL AND nCountDittaForz > 0
      THEN
         nAltreMacchine := 1;
      ELSE
         IF NOT RICERCA_MAO_V_D (P_ID_DOMANDA_ASSEGNAZIONE,
                                 nContaMaoVD,
                                 P_MSGERR,
                                 P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         IF NOT RICERCA_ASM (P_ID_DOMANDA_ASSEGNAZIONE,
                             nContaAsm,
                             P_MSGERR,
                             P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         nAltreMacchine := nContaMaoVD + nContaAsm;
      END IF;

      IF nAltreMacchine > 0
      THEN
         vAltreMacchineDittaForzata := 'S';
      ELSE
         vAltreMacchineDittaForzata := 'N';
      END IF;

      DELETE DB_DETTAGLIO_CALCOLO
       WHERE     ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (NUMERO_SUPPLEMENTO, 0) = NVL (P_NUMERO_SUPPLEMENTO, 0);

      INSERT INTO DB_DETTAGLIO_CALCOLO (ID_DETTAGLIO_CALCOLO,
                                        ID_DOMANDA_ASSEGNAZIONE,
                                        TIPO_ASSEGNAZIONE,
                                        NUMERO_SUPPLEMENTO,
                                        DATA_DECORRENZA,
                                        CARBURANTE_LAVORAZIONE,
                                        CARBURANTE_ASSERVIMENTO,
                                        CARBURANTE_ALLEVAMENTO,
                                        TOT_CARB_COLTURA_ALLEV,
                                        CARBURANTE_MACCHINE,
                                        QUANTITATIVO_MASSIMO,
                                        CARBURANTE_MIETITREBB,
                                        CARBURANTE_ESSICAZIONE,
                                        MAX_CONTO_PROPRIO,
                                        MAX_CONTO_PROPRIO_RIDOTTO,
                                        PERCENTUALE_RIDUZIONE,
                                        DECURTAZIONE_LAV_BENZINA,
                                        DECURTAZIONE_LAV_GASOLIO,
                                        TOTALE_CONTO_PROPRIO,
                                        CARBURANTE_RISCALDAMENTO,
                                        TOTALE_SERRA,
                                        ALTRE_MACCHINE_DITTA_FORZATA,
                                        DATA_AGGIORNAMENTO,
                                        EXT_ID_UTENTE_AGGIORNAMENTO,
                                        TOTALE_CONTO_TERZI,
                                        CARB_LAVORAZ_AUMENTO,
                                        CARB_LAVORAZ_COLT_SEC,
                                        CARB_LAVORAZ_ECCEZ,
                                        CARB_LAVORAZIONI_BASE,
                                        CARB_AUMENTO_ALLEVAMENTO,
                                        CARB_AUMENTO_MACCHINE,
                                        CARB_AUMENTO_RISCALDAMENTO,
                                        CARBURANTE_LAV_CT_DA_CP,
                                        CARBURANTE_CONTO_TERZI_LAV,
                                        ASSEGNATO_PREC_CONTO_TERZI,
                                        MAX_CONTO_TERZI)
           VALUES (SEQ_DB_DETTAGLIO_CALCOLO.NEXTVAL,
                   P_ID_DOMANDA_ASSEGNAZIONE,
                   P_TIPO_ASSEGNAZIONE,
                   P_NUMERO_SUPPLEMENTO,
                   dDataDecorrenza,
                   NVL (nCarburanteLavorazione, 0),
                   NVL (nCarburanteAsservimento, 0),
                   NVL (nCarburanteAllevamento, 0),
                   NVL (nSommaAB, 0),
                   NVL (nCarburanteAssegnato, 0),
                   NVL (nQuantitativoMassimo, 0),
                   NVL (nCarburanteMietitrebb, 0),
                   NVL (nCarburanteEssicazione, 0),
                   NVL (nQuantMaxContoProprio, 0),
                   NVL (nAssegnazioneSuccess, 0),
                   NVL (nPercentuale, 0),
                   NVL (nRimanenzaLavBenzina, 0),
                   NVL (nRimanenzaLavGasolio, 0),
                   NVL (nTotaleContoProprio, 0),
                   NVL (nCarburanteRiscaldamento, 0),
                   NVL (nTotaleSerra, 0),
                   vAltreMacchineDittaForzata,
                   SYSDATE,
                   P_ID_UTENTE,
                   nTotaleContoTerzi,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   nCarburanteLavCtDaCp,
                   nCarburanteContoTerziLav,
                   nAssegnatoPrecContoTerzi,
                   nMaxContoTerzi);
   EXCEPTION
      WHEN SCARTO
      THEN
         NULL;
      WHEN OTHERS
      THEN
         P_CODERR := SQLCODE;
         P_MSGERR := 'Errore generico ' || SQLERRM;
   END CALCOLO_ASSEGNAZIONE_CARB;

   FUNCTION TOTALE_CARB_AUMENTO_SUP (
      P_ID_DOMANDA_ASSEGNAZIONE           DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE                 DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO                DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      pIdDittaUma                         DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE,
      pDataRif                            DATE,
      P_CARB_AUMENTO_SUP              OUT NUMBER,
      P_AumentoCarbMietitrebbiatura   OUT NUMBER,
      P_AumentoCarbEssicazione        OUT NUMBER,
      P_MSGERR                        OUT VARCHAR2,
      P_CODERR                        OUT VARCHAR2)
      RETURN BOOLEAN
   IS
      nCarburanteLavorazione        NUMBER := 0;
      nCarburanteMietitrebbiatura   NUMBER := 0;
      nCarburanteEssicazione        NUMBER := 0;
      nCarbLavorazioneBase          NUMBER := 0;
      nCarbMietitrebbiaturaBase     NUMBER := 0;
      nCarbEssicazioneBase          NUMBER := 0;
      nAumentoCarbLavorazione       NUMBER := 0;
      --nAumentoCarbMietitrebbiatura NUMBER := 0;
      --nAumentoCarbEssicazione NUMBER := 0;
      nContTrattice                 PLS_INTEGER;
      nFramm                        NUMBER := 0;
      nAumSupCollMont               NUMBER := 0;
      nLitriBase                    NUMBER := 0;
      nLitriMedioImpasto            NUMBER := 0;
      nLitriAcclivita               NUMBER := 0;
      bFoundLav                     BOOLEAN := FALSE;
      nPotMaxColt                   NUMBER := 0;
      nCarbLavNoPot                 NUMBER := 0;
      nSupOre                       NUMBER := 0;
      nPotMax                       NUMBER := 0;
      nPotMaxTot                    NUMBER := 0;
      nContNonPot                   PLS_INTEGER;
      nCarbLavPot                   NUMBER := 0;
   BEGIN
      SELECT NVL (SUM (CARBURANTE_LAVORAZIONE), 0),
             NVL (SUM (CARBURANTE_MIETITREBBIATURA), 0),
             NVL (SUM (CARBURANTE_ESSICAZIONE), 0)
        INTO nCarburanteLavorazione,
             nCarburanteMietitrebbiatura,
             nCarburanteEssicazione
        FROM DB_CARBURANTE_COLTURA CC, DB_COLTURA_PRATICATA CP
       WHERE     CC.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND CC.TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (CC.NUMERO_SUPPLEMENTO, 0) =
                    NVL (P_NUMERO_SUPPLEMENTO, 0)
             AND CP.ID_COLTURA_PRATICATA = CC.ID_COLTURA_PRATICATA
             AND CP.FLAG_COLTURA_SECONDARIA = 'N';   

      SELECT NVL (SUM (CARBURANTE_LAVORAZIONE), 0),
             NVL (SUM (CARBURANTE_MIETITREBBIATURA), 0),
             NVL (SUM (CARBURANTE_ESSICAZIONE), 0)
        INTO nCarbLavorazioneBase,
             nCarbMietitrebbiaturaBase,
             nCarbEssicazioneBase
        FROM DB_CARBURANTE_COLTURA CC, DB_COLTURA_PRATICATA CP
       WHERE     CC.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND CC.TIPO_ASSEGNAZIONE = 'B'
             AND CC.NUMERO_SUPPLEMENTO IS NULL
             AND CP.ID_COLTURA_PRATICATA = CC.ID_COLTURA_PRATICATA
             AND CP.FLAG_COLTURA_SECONDARIA = 'N';   

      nAumentoCarbLavorazione := nCarburanteLavorazione - nCarbLavorazioneBase;
      P_AumentoCarbMietitrebbiatura :=
         nCarburanteMietitrebbiatura - nCarbMietitrebbiaturaBase;
      P_AumentoCarbEssicazione :=
         nCarburanteEssicazione - nCarbEssicazioneBase;

      IF nAumentoCarbLavorazione < 0
      THEN
         nAumentoCarbLavorazione := 0;
      END IF;

      IF P_AumentoCarbMietitrebbiatura < 0
      THEN
         P_AumentoCarbMietitrebbiatura := 0;
      END IF;

      IF P_AumentoCarbEssicazione < 0
      THEN
         P_AumentoCarbEssicazione := 0;
      END IF;
      
      select sum(num_rec)
            INTO nContTrattice
            from (SELECT COUNT (*) num_rec
        FROM DB_UTILIZZO U,
             DB_MACCHINA M,
             DB_MATRICE MA,
             DB_TIPO_GENERE_MACCHINA TGM
       WHERE     M.ID_MACCHINA = U.ID_MACCHINA
             AND TGM.ID_GENERE_MACCHINA = MA.ID_GENERE_MACCHINA
             AND MA.ID_MATRICE = M.ID_MATRICE
             AND U.ID_DITTA_UMA = pIdDittaUma
             AND U.DATA_CARICO <= pDataRif
             AND (U.DATA_SCARICO IS NULL OR U.DATA_SCARICO >= pDataRif)
             AND MA.ID_ALIMENTAZIONE IN (1, 2)
             AND TRIM (TGM.CODIFICA_BREVE) = 'T'
      union
      SELECT COUNT (*) num_rec
           FROM DB_UTILIZZO U,
                DB_MACCHINA M,
                DB_DATI_MACCHINA DM,
                DB_TIPO_GENERE_MACCHINA TGM
          WHERE     M.ID_MACCHINA = U.ID_MACCHINA
                AND TGM.ID_GENERE_MACCHINA = DM.ID_GENERE_MACCHINA
                AND M.ID_MACCHINA = DM.ID_MACCHINA
                AND U.ID_DITTA_UMA = pIdDittaUma
                AND U.DATA_CARICO <= pDataRif
                AND (   U.DATA_SCARICO IS NULL
                     OR U.DATA_SCARICO >= pDataRif)
                AND DM.ID_ALIMENTAZIONE IN (1, 2)
                AND TRIM (TGM.CODIFICA_BREVE) = 'T');

      SELECT TO_NUMBER (REPLACE (VALORE, '.', ','))
        INTO nFramm
        FROM DB_PARAMETRO
       WHERE ID_PARAMETRO = 'UMFR';

      FOR recColtPrinc
         IN (SELECT ATT.ID_CATEGORIA_UTILIZZO_UMA,
                    CASE
                       WHEN (ATT.SUP_COMPLES - NVL (BASE.SUP_COMPLES, 0)) < 0
                       THEN
                          0
                       ELSE
                          (ATT.SUP_COMPLES - NVL (BASE.SUP_COMPLES, 0))
                    END
                       AUM_SUP_COMPLES,
                    CASE
                       WHEN (ATT.SUP_FRAMM - NVL (BASE.SUP_FRAMM, 0)) < 0
                       THEN
                          0
                       ELSE
                          (ATT.SUP_FRAMM - NVL (BASE.SUP_FRAMM, 0))
                    END
                       AUM_SUP_FRAMM
               FROM (  SELECT CUU.ID_CATEGORIA_UTILIZZO_UMA,
                              NVL (SUM (CP.SUPERFICIE_UTILIZZATA), 0)
                                 SUP_COMPLES,
                              (NVL (SUM (CP.SUPERFICIE_UTILIZZATA), 0) * 1)
                                 SUP_FRAMM
                         FROM DB_CATEGORIA_UTILIZZO_UMA CUU,
                              DB_CATEGORIA_COLTURA CC,
                              DB_SUPERFICIE_AZIENDA SA,
                              DB_COLTURA_PRATICATA CP
                        WHERE     CUU.ID_CATEGORIA_UTILIZZO_UMA =
                                     CC.ID_CATEGORIA_UTILIZZO_UMA
                              AND SA.ID_SUPERFICIE_AZIENDA =
                                     CP.ID_SUPERFICIE_AZIENDA
                              AND CP.ID_COLTURA = CC.ID_COLTURA
                              AND SA.ID_DITTA_UMA = pIdDittaUma
                              AND SA.DATA_FINE_VALIDITA IS NULL
                              AND SA.DATA_SCARICO IS NULL
                              AND CC.DATA_FINE_VALIDITA IS NULL
                              AND CUU.DATA_FINE_VALIDITA IS NULL
                              AND CP.FLAG_COLTURA_SECONDARIA = 'N'
                     GROUP BY CUU.ID_CATEGORIA_UTILIZZO_UMA) ATT,
                    (  SELECT CUU.ID_CATEGORIA_UTILIZZO_UMA,
                              NVL (SUM (CP.SUPERFICIE_UTILIZZATA), 0)
                                 SUP_COMPLES,
                              (NVL (SUM (CP.SUPERFICIE_UTILIZZATA), 0) * 1)
                                 SUP_FRAMM
                         FROM DB_CATEGORIA_UTILIZZO_UMA CUU,
                              DB_CATEGORIA_COLTURA CC,
                              DB_SUPERFICIE_AZIENDA SA,
                              DB_COLTURA_PRATICATA CP
                        WHERE     CUU.ID_CATEGORIA_UTILIZZO_UMA =
                                     CC.ID_CATEGORIA_UTILIZZO_UMA
                              AND SA.ID_SUPERFICIE_AZIENDA =
                                     CP.ID_SUPERFICIE_AZIENDA
                              AND CP.ID_COLTURA = CC.ID_COLTURA
                              AND SA.ID_DITTA_UMA = pIdDittaUma
                              AND pDataRif BETWEEN SA.DATA_inizio_VALIDITA
                                               AND NVL (SA.DATA_FINE_VALIDITA,
                                                        SYSDATE)
                              AND CC.DATA_FINE_VALIDITA IS NULL
                              AND CUU.DATA_FINE_VALIDITA IS NULL
                              AND CP.FLAG_COLTURA_SECONDARIA = 'N'
                     GROUP BY CUU.ID_CATEGORIA_UTILIZZO_UMA) BASE
              WHERE ATT.ID_CATEGORIA_UTILIZZO_UMA =
                       BASE.ID_CATEGORIA_UTILIZZO_UMA(+))
      LOOP
         SELECT NVL (SUM (PC.SUPERFICIE_UTILIZZATA), 0)
           INTO nAumSupCollMont
           FROM DB_SUPERFICIE_AZIENDA SA,
                DB_COLTURA_PRATICATA CP,
                DB_PARTICELLA_COLTURA PC,
                DB_STORICO_PARTICELLA SP,
                DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,
                DB_ZONA_ALTIMETRICA ZA,
                DB_CATEGORIA_COLTURA CC
          WHERE     CC.ID_CATEGORIA_UTILIZZO_UMA =
                       recColtPrinc.ID_CATEGORIA_UTILIZZO_UMA
                AND SA.ID_SUPERFICIE_AZIENDA = CP.ID_SUPERFICIE_AZIENDA
                AND CP.ID_COLTURA_PRATICATA = PC.ID_COLTURA_PRATICATA
                AND PC.EX_ID_STORICO_PARTICELLA = SP.ID_STORICO_PARTICELLA
                AND SP.ID_ZONA_ALTIMETRICA = ZAUG.EXT_ID_ZONA_ALTIMETRICA
                AND ZAUG.ID_ZONA_ALTIMETRICA = ZA.ID_ZONA_ALTIMETRICA
                AND ZAUG.DATA_FINE_VALIDITA IS NULL
                AND ZA.CODICE = 'M'
                AND SA.ID_DITTA_UMA = pIdDittaUma
                AND SA.DATA_SCARICO IS NULL
                AND SA.DATA_FINE_VALIDITA IS NULL
                AND CP.ID_COLTURA = CC.ID_COLTURA
                AND CP.FLAG_COLTURA_SECONDARIA = 'N'
                AND CC.DATA_FINE_VALIDITA IS NULL;

         SELECT nAumSupCollMont - NVL (SUM (PC.SUPERFICIE_UTILIZZATA), 0)
           INTO nAumSupCollMont
           FROM DB_SUPERFICIE_AZIENDA SA,
                DB_COLTURA_PRATICATA CP,
                DB_PARTICELLA_COLTURA PC,
                DB_STORICO_PARTICELLA SP,
                DB_R_ZONA_ALTIMETRICA_UMA_GAA ZAUG,
                DB_ZONA_ALTIMETRICA ZA,
                DB_CATEGORIA_COLTURA CC
          WHERE     CC.ID_CATEGORIA_UTILIZZO_UMA =
                       recColtPrinc.ID_CATEGORIA_UTILIZZO_UMA
                AND SA.ID_SUPERFICIE_AZIENDA = CP.ID_SUPERFICIE_AZIENDA
                AND CP.ID_COLTURA_PRATICATA = PC.ID_COLTURA_PRATICATA
                AND PC.EX_ID_STORICO_PARTICELLA = SP.ID_STORICO_PARTICELLA
                AND SP.ID_ZONA_ALTIMETRICA = ZAUG.EXT_ID_ZONA_ALTIMETRICA
                AND ZAUG.ID_ZONA_ALTIMETRICA = ZA.ID_ZONA_ALTIMETRICA
                AND ZAUG.DATA_FINE_VALIDITA IS NULL
                AND ZA.CODICE = 'M'
                AND SA.ID_DITTA_UMA = pIdDittaUma
                AND pDataRif BETWEEN SA.DATA_inizio_VALIDITA
                                 AND NVL (SA.DATA_FINE_VALIDITA, SYSDATE)
                AND CC.DATA_FINE_VALIDITA IS NULL
                AND CP.FLAG_COLTURA_SECONDARIA = 'N';

         IF nAumSupCollMont < 0
         THEN
            nAumSupCollMont := 0;
         END IF;

         bFoundLav := FALSE;
         nPotMaxColt := 0;
         nCarbLavNoPot := 0;
         nLitriBase := 0;
         nLitriMedioImpasto := 0;
         nLitriAcclivita := 0;

         FOR recLav
            IN (SELECT CCL.ID_LAVORAZIONI,
                       CCL.ID_UNITA_MISURA,
                       NVL (LINEA.MAX_ESECUZIONI_LINEA_LAVORAZ,
                            CCL.MAX_ESECUZIONI)
                          NUM_ESEC,
                       CCL.LITRI_BASE,
                       CCL.LITRI_MEDIO_IMPASTO,
                       CCL.LITRI_TERRENI_DECLIVI
                  FROM DB_CATEG_COLTURA_LAVORAZIONI CCL,
                       DB_UNITA_MISURA UM,
                       DB_TIPO_LAVORAZIONI TL,
                       (SELECT LLL.MAX_ESECUZIONI_LINEA_LAVORAZ,
                               LLL.ID_LAVORAZIONI,
                               CLL.LINEA_LAVORAZIONE_PRIMARIA
                          FROM DB_COLTURA_LINEA_LAVORAZIONE CLL,
                               DB_LAVORAZIONI_LINEA_LAVORAZIO LLL
                         WHERE     (   LLL.DATA_FINE_VALIDITA IS NULL
                                    OR TRUNC (LLL.DATA_FINE_VALIDITA) >=
                                          TRUNC (SYSDATE))
                               AND TRUNC (LLL.DATA_INIZIO_VALIDITA) <=
                                      TRUNC (SYSDATE)
                               AND (   CLL.DATA_FINE_VALIDITA IS NULL
                                    OR TRUNC (CLL.DATA_FINE_VALIDITA) >=
                                          TRUNC (SYSDATE))
                               AND TRUNC (CLL.DATA_INIZIO_VALIDITA) <=
                                      TRUNC (SYSDATE)
                               AND CLL.ID_CATEGORIA_UTILIZZO_UMA =
                                      recColtPrinc.ID_CATEGORIA_UTILIZZO_UMA
                               AND CLL.ID_COLTURA_LINEA_LAVORAZIONE =
                                      LLL.ID_COLTURA_LINEA_LAVORAZIONE) LINEA
                 WHERE     UM.ID_UNITA_MISURA = CCL.ID_UNITA_MISURA
                       AND CCL.ID_CATEGORIA_UTILIZZO_UMA =
                              recColtPrinc.ID_CATEGORIA_UTILIZZO_UMA
                       AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                       AND CCL.ID_LAVORAZIONI = LINEA.ID_LAVORAZIONI(+)
                       AND TL.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                       AND TL.FLAG_ASSERVIMENTO = 'N'
                       AND UM.TIPO = 'S'
                       AND TRUNC (CCL.DATA_INIZIO_VALIDITA) <=
                              TRUNC (SYSDATE)
                       AND (   CCL.DATA_FINE_VALIDITA IS NULL
                            OR TRUNC (CCL.DATA_FINE_VALIDITA) >=
                                  TRUNC (SYSDATE))
                       AND LAVORAZIONE_STRAORDINARIA = 'N'
                       AND LAVORAZIONE_DEFAULT = 'S'
                       AND NVL (LINEA.LINEA_LAVORAZIONE_PRIMARIA, 'S') = 'S'
                       AND EXISTS
                              (SELECT 'X'
                                 FROM DB_CATEG_MACCHINE_LAVORAZIONI CML,
                                      DB_TIPO_GENERE_MACCHINA TGM,
                                      DB_UTILIZZO U,
                                      DB_MACCHINA M
                                WHERE     TGM.ID_GENERE_MACCHINA =
                                             CML.ID_GENERE_MACCHINA
                                      AND M.ID_MACCHINA = U.ID_MACCHINA
                                      AND CML.ID_CATEGORIA_UTILIZZO_UMA =
                                             recColtPrinc.ID_CATEGORIA_UTILIZZO_UMA
                                      AND CML.ID_LAVORAZIONI =
                                             CCL.ID_LAVORAZIONI
                                      AND CML.DATA_FINE_VALIDITA IS NULL
                                      AND U.ID_DITTA_UMA = pIdDittaUma
                                      AND U.DATA_SCARICO IS NULL
                                      AND TGM.ID_GENERE_MACCHINA IN
                                             (SELECT DM.ID_GENERE_MACCHINA
                                                FROM DB_DATI_MACCHINA DM
                                               WHERE     DM.ID_MACCHINA =
                                                            M.ID_MACCHINA
                                                     AND NVL (
                                                            CML.ID_CATEGORIA,
                                                            -1) =
                                                            NVL (
                                                               DM.ID_CATEGORIA,
                                                               -1)
                                              UNION
                                              SELECT MAT.ID_GENERE_MACCHINA
                                                FROM DB_MATRICE MAT
                                               WHERE     MAT.ID_MATRICE =
                                                            M.ID_MATRICE
                                                     AND NVL (
                                                            CML.ID_CATEGORIA,
                                                            -1) =
                                                            NVL (
                                                               MAT.ID_CATEGORIA,
                                                               -1))))
         LOOP
            nLitriBase :=
                 nLitriBase
               + (  recColtPrinc.AUM_SUP_COMPLES
                  * recLav.NUM_ESEC
                  * recLav.LITRI_BASE);
            nLitriMedioImpasto :=
                 nLitriMedioImpasto
               + (  recColtPrinc.AUM_SUP_COMPLES
                  * recLav.NUM_ESEC
                  * recLav.LITRI_MEDIO_IMPASTO);
            nLitriAcclivita :=
                 nLitriAcclivita
               + (  nAumSupCollMont
                  * recLav.NUM_ESEC
                  * recLav.LITRI_TERRENI_DECLIVI);
            bFoundLav := TRUE;
         END LOOP;

         IF bFoundLav
         THEN
            nPotMaxColt :=
                 nLitriBase
               + nLitriMedioImpasto
               + nLitriAcclivita
               + recColtPrinc.AUM_SUP_FRAMM;
         ELSE
            nPotMaxColt := nLitriBase + nLitriMedioImpasto + nLitriAcclivita;
         END IF;

         -- Calcolo carburante lavorazioni NON oltre la potenzialità caricate su ditta Uma
         FOR recLavCp
            IN (  SELECT LCP.ID_CATEGORIA_UTILIZZO_UMA,
                         NVL (SUM (LCP.TOT_LITRI_LAVORAZIONE), 0) TOT_LIT_LAV
                    FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                         DB_CATEG_COLTURA_LAVORAZIONI CCL
                   WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                CCL.ID_CATEGORIA_UTILIZZO_UMA
                         AND CCL.ID_CATEGORIA_UTILIZZO_UMA =
                                recColtPrinc.ID_CATEGORIA_UTILIZZO_UMA    --EB
                         AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                         AND LCP.ID_DITTA_UMA = pIdDittaUma
                         AND LCP.ANNO_CAMPAGNA =
                                TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                         AND LCP.DATA_FINE_VALIDITA IS NULL
                         AND LCP.DATA_CESSAZIONE IS NULL
                         AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                         AND CCL.DATA_FINE_VALIDITA IS NULL
                         AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
                         AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL
                         AND LCP.ID_MOTIVO_LAVORAZIONE =
                                PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                   'AS')
                GROUP BY LCP.ID_CATEGORIA_UTILIZZO_UMA)
         LOOP
            SELECT NVL (MIN (LCP.SUP_ORE), 0) * nFramm
              INTO nSupOre
              FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                   DB_CATEG_COLTURA_LAVORAZIONI CCL,
                   DB_UNITA_MISURA UM
             WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                          recLavCp.ID_CATEGORIA_UTILIZZO_UMA
                   AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                          CCL.ID_CATEGORIA_UTILIZZO_UMA
                   AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                   AND LCP.ID_DITTA_UMA = pIdDittaUma
                   AND LCP.ANNO_CAMPAGNA =
                          TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                   AND LCP.DATA_FINE_VALIDITA IS NULL
                   AND LCP.DATA_CESSAZIONE IS NULL
                   AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                   AND CCL.DATA_FINE_VALIDITA IS NULL
                   AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
                   AND CCL.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
                   AND UM.TIPO = 'S'
                   AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL
                   AND LCP.ID_MOTIVO_LAVORAZIONE =
                          PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV ('AS');

            nCarbLavNoPot := recLavCp.TOT_LIT_LAV + nSupOre;
         END LOOP;

         --nPotMax := nPotMax + LEAST (nPotMaxColt, nCarbLavNoPot);
         nPotMax := nPotMax + nCarbLavNoPot;

         IF nContTrattice != 0
         THEN
            nPotMaxTot := nPotMax;
         ELSE
            nPotMaxTot := nPotMax;
/*
            nPotMaxTot :=
               LEAST (
                  nPotMax,
                  (  nAumentoCarbLavorazione
                   + P_AumentoCarbMietitrebbiatura
                   + P_AumentoCarbEssicazione));
*/
         END IF;

         -- Calcolo carburante lavorazioni oltre la potenzialità caricate su ditta Uma
         FOR recLavCpPot
            IN (  SELECT LCP.ID_CATEGORIA_UTILIZZO_UMA,
                         NVL (SUM (LCP.TOT_LITRI_LAVORAZIONE), 0) TOT_LIT_LAV
                    FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                         DB_CATEG_COLTURA_LAVORAZIONI CCL
                   WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                CCL.ID_CATEGORIA_UTILIZZO_UMA
                         AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                         AND LCP.ID_DITTA_UMA = pIdDittaUma
                         AND LCP.ANNO_CAMPAGNA =
                                TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                         AND LCP.DATA_FINE_VALIDITA IS NULL
                         AND LCP.DATA_CESSAZIONE IS NULL
                         AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                         AND CCL.DATA_FINE_VALIDITA IS NULL
                         AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'S'
                         AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL
                         AND LCP.ID_MOTIVO_LAVORAZIONE =
                                PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                   'AS')
                GROUP BY LCP.ID_CATEGORIA_UTILIZZO_UMA)
         LOOP
            SELECT COUNT (*)
              INTO nContNonPot
              FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                   DB_CATEG_COLTURA_LAVORAZIONI CCL
             WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                          recLavCpPot.ID_CATEGORIA_UTILIZZO_UMA
                   AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                          CCL.ID_CATEGORIA_UTILIZZO_UMA
                   AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                   AND LCP.ID_DITTA_UMA = pIdDittaUma
                   AND LCP.ANNO_CAMPAGNA =
                          TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                   AND LCP.DATA_FINE_VALIDITA IS NULL
                   AND LCP.DATA_CESSAZIONE IS NULL
                   AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                   AND CCL.DATA_FINE_VALIDITA IS NULL
                   AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
                   AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL
                   AND LCP.ID_MOTIVO_LAVORAZIONE =
                          PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV ('AS');

            IF nContNonPot = 0
            THEN
               SELECT NVL (MIN (LCP.SUP_ORE), 0) * nFramm
                 INTO nSupOre
                 FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                      DB_CATEG_COLTURA_LAVORAZIONI CCL,
                      DB_UNITA_MISURA UM
                WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                             recLavCpPot.ID_CATEGORIA_UTILIZZO_UMA
                      AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                             CCL.ID_CATEGORIA_UTILIZZO_UMA
                      AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                      AND LCP.ID_DITTA_UMA = pIdDittaUma
                      AND LCP.ANNO_CAMPAGNA =
                             TO_NUMBER (TO_CHAR (pDataRif, 'YYYY'))
                      AND LCP.DATA_FINE_VALIDITA IS NULL
                      AND LCP.DATA_CESSAZIONE IS NULL
                      AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                      AND CCL.DATA_FINE_VALIDITA IS NULL
                      AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'S'
                      AND CCL.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
                      AND UM.TIPO = 'S'
                      AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL
                      AND LCP.ID_MOTIVO_LAVORAZIONE =
                             PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV ('AS');
            ELSE
               nSupOre := 0;
            END IF;

            nCarbLavPot := nCarbLavPot + recLavCpPot.TOT_LIT_LAV + nSupOre;
         END LOOP;
      END LOOP;

      P_CARB_AUMENTO_SUP := CEIL (nPotMaxTot + nCarbLavPot);

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_MSGERR := 'ERRORE TOTALE CARBURANTE_MACCHINA: ' || SQLERRM;
         P_CODERR := SQLCODE;
         RETURN FALSE;
   END TOTALE_CARB_AUMENTO_SUP;

   PROCEDURE CALCOLO_ASSEGNAZIONE_SUPPL (
      P_ID_DOMANDA_ASSEGNAZIONE       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE             DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO            DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_ID_UTENTE                     DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
      P_MSGERR                    OUT VARCHAR2,
      P_CODERR                    OUT VARCHAR2)
   IS
      SCARTO                         EXCEPTION;
      nAnnoRiferimento               NUMBER (4);
      nIdDittaUma                    NUMBER (10);
      nIdAzienda                     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE;
      nIdConsistenza                 DB_DOMANDA_ASSEGNAZIONE.EXT_ID_CONSISTENZA%TYPE;
      recTDatiDitta                  DB_DATI_DITTA%ROWTYPE;
      dDataRif                       DATE;
      nCarburanteLavorazione         NUMBER := 0;
      nCarburanteMietitrebb          NUMBER := 0;
      nCarburanteEssicazione         NUMBER := 0;
      nAnnoUmlc                      NUMBER;
      nCarburanteColtSec             NUMBER := 0;
      nFramm                         NUMBER := 0;
      nContLav                       PLS_INTEGER;
      nSupOre                        NUMBER := 0;
      nCarbLavEcc                    NUMBER := 0;
      nCarbLavorazioneBase           DB_DETTAGLIO_CALCOLO.CARBURANTE_LAVORAZIONE%TYPE
         := 0;
      nCarbMacchineBase              DB_DETTAGLIO_CALCOLO.CARBURANTE_MACCHINE%TYPE
                                        := 0;
      nCarbAllevamentoBase           DB_DETTAGLIO_CALCOLO.CARBURANTE_ALLEVAMENTO%TYPE
         := 0;
      nCarburanteAllevamento         NUMBER := 0;
      nCarburanteMacchina            NUMBER := 0;
      nCarbAumentoSup                NUMBER := 0;
      nTotCarbColturaAllev           DB_DETTAGLIO_CALCOLO.TOT_CARB_COLTURA_ALLEV%TYPE
         := 0;
      nMaxAssParziale                NUMBER := 0;
      nTotaleContoProprio            DB_DETTAGLIO_CALCOLO.TOTALE_CONTO_PROPRIO%TYPE
                                        := 0;
      nCarburanteSerra               NUMBER := 0;
      nCarbSerraBase                 NUMBER := 0;
      nTotaleSerra                   DB_DETTAGLIO_CALCOLO.TOTALE_SERRA%TYPE := 0;
      nCarburanteRiscaldamento       DB_DETTAGLIO_CALCOLO.CARBURANTE_RISCALDAMENTO%TYPE
         := 0;
      nComodo                        NUMBER := 0;
      nMaxContoProprio               DB_DETTAGLIO_CALCOLO.MAX_CONTO_PROPRIO%TYPE
                                        := 0;
      nAumentoCarbMietitrebbiatura   NUMBER := 0;
      nAumentoCarbEssicazione        NUMBER := 0;
      nCarburanteAllevamentoTab      DB_DETTAGLIO_CALCOLO.CARBURANTE_ALLEVAMENTO%TYPE
         := 0;
      nCarburanteMacchinaTab         DB_DETTAGLIO_CALCOLO.CARBURANTE_MACCHINE%TYPE
         := 0;
      nCarbMietitrebbiatura          NUMBER := 0;
      nCarbEssicazione               NUMBER := 0;
      nCarbMietitrebbiaturaBase      NUMBER := 0;
      nCarbEssicazioneBase           NUMBER := 0;
   BEGIN
      SELECT TO_NUMBER (VALORE)
        INTO nAnnoUmlc
        FROM DB_PARAMETRO
       WHERE ID_PARAMETRO = 'UMLC';

      SELECT TO_NUMBER (REPLACE (VALORE, '.', ','))
        INTO nFramm
        FROM DB_PARAMETRO
       WHERE ID_PARAMETRO = 'UMFR';

      SELECT NVL (SUM (CARBURANTE_MIETITREBBIATURA), 0),
             NVL (SUM (CARBURANTE_ESSICAZIONE), 0)
        INTO nCarbMietitrebbiatura, nCarbEssicazione
        FROM DB_CARBURANTE_COLTURA CC, DB_COLTURA_PRATICATA CP
       WHERE     CC.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND CC.TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (CC.NUMERO_SUPPLEMENTO, 0) =
                    NVL (P_NUMERO_SUPPLEMENTO, 0)
             AND CP.ID_COLTURA_PRATICATA = CC.ID_COLTURA_PRATICATA;

      SELECT NVL (SUM (CARBURANTE_MIETITREBBIATURA), 0),
             NVL (SUM (CARBURANTE_ESSICAZIONE), 0)
        INTO nCarbMietitrebbiaturaBase, nCarbEssicazioneBase
        FROM DB_CARBURANTE_COLTURA CC, DB_COLTURA_PRATICATA CP
       WHERE     CC.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND CC.TIPO_ASSEGNAZIONE = 'B'
             AND CC.NUMERO_SUPPLEMENTO IS NULL
             AND CP.ID_COLTURA_PRATICATA = CC.ID_COLTURA_PRATICATA
             AND CP.FLAG_COLTURA_SECONDARIA = 'N';

      -- spostato reperimento dell'anno di riferimento in testa
      IF NOT REPERISCI_ANNO_RIFERIMENTO (P_ID_DOMANDA_ASSEGNAZIONE,
                                         nAnnoRiferimento,
                                         nIdDittaUma,
                                         nIdAzienda,
                                         nIdConsistenza,
                                         dDataRif,
                                         P_MSGERR,
                                         P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      -- mi cerco su DB_DATI_DITTA la data della ricevuta del documento
      -- di assegnazione
      recTDatiDitta :=
         SelectTDatiDittaByIdDomAssegn (P_ID_DOMANDA_ASSEGNAZIONE);

      -- se l'azienda è un consorzio il calcolo del quantitativo massimo assegnabile
      -- per conto proprio è molto semplice
      IF IsAziendaConsorzio (nIdAzienda)
      THEN
         nCarburanteLavorazione := 0;
         nCarburanteMietitrebb := 0;
         nCarburanteEssicazione := 0;
      ELSE
         IF NOT TOTALE_CARBURANTE_COLTURA (P_ID_DOMANDA_ASSEGNAZIONE,
                                           nAnnoUmlc,
                                           nIdDittaUma,
                                           dDataRif,
                                           P_TIPO_ASSEGNAZIONE,
                                           P_NUMERO_SUPPLEMENTO,
                                           'S',
                                           'CS',
                                           nCarburanteColtSec,
                                           nCarburanteMietitrebb,
                                           nCarburanteEssicazione,
                                           P_MSGERR,
                                           P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         -- Calcolo carburante lavorazioni oltre la potenzialità caricate su ditta Uma
         FOR recLavCpPot
            IN (  SELECT LCP.ID_CATEGORIA_UTILIZZO_UMA,
                         NVL (SUM (LCP.TOT_LITRI_LAVORAZIONE), 0) TOT_LIT_LAV
                    FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                         DB_CATEG_COLTURA_LAVORAZIONI CCL
                   WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                                CCL.ID_CATEGORIA_UTILIZZO_UMA
                         AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                         AND LCP.ID_DITTA_UMA = nIdDittaUma
                         AND LCP.ANNO_CAMPAGNA =
                                TO_NUMBER (TO_CHAR (dDataRif, 'YYYY'))
                         AND LCP.DATA_FINE_VALIDITA IS NULL
                         AND LCP.DATA_CESSAZIONE IS NULL
                         AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                         AND CCL.DATA_FINE_VALIDITA IS NULL
                         --AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'S'
                         AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                         AND LCP.ID_MOTIVO_LAVORAZIONE =
                                PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV (
                                   'LE')
                GROUP BY LCP.ID_CATEGORIA_UTILIZZO_UMA)
         LOOP
            SELECT COUNT (*)
              INTO nContLav
              FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                   DB_CATEG_COLTURA_LAVORAZIONI CCL
             WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                          recLavCpPot.ID_CATEGORIA_UTILIZZO_UMA
                   AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                          CCL.ID_CATEGORIA_UTILIZZO_UMA
                   AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                   AND LCP.ID_DITTA_UMA = nIdDittaUma
                   AND LCP.ANNO_CAMPAGNA =
                          TO_NUMBER (TO_CHAR (dDataRif, 'YYYY'))
                   AND LCP.DATA_FINE_VALIDITA IS NULL
                   AND LCP.DATA_CESSAZIONE IS NULL
                   AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                   AND CCL.DATA_FINE_VALIDITA IS NULL
                   --AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'N'
                   AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                   AND LCP.ID_MOTIVO_LAVORAZIONE IN
                          (PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV ('LB'),
                           PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV ('CS'));

            IF nContLav = 0
            THEN
               SELECT NVL (MIN (LCP.SUP_ORE), 0) * nFramm
                 INTO nSupOre
                 FROM DB_LAVORAZIONE_CONTO_PROPRIO LCP,
                      DB_CATEG_COLTURA_LAVORAZIONI CCL,
                      DB_UNITA_MISURA UM
                WHERE     LCP.ID_CATEGORIA_UTILIZZO_UMA =
                             recLavCpPot.ID_CATEGORIA_UTILIZZO_UMA
                      AND LCP.ID_CATEGORIA_UTILIZZO_UMA =
                             CCL.ID_CATEGORIA_UTILIZZO_UMA
                      AND LCP.ID_LAVORAZIONI = CCL.ID_LAVORAZIONI
                      AND LCP.ID_DITTA_UMA = nIdDittaUma
                      AND LCP.ANNO_CAMPAGNA =
                             TO_NUMBER (TO_CHAR (dDataRif, 'YYYY'))
                      AND LCP.DATA_FINE_VALIDITA IS NULL
                      AND LCP.DATA_CESSAZIONE IS NULL
                      AND CCL.ID_TIPO_COLTURA_LAVORAZIONE = 2
                      AND CCL.DATA_FINE_VALIDITA IS NULL
                      --AND CCL.INCREMENTO_OLTRE_POTENZIALITA = 'S'
                      AND CCL.ID_UNITA_MISURA = UM.ID_UNITA_MISURA
                      AND UM.TIPO = 'S'
                      AND LCP.ID_ASSEGNAZIONE_CARBURANTE IS NULL 
                      AND LCP.ID_MOTIVO_LAVORAZIONE =
                             PCK_SMRUMA_CARICA_LAVORAZ_CP.RETURNMOTLAV ('LE');
            ELSE
               nSupOre := 0;
            END IF;

            nCarbLavEcc := nCarbLavEcc + recLavCpPot.TOT_LIT_LAV + nSupOre;
         END LOOP;

         SELECT DC.CARBURANTE_LAVORAZIONE,
                DC.CARBURANTE_MACCHINE,
                DC.CARBURANTE_ALLEVAMENTO
           INTO nCarbLavorazioneBase, nCarbMacchineBase, nCarbAllevamentoBase
           FROM DB_DETTAGLIO_CALCOLO DC
          WHERE     DC.ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
                AND DC.TIPO_ASSEGNAZIONE = 'B'
                AND DC.NUMERO_SUPPLEMENTO IS NULL;

         IF NOT TOTALE_CARBURANTE_ALLEVAMENTO (P_ID_DOMANDA_ASSEGNAZIONE,
                                               P_TIPO_ASSEGNAZIONE,
                                               P_NUMERO_SUPPLEMENTO,
                                               nCarburanteAllevamento,
                                               P_MSGERR,
                                               P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         IF NOT TOTALE_CARBURANTE_MACCHINA (P_ID_DOMANDA_ASSEGNAZIONE,
                                            P_TIPO_ASSEGNAZIONE,
                                            P_NUMERO_SUPPLEMENTO,
                                            nCarburanteMacchina,
                                            P_MSGERR,
                                            P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         IF NOT TOTALE_CARB_AUMENTO_SUP (P_ID_DOMANDA_ASSEGNAZIONE,
                                         P_TIPO_ASSEGNAZIONE,
                                         P_NUMERO_SUPPLEMENTO,
                                         nIdDittaUma,
                                         dDataRif,
                                         nCarbAumentoSup,
                                         nAumentoCarbMietitrebbiatura,
                                         nAumentoCarbEssicazione,
                                         P_MSGERR,
                                         P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

         nTotCarbColturaAllev :=
            (  nCarbLavorazioneBase
             + nCarbAumentoSup
             + nCarburanteAllevamento
             + nCarburanteColtSec);
         nCarburanteAllevamentoTab :=
            (nCarburanteAllevamento - nCarbAllevamentoBase);
         nCarburanteMacchinaTab := (nCarburanteMacchina - nCarbMacchineBase);

         IF nCarburanteAllevamentoTab <= 0
         THEN
            nCarburanteAllevamentoTab := 0;
         END IF;

         IF nCarburanteMacchinaTab <= 0
         THEN
            nCarburanteMacchinaTab := 0;
         END IF;

         IF nTotCarbColturaAllev <=
               (  nCarburanteMacchina
                + nCarbEssicazione
                + nCarbMietitrebbiatura)
         THEN
            IF nCarburanteAllevamentoTab > 0
            THEN
               nMaxAssParziale :=
                    nCarbAumentoSup
                  + nCarburanteAllevamentoTab
                  + nCarburanteColtSec;
            ELSE
               nCarburanteAllevamentoTab := 0;
               nMaxAssParziale := nCarbAumentoSup + nCarburanteColtSec;
            END IF;

            IF   (nCarbLavorazioneBase + nCarbAllevamentoBase)
               - nCarbMacchineBase > 0
            THEN
               nMaxAssParziale :=
                    nMaxAssParziale
                  + (nCarbLavorazioneBase + nCarbAllevamentoBase)
                  - nCarbMacchineBase;
            END IF;
         ELSE
            IF nCarburanteMacchinaTab > 0
            THEN
               nMaxAssParziale := nCarburanteMacchinaTab;
            ELSE
               nMaxAssParziale := 0;
               nCarburanteMacchinaTab := 0;
            END IF;

            IF (nCarbEssicazione - nCarbEssicazioneBase) > 0
            THEN
               nMaxAssParziale :=
                  nMaxAssParziale + (nCarbEssicazione - nCarbEssicazioneBase);
            END IF;

            IF (nCarbMietitrebbiatura - nCarbMietitrebbiaturaBase) > 0
            THEN
               nMaxAssParziale :=
                    nMaxAssParziale
                  + (nCarbMietitrebbiatura - nCarbMietitrebbiaturaBase);
            END IF;

            IF   nCarbMacchineBase
               - (nCarbLavorazioneBase + nCarbAllevamentoBase) > 0
            THEN
               nMaxAssParziale :=
                    nMaxAssParziale
                  + nCarbMacchineBase
                  - (nCarbLavorazioneBase + nCarbAllevamentoBase);
            END IF;
         END IF;

         nMaxContoProprio := nMaxAssParziale + nCarbLavEcc;
      END IF;

      nComodo := (NVL (nMaxContoProprio, 0) + 4.99) / 10;
      nComodo := ROUND (nComodo, 0);
      nTotaleContoProprio := nComodo * 10;

      IF NOT TOTALE_CARBURANTE_SERRA (P_ID_DOMANDA_ASSEGNAZIONE,
                                      P_TIPO_ASSEGNAZIONE,
                                      P_NUMERO_SUPPLEMENTO,
                                      nCarburanteSerra,
                                      P_MSGERR,
                                      P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      IF NOT TOTALE_CARBURANTE_SERRA (P_ID_DOMANDA_ASSEGNAZIONE,
                                      'B',
                                      NULL,
                                      nCarbSerraBase,
                                      P_MSGERR,
                                      P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      IF (nCarburanteSerra - nCarbSerraBase) > 0
      THEN
         nCarburanteRiscaldamento := (nCarburanteSerra - nCarbSerraBase);
      ELSE
         nCarburanteRiscaldamento := 0;
      END IF;

      nComodo := (NVL (nCarburanteRiscaldamento, 0) + 4.99) / 10;
      nComodo := ROUND (nComodo, 0);
      nTotaleSerra := nComodo * 10;

      DELETE DB_DETTAGLIO_CALCOLO
       WHERE     ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (NUMERO_SUPPLEMENTO, 0) = NVL (P_NUMERO_SUPPLEMENTO, 0);

      INSERT INTO DB_DETTAGLIO_CALCOLO (ID_DETTAGLIO_CALCOLO,
                                        ID_DOMANDA_ASSEGNAZIONE,
                                        TIPO_ASSEGNAZIONE,
                                        NUMERO_SUPPLEMENTO,
                                        DATA_DECORRENZA,
                                        CARBURANTE_LAVORAZIONE,
                                        CARBURANTE_ASSERVIMENTO,
                                        CARBURANTE_ALLEVAMENTO,
                                        TOT_CARB_COLTURA_ALLEV,
                                        CARBURANTE_MACCHINE,
                                        QUANTITATIVO_MASSIMO,
                                        CARBURANTE_MIETITREBB,
                                        CARBURANTE_ESSICAZIONE,
                                        MAX_CONTO_PROPRIO,
                                        MAX_CONTO_PROPRIO_RIDOTTO,
                                        PERCENTUALE_RIDUZIONE,
                                        DECURTAZIONE_LAV_BENZINA,
                                        DECURTAZIONE_LAV_GASOLIO,
                                        TOTALE_CONTO_PROPRIO,
                                        CARBURANTE_RISCALDAMENTO,
                                        TOTALE_SERRA,
                                        ALTRE_MACCHINE_DITTA_FORZATA,
                                        DATA_AGGIORNAMENTO,
                                        EXT_ID_UTENTE_AGGIORNAMENTO,
                                        TOTALE_CONTO_TERZI,
                                        CARB_LAVORAZ_AUMENTO,
                                        CARB_LAVORAZ_COLT_SEC,
                                        CARB_LAVORAZ_ECCEZ,
                                        CARB_LAVORAZIONI_BASE,
                                        CARB_AUMENTO_ALLEVAMENTO,
                                        CARB_AUMENTO_MACCHINE,
                                        CARB_AUMENTO_RISCALDAMENTO,
                                        CARBURANTE_LAV_CT_DA_CP,
                                        ASSEGNATO_PREC_CONTO_TERZI,
                                        CARBURANTE_CONTO_TERZI_LAV,
                                        MAX_CONTO_TERZI)
           VALUES (SEQ_DB_DETTAGLIO_CALCOLO.NEXTVAL,
                   P_ID_DOMANDA_ASSEGNAZIONE,
                   P_TIPO_ASSEGNAZIONE,
                   P_NUMERO_SUPPLEMENTO,
                   NULL,
                   0,
                   0,
                   nCarburanteAllevamento,
                   nTotCarbColturaAllev,
                   nCarburanteMacchina,
                   nMaxAssParziale,
                   nAumentoCarbMietitrebbiatura,
                   nAumentoCarbEssicazione,
                   nMaxContoProprio,
                   0,
                   0,
                   0,
                   0,
                   nTotaleContoProprio,
                   nCarburanteSerra,
                   nTotaleSerra,
                   'N',
                   SYSDATE,
                   P_ID_UTENTE,
                   0,
                   nCarbAumentoSup,
                   nCarburanteColtSec,
                   nCarbLavEcc,
                   nCarbLavorazioneBase,
                   nCarburanteAllevamentoTab,
                   nCarburanteMacchinaTab,
                   nCarburanteRiscaldamento,
                   0,
                   0,
                   0,
                   0);
   EXCEPTION
      WHEN SCARTO
      THEN
         NULL;
      WHEN OTHERS
      THEN
         P_CODERR := SQLCODE;
         P_MSGERR := 'Errore generico ' || SQLERRM;
   END CALCOLO_ASSEGNAZIONE_SUPPL;


   PROCEDURE CALCOLO_ASSEGNAZIONE_MAGG (
      P_ID_DOMANDA_ASSEGNAZIONE       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      P_TIPO_ASSEGNAZIONE             DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      P_NUMERO_SUPPLEMENTO            DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      P_ID_UTENTE                     DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
      P_MSGERR                    OUT VARCHAR2,
      P_CODERR                    OUT VARCHAR2)
   IS
      SCARTO                         EXCEPTION;
      nAnnoRiferimento               NUMBER (4);
      nIdDittaUma                    NUMBER (10);
      nIdAzienda                     DB_DITTA_UMA.EXT_ID_AZIENDA%TYPE;
      nIdConsistenza                 DB_DOMANDA_ASSEGNAZIONE.EXT_ID_CONSISTENZA%TYPE;
      recTDatiDitta                  DB_DATI_DITTA%ROWTYPE;
      dDataRif                       DATE;
      nCarburanteMacchina            NUMBER := 0;

      nPercContoPropio               DB_CAMPAGNA_MAGGIORAZIONE.PERCENTUALE_CONTO_PROPRIO%TYPE    := 0; 
      nPercContoTerzi                DB_CAMPAGNA_MAGGIORAZIONE.PERCENTUALE_CONTO_TERZI%TYPE      := 0; 
      nPercSerre                     DB_CAMPAGNA_MAGGIORAZIONE.PERCENTUALE_SERRE%TYPE            := 0; 
      nAssegnContoProprio            DB_QUANTITA_ASSEGNATA.ASSEGNAZIONE_CONTO_PROPRIO%TYPE       := 0;
      nAssegnContoTerzi              DB_QUANTITA_ASSEGNATA.ASSEGNAZIONE_CONTO_TERZI%TYPE         := 0;
      nAssegnSerre                   DB_QUANTITA_ASSEGNATA.ASSEGNAZIONE_SERRA%TYPE               := 0;
      nMaggContoProprio              DB_QUANTITA_ASSEGNATA.ASSEGNAZIONE_CONTO_PROPRIO%TYPE       := 0;
      nMaggContoTerzi                DB_QUANTITA_ASSEGNATA.ASSEGNAZIONE_CONTO_TERZI%TYPE         := 0;
      nMaggSerre                     DB_QUANTITA_ASSEGNATA.ASSEGNAZIONE_SERRA%TYPE               := 0;
   BEGIN

      -- spostato reperimento dell'anno di riferimento in testa
      IF NOT REPERISCI_ANNO_RIFERIMENTO (P_ID_DOMANDA_ASSEGNAZIONE,
                                         nAnnoRiferimento,
                                         nIdDittaUma,
                                         nIdAzienda,
                                         nIdConsistenza,
                                         dDataRif,
                                         P_MSGERR,
                                         P_CODERR)
      THEN
         RAISE SCARTO;
      END IF;

      -- mi cerco su DB_DATI_DITTA la data della ricevuta del documento
      -- di assegnazione
      recTDatiDitta :=
         SelectTDatiDittaByIdDomAssegn (P_ID_DOMANDA_ASSEGNAZIONE);

         IF NOT TOTALE_CARBURANTE_MACCHINA (P_ID_DOMANDA_ASSEGNAZIONE,
                                            P_TIPO_ASSEGNAZIONE,
                                            P_NUMERO_SUPPLEMENTO,
                                            nCarburanteMacchina,
                                            P_MSGERR,
                                            P_CODERR)
         THEN
            RAISE SCARTO;
         END IF;

      select percentuale_conto_proprio, percentuale_conto_terzi, percentuale_serre
      into nPercContoPropio, nPercContoTerzi, nPercSerre
      from db_campagna_maggiorazione
      where sysdate between data_inizio_val and data_fine_val;

      select sum(assegnazione_conto_proprio), sum(assegnazione_conto_terzi), sum(assegnazione_serra) 
      into nAssegnContoProprio, nAssegnContoTerzi, nAssegnSerre 
      from smruma.db_domanda_assegnazione dom
      join smruma.db_assegnazione_carburante ass on ass.id_domanda_assegnazione = dom.id_domanda_assegnazione
      join smruma.db_quantita_assegnata qa on qa.id_assegnazione_carburante = ass.id_assegnazione_carburante
      where dom.id_stato_domanda in (30)
      and   ( ass.tipo_assegnazione = 'B' or (ass.tipo_assegnazione = 'S' and ass.id_stato_domanda = 30) )
      and   to_char(dom.data_riferimento, 'YYYY') = to_char(sysdate, 'YYYY')
      and   dom.id_ditta_uma = nIdDittaUma ;

      nMaggContoProprio := round(nAssegnContoProprio*nPercContoPropio/100, 0);
      nMaggContoTerzi := round(nAssegnContoTerzi*nPercContoTerzi/100, 0);
      nMaggSerre := round(nAssegnSerre*nPercSerre/100, 0);
    
      DELETE DB_DETTAGLIO_CALCOLO
       WHERE     ID_DOMANDA_ASSEGNAZIONE = P_ID_DOMANDA_ASSEGNAZIONE
             AND TIPO_ASSEGNAZIONE = P_TIPO_ASSEGNAZIONE
             AND NVL (NUMERO_SUPPLEMENTO, 0) = NVL (P_NUMERO_SUPPLEMENTO, 0);

      INSERT INTO DB_DETTAGLIO_CALCOLO (ID_DETTAGLIO_CALCOLO,
                                        ID_DOMANDA_ASSEGNAZIONE,
                                        TIPO_ASSEGNAZIONE,
                                        NUMERO_SUPPLEMENTO,
                                        DATA_DECORRENZA,
                                        CARBURANTE_LAVORAZIONE,
                                        CARBURANTE_ASSERVIMENTO,
                                        CARBURANTE_ALLEVAMENTO,
                                        TOT_CARB_COLTURA_ALLEV,
                                        CARBURANTE_MACCHINE,
                                        QUANTITATIVO_MASSIMO,
                                        CARBURANTE_MIETITREBB,
                                        CARBURANTE_ESSICAZIONE,
                                        MAX_CONTO_PROPRIO,
                                        MAX_CONTO_PROPRIO_RIDOTTO,
                                        PERCENTUALE_RIDUZIONE,
                                        DECURTAZIONE_LAV_BENZINA,
                                        DECURTAZIONE_LAV_GASOLIO,
                                        TOTALE_CONTO_PROPRIO,
                                        CARBURANTE_RISCALDAMENTO,
                                        TOTALE_SERRA,
                                        ALTRE_MACCHINE_DITTA_FORZATA,
                                        DATA_AGGIORNAMENTO,
                                        EXT_ID_UTENTE_AGGIORNAMENTO,
                                        TOTALE_CONTO_TERZI,
                                        CARB_LAVORAZ_AUMENTO,
                                        CARB_LAVORAZ_COLT_SEC,
                                        CARB_LAVORAZ_ECCEZ,
                                        CARB_LAVORAZIONI_BASE,
                                        CARB_AUMENTO_ALLEVAMENTO,
                                        CARB_AUMENTO_MACCHINE,
                                        CARB_AUMENTO_RISCALDAMENTO,
                                        CARBURANTE_LAV_CT_DA_CP,
                                        ASSEGNATO_PREC_CONTO_TERZI,
                                        CARBURANTE_CONTO_TERZI_LAV,
                                        MAX_CONTO_TERZI)
           VALUES (SEQ_DB_DETTAGLIO_CALCOLO.NEXTVAL,
                   P_ID_DOMANDA_ASSEGNAZIONE,
                   P_TIPO_ASSEGNAZIONE,
                   P_NUMERO_SUPPLEMENTO,
                   NULL,
                   nMaggContoProprio,  
                   0,
                   0, 
                   nMaggContoProprio, 
                   nCarburanteMacchina,
                   nMaggContoProprio, 
                   0, 
                   0, 
                   nMaggContoProprio, 
                   0,
                   0,
                   0,
                   0,
                   nMaggContoProprio, 
                   nMaggSerre, 
                   nMaggSerre, 
                   'N',
                   SYSDATE,
                   P_ID_UTENTE,
                   nMaggContoTerzi, 
                   0, 
                   0, 
                   nMaggContoTerzi, 
                   nMaggContoProprio, 
                   0, 
                   0, 
                   nMaggSerre, 
                   0,
                   0,
                   0,
                   nMaggContoTerzi 
                   );
   EXCEPTION
      WHEN SCARTO
      THEN
         NULL;
      WHEN OTHERS
      THEN
         P_CODERR := SQLCODE;
         P_MSGERR := 'Errore generico ' || SQLERRM;
   END CALCOLO_ASSEGNAZIONE_MAGG;


   PROCEDURE CALCOLO_ASSEGNAZIONE_ACCONTO (
      pIdDomandaAssegnazione       DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE,
      pTipoAssegnazione            DB_DOMANDA_ASSEGNAZIONE.TIPO_DOMANDA%TYPE,
      pNumeroSupplemento           DB_ASSEGNAZIONE_CARBURANTE.NUMERO_SUPPLEMENTO%TYPE,
      pIdUtente                    DB_DETTAGLIO_CALCOLO.EXT_ID_UTENTE_AGGIORNAMENTO%TYPE,
      pMsgErr                  OUT VARCHAR2,
      pCodErr                  OUT VARCHAR2)
   IS
      nIdDittaUma                     DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE;
      nIdDomandaAssegnazionePrec      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
      nTotaleContoProprio             DB_DETTAGLIO_CALCOLO.TOTALE_CONTO_PROPRIO%TYPE
         := 0;
      nTotaleContoTerzi               DB_DETTAGLIO_CALCOLO.TOTALE_CONTO_TERZI%TYPE
         := 0;
      nTotaleSerra                    DB_DETTAGLIO_CALCOLO.TOTALE_SERRA%TYPE
                                         := 0;
      nMaxAssegnabile                 NUMBER;
      nIdConduzione                   DB_DATI_DITTA.ID_CONDUZIONE%TYPE;
      nCont                           SIMPLE_INTEGER := 0;
      nConsumoContoProprio            NUMBER := 0;
      nConsumoContoTerzi              NUMBER := 0;
      nConsumoSerra                   NUMBER := 0;
      nAssegnazioneContoProprio       NUMBER := 0;
      nAssegnazioneContoTerzi         NUMBER := 0;
      nAssegnazioneSerra              NUMBER := 0;
      nRimanenzaContoProprio          NUMBER := 0;
      nRimanenzaContoTerzi            NUMBER := 0;
      nRimanenzaSerra                 NUMBER := 0;
      nPercRiduzioneContoProprio      NUMBER := 0;
      nPercRiduzioneContoTerzi        NUMBER := 0;
      nPercRiduzioneSerra             NUMBER := 0;
      nPercRiduzioneDitteNoPrelievi   NUMBER := 0;
   BEGIN
      pCodErr := NULL;
      pMsgErr := '';

      SELECT ID_DITTA_UMA
        INTO nIdDittaUma
        FROM DB_DOMANDA_ASSEGNAZIONE
       WHERE ID_DOMANDA_ASSEGNAZIONE = pIdDomandaAssegnazione;

      SELECT MAX (ID_DOMANDA_ASSEGNAZIONE)
        INTO nIdDomandaAssegnazionePrec
        FROM DB_DOMANDA_ASSEGNAZIONE
       WHERE     ID_DOMANDA_ASSEGNAZIONE < pIdDomandaAssegnazione
             AND ID_DITTA_UMA = nIdDittaUma
             AND TIPO_DOMANDA IN ('A', 'B')
             AND ID_STATO_DOMANDA IN (30, 35);

      IF nIdDomandaAssegnazionePrec IS NULL
      THEN
         SELECT TO_NUMBER (VALORE)
           INTO nMaxAssegnabile
           FROM DB_TIPO_PARAMETRO
          WHERE COD_PARAMETRO = 'UMAM' AND DATA_FINE_VALIDITA IS NULL;

         SELECT ID_CONDUZIONE
           INTO nIdConduzione
           FROM DB_DATI_DITTA
          WHERE ID_DITTA_UMA = nIdDittaUma AND DATA_FINE_VALIDITA IS NULL;

         -- Conto Proprio o Conto Proprio e Terzi
         IF nIdConduzione IN (1, 3)
         THEN
            IF IsUtentePA (pIdUtente)
            THEN
               nTotaleContoProprio := nMaxAssegnabile;
            ELSE
               nTotaleContoProprio := 0;
            END IF;
         END IF;

         -- Conto Terzi o Conto Proprio e Terzi
         IF nIdConduzione IN (2, 3)
         THEN
            IF IsUtentePA (pIdUtente)
            THEN
               nTotaleContoTerzi := nMaxAssegnabile;
            ELSE
               nTotaleContoTerzi := 0;
            END IF;
         END IF;

         SELECT COUNT (*)
           INTO nCont
           FROM DB_SERRA
          WHERE ID_DITTA_UMA = nIdDittaUma AND DATA_CARICO IS NULL;

         IF nCont != 0
         THEN
            IF IsUtentePA (pIdUtente)
            THEN
               nTotaleSerra := nMaxAssegnabile;
            ELSE
               nTotaleSerra := 0;
            END IF;
         END IF;
      ELSE
         SELECT COUNT (*)
           INTO nCont
           FROM DB_PRELIEVO P,
                DB_DOMANDA_ASSEGNAZIONE DA,
                DB_BUONO_CARBURANTE BC,
                DB_BUONO_PRELIEVO BP,
                NEWMA_R_STATO_PRELIEVO SP,
                NEWMA_D_CAUSALE_STATO CS
          WHERE     DA.ID_DITTA_UMA = nIdDittaUma
                AND DA.ID_STATO_DOMANDA != 40
                AND BP.ANNO_RIFERIMENTO =
                       (SELECT TO_NUMBER (TO_CHAR (DATA_RIFERIMENTO, 'YYYY'))
                          FROM DB_DOMANDA_ASSEGNAZIONE
                         WHERE ID_DOMANDA_ASSEGNAZIONE =
                                  nIdDomandaAssegnazionePrec)
                AND BP.ANNULLATO IS NULL
                AND P.QUANTITA_PRELEVATA > 0
                AND SP.DATA_FINE_VALIDITA IS NULL
                AND CS.ID_CODICE_STATO_PRELIEVO != 40
                AND BC.ID_BUONO_CARBURANTE = P.ID_BUONO_CARBURANTE
                AND BP.ID_BUONO_PRELIEVO = BC.ID_BUONO_PRELIEVO
                AND DA.ID_DOMANDA_ASSEGNAZIONE = BP.ID_DOMANDA_ASSEGNAZIONE
                AND P.ID_PRELIEVO = SP.ID_PRELIEVO
                AND CS.ID_CAUSALE_STATO = SP.ID_CAUSALE_STATO;

         SELECT NVL (SUM (NVL (CONSUMO_CONTO_PROPRIO, 0)), 0),
                NVL (SUM (NVL (CONSUMO_CONTO_TERZI, 0)), 0),
                NVL (SUM (NVL (CONSUMO_SERRA, 0)), 0)
           INTO nConsumoContoProprio, nConsumoContoTerzi, nConsumoSerra
           FROM DB_CONSUMO_RIMANENZA
          WHERE ID_DOMANDA_ASSEGNAZIONE = pIdDomandaAssegnazione;

         SELECT NVL (SUM (NVL (ASSEGNAZIONE_CONTO_PROPRIO, 0)), 0),
                NVL (SUM (NVL (ASSEGNAZIONE_CONTO_TERZI, 0)), 0),
                NVL (SUM (NVL (ASSEGNAZIONE_SERRA, 0)), 0)
           INTO nAssegnazioneContoProprio,
                nAssegnazioneContoTerzi,
                nAssegnazioneSerra
           FROM DB_QUANTITA_ASSEGNATA QA, DB_ASSEGNAZIONE_CARBURANTE AC
          WHERE     AC.ID_DOMANDA_ASSEGNAZIONE = nIdDomandaAssegnazionePrec
                AND AC.TIPO_ASSEGNAZIONE != 'S'
                AND AC.ANNULLATO IS NULL
                AND AC.ID_ASSEGNAZIONE_CARBURANTE =
                       QA.ID_ASSEGNAZIONE_CARBURANTE;

         SELECT NVL (SUM (NVL (RIMANENZA_CONTO_PROPRIO, 0)), 0),
                NVL (SUM (NVL (RIMANENZA_CONTO_TERZI, 0)), 0),
                NVL (SUM (NVL (RIMANENZA_SERRA, 0)), 0)
           INTO nRimanenzaContoProprio, nRimanenzaContoTerzi, nRimanenzaSerra
           FROM DB_CONSUMO_RIMANENZA
          WHERE ID_DOMANDA_ASSEGNAZIONE = nIdDomandaAssegnazionePrec;

         IF nCont != 0
         THEN
            SELECT TO_NUMBER (VALORE)
              INTO nPercRiduzioneContoProprio
              FROM DB_TIPO_PARAMETRO
             WHERE COD_PARAMETRO = 'PRAC' AND DATA_FINE_VALIDITA IS NULL;

            SELECT TO_NUMBER (VALORE)
              INTO nPercRiduzioneContoTerzi
              FROM DB_TIPO_PARAMETRO
             WHERE COD_PARAMETRO = 'PRAT' AND DATA_FINE_VALIDITA IS NULL;

            SELECT TO_NUMBER (VALORE)
              INTO nPercRiduzioneSerra
              FROM DB_TIPO_PARAMETRO
             WHERE COD_PARAMETRO = 'PRAS' AND DATA_FINE_VALIDITA IS NULL;
         ELSE
            SELECT TO_NUMBER (VALORE)
              INTO nPercRiduzioneDitteNoPrelievi
              FROM DB_TIPO_PARAMETRO
             WHERE COD_PARAMETRO = 'PRAP' AND DATA_FINE_VALIDITA IS NULL;

            nPercRiduzioneContoProprio := nPercRiduzioneDitteNoPrelievi;
            nPercRiduzioneContoTerzi := nPercRiduzioneDitteNoPrelievi;
            nPercRiduzioneSerra := nPercRiduzioneDitteNoPrelievi;
         END IF;

         IF nCont != 0 OR nConsumoContoProprio > 0
         THEN
            nTotaleContoProprio :=
                 LEAST (nConsumoContoProprio,
                        (nAssegnazioneContoProprio + nRimanenzaContoProprio))
               - (  LEAST (
                       nConsumoContoProprio,
                       (nAssegnazioneContoProprio + nRimanenzaContoProprio))
                  * nPercRiduzioneContoProprio
                  / 100);
         ELSE
            IF IsUtentePA (pIdUtente)
            THEN
               nTotaleContoProprio :=
                    (nAssegnazioneContoProprio + nRimanenzaContoProprio)
                  - (  (nAssegnazioneContoProprio + nRimanenzaContoProprio)
                     * nPercRiduzioneContoProprio
                     / 100);
            ELSE
               nTotaleContoProprio := 0;
            END IF;
         END IF;

         IF nCont != 0 OR nConsumoContoTerzi > 0
         THEN
            nTotaleContoTerzi :=
                 LEAST (nConsumoContoTerzi,
                        (nAssegnazioneContoTerzi + nRimanenzaContoTerzi))
               - (  LEAST (nConsumoContoTerzi,
                           (nAssegnazioneContoTerzi + nRimanenzaContoTerzi))
                  * nPercRiduzioneContoTerzi
                  / 100);
         ELSE
            IF IsUtentePA (pIdUtente)
            THEN
               nTotaleContoTerzi :=
                    (nAssegnazioneContoTerzi + nRimanenzaContoTerzi)
                  - (  (nAssegnazioneContoTerzi + nRimanenzaContoTerzi)
                     * nPercRiduzioneContoTerzi
                     / 100);
            ELSE
               nTotaleContoTerzi := 0;
            END IF;
         END IF;

         IF nCont != 0 OR nConsumoSerra > 0
         THEN
            nTotaleSerra :=
                 LEAST (nConsumoSerra,
                        (nAssegnazioneSerra + nRimanenzaSerra))
               - (  LEAST (nConsumoSerra,
                           (nAssegnazioneSerra + nRimanenzaSerra))
                  * nPercRiduzioneSerra
                  / 100);
         ELSE
            IF IsUtentePA (pIdUtente)
            THEN
               nTotaleSerra :=
                    (nAssegnazioneSerra + nRimanenzaSerra)
                  - (  (nAssegnazioneSerra + nRimanenzaSerra)
                     * nPercRiduzioneSerra
                     / 100);
            ELSE
               nTotaleSerra := 0;
            END IF;
         END IF;
      END IF;

      DELETE DB_DETTAGLIO_CALCOLO
       WHERE     ID_DOMANDA_ASSEGNAZIONE = pIdDomandaAssegnazione
             AND TIPO_ASSEGNAZIONE = pTipoAssegnazione
             AND NUMERO_SUPPLEMENTO IS NULL;

      INSERT INTO DB_DETTAGLIO_CALCOLO (ID_DETTAGLIO_CALCOLO,
                                        ID_DOMANDA_ASSEGNAZIONE,
                                        TIPO_ASSEGNAZIONE,
                                        CARBURANTE_LAVORAZIONE,
                                        CARBURANTE_ASSERVIMENTO,
                                        CARBURANTE_ALLEVAMENTO,
                                        TOT_CARB_COLTURA_ALLEV,
                                        CARBURANTE_MACCHINE,
                                        QUANTITATIVO_MASSIMO,
                                        CARBURANTE_MIETITREBB,
                                        MAX_CONTO_PROPRIO,
                                        MAX_CONTO_PROPRIO_RIDOTTO,
                                        PERCENTUALE_RIDUZIONE,
                                        DECURTAZIONE_LAV_BENZINA,
                                        DECURTAZIONE_LAV_GASOLIO,
                                        TOTALE_CONTO_PROPRIO,
                                        CARBURANTE_RISCALDAMENTO,
                                        TOTALE_SERRA,
                                        ALTRE_MACCHINE_DITTA_FORZATA,
                                        DATA_AGGIORNAMENTO,
                                        EXT_ID_UTENTE_AGGIORNAMENTO,
                                        TOTALE_CONTO_TERZI,
                                        CARB_LAVORAZ_AUMENTO,
                                        CARB_LAVORAZ_COLT_SEC,
                                        CARB_LAVORAZ_ECCEZ,
                                        CARB_LAVORAZIONI_BASE,
                                        CARB_AUMENTO_ALLEVAMENTO,
                                        CARB_AUMENTO_MACCHINE,
                                        CARB_AUMENTO_RISCALDAMENTO,
                                        CARBURANTE_LAV_CT_DA_CP,
                                        CARBURANTE_ESSICAZIONE,
                                        ASSEGNATO_PREC_CONTO_TERZI,
                                        CARBURANTE_CONTO_TERZI_LAV,
                                        MAX_CONTO_TERZI)
           VALUES (SEQ_DB_DETTAGLIO_CALCOLO.NEXTVAL,
                   pIdDomandaAssegnazione,
                   pTipoAssegnazione,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   nTotaleContoProprio,
                   0,
                   nTotaleSerra,
                   'N',
                   SYSDATE,
                   pIdUtente,
                   nTotaleContoTerzi,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   nTotaleContoTerzi);

      pCodErr := NULL;
      pMsgErr := '';
   EXCEPTION
      WHEN OTHERS
      THEN
         pCodErr := SQLCODE;
         pMsgErr :=
               'CALCOLO_ASSEGNAZIONE_ACCONTO '
            || SQLERRM
            || ' riga = '
            || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
   END CALCOLO_ASSEGNAZIONE_ACCONTO;

   -- attribuisce un identificativo alfanumerico univoco alla domanda di assegnazione (acconto, base/saldo, supplemento)
   PROCEDURE ATTRIBUISCI_IDENTIFICATIVO (
      pIdAssegnazioneCarburante       NUMBER,
      pCodiceTipoIstanza              DB_TIPO_ISTANZA.CODICE%TYPE,
      pAnnoCampagna                   NUMBER,
      pMsgErr                     OUT VARCHAR2,
      pCodErr                     OUT VARCHAR2)
   IS
      nRangeA                     DB_D_RANGE_IDENTIFICATIVO.RANGE_A%TYPE;
      nUltimoNumero               DB_D_RANGE_IDENTIFICATIVO.ULTIMO_NUMERO%TYPE;
      nIdRangeIdentificativo      DB_D_RANGE_IDENTIFICATIVO.ID_RANGE_IDENTIFICATIVO%TYPE;
      nIdDittaUma                 DB_DOMANDA_ASSEGNAZIONE.ID_DITTA_UMA%TYPE;
      vIdentificativo             DB_ASSEGNAZIONE_CARBURANTE.IDENTIFICATIVO_DOMANDA%TYPE;
      nCont                       SIMPLE_INTEGER := 0;
      nIdDomandaAssegnazione      DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
      nIdDomandaAccontoValidato   DB_DOMANDA_ASSEGNAZIONE.ID_DOMANDA_ASSEGNAZIONE%TYPE;
      vIdentificativoDomanda      DB_ASSEGNAZIONE_CARBURANTE.IDENTIFICATIVO_DOMANDA%TYPE;
      nAnno                       NUMBER (4);
   BEGIN
      pCodErr := '0';
      pMsgErr := '';

      IF    pIdAssegnazioneCarburante IS NULL
         OR pCodiceTipoIstanza IS NULL
         OR pAnnoCampagna IS NULL
      THEN
         pCodErr := '1';
         pMsgErr :=
            'UNO O PIU'' PARAMETRI DI INPUT OBBLIGATORI NON VALORIZZATI';
         RETURN;
      END IF;

      IF UPPER (pCodiceTipoIstanza) NOT IN ('SA', 'AC', 'BA', 'SP')
      THEN
         pCodErr := '1';
         pMsgErr := 'Codice tipo istanza in input non previsto';
         RETURN;
      END IF;

      -- per il 2016 l'acconto o la base/saldo saranno senza identificativo
      SELECT TO_NUMBER (VALORE)
        INTO nAnno
        FROM DB_TIPO_PARAMETRO
       WHERE COD_PARAMETRO = 'UMID' AND DATA_FINE_VALIDITA IS NULL;

      IF pAnnoCampagna < nAnno
      THEN
         pCodErr := '0';
         pMsgErr := '';
         RETURN;
      END IF;

      IF UPPER (pCodiceTipoIstanza) IN ('AC', 'BA')
      THEN
         -- si attribuisce un nuovo numero identificativo
         BEGIN
                SELECT RANGE_A, ULTIMO_NUMERO, ID_RANGE_IDENTIFICATIVO
                  INTO nRangeA, nUltimoNumero, nIdRangeIdentificativo
                  FROM DB_D_RANGE_IDENTIFICATIVO
                 WHERE ANNO_CAMPAGNA = pAnnoCampagna
            FOR UPDATE OF ULTIMO_NUMERO;

            IF (nUltimoNumero + 1) > nRangeA
            THEN
               pCodErr := '1';
               pMsgErr :=
                  'Range identificativo domande esaurito per l''anno in input';
               RETURN;
            END IF;

            UPDATE DB_D_RANGE_IDENTIFICATIVO
               SET ULTIMO_NUMERO = (nUltimoNumero + 1)
             WHERE ID_RANGE_IDENTIFICATIVO = nIdRangeIdentificativo;

            vIdentificativoDomanda :=
               (nUltimoNumero + 1) || '-' || pCodiceTipoIstanza || '-01';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pCodErr := '1';
               pMsgErr :=
                  'Range identificativo domande non trovato per l''anno in input';
               RETURN;
         END;
      END IF;

      IF UPPER (pCodiceTipoIstanza) = 'SA'
      THEN
         BEGIN
            SELECT DA.ID_DITTA_UMA
              INTO nIdDittaUma
              FROM DB_ASSEGNAZIONE_CARBURANTE AC, DB_DOMANDA_ASSEGNAZIONE DA
             WHERE     DA.ID_DOMANDA_ASSEGNAZIONE =
                          AC.ID_DOMANDA_ASSEGNAZIONE
                   AND AC.ID_ASSEGNAZIONE_CARBURANTE =
                          pIdAssegnazioneCarburante;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pCodErr := '1';
               pMsgErr :=
                  'Ditta Uma non trovata per la domanda di assegnazione in input';
               RETURN;
         END;

         BEGIN
            SELECT SUBSTR (AC.IDENTIFICATIVO_DOMANDA, 1, 11),
                   DA.ID_DOMANDA_ASSEGNAZIONE
              INTO vIdentificativo, nIdDomandaAccontoValidato
              FROM DB_ASSEGNAZIONE_CARBURANTE AC, DB_DOMANDA_ASSEGNAZIONE DA
             WHERE     DA.ID_DOMANDA_ASSEGNAZIONE =
                          AC.ID_DOMANDA_ASSEGNAZIONE
                   AND DA.ID_DITTA_UMA = nIdDittaUma
                   AND pAnnoCampagna =
                          TO_NUMBER (TO_CHAR (DA.DATA_RIFERIMENTO, 'YYYY'))
                   AND DA.ID_STATO_DOMANDA = 35
                   AND DA.TIPO_DOMANDA = 'A'
                   AND AC.ANNULLATO IS NULL;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pCodErr := '1';
               pMsgErr :=
                  'Domanda di acconto non trovata per la domanda di saldo in input';
               RETURN;
         END;

         SELECT COUNT (*) + 1
           INTO nCont
           FROM DB_ASSEGNAZIONE_CARBURANTE AC, DB_DOMANDA_ASSEGNAZIONE DA
          WHERE     DA.ID_DOMANDA_ASSEGNAZIONE = AC.ID_DOMANDA_ASSEGNAZIONE
                AND DA.ID_DITTA_UMA = nIdDittaUma
                AND pAnnoCampagna =
                       TO_NUMBER (TO_CHAR (DA.DATA_RIFERIMENTO, 'YYYY'))
                AND DA.TIPO_DOMANDA = 'B'
                AND AC.TIPO_ASSEGNAZIONE = 'B'
                AND DA.ID_DOMANDA_ASSEGNAZIONE > nIdDomandaAccontoValidato
                AND AC.ID_ASSEGNAZIONE_CARBURANTE !=
                       pIdAssegnazioneCarburante;

         vIdentificativoDomanda :=
               vIdentificativo
            || '-'
            || pCodiceTipoIstanza
            || '-'
            || LPAD (TO_CHAR (nCont), 2, '0');
      END IF;

      IF UPPER (pCodiceTipoIstanza) = 'SP'
      THEN
         BEGIN
            SELECT SUBSTR (AC.IDENTIFICATIVO_DOMANDA, 1, 11),
                   DA.ID_DOMANDA_ASSEGNAZIONE
              INTO vIdentificativo, nIdDomandaAssegnazione
              FROM DB_ASSEGNAZIONE_CARBURANTE AC, DB_DOMANDA_ASSEGNAZIONE DA
             WHERE     DA.ID_DOMANDA_ASSEGNAZIONE =
                          AC.ID_DOMANDA_ASSEGNAZIONE
                   AND AC.ID_ASSEGNAZIONE_CARBURANTE =
                          pIdAssegnazioneCarburante
                   AND DA.TIPO_DOMANDA = 'B'
                   AND AC.ANNULLATO IS NULL;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               pCodErr := '1';
               pMsgErr :=
                  'Domanda di assegnazione base o saldo non trovata per la domanda di assegnazione supplementare in input';
               RETURN;
         END;

         SELECT COUNT (*) + 1
           INTO nCont
           FROM DB_ASSEGNAZIONE_CARBURANTE AC, DB_DOMANDA_ASSEGNAZIONE DA
          WHERE     DA.ID_DOMANDA_ASSEGNAZIONE = AC.ID_DOMANDA_ASSEGNAZIONE
                AND AC.ID_ASSEGNAZIONE_CARBURANTE !=
                       pIdAssegnazioneCarburante
                AND DA.ID_DOMANDA_ASSEGNAZIONE = nIdDomandaAssegnazione
                AND AC.TIPO_ASSEGNAZIONE = 'S';

         vIdentificativoDomanda :=
               vIdentificativo
            || '-'
            || pCodiceTipoIstanza
            || '-'
            || LPAD (TO_CHAR (nCont), 2, '0');
      END IF;

      UPDATE DB_ASSEGNAZIONE_CARBURANTE
         SET IDENTIFICATIVO_DOMANDA = vIdentificativoDomanda
       WHERE ID_ASSEGNAZIONE_CARBURANTE = pIdAssegnazioneCarburante;
   EXCEPTION
      WHEN OTHERS
      THEN
         pCodErr := SQLCODE;
         pMsgErr :=
               'ATTRIBUISCI_IDENTIFICATIVO '
            || SQLERRM
            || ' riga = '
            || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
   END ATTRIBUISCI_IDENTIFICATIVO;
END PCK_SMRUMA_ASSEGNAZ_CARB;
/
