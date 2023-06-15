/**
 * RENEW SESSION
 */
//Gestione refresh sessione

//Funzioni per il refresh della sessione - Begin
var req;
var isIE;
var timeout = 1680000; // ms = 28m
//var timeout = 45000; // ms = 45s
var cntRefresh = 0;
var MAX_TIME_REFRESH = 3;

if(typeof(window.opener)=="undefined") {
  initTimeout();
}

function initTimeout() {
    setTimeout("refreshSession()",timeout);
}

// (3) JavaScript function in which XMLHttpRequest JavaScript object is created.
// Please note that depending on a browser type, you create
// XMLHttpRequest JavaScript object differently.  Also the "url" parameter is not
// used in this code (just in case you are wondering why it is
// passed as a parameter).
//
function initRequest(url) {
    if (window.XMLHttpRequest) {
        req = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        isIE = true;
        req = new ActiveXObject("Microsoft.XMLHTTP");
    }
}

// (2) Event handler that gets invoked whenever a user types a character
// in the input form field whose id is set as "name".  This event
// handler invokes "initRequest(url)" function above to create XMLHttpRequest
// JavaScript object.
//
function refreshSession() {
    //window.alert('Get new Request');
    //var url = "../../servlet/RefreshServlet";
    var url = window.location.protocol +
            window.location.host +
            window.location.pathname +
            "/client/RefreshServlet";

    //window.alert('Get new Request');

    // Invoke initRequest(url) to create XMLHttpRequest object
    initRequest(url);

    // The "processRequest" function is set as a callback function.
    // (Please note that, in JavaScript, functions are first-class objects: they
    // can be passed around as objects.  This is different from the way
    // methods are treated in Java programming language.)
    req.onreadystatechange = processRequest;
    req.open("GET", url, true);
    req.send(null);
}

// (4) Callback function that gets invoked asynchronously by the browser
// when the data has been successfully returned from the server.
// (Actually this callback function gets called every time the value
// of "readyState" field of the XMLHttpRequest object gets changed.)
// This callback function needs to be set to the "onreadystatechange"
// field of the XMLHttpRequest.
//
function processRequest() {
    if (req.readyState == 4) {
      if (req.status == 200) {
        cntRefresh++;
        if(cntRefresh<MAX_TIME_REFRESH){
          initTimeout();
        }
      }
    }
}
//Funzioni per il refresh della sessione - End

//Gestione per singolo click su pulsante di submit - Begin
setTimeout(event_onload, 100);

function noSubmit(){
  return false;
}

function singleClick(){
  for (i=0; i<document.forms.length; i++)
  {
    var itemForm = document.forms[i];
    itemForm.onsubmit=noSubmit;
    //window.alert('itemForm.name: '+itemForm.name);
  }
}

function event_onload()
{
  if(document.forms){
    var i;
    for (i=0; i<document.forms.length; i++)
    {
      var itemForm = document.forms[i];
      itemForm.onsubmit=singleClick;
    }
  }
  else{
    setTimeout(event_onload, 100);
  }
}
//Gestione per singolo click su pulsante di submit - End

// Questa funzione apre un nuovo pop-up solo a condizione che il parametro "richiesta" sia valorizzato
function NewWindow(mypage, myname, w, h, scroll,richiestaModifica) {
  if(richiestaModifica != '') {
    var winl = (screen.width - w) / 2;
    var wint = (screen.height - h) / 2;
    winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable'
    win = window.open(mypage, myname, winprops)
    if (parseInt(navigator.appVersion) >= 4) {
      win.window.focus();
    }
  }
}

function NewWindowComune(mypage, myname, w, h, scroll,provincia,comune) {
  NewWindowComune(mypage, myname, w, h, scroll,provincia,comune,'');
}

function NewWindowComune(mypage, myname, w, h, scroll,provincia,comune,obiettivo) {
  var winl = (screen.width - w) / 2;
  var wint = (screen.height - h) / 2;
  if(provincia ==  '' && comune == '') {
    alert('Inserire una provincia o un comune!');
  }
  else if(!mappaOggetti(provincia) || !mappaOggetti(comune) || !mappaOggetti(obiettivo)) {
  }
  else {
    winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable';
    win = window.open(mypage+'?obiettivo='+obiettivo+'&provincia='+provincia+'&comune='+comune, myname, winprops);
    if (parseInt(navigator.appVersion) >= 4) {
      win.window.focus();
    }
  }
}

function NewWindowStato(mypage, myname, w, h, scroll,stato) {
  var winl = (screen.width - w) / 2;
  var wint = (screen.height - h) / 2;

  if(!mappaOggetti(stato)) {
  }
  else {
    winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable';
    win = window.open(mypage+'?stato='+stato, myname, winprops);
    if (parseInt(navigator.appVersion) >= 4) {
      win.window.focus();
    }
  }
}

function NewWindowStatoObj(mypage, myname, w, h, scroll,stato,obiettivo) {
  var winl = (screen.width - w) / 2;
  var wint = (screen.height - h) / 2;

  if(!mappaOggetti(stato)) {
  }
  else {
    winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable';
    win = window.open(mypage+'?stato='+stato+'&obiettivo='+obiettivo, myname, winprops);
    if (parseInt(navigator.appVersion) >= 4) {
      win.window.focus();
    }
  }
}

// Funzione di controllo per i caratteri non validi
function mappaOggetti(stringa) {

    var nonvalidi = '"<>$ï¿½|()^*:;0123456789';
    var trovatocarattere = false;

      if (stringa!=" " && stringa!="") {
        if(eValida(stringa, nonvalidi)) {
        }
        else {
          trovatocarattere = true;
        }
      }
      else {
      }
      if (trovatocarattere) {
        alert('I campi non possono contenere caratteri speciali');
        return false;
      }
      else {
        return true;
      }
}


//queste funzioni controllano lo stato di determinati campi della form
function eValida(stringa,nonammessi) {
  for (var i=0; i< stringa.length; i++) {
    if (nonammessi.indexOf(stringa.substring(i, i+1)) != -1) {
      return false;
    }
  }
  return true;
}
// Funzione per chiudere la finestra di pop-up e valorizzare i campi della finestra padre con i valori selezionati
// precedentemente dall'utente
function confermaComune() 
{
  if(document.sceltaComune.istat != null) 
  {
    var radio;
    var obiettivo = document.sceltaComune.obiettivo;
    for(var i = 0; i<document.sceltaComune.istat.length || i < 1;i++) 
    {
      radio = document.sceltaComune.istat[i];
      if(radio == null) 
      {
        radio = document.sceltaComune.istat;
      }
      if(radio.checked == true) 
      {
        var provincia = document.sceltaComune.siglaProvincia[i];
        var comune = document.sceltaComune.comune[i];
        var istatComune = document.sceltaComune.istatComune[i];
        var cap = document.sceltaComune.cap[i];
        var istatProvincia = document.sceltaComune.istatProvincia[i];
        var codiceFiscaleComune = document.sceltaComune.codiceFiscaleComune[i];
        //
        var zonaAlt = document.sceltaComune.zonaAltimetrica[i];
        if(provincia == null) 
        {
          provincia = document.sceltaComune.siglaProvincia;
        }
        if(comune == null) 
        {
          comune = document.sceltaComune.comune;
        }
        if(istatComune == null) 
        {
          istatComune = document.sceltaComune.istatComune;
        }
        if(cap == null) 
        {
          cap = document.sceltaComune.cap;
        }
        if(istatProvincia == null) 
        {
          istatProvincia = document.sceltaComune.istatProvincia;
        }
        //
        if(zonaAlt == null) 
        {
          zonaAlt = document.sceltaComune.zonaAltimetrica;
        }
        if(codiceFiscaleComune == null) 
        {
          codiceFiscaleComune = document.sceltaComune.codiceFiscaleComune;
        }
        // MODIFICA X NUOVA LAV CONTO TERZI
        if (window.opener.document.getElementById("sedeLegaleStr"))
        {
          //alert('comune.value vale: '+comune.value);
          //alert('provincia.value vale: '+provincia.value);
          var comuneOpener=window.opener.document.getElementById("sedeLegaleStr");
          comuneOpener.value=comune.value+" ("+provincia.value+")";
         
        }
        
        // FINE MODIFICA
	    if(obiettivo == null || obiettivo.value == '')
        {
          //alert('sono in conferma comune..');
          // AGGIUNTA PER SUPERFICI E VARIAZIONE DITTA UMA
          if (window.opener.document.getElementById("descComune"))
          {
            var comuneOpener=window.opener.document.getElementById("descComune");
            var provinciaOpener=window.opener.document.getElementById("sedelegProvincia");
            if (comuneOpener)
            {
              comuneOpener.value=comune.value;
            }
            if (provinciaOpener)
            {
              provinciaOpener.value=provincia.value;
            }
            window.close();
            return;
          }
          // FINE AGGIUNTA
          // alert('setto campi su opener.. ');
	      opener.document.form1.provincia.value = provincia.value;
	      //alert('setto campi su opener comune.. ');
	      opener.document.form1.comune.value = comune.value;
	      //alert('setto campi su opener istatComune.. ');
	      opener.document.form1.istatComune.value = istatComune.value;
	      //alert('setto campi su opener cap.. ');
	      opener.document.form1.cap.value = cap.value;
	      //
          if(opener.document.form1.tipiZonaAltimetrica != null) 
          {
	        for(k=0;k<opener.document.form1.tipiZonaAltimetrica.options.length;k++)
	        {
	          if(opener.document.form1.tipiZonaAltimetrica.options[k].value==zonaAlt.value)
	          {
	            opener.document.form1.tipiZonaAltimetrica.selectedIndex = k;
	        }
	      }
	    }
	  }
      else if(obiettivo.value=='nascita') 
      {
	    opener.document.form1.nascitaComune.value = comune.value;
	    opener.document.form1.descNascitaComune.value = istatComune.value;
	  }
      else if(obiettivo.value=='res') 
      {
	    opener.document.form1.resCAP.value = cap.value;
	    opener.document.form1.descResComune.value = comune.value;
	    opener.document.form1.resComune.value = istatComune.value;
	    opener.document.form1.resProvincia.value = provincia.value;
	  }
      else if(obiettivo.value == 'sedeleg') 
      {
	    opener.document.form1.sedelegCAP.value = cap.value;
	    opener.document.form1.descComune.value = comune.value;
	    opener.document.form1.sedelegComune.value = istatComune.value;
	    opener.document.form1.sedelegProv.value = provincia.value;
	  }
      else if (obiettivo.value == 'nascitaProvCom')
      {
        opener.document.form1.nascitaProv.value = provincia.value;
        opener.document.form1.descNascitaComune.value = comune.value;
      }
      else if(obiettivo.value == 'insAzienda') 
      {
        opener.document.form1.descNascitaComune.value = comune.value;
        opener.document.form1.nascitaComune.value = istatComune.value;
        opener.document.form1.codiceFiscaleComune.value = codiceFiscaleComune.value;
        opener.document.form1.nascitaProv.value = provincia.value;
      }
      else if(obiettivo.value == 'insAziendaProvAndCom') 
      {
        opener.document.form1.resProvincia.value = provincia.value;
        opener.document.form1.descResComune.value = comune.value;
        opener.document.form1.resComune.value = istatComune.value;
        opener.document.form1.resCAP.value = cap.value;
      }
      else if(obiettivo.value == 'insSede') 
      {
        opener.document.form1.sedelegProv.value = provincia.value;
        opener.document.form1.sedelegComune.value = comune.value;
        opener.document.form1.sedelegCAP.value = cap.value;
      }
      else if(obiettivo.value == 'ricercaAzienda') 
      {
        opener.document.form1.sedelegProvincia.value = provincia.value;
        opener.document.form1.descComune.value = comune.value;
        opener.document.form1.cap.value = cap.value;
        opener.document.form1.istatComune.value = istatComune.value;
      }
      else if(obiettivo.value == 'consegna') 
      {
    	  opener.document.form1.provinciaConsegna.value = provincia.value;
    	  opener.document.form1.comuneConsegna.value = comune.value;
    	  opener.document.form1.capConsegna.value = cap.value;
    	  opener.document.form1.istatComuneConsegna.value = istatComune.value;
      }
      else
      {
        if(obiettivo.value == 'lavContoTerzi') 
        {
          opener.document.form1.sedeLegaleStr.value = comune.value;
          opener.document.form1.provinciaStr.value = provincia.value;
        }
        else 
        {
          opener.document.form1.descComune.value = comune.value;
          opener.document.form1.provincia.value = provincia.value;
        }
      }

      window.close();
      return;
    }
  }
  alert('Selezionare un comune!');
}
}

// Funzione per disabilitare il campo stato estero nel caso in cui siano valorizzati provincia,comune o cap
function disabilitaStatoEstero(provincia,comune,cap) {
  if(provincia != '' || comune!= '' || cap != '' ) {
    document.form1.statoEstero.disabled = true;
  }
  else {
    document.form1.statoEstero.disabled = false;
  }
}

// Funzione per disabilitare il campo stato estero oppure i campi provincia comune e cap in base al loro valore
function disabilitaCampo(provincia,comune,cap,statoEstero) {
  if(provincia.value != '' ||  comune.value != '' || cap.value != '') {
    statoEstero.disabled = true;
  }
  else if(statoEstero.value != '') {
    provincia.disabled = true;
    comune.disabled = true;
    cap.disabled = true;
  }
}



function visualError()
{
    oggettoDiv = document.getElementById("messageError");
    if ( (oggettoDiv != null) && (oggettoDiv.innerHTML != '') ){
            window.alert(oggettoDiv.innerHTML);
    }
}

// Utilizzato per la gestione dei pulsanti precedente/successivo negli elenchi di UMA
function goToLine(prev)
{
  document.paginazione.startRow.value=prev;
  document.paginazione.submit();
}


function doForm(hiddenName)
{
  //alert('sono in doform() 1');	
  var divElement=document.getElementById("hiddenElement");
  divElement.innerHTML="<input type='hidden' name='"+hiddenName+"' value=''>";
  //alert('sono in doform() 2');
  document.form1.submit();
}

function doFormPage(hiddenName, page)
{
  var divElement=document.getElementById("hiddenElement");
  divElement.innerHTML="<input type='hidden' name='"+hiddenName+"' value=''>";
  var action=document.form1.action;
  document.form1.action=page;
  document.form1.submit();
  document.form1.action=action;  
}


function pop(page,w,h,target)
{
  var winl = (screen.width - w) / 2;
  var wint = (screen.height - h) / 2;
  winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars=yes';
  win = window.open(page, target, winprops);
  if (parseInt(navigator.appVersion) >= 4)
  {
    win.window.focus();
  }
}

function popR(page,w,h,target)
{
  var winl = (screen.width - w) / 2;
  var wint = (screen.height - h) / 2;
  winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars=yes, resizable=yes';
  win = window.open(page, target, winprops);
  if (parseInt(navigator.appVersion) >= 4)
  {
    win.window.focus();
  }
}

function testLength(controllo,maxLength,doTrunc)
{
    var msg="Lunghezza massima raggiunta\n(" + maxLength + " caratteri)";
    if (doTrunc=="false" && controllo.value.length>=maxLength)
    {
        alert(msg);
        return false;
    }
    if (doTrunc=="true" && controllo.value.length>maxLength)
    {
        msg=msg+"\n\nIl contenuto del campo ï¿½ stato troncato.";
        controllo.value=controllo.value.substring(0,maxLength);
        alert(msg);
        return false;
    }
    else
        return true;
}

function dotCheck(input)
{
    return input.replace(".",",");
}

function commaCheck(input)
{
    return input.replace(",",".");
}

// Funzione per chiudere la finestra di pop-up e valorizzare i campi della finestra padre con i valori selezionati
// precedentemente dall'utente
function confermaStato() {
  var obiettivo=document.sceltaStato.obiettivo.value;
  if(document.sceltaStato.istat != null) {
    var radio;
    for(var i = 0;i<document.sceltaStato.istat.length || i<1 ;i++) {
      radio = document.sceltaStato.istat[i];
      if(radio==null) {
        radio = document.sceltaStato.istat;
      }
      if(radio.checked == true) {
        var sigla = document.sceltaStato.siglaStato[i];
        if(sigla==null) {
          sigla = document.sceltaStato.siglaStato;
        }
        if (obiettivo=='nascita'){
          opener.document.form1.nascitaStatoEstero.value = sigla.value;
        }
        else if(obiettivo == 'statoEsteroResidenza') {
          opener.document.form1.descStatoEsteroResidenza.value = sigla.value;
        }
        else if(obiettivo == 'statoEsteroSede') {
          opener.document.form1.sedelegEstero.value = sigla.value;
        }
        else {
          opener.document.form1.sedelegEstero.value = sigla.value;
          opener.document.form1.istatStatoEstero.value = radio.value;
        }
        window.close();
        return;
      }
    }
    alert('Selezionare uno stato!');
  }
}

  // Funzione per chiudere la finestra di pop-up e valorizzare i campi della finestra padre con i valori selezionati
  // precedentemente dall'utente
  function confermaMarca() {
    if(document.form1.idMarca != null) {
      var radio;
      var matrice;
      for(var i = 0; i<document.form1.idMarca.length || i < 1;i++) {
        radio = document.form1.idMarca[i];
        if(radio == null) {
          radio = document.form1.idMarca;
        }
        if(radio.checked == true) {
          var descrizioneMarca = document.form1.descrizione[i];
          matrice = document.form1.matrice[i];
          if(descrizioneMarca == null) {
            descrizioneMarca = document.form1.descrizione;
            matrice = document.form1.matrice;
          }

          opener.document.form1.descMarca.value = descrizioneMarca.value;
          opener.document.form1.matriceMarca.value = matrice.value;
          window.close();
          return;
        }
      }
      alert('Selezionare una marca!');
    }
  }
  
  function sendFormToPage(form, page)
  {
    var action=form.action;
    form.action=page;
    form.submit();
    form.action=action;
  }

function selezionaTutti(elementi,checked)
{
  if (elementi)
  {
    if (elementi.length)
    {
      var len=elementi.length;
      for(i=0;i<len;++i)
      {
        elementi[i].checked=checked;
      }
    }
    else
    {
      elementi.checked=checked;
    }
  }
}

function IsNumeric(sText) {
  if(!sText)
    return false;
  var ValidChars = "0123456789.,";
  var IsNumber=true;
  var Char;
  for(i = 0; i < sText.length && IsNumber == true; i++) { 
      Char = sText.charAt(i); 
      if(ValidChars.indexOf(Char) == -1) {
        IsNumber = false;
      }
    }
  return IsNumber;
}



function newWindowDoForm(mypage, formName, myname, w, h, scroll) 
{
	var winl = (screen.width - w) / 2;
	var wint = (screen.height - h) / 2;
	
	winprops =    'height='+h+',width='+w+',top='+wint+',left='+winl+',scrollbars='+scroll+',resizable';
	win = window.open('', myname, winprops);
	if (myname=='abaco') {
	  win.close();
	  win = window.open('', myname, winprops);
	}
	
	if (parseInt(navigator.appVersion) >= 4) {
	  win.window.focus();
	}
	
	var target1 = formName.target;
	var action1 = formName.action;
	formName.target = myname;
	formName.action = mypage;
	formName.submit();
	formName.target = target1;
	formName.action = action1;
}

function validaElencoMotivazini(){
	if($("input:checked" ).length < 1 ){
		$('#popupValidazione').dialog({
		    modal: true,
		    autoOpen: false,
		    draggable: false,
		    height: 170,
		  	width: 430,
		    title: 'Seleziona almeno una voce'
		})
		$('#popupValidazione').dialog( "open" );
		return false;
	}else{
		return true;
	}
}


function allega(idAllegatoIstanza)
{
    pop('../layout/allegaFilePOP.htm?funzione=primo&idAllegatoIstanza='+idAllegatoIstanza,640,480,'Allegati');
  
}

function visualizzaFile(idFile)
{
  // alert("ho cliccato su visualizza file");
   document.formVis.idFile.value = idFile;
  // alert("visualizza file "+idFile );
   document.formVis.action = '../layout/visualizzaFileAllegato.htm';
   document.formVis.submit();
}

function calcoloCarburanteAssSupp(suffix) {
	
	if(!suffix){
		suffix = "";
	}
	
	//alert('sono in calcoloCarburanteAss');
	//alert('suffix' + suffix);
			 		
	// SOLO se &agrave; stata selezionata una lavorazione, effettuo il calcolo carburante
	var idLavorazione = window.document.getElementById("idLavorazione"+suffix).value;	
	//alert(idLavorazione);
	if(idLavorazione){
	 //   alert('-- calcolare il carburante');
		
		var numeroEsecuzioni = 1;	

		if(suffix !=""){
			var numEsecuzioniTemp = window.document.getElementById("numeroEsecuzioni"+suffix).value;
			numeroEsecuzioni = Number(numEsecuzioniTemp.replace(".",","));
			var maxNumEsecuzioni = window.document.getElementById("maxNumEsecuzioni"+suffix).value;
			if(!numeroEsecuzioni || numeroEsecuzioni == '' || isNaN(numeroEsecuzioni)){
				alert("Il valore inserito di 'numero esecuzioni' non valido");
				numeroEsecuzioni = maxNumEsecuzioni;
			}else if(numeroEsecuzioni > maxNumEsecuzioni){
				alert("Il valore inserito di 'numero esecuzioni' non deve essere maggiore del massimo consentito: " + maxNumEsecuzioni);
				numeroEsecuzioni = maxNumEsecuzioni;
			}
		}
		
		var eseguiCalcolaCarb = window.document.getElementById("eseguiCalcolaCarb"+suffix);			
		
		var flagEscludiEsecuzioni = window.document.getElementById("flagEscludiEsecuzioni"+suffix).value;
			
		var tipoUnitaMisura = window.document.getElementById("tipoUnitaMisura"+suffix).value;
					
		var litriCarburante = window.document.getElementById("litriCarburante"+suffix);
		var litriAcclivitaCalcolati =  window.document.getElementById("litriAcclivita"+suffix);
		var litriBaseCalcolati = window.document.getElementById("litriBaseCalcolati"+suffix);
		var litriMedioImpastoCalcolati = window.document.getElementById("litriMedioImpastoCalcolati"+suffix);
		
		var litriBase = Number(window.document.getElementById("litriBase"+suffix).value);
		//alert('tipoUnitaMisura vale: '+tipoUnitaMisura);			
		var litriMedioImpasto = Number(window.document.getElementById("litriMedioImpasto"+suffix).value);
		//alert('litriMedioImpasto:' +litriMedioImpasto);
		var litriTerDeclivi = Number(window.document.getElementById("litriTerDeclivi"+suffix).value);
		//alert('litriTerDeclivi:' +litriTerDeclivi);			
		var ettariTemp = window.document.getElementById("supOreStr"+suffix).value;
		var ettari = Number(ettariTemp.replace(",", "."));				
		var supOre = window.document.getElementById("supOreStr"+suffix);
		//alert('ettari: '+ettari);
		
		var cavalli = Number(window.document.getElementById("cavalli"+suffix).value);
		//alert('cavalli: '+cavalli);
		//alert(window.document.getElementById("coefficiente").value);
		var coefficiente = Number(window.document.getElementById("coefficiente"+suffix).value);
		//alert('coefficiente: '+coefficiente);									
				
		var supTotaleCalcolataTmp = window.document.getElementById("supTotaleCalcolata"+suffix).value;
		var supTotaleCalcolata = Number(supTotaleCalcolataTmp.replace(",", "."));
		
		var supMontagnaCalcolataTmp = window.document.getElementById("supMontagnaCalcolata"+suffix).value; 	
		var supMontagnaCalcolata = Number(supMontagnaCalcolataTmp.replace(",", "."));	
			
		var carburante = 0;
		var litriAcclivita = 0;
		
		
		var riduzione = null;
		if(window.document.getElementById("riduzione"+suffix)!=null){
			riduzione = window.document.getElementById("riduzione"+suffix).value; 
		}
		
			
		//alert('tipoUnitaMisura' + tipoUnitaMisura);
		// ----------- ********* CALCOLO CARBURANTE PER SUPERFICIE ************ ------------
		if (tipoUnitaMisura == 'S') {
		  /*  alert('* CALCOLO CARBURANTE PER SUPERFICIE *');	
			alert('litriBase : '+litriBase);
			alert('litriMedioImpasto: '+litriMedioImpasto);
			alert('litriTerDeclivi: '+litriTerDeclivi);
			alert('ettari: '+ettari);		
			alert('numeroEsecuzioni : '+numeroEsecuzioni);		
			alert('supTotaleCalcolata : '+supTotaleCalcolata);
			alert('supMontagnaCalcolata : '+supMontagnaCalcolata);*/
			
			//alert('numeroEsecuzioni ='+numeroEsecuzioni);
			if(numeroEsecuzioni != null && numeroEsecuzioni != ''){
			//  alert('calcolo i litri base');
				
			  litriBase *= numeroEsecuzioni;
			  litriBase *= ettari;
			  litriBase = arrotondamento(litriBase);
			//  alert('litriBase calcolati ='+litriBase);
			  
			  litriMedioImpasto *= numeroEsecuzioni;
			  litriMedioImpasto *= ettari;
			  litriMedioImpasto = arrotondamento(litriMedioImpasto);
			}
			else{
			  litriBase = 0;
			  litriMedioImpasto = 0;
			}
			
			// Calcolo litri per acclivita (se la superficie totale calcolata &agrave; valorizzata): 
			if(supTotaleCalcolata != null && supTotaleCalcolata != '' && supTotaleCalcolata != '0'){
			//  alert('ettari ='+ettari);
			//  alert('supMontagnaCalcolata ='+supMontagnaCalcolata);
			//  alert('supTotaleCalcolata ='+supTotaleCalcolata);
			  var supMontagnaPerEttari = (ettari * supMontagnaCalcolata) / supTotaleCalcolata;
			  
			//  alert('litriTerDeclivi ='+litriTerDeclivi);
			  litriAcclivita = supMontagnaPerEttari * litriTerDeclivi;
			  litriAcclivita *= numeroEsecuzioni;
			  litriAcclivita = arrotondamento(litriAcclivita);
			}
			
			//alert('litriBase arrotondati ='+litriBase);
			//alert('litriMedioImpasto  arrotondati ='+litriMedioImpasto);
			//alert('litriAcclivita arrotondati ='+litriAcclivita);
			if(riduzione !=null && riduzione !=''){
				carburante = litriBase - ( litriBase*riduzione/100 ) + litriMedioImpasto + litriAcclivita;	
			}else{
				carburante = litriBase + litriMedioImpasto + litriAcclivita;											
			}
		}
		
		// ----------- ********* CALCOLO CARBURANTE PER METRO LINEARE ************ ------------
		else if(tipoUnitaMisura == 'M') {
			if(numeroEsecuzioni != null && numeroEsecuzioni != ''){
				

				
					litriBase *= numeroEsecuzioni;
					litriBase *= ettari;
					litriBase = arrotondamento(litriBase);
					  
					litriMedioImpasto *= numeroEsecuzioni;
					litriMedioImpasto *= ettari;
					litriMedioImpasto = arrotondamento(litriMedioImpasto);
				}
				else{
				  litriBase = 0;
				  litriMedioImpasto = 0;
				}
				
				litriAcclivita = 0;
				
				if(riduzione !=null && riduzione !=''){
					  carburante = litriBase - ( litriBase*riduzione/100 ) + litriMedioImpasto + litriAcclivita;
				}else{
					carburante = litriBase + litriMedioImpasto + litriAcclivita;
				}
			
		}
		
		// ----------- ********* CALCOLO CARBURANTE PER ORE ************ ------------ 
		else if (tipoUnitaMisura == 'T') {		
		  /*  alert('* CALCOLO CARBURANTE PER TEMPO *');	    
			alert('ettari :'+ettari);
			alert('coefficiente :'+coefficiente);
			alert('cavalli :'+cavalli);	
			alert('flagEscludiEsecuzioni :'+flagEscludiEsecuzioni);
			alert('numeroEsecuzioni :'+numeroEsecuzioni);*/
			
			
			carburante = ettari * cavalli * coefficiente;
			
			if(riduzione !=null && riduzione !=''){
				carburante *= ((100-riduzione)/100);	
			}
			
			if(numeroEsecuzioni != null && numeroEsecuzioni != '') {
				if (flagEscludiEsecuzioni == null
						|| flagEscludiEsecuzioni == ''
						|| flagEscludiEsecuzioni == 'N') {							
					carburante = carburante * numeroEsecuzioni;
				} 
				else {
			//	  alert('tipoUnitaMisura=T && flagEscludiEsecuzioni==S');
				}
			}
			// nel caso in cui si deve moltiplicare anche per il numero esecuzioni ed il numero non &agrave; indicato, forzare 0
			else{
			  if (flagEscludiEsecuzioni == null
						|| flagEscludiEsecuzioni == ''
						|| flagEscludiEsecuzioni == 'N') {
						carburante = 0;							
			  }			
			}
		//	alert('carburante calcolato :'+carburante);								
		}
	
		//alert('carburante calcolato :'+carburante);	
		if (isNaN(carburante)) {
			carburante = "";
		} 
		else {
			carburante = arrotondamentoLitro(carburante);
		}
	//	alert('carburante arrotondato :'+carburante);							
		
		if (eseguiCalcolaCarb.value != 'false') {
			if (tipoUnitaMisura == 'S' || tipoUnitaMisura=='M') {
			  litriCarburante.value = carburante;	
		 // 	  alert('litriCarburante ='+litriCarburante.value);
		  	  
		  	  if(isNaN(litriBase)){
		  	    litriBaseCalcolati.value = "";			  	    
		  	  }
		  	  else{
		  	    litriBaseCalcolati.value = arrotondamento(litriBase);
		//  	    alert('litriBaseCalcolati ='+litriBaseCalcolati.value);
		  	  }
		  	  
		  	  if(isNaN(litriMedioImpasto)) {	
		  	    litriMedioImpastoCalcolati.value = "";		  	    
		  	  }
		  	  else{
		  	    litriMedioImpastoCalcolati.value = arrotondamento(litriMedioImpasto);
		//  	    alert('litriMedioImpastoCalcolati ='+litriMedioImpastoCalcolati.value);
		  	  }
		  	  
		  	  if(isNaN(litriAcclivita)) {
		  	    litriAcclivitaCalcolati.value = "";
		  	  } 
		  	  else{
		  	    litriAcclivitaCalcolati.value = arrotondamento(litriAcclivita);
		//  	    alert('litriAcclivitaCalcolati ='+litriAcclivitaCalcolati.value);
		  	  } 
			}
			// in questo caso valorizzo solo i campi 'Litri carburante' e 'Litri base'
			else if (tipoUnitaMisura == 'T') {
			  litriCarburante.value = carburante;	
		//  	  alert('litriCarburante ='+litriCarburante.value);
		  	  // Nel campo 'Litri base' visualizzare il valore calcolato per 'Litri carburante'
		  	  litriBaseCalcolati.value = carburante;
		//  	  alert('litriBaseCalcolati ='+litriBaseCalcolati.value);
			}
		}
		else{
		   eseguiCalcolaCarb.value = "true";
		}								
	}	
}

function arrotondamentoLitro(num) {
    num = num + 0.9999;
    num = Math.abs(Math.floor(num));
    return num;
  }
  function arrotondamento(num) {
    //alert('sono in arrotondamento');    
    num = Math.round(num * 100) / 100
    return num;
  }
  
	function onlyNumbers(evt) {
	    var theEvent = evt || window.event;
	    var key = theEvent.keyCode || theEvent.which;
	    key = String.fromCharCode( key );
	    var regex = /[0-9]/;
	    if( !regex.test(key) ) {
	      theEvent.returnValue = false;
	      if(theEvent.preventDefault) theEvent.preventDefault();
	    }
	}	
	
  