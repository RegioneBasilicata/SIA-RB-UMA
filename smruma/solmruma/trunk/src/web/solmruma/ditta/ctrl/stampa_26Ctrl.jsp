<%@ page language="java"
      contentType="text/html"
      isErrorPage="true"
%>

<%@ page import="java.util.*" %>
<%@ page import="it.csi.jsf.htmpl.*" %>
<%@ page import="it.csi.solmr.client.uma.*" %>
<%@ page import="it.csi.solmr.client.anag.*" %>
<%@ page import="it.csi.solmr.util.*" %>
<%@ page import="it.csi.solmr.dto.uma.*" %>
<%@ page import="it.csi.solmr.etc.*" %>
<%@ page import="it.csi.solmr.dto.*" %>
<%@ page import="it.csi.solmr.etc.uma.*" %>
<%@ page import="it.csi.solmr.exception.*" %>
<%@ page import="it.csi.solmr.dto.profile.RuoloUtenza" %>


<%!
  private static final String VIEW="../view/stampa_26View.jsp";
%><%!
  public void checkValidation(HttpServletRequest request)
  throws Exception
  {
    if (request.getParameter("conferma")==null)
    {
      // Prima volta che entro sulla pagina ==> non faccio nulla
      return;
    }
    ValidationErrors errors=new ValidationErrors();
    String strDataUtente = request.getParameter("dataUtente");
    Validator.validateDateAll(strDataUtente, "dataUtente", "data di riferimento", errors, true, true);
    if (errors.size()==0)
    {
      // Richiedo il controllo di obbligatoriet� solo se la data � valida
      // (altrimenti non posso sapere se � una ristampa in quanto dipeneda dalla
      // data inserita)
      UmaFacadeClient umaFacadeClient=new UmaFacadeClient();
      // Preparo i dati da passare al metodo UmaFacadeClient.isRistampaMod26()
      DittaUMAAziendaVO dittaUMAAziendaVO=(DittaUMAAziendaVO)request.getSession().getAttribute("dittaUMAAziendaVO");
      String strDittaUma = request.getParameter("dittaUma");
      String strProvinciaUma = request.getParameter("provinciaUma");
      String strDataRiferimentoUma = request.getParameter("dataUtente");
      String strDataRiferimentoUmaO = strDataRiferimentoUma;
      Date dataRiferimento = null;
      if (strDataRiferimentoUma != null) {
    	SolmrLogger.debug(this, "--- strDataRiferimentoUma ="+strDataRiferimentoUma);
        strDataRiferimentoUma = strDataRiferimentoUma + " 23:59:59";        
        dataRiferimento = Validator.parseDate(strDataRiferimentoUma, "dd/MM/yyyy kk:mm:ss");
        int year = UmaDateUtils.extractYearFromDate(dataRiferimento);
        SolmrLogger.debug(this, "--- year ="+year);
        SolmrLogger.debug(this, "--- idDittaUma ="+dittaUMAAziendaVO.getIdDittaUMA());
        /* 
        	Controllare se esiste domanda validata per lo stesso anno inserito nella data di riferimento
        	Se esiste: stampo
        	Se non esiste: dare il messaggio che avvisa che non � presente alcuna domanda validata
        */
        
        SolmrLogger.debug(this, "--- Controllare se esiste domanda validata per lo stesso anno inserito nella data di riferimento");        
        DomandaAssegnazione domAss = umaFacadeClient.getDomAssValidataByIdDittaUmaAnno(dittaUMAAziendaVO.getIdDittaUMA(),year);
      	if(domAss == null){
      		SolmrLogger.debug(this, "-- NON � stata trovata la Domanda Assegnazione, non si pu� effettuare la stampa");
      		errors.add("dataUtente", new ValidationError("Non � presente alcuna domanda validata per l''anno indicato, pertanto non � possibile effettuare la stampa"));
      	}
        
      } 
      else {
        //non ci passa mai
        dataRiferimento = new Date();
      }
      DittaUMAVO duVO = new DittaUMAVO();
      duVO.setIdDitta(dittaUMAAziendaVO.getIdDittaUMA());
      duVO.setExtIdAzienda(dittaUMAAziendaVO.getIdAzienda());
      // Controllo se � una ristampa
      boolean isRistampa=umaFacadeClient.isRistampaMod26(duVO,dataRiferimento);
      request.setAttribute("isRistampa",new Boolean(isRistampa));
      SolmrLogger.debug(this,"[stampa_26Ctrl:checkValidation] isRistampa="+isRistampa);
      if (isRistampa)
      {
        // Deve essere valorizzato il motivo.
        String idMotivazioneRistampa=request.getParameter("idMotivazioneRistampa");
        SolmrLogger.debug(this,"[stampa_26Ctrl:checkValidation] idMotivazioneRistampa="+idMotivazioneRistampa);
        if ("".equals(idMotivazioneRistampa))
        {
          // In request c'� l'id ma � vuoto==>Non � stata inserita la
          // motivazione
          errors.add("idMotivazioneRistampa",new ValidationError(UmaErrors.ERRORE_VAL_CAMPO_OBBLIGATORIO));
        }
        else
        {
          if (idMotivazioneRistampa==null)
          {
            // In request non c'� l'id ==> L'utente non ha ancora la combo e ha
           // solo inserito la data e premuto conferma ==> metto in request
           // una variabile che mi indica questo fatto in modo da non aprire il
           // pdf
           SolmrLogger.debug(this,"[stampa_26Ctrl:checkValidation] NO_PDF=");
           request.setAttribute("noPdf",Boolean.TRUE);
          }
        }
      }
    }
    if (errors.size()>0)
    {
    request.setAttribute("errors",errors);
    }
  }
%>
<%
  String iridePageName = "stampa_26Ctrl.jsp";
  %><%@include file = "/include/autorizzazione.inc" %><%
  try  {
    UmaFacadeClient umaClient = new UmaFacadeClient();
    RuoloUtenza ruoloUtenza = (RuoloUtenza) session.getAttribute("ruoloUtenza");
    checkValidation(request);
  }
  catch(Exception e) {
    ValidationErrors errors=new ValidationErrors();
    errors.add("error",new ValidationError(e.getMessage()));
    request.setAttribute("errors",errors);
  }
%>
<jsp:forward page="<%=VIEW%>"/>

