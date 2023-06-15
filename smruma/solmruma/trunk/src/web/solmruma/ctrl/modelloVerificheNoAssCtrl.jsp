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

  private static final String VIEW="../view/modelloVerificheNoAssView.jsp";

%>

<%
  String iridePageName = "modelloVerificheNoAssCtrl.jsp";
  %><%@include file = "/include/autorizzazione.inc" %><%

  try

  {

    UmaFacadeClient umaClient = new UmaFacadeClient();

    RuoloUtenza ruoloUtenza = (RuoloUtenza) session.getAttribute("ruoloUtenza");

    String idProvinciaProf = ruoloUtenza.getIstatProvincia();



    ValidationErrors errors=new ValidationErrors();

    String idProvincia = request.getParameter("idProvincia");

    String anno = request.getParameter("anno");

    String mese = request.getParameter("mese");

    ValidationError vError = null;



// Modifica del 26/5/2004



      if (request.getParameter("conferma") != null) {

        if(!ruoloUtenza.isUtenteIntermediario() &&

           !(ruoloUtenza.isUtenteRegionale()) &&

           !idProvinciaProf.equals(idProvincia))

          errors.add("idProvincia",new ValidationError("Funzionario PA appartenente ad una provincia differente da quella selezionata"));

        if (!Validator.isNotEmpty(anno) || anno.length()!=4 || !Validator.isNumericInteger(anno))

          errors.add("anno",new ValidationError("L''anno dev''essere un numero nel formato aaaa"));

        if (!Validator.isNotEmpty(mese))

          errors.add("mese",new ValidationError("Scegliere il mese"));

      }

      if (errors.size()!=0) {

        request.setAttribute("errors", errors);

      }

//    }

  }

  catch(Exception e) {

    ValidationErrors errors=new ValidationErrors();

    errors.add("error",new ValidationError(e.getMessage()));

    request.setAttribute("errors",errors);

  }

%>

<jsp:forward page="<%=VIEW%>"/>



