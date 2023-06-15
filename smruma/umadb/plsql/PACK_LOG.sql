CREATE OR REPLACE package PACK_LOG is

    FUNCTION  Inserisci_Log (P_Max_Occ            IN  TMP_LOG.DA_ELABORARE%TYPE,
                             P_Fase               IN  TMP_LOG.NOME_FASE%TYPE,
                             P_IdLog               OUT TMP_LOG.ID_LOG%TYPE,
                              p_MsgErr           OUT varchar2,
                            p_CodErr           OUT varchar2)  RETURN BOOLEAN;

    FUNCTION Aggiorna_Log   (P_id_log            IN TMP_LOG.ID_LOG%TYPE,
                              p_esito_fase       IN TMP_LOG.ESITO_FASE%TYPE,
                             p_elaborati       IN TMP_LOG.ELABORATI%TYPE,
                            p_scartati           IN TMP_LOG.SCARTATI%TYPE,
                             p_cod_errore       IN OUT TMP_LOG.COD_ERRORE%TYPE,
                             p_desc_errore       IN OUT TMP_LOG.DESC_ERRORE%TYPE)  RETURN BOOLEAN;

END;
/


CREATE OR REPLACE package body PACK_LOG is

FUNCTION Inserisci_Log (P_Max_Occ            IN  TMP_LOG.DA_ELABORARE%TYPE,
                         P_Fase               IN  TMP_LOG.NOME_FASE%TYPE,
                         P_IdLog               OUT TMP_LOG.ID_LOG%TYPE,
                          p_MsgErr           OUT varchar2,
                        p_CodErr           OUT varchar2)  RETURN BOOLEAN Is
BEGIN
     select seq_log.nextval
     into  p_idlog
     from dual;

     insert into Tmp_Log (id_log, nome_fase, esito_fase, da_elaborare, elaborati,
             scartati, cod_errore, desc_errore, data_inizio_elab, data_fine_elab)
     Values (p_idlog, P_Fase,'KO', p_Max_Occ, null, null, null, null, sysdate, null);

     Return (True);
exception when others then
    p_MsgErr   := 'Errore inserimento Tmp_Log. Desc: ' || sqlerrm;
    p_CodErr   := sqlcode;
    return (False);

END Inserisci_Log;

FUNCTION Aggiorna_Log   (P_id_log            IN TMP_LOG.ID_LOG%TYPE,
                          p_esito_fase       IN TMP_LOG.ESITO_FASE%TYPE,
                         p_elaborati       IN TMP_LOG.ELABORATI%TYPE,
                         p_scartati           IN TMP_LOG.SCARTATI%TYPE,
                         p_cod_errore       IN OUT TMP_LOG.COD_ERRORE%TYPE,
                         p_desc_errore       IN OUT TMP_LOG.DESC_ERRORE%TYPE)
                          RETURN BOOLEAN IS

BEGIN

     update Tmp_Log set esito_fase  = p_esito_fase,
                         elaborati   = p_elaborati,
                        scartati    = p_scartati,
                        cod_errore  = p_cod_errore,
                        desc_errore = p_desc_errore,
                        data_fine_elab = sysdate
     where id_log = p_id_log;

     Return (True);

exception when others then
    p_desc_errore := 'Errore aggiornamento Tmp_Log. Desc: ' || sqlerrm;
    p_cod_errore  := sqlcode;
    return (False);
END Aggiorna_Log;

END PACK_LOG;
/
