CREATE OR REPLACE PACKAGE PCK_SMRUMA_UTILITY_BATCH AS

/*******************************************************************************
   NAME:       PCK_SMRUMA_UTILITY_BATCH
   PURPOSE:    Package di funzioni di utility batch
*******************************************************************************/

  /************************************************************************
  InsProcBatch : Inserisce i dati del processo batch in esecuzione

  Parametri input:  pNomeBatch - nome del batch
  Parametri output: pIdProc    - id processo batch
  *************************************************************************/

  FUNCTION InsProcBatch(pNomeBatch  DB_NOME_BATCH.NOME_BATCH%TYPE) RETURN DB_PROCESSO_BATCH.ID_PROCESSO_BATCH%TYPE ;

  /************************************************************************
  UpdFineProcBatch : Aggiorna la data fine elaborazione
                     del processo batch in esecuzione

  Parametri input:  pIdProc   - id processo batch
                    pEsito    - esito del processo batch OK o KO
  *************************************************************************/

  PROCEDURE UpdFineProcBatch (pIdProc DB_PROCESSO_BATCH.ID_PROCESSO_BATCH%TYPE,
                              pEsito  DB_PROCESSO_BATCH.FLAG_ESITO%TYPE);

  /************************************************************************
  InsLogBatch : Popola la Tabella di Log

  Parametri input:  pId         - id identificativo batch
                    pCodErr     - codice errore
                    pMessErr    - messaggio errore
  ***************************************************************************/

  PROCEDURE InsLogBatch (pIdProc  DB_LOG_BATCH.ID_PROCESSO_BATCH%TYPE,
                         pCodErr  DB_LOG_BATCH.CODICE_ERRORE%TYPE,
                         pMessErr DB_LOG_BATCH.MESSAGGIO_ERRORE%TYPE);

END PCK_SMRUMA_UTILITY_BATCH;
/


CREATE OR REPLACE PACKAGE BODY PCK_SMRUMA_UTILITY_BATCH AS


/************************************************************************
  InsProcBatch : Inserisce i dati del processo batch in esecuzione

  Parametri input:  pNomeBatch - nome del batch
  Parametri output: pIdProc    - id processo batch
  *************************************************************************/

FUNCTION InsProcBatch(pNomeBatch DB_NOME_BATCH.NOME_BATCH%TYPE) RETURN DB_PROCESSO_BATCH.ID_PROCESSO_BATCH%TYPE IS

  PRAGMA   AUTONOMOUS_TRANSACTION;
  nIdProc  DB_PROCESSO_BATCH.ID_PROCESSO_BATCH%TYPE;
BEGIN

  INSERT INTO DB_PROCESSO_BATCH
  (ID_PROCESSO_BATCH,
   ID_NOME_BATCH,
   DT_INIZIO_ELABORAZIONE)
  VALUES
  (SEQ_DB_PROCESSO_BATCH.NEXTVAL,
   (SELECT ID_NOME_BATCH FROM DB_NOME_BATCH WHERE NOME_BATCH = pNomeBatch),
   SYSDATE)
  RETURNING ID_PROCESSO_BATCH INTO nIdProc;

  COMMIT;

  RETURN nIdProc;
END InsProcBatch;

  /************************************************************************
  UpdFineProcBatch : Aggiorna la data fine elaborazione
                     del processo batch in esecuzione

  Parametri input:  pIdProc   - id processo batch
                    pEsito    - esito del processo batch OK o KO
  *************************************************************************/

PROCEDURE UpdFineProcBatch (pIdProc DB_PROCESSO_BATCH.ID_PROCESSO_BATCH%TYPE,
                            pEsito  DB_PROCESSO_BATCH.FLAG_ESITO%TYPE) IS

  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  UPDATE DB_PROCESSO_BATCH
  SET    DT_FINE_ELABORAZIONE = SYSDATE,
         FLAG_ESITO           = pEsito
  WHERE  ID_PROCESSO_BATCH    = pIdProc;
  COMMIT;
END UpdFineProcBatch;

  /************************************************************************
  InsLogBatch : Popola la Tabella di Log

  Parametri input:  pId         - id identificativo batch
                    pCodErr     - codice errore
                    pMessErr    - messaggio errore
  ***************************************************************************/

PROCEDURE InsLogBatch (pIdProc  DB_LOG_BATCH.ID_PROCESSO_BATCH%TYPE,
                       pCodErr  DB_LOG_BATCH.CODICE_ERRORE%TYPE,
                       pMessErr DB_LOG_BATCH.MESSAGGIO_ERRORE%TYPE) is

  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  INSERT INTO DB_LOG_BATCH
  (ID_LOG_BATCH, ID_PROCESSO_BATCH, DT_INSERIMENTO, CODICE_ERRORE, MESSAGGIO_ERRORE)
  VALUES
  (SEQ_DB_LOG_BATCH.NEXTVAL,pIdProc ,SYSDATE , pCodErr, pMessErr );

  COMMIT;

END InsLogBatch;

END PCK_SMRUMA_UTILITY_BATCH;
/
