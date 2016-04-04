<!DOCTYPE html>
<!--[if lt IE 7 ]><html class="ie ie6" lang="en"> <![endif]-->
<!--[if IE 7 ]><html class="ie ie7" lang="en"> <![endif]-->
<!--[if IE 8 ]><html class="ie ie8" lang="en"> <![endif]-->
<!--[if (gte IE 9)|!(IE)]><!--><html lang="en-US"> <!--<![endif]-->

<!-- head -->
<head>

<!-- meta -->
<meta charset="UTF-8" />
<meta http-equiv="X-UA-Compatible" content="IE=9" />
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<title>TherapyAppointment</title>

<!--- stylesheet 
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol-child/style.css" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/js/fancybox/jquery.fancybox-1.3.4.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/ui/jquery.ui.all.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/responsive.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/skins/blue/images.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/style-colors.php?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/style.php?ver=1.2.2" media="all" />
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Raleway:300,400,400italic,700" >
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Raleway:300,400,400italic,700" >
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Raleway:300,400,400italic,700" >
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Patua+One" > ----->

<!-- wp_head() -->

<link rel="icon" href="https://www.psychselect.com/wp-stuff/favicon.ico" type="image/x-icon" />
<link rel="shortcut icon" href="https://www.psychselect.com/wp-stuff/favicon.ico" type="image/x-icon" />

<meta name="description" content="a practice management system designed to simplify routine office tasks for mental health professionals" />

<script type='text/javascript' src='https://www.psychselect.com/wp-stuff/wp-includes/js/jquery/jquery.js?ver=1.8.3'></script>

<link rel='canonical' href='http://therapyappointment.com' />

<!--[if lt IE 9]>
<script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
<!--[if lte IE 8]>
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/ie8.css" />
<![endif]-->

<script type="text/javascript">

function _cookiesAreEnabled() {
  SetCookie( "foo", "bar" );
  if ( GetCookie( "foo" ) ) {
    DeleteCookie( "foo" );
    return true;
  } else {
    return false;
  }
}
navigator.cookiesAreEnabled = _cookiesAreEnabled;

function _getHVCCAuthID() {
  return GetCookie( "HVCCAuthID" );
}
document.getHVCCAuthID = _getHVCCAuthID;

function GetCookie( name ) {
  var arg = name + "=";
  var alen = arg.length;
  var clen = document.cookie.length;
  var i = 0;
  while ( i < clen ) {
    var j = i + alen;
    if ( document.cookie.substring(i, j) == arg ) return getCookieVal(j);
    i = document.cookie.indexOf( " ", i ) + 1;
    if ( i == 0 ) break;
  }
  return null;
}

function DeleteCookie( name, path, domain ) {
  if ( GetCookie( name ) ) {
    document.cookie = name + "=" +
    ( ( path ) ? "; path=" + path : "" ) +
    ( ( domain ) ? "; domain=" + domain : "" ) +
    "; expires=Thu, 01-Jan-70 00:00:01 GMT";
  }
}

function SetCookie( name, value, expires, path, domain, secure ) {
  document.cookie = name + "=" + escape (value) +
  ( ( expires ) ? "; expires=" + expires.toGMTString() : "" ) +
  ( ( path ) ? "; path=" + path : "" ) +
  ( ( domain ) ? "; domain=" + domain : "" ) +
  ( ( secure ) ? "; secure" : "" );
}

/**
 *   Helper function for GetCookie()
 */
function getCookieVal( offset ) {
  var endstr = document.cookie.indexOf ( ";", offset );
  if ( endstr == -1 ) endstr = document.cookie.length;
  return unescape( document.cookie.substring( offset, endstr ) );
}


</Script>

<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-42664327-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>

</head>

<body>
<!-- body -->
<body>
<center>

	<div id="Wrapper">

		<!-- #Header -->
		<!-- #Header -->
		<header id="Header">
			<div id="top_bar">
				<div class="container">
					<div class="sixteen columns">
						<!-- #logo -->
							<p>&nbsp;<p>
							<img src="https://www.psychselect.com/wp-stuff/wp-content/uploads/2013/07/logo.png" alt="TherapyAppointment" />
						
					</div>		
				</div>
			</div>
			
			<div id="Subheader"><div class="container"><div class="sixteen columns"><h1 style="font-family:arial;color:lightgrey;">Thanks for your payment!</h1></div></div></div>
			<!---display error message if it exists--->
			<cfif structKeyExists(url,'result')>
				<cfoutput><p style="color:red;font-family:arial;font-size:18pt;">#htmleditformat(urlDecode(url.result))#</strong></p></cfoutput>
			</cfif>
		</header>		
<!-- Content -->
<div id="Content">
	<div class="container">

		<!-- .content -->
	<div style="min-height:400px;" class="the_content the_content_wrapper">
        <!-- CONTENT GOES HERE. TO HIGHLIGHT A PAGE IN MENU, ADD current-menu-item CLASS TO THE PAGE'S LI YOU WISH TO BE THE CURRENT PAGE -->
<CFIf NOT isDefined("URL.TransactionID")>
	<center><font face="arial" color="darkred" size="+2">
	<p>ERROR: Credit card transaction was interrupted. Please contact technical support (800-242-2127 or wcw@psychselect.com) for further instructions.</font></center></body></html>
	<CFAbort>
<CFElse>
	<CFQuery Name="GetTheName" DATASOURCE="#DBDSN#">
		Select *
		FROM TransactionLog
		Where TransactionID = #val(URL.TransactionID)#
	</CFQuery>
</CFIf>

<CFIf GetTheName.RecordCount IS NOT 1 OR Len(trim(GetTheName.Status))>
	<center><font face="arial" color="darkred" size="+2">
	<p>ERROR: It appears that you have returned to this page by mistake, or have come here in another non-standard way.</font></center></body></html>
	<CFAbort>
</CFIf>

<cfset Output = "New Account Transaction details: ">

<CFIF isDefined("GetTheName.CardHolder")>
	<cfset Output = Output & "Name: " & GetTheName.CardHolder & "; ">
</cfif>

<CFIF isDefined("GetTheName.Email")>
	<cfset Output = Output & "Email: " & GetTheName.Email & "; ">
</cfif>

<CFIF isDefined("GetTheName.Amount")>
	<cfset Output = Output & "Amount: $" & GetTheName.Amount & "; ">
</cfif>

<CFIF isDefined("URL.Status")>
	<cfset Output = Output & "CC Status: " & URL.Status & "; ">
</cfif>

<CFIF isDefined("URL.TransactionID")>
	<cfset Output = Output & "Transaction ID: " & URL.TransactionID >
</cfif>

<!--- construct a message to Bill about the transaction --->

<cfset Form.Message = "NEW:" & encrypt(Output,"1aHvQNjAy9rDEcOpIKZgjQ==","AES","Base64")>
<CFSet Form.DateAndTime = CreateODBCDateTime(Now())>
<CFSet Form.Receiver = "Technical Support">
<CFSet Form.Sender = "System Message">
<CFSet Form.Done = "N">
<CFSet Form.Urgent = "Y">
<CFSet Form.PhoneMessage = "N">
<CFInsert datasource="#DBDSN#" tablename="Messages" 
		  formfields="DateAndTime, Receiver, Sender, Message, Done, Urgent, PhoneMessage">
		  
<!--- and an email------------------------------------------->

<CFMail To = "wcw@psychselect.com"
        From = "wcw@psychselect.com"
		CC = "sewcgkt@gmail.com,new.therapyappointment@gmail.com"
        Subject = "New PAYLINE TherapyAppointment.com customer payment"> 

A new TherapyAppointment.com customer attempted a payment through Payline Data.

#Output#
</CFMail>

<!--- and a text message ------------------------------------------------------------------------------------------------
<CFIf isDefined("URL.Status")>
	<CFMail To = "2145298846@txt.att.net"
        From = "NewCustomer@psychselect.com"
        Subject = "Customer payment">A new TherapyAppointment.com customer attempted a payment: #URL.Status#</CFMail>
</CFIf>
------------------------------------------------------------------------------------------------------------------------>

<CFParam Name="URL.Status" Default="(Not reported)">
	<CFSet form.Status = left(URL.Status,60)>
<CFParam Name="URL.RefID" Default="">
	<CFSet form.RefID = left(URL.RefID,12)>
<CFParam Name="URL.AuthCode" Default="(N/A)">
	<CFSet form.AuthCode = left(URL.AuthCode,20)>
<CFParam Name="URL.CardType" Default="">
	<CFSet form.CardType = left(URL.CardType,2)>
<CFParam Name="URL.CardNumber" Default="(Not reported)">
	<CFSet form.CardNumber = left(URL.CardNumber,20)>
<CFParam Name="URL.AVS" Default="">
	<CFSet form.AVS = left(URL.AVS,4)>
<CFParam Name="URL.CVV" Default="">
	<CFSet form.CVV = left(URL.CVV,4)>
	<CFSet form.TransactionID = URL.TransactionID>

<CFUpdate datasource="#DBDSN#" tablename="TransactionLog" 
	Formfields="TransactionID,Status,RefID,AuthCode,CardType,CardNumber,AVS,CVV">

<CFIf NOT FindNoCase("APPROVED", URL.Status)> 

	<center>
	<p>&nbsp;<p>
	<Font size="+2" face="Arial" Color="blue">
	Sorry...your charge card payment was not approved.<p>
	</font>
	<font face="arial" color="darkblue" size="+1">
	Usually, this means that you miskeyed information or are using an expired charge card.<br>
	Please call us (800-242-2127, option 4) or <a href="https://therapyappointment.desk.com/customer/portal/emails/new" target="_blank">email us</a> for help with this issue.<p>
	</center>
	</body>
	</html>

	<CFAbort>
</CFIf>

<!---New 6/9/13, reduce fees of others in the group in response to the addition of this new group member...but it isn't working, so deleted for now-----
<CFIf isDefined("Cookie.FFP") AND isDefined("Cookie.NFF")>
		<CFQuery Name="OtherPracInfo" datasource="#DBDSN#">
			Select Practitioner,PayRate,SetRate,email,name,PayPlan,BillingNotes
			FROM UserLogin
			WHERE Practitioner IN (#URLdecode(Cookie.FFP)#)
			AND SetRate > #URLdecode(Cookie.NFF)#
		</CFQuery>
		
		<CFLoop Query="OtherPracInfo">
			<CFSet NewBillingNotes = OtherPracInfo.BillingNotes & dateformat(Now(),"short") & " SetRate (but NOT PayRate) adjusted automatically to " & DollarFormat(Cookie.NFF) & " due to addition of new member.">
			<CFQuery Name="Update" datasource="#DBDSN#">
				UPDATE UserLogin
				SET SetRate = #URLdecode(Cookie.NFF)#, BillingNotes = '#NewBillingNotes#'
				WHERE Practitioner = #OtherPracInfo.Practitioner#
			<CFQuery>
		</CFLoop>	
</CFIf>-------------------------------------------------------------------------------------------------------->


<center>
<p>&nbsp;<p>

<!---Create New entry in UserLogin table ----->
<CFSet Form.Word = RandRange(100000,999999)>
<CFSet Form.ID = "(" & Left(GetTheName.CardHolder,13) & ")">
<CFSet Form.AcctFirstSetUp = CreateODBCDateTime(Now())>
<CFSet Form.PayRate = GetTheName.Amount - 39.00>
<CFIf PayRate IS 30.00>
	<CFSet Form.MaxHoursPerMonth = 40>
<CFElseIf PayRate IS 10.00>
	<CFSet Form.MaxHoursPerMonth = 10>
<CFElse>
	<CFSet Form.MaxHoursPerMonth = 500>
</CFIf>

<CFSet Form.PayPlan = "P">
<CFSet Form.PaidThrough = CreateODBCDate(Now() + CreateTimeSpan(30,0,0,0))>
<CFSet Form.TherapistCCRefID = URL.RefID>

<CFIf NOT isDefined("cookie.GroupNumber")>
	You seem to have set up your browser so that it will not accept "cookies." This has prevented us from being able to link your account with others, if that was what you wanted. Contact us at wcw@psychselect.com for more information on this issue. We will have to adjust your account manually.<p>
	<CFSet Form.MaxHoursPerMonth = 500>
	<CFSet Form.PayRate = 57.50>
</CFIf>

<CFIf isDefined("cookie.GroupNumber") AND cookie.GroupNumber GREATER THAN 0>
	<CFSet Form.GroupNumber = cookie.GroupNumber>
<CFElse>
	<CFQuery name="GetNewGroupNumber" dataSource = "#DBDSN#">
		SELECT MAX(GroupNumber) AS New
		FROM UserLogin
	</CFQuery>
	
	<CFSet Form.GroupNumber = GetNewGroupNumber.New + 1>
</CFIf>

<CFIf isDefined("Cookie.GoodTherapy") AND Cookie.GoodTherapy GREATER THAN 0> <!---If this is a GoodTherapy Discount signup ----->
	<CFSet Form.PaidThrough = CreateODBCDate(Now() + CreateTimeSpan(61,0,0,0))>
	<CFIf Cookie.GoodTherapy is 40>
		<CFSet Form.MaxHoursPerMonth = 40>
		<CFSet Form.PayRate = 30>
	<CFElseIf Cookie.GoodTherapy is 10>
		<CFSet Form.MaxHoursPerMonth = 10>
		<CFSet Form.PayRate = 10>
	<CFElse>
		<CFSet Form.MaxHoursPerMonth = 500>
		<CFSet Form.PayRate = 57.50>
	</CFIf>
</CFIf>


<CFTry>
 <cfinsert dataSource = "#DBDSN#" tableName = "UserLogin" FormFields="Word,ID,AcctFirstSetUp,PayRate,PayPlan,PaidThrough,TherapistCCRefID,GroupNumber,MaxHoursPerMonth">

     <CFQUERY NAME="GetPractitionerNumber" DATASOURCE="#DBDSN#">
      SELECT Practitioner
      FROM UserLogin
      WHERE Word = #form.Word#
     </CFQUERY>
	 
	 <CFIf GetPractitionerNumber.RecordCount IS NOT 1>
		<h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
 
		Error encountered when retrieving Practitioner Number<br>
		<CFAbort>
	 </CFIf>
	 
	 <CFSet form.Practitioner = GetPractitionerNumber.Practitioner>
	 <CFUpdate datasource="#DBDSN#" tablename="TransactionLog" 
			Formfields="TransactionID,Practitioner">
	 
	 <CFSet PractitionerNumber = GetPractitionerNumber.Practitioner>
	 <CFSet form.PractitionerNumber = PractitionerNumber>
	 <CFSet form.Practitioner = PractitionerNumber>
	 <cfupdate dataSource = "#DBDSN#" 
		tableName = "UserLogin" FormFields = "Practitioner, PractitionerNumber">
	<cfcatch>
        <h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
        <cfoutput>
		Error encountered when creating entry into userlogin table<br>
            <!--- and the diagnostic message from the ColdFusion server --->
            <p>#cfcatch.message#</p>
            <p>Caught an exception, type = #CFCATCH.TYPE# </p>
            <p>The contents of the tag stack are:</p>
            <cfloop index = i from = 1 
                    to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
                <cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
                <br>#i# #sCurrent["ID"]# 
                    (#sCurrent["LINE"]#,#sCurrent["COLUMN"]#) 
                    #sCurrent["TEMPLATE"]#
            </cfloop>
        </cfoutput>
		<CFAbort>
    </cfcatch>
</cftry>
		
<!--- Create appointments table ------>
<!---<CFTry>--->
<CFQUERY NAME="CreateApptTable" DATASOURCE="#DBDSN#">
 CREATE  TABLE  `therapyappoint`.`Appointments#PractitionerNumber#` (  `Counter` int( 10  )  NOT  NULL  auto_increment ,
 `Practitioner` INT NOT NULL DEFAULT '#PractitionerNumber#' ,
 `DateAndTime` datetime  default NULL ,
 `StartTime` time default NULL ,
 `EndTime` time default NULL ,  
 `Patient` varchar( 30  )  default NULL ,
 `Meeting` varchar( 50  )  default NULL ,
 `CPT` varchar( 5  )  default NULL ,
 `Units` double  default NULL ,
 `Notes` longtext,
 `HIPAAtext` longtext,
 `Billable` varchar( 1  )  default NULL ,
 `Posted` varchar( 1  )  default NULL ,
 `PatientCounter` int( 10  )  default NULL ,
 `Locked` varchar( 1  )  default NULL ,
 `LockedTime` datetime  default NULL ,
 `FeeType` varchar( 6  )  default NULL ,
 `FeeCollected` double NOT  NULL default  '-1e-05',
 `FeeCollectedDate` datetime NOT  NULL default  '2000-01-01 00:00:00',
 `Copay` DOUBLE NOT NULL DEFAULT '-1e-005', 
 `SuggestedFee` double NOT  NULL default  '0',
 `TotalFee` double NOT  NULL default  '0',
 `InsurancePmt` double NOT  NULL default  '-1e-05',
 `InsurancePmtDate` datetime NOT  NULL default  '2000-01-01 00:00:00',
 `Discount` double NOT  NULL default  '-1e-05',
 `DistAdjust` DOUBLE NOT NULL DEFAULT '0',
 `ToDeductible` double NOT  NULL default  '-1e-05',
 `SecInsPmt` double NOT  NULL default  '-1e-05',
 `SecInsPmtDate` datetime NOT  NULL default  '2000-01-01 00:00:00',
 `InsFormPrintedDate` datetime NOT  NULL default  '2000-01-01 00:00:00',
 `POS` varchar( 2  )  default NULL ,
 `InsCounter` int( 11  )  NOT  NULL default  '0',
 `SecInsCounter` int( 11  )  NOT  NULL default  '0',
 `InsuranceNotes` longtext,
 `StallUntil` date NOT  NULL default  '2000-01-01',
 `PaymentInfo` varchar( 60  )  default NULL ,
 `Modifier4` varchar( 2  )  default NULL ,
 `OAclaimID` varchar( 12 )  default NULL ,
 `AddOn` VARCHAR(25) DEFAULT NULL ,
 `PQRS` VARCHAR(41) DEFAULT NULL ,
 PRIMARY  KEY (  `Counter`  ) ,
 KEY  `Billable` (  `Billable`  ) ,
 KEY  `CPT` (  `CPT`  ) ,
 KEY  `InsFormPrintedDate` (  `InsFormPrintedDate`  ) ,
 KEY  `InsurancePmtDate` (  `InsurancePmtDate`  ) ,
 KEY  `SecInsPmtDate` (  `SecInsPmtDate`  ) ,
 KEY  `DateAndTime` (  `DateAndTime`  ) ,
 KEY  `Locked` (  `Locked`  ) ,
 KEY  `Meeting` (  `Meeting`  ) ,
 KEY  `PatientCounter` (  `PatientCounter`  ) ,
 KEY  `OAClaimID` (  `OAClaimID`  ) ,
 KEY  `Posted` (  `Posted`  )  ) ENGINE  =  InnoDB  DEFAULT CHARSET  = latin1;
 </CFQuery>
 <!---<cfcatch>
        <h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
        <cfoutput>
		Error encountered when creating "Appointments#PractitionerNumber#" table<br>
       
            <p>#cfcatch.message#</p>
            <p>Caught an exception, type = #CFCATCH.TYPE# </p>
            <p>The contents of the tag stack are:</p>
            <cfloop index = i from = 1 
                    to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
                <cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
                <br>#i# #sCurrent["ID"]# 
                    (#sCurrent["LINE"]#,#sCurrent["COLUMN"]#) 
                    #sCurrent["TEMPLATE"]#
            </cfloop>
        </cfoutput>
		<CFAbort>
    </cfcatch>
</cftry>--->

 
 <!--- Create Insurance table -------->
 <CFTry>
 <CFQUERY NAME="CreateInsTable" DATASOURCE="#DBDSN#">
  CREATE  TABLE  `therapyappoint`.`Insurance#PractitionerNumber#` (  `InsCounter` int( 10  )  unsigned NOT  NULL  auto_increment ,
 `Practitioner` INT NOT NULL DEFAULT '#PractitionerNumber#' ,
 `InsName` varchar( 60  )  default NULL ,
 `InsType` varchar( 1  )  default NULL ,
 `InsPayerID` varchar( 10 ) default NULL ,
 `InsAddress1` varchar( 60  )  default NULL ,
 `InsCity` varchar( 40  )  default NULL ,
 `InsState` varchar( 2  )  default NULL ,
 `InsZip` varchar( 10  )  default NULL ,
 `InsPhone` varchar( 20  )  default NULL ,
 `InsClaimType` varchar( 1  )  default NULL ,
 `InsProvID` varchar( 40  )  default NULL ,
 `InsAcceptAssign` varchar( 1  )  default NULL ,
 `InsPrecertForm` varchar( 20  )  default NULL  COMMENT  'filename of form',
 `InsWebAddress` varchar( 70  )  default NULL ,
 `InsUserID` varchar( 30  )  default NULL ,
 `Ins90801` double NOT NULL default  '0',
 `Ins90806` double NOT NULL default  '0',
 `Ins90847` double NOT NULL default  '0',
 `Ins90853` double NOT NULL default  '0',
 `InsOtherCPT` double NOT NULL default  '0',
 `InsCPTMod` VARCHAR( 1 ) NOT NULL DEFAULT 'N',
 `InsCPTModCode1` VARCHAR( 2 ) default NULL,
 `InsCPTModCode2` VARCHAR( 2 ) default NULL,
 `InsCPTModCode3` VARCHAR( 2 ) default NULL,
 `InsCPTModCode4` VARCHAR( 2 ) default NULL, 
 `InsTaxonomy` VARCHAR( 1 ) NOT NULL DEFAULT 'N',
 `InsNPI24J` VARCHAR( 1 ) NOT NULL DEFAULT 'Y',
 `InsBox24JTop` VARCHAR( 1 ) NOT NULL DEFAULT 'N', 
 `InsDirDeposit` VARCHAR( 1 ) NOT NULL DEFAULT 'N',
 `InsUseIndivNPI` TINYINT NOT NULL DEFAULT '0',
 `InsUseSupervisorInfo` INT NOT NULL DEFAULT '0',
 `InsBox19` varchar( 42 )  default NULL ,
 `InsIncludePaid` TINYINT NOT NULL DEFAULT '0', 
 PRIMARY  KEY (  `InsCounter`  )  ) ENGINE  =  InnoDB  DEFAULT CHARSET  = latin1;
 </CFQuery>
 <cfcatch>
        <h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
        <cfoutput>
		Error encountered when creating "Insurance#PractitionerNumber#" table<br>
            <!--- and the diagnostic message from the ColdFusion server --->
            <p>#cfcatch.message#</p>
            <p>Caught an exception, type = #CFCATCH.TYPE# </p>
            <p>The contents of the tag stack are:</p>
            <cfloop index = i from = 1 
                    to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
                <cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
                <br>#i# #sCurrent["ID"]# 
                    (#sCurrent["LINE"]#,#sCurrent["COLUMN"]#) 
                    #sCurrent["TEMPLATE"]#
            </cfloop>
        </cfoutput>
		<CFAbort>
    </cfcatch>
</cftry>
 
 <!---Create Patients table ------------->
 <CFTry>
 <CFQUERY NAME="CreatePatientsTable" DATASOURCE="#DBDSN#">
  CREATE  TABLE  `therapyappoint`.`Patients#PractitionerNumber#` (  `Counter` int( 10  )  NOT  NULL  auto_increment ,
 `Practitioner` INT NOT NULL DEFAULT '#PractitionerNumber#' ,
 `LastName` varchar( 50  )  default NULL ,
 `FirstName` varchar( 50  )  default NULL ,
 `Initial` varchar( 1  )  default NULL ,
 `NickName` varchar( 30  )  default NULL ,
 `Sex` varchar( 1  )  default NULL ,
 `PatMarried` varchar( 1  )  default NULL ,
 `PatEmployed` varchar( 1  )  default NULL ,
 `EmerContact` VARCHAR( 60 ) DEFAULT NULL ,
 `RefSource` varchar( 30  )  NOT NULL default 'Unknown' ,
 `Allergies` varchar( 50  )  default NULL ,
 `LoginName` varchar( 15  )  default NULL ,
 `Password` varchar( 10  )  default NULL ,
 `CPT` varchar( 5  )  default NULL ,
 `Address1` varchar( 50  )  default NULL ,
 `Address2` varchar( 50  )  default NULL ,
 `Address3` varchar( 50  )  default NULL ,
 `City` varchar( 40  )  default NULL ,
 `State` varchar( 2  )  default NULL ,
 `Zip` varchar( 10  )  default NULL ,
 `HomePhone` varchar( 45  )  default NULL ,
 `WorkPhone` varchar( 15  )  default NULL ,
 `WorkExt` varchar( 5  )  default NULL ,
 `CellPhone` varchar( 45  )  default NULL ,
 `Email` varchar( 120  )  default NULL ,
 `DOB` datetime  default NULL ,
 `Dx` varchar( 85  )  default NULL ,
 `CertLeft` smallint( 5  )  default NULL ,
 `CertExpire` datetime  default NULL ,
 `Active` varchar( 1  )  default NULL ,
 `WantsEmail` varchar( 1  )  default NULL ,
 `CellCarrier` varchar( 1  )  default NULL ,
 `WantsPhone` varchar( 1  )  default NULL ,
 `PhonePref` varchar( 1  )  default NULL ,
 `Reminder` longtext,
 `UsualFee` double( 15, 5  )  default NULL ,
 `InsuredName` varchar( 50  )  default NULL ,
 `Employer` varchar( 50  )  default NULL ,
 `ID` varchar( 50  )  default NULL ,
 `GroupNo` varchar( 50  )  default NULL ,
 `Insurance` varchar( 50  )  default NULL ,
 `ClaimsMail1` varchar( 50  )  default NULL ,
 `ClaimsMail2` varchar( 50  )  default NULL ,
 `InsPhone` varchar( 50  )  default NULL ,
 `EffDate` datetime  default NULL ,
 `Preexist` varchar( 1  )  default NULL ,
 `Deductible` varchar( 25  )  default NULL ,
 `DeductMet` varchar( 25  )  default NULL ,
 `InsPaysAt` varchar( 25  )  default NULL ,
 `VisitLimit` int( 10  )  default NULL ,
 `NeedPrecert` varchar( 1  )  default NULL ,
 `PreCertWhom` varchar( 50  )  default NULL ,
 `PrecertPhone` varchar( 30  )  default NULL ,
 `AuthNo` varchar( 50  )  default NULL ,
 `SecondaryAuthNo` varchar( 20  )  default NULL ,
 `CertBegin` datetime  default NULL ,
 `SpokeWithBen` varchar( 50  )  default NULL ,
 `SpokeWithPA` varchar( 50  )  default NULL ,
 `EnterBy` varchar( 30  )  default NULL ,
 `EnterDate` datetime  default NULL ,
 `InsuranceMemo` longtext,
 `Assessments` varchar( 255  )  default NULL ,
 `PatPHash` varchar( 128  )  default NULL ,
 `InsuredAdd1` varchar( 60  )  default NULL ,
 `InsuredCity` varchar( 40  )  default NULL ,
 `InsuredState` varchar( 2  )  default NULL ,
 `InsuredZip` varchar( 10  )  default NULL ,
 `InsuredPhone` varchar( 20  )  default NULL ,
 `InsuredDOB` date  default NULL ,
 `InsuredSex` varchar( 1  )  default NULL ,
 `OtherInsuredName` varchar( 60  )  default NULL ,
 `PatRelOtherIns` varchar( 6 ) default NULL ,
 `OtherInsuredPolicyNo` varchar( 60  )  default NULL ,
 `OtherInsuredGroupNo` varchar( 20 )  default NULL ,
 `OtherInsuredDOB` date  default NULL ,
 `OtherInsuredSex` varchar( 1  )  default NULL ,
 `OtherInsuredEmployer` varchar( 60  )  default NULL ,
 `PatRelIns` varchar( 6  )  default NULL ,
 `ConditEmp` varchar( 1  )  default NULL ,
 `ConditAuto` varchar( 1  )  default NULL ,
 `AutoState` varchar( 2  )  default NULL ,
 `ConditAcc` varchar( 1  )  default NULL ,
 `FirstSx` date  default NULL ,
 `SimIllness` date  default NULL ,
 `InsCounter` int( 11  )  NOT  NULL default  '0',
 `SecInsCounter` int( 11  )  NOT  NULL default  '0',
 `TreatFreq` varchar( 12  )  default NULL ,
 `Sx` varchar( 255  )  default NULL ,
 `Status` varchar( 255  )  default NULL ,
 `Prognosis` varchar( 12  )  default NULL ,
 `Progress` varchar( 14  )  default NULL ,
 `Medication` varchar( 255  )  default NULL ,
 `TreatPlan` longtext,
 `PHIrelease` longtext,
 `BioInfo` longtext,
 `CCaddressLine1` varchar( 60  )  default NULL ,
 `CCzip` varchar( 10  )  default NULL ,
 `CCcardholder` varchar( 60  )  default NULL ,
 `CCrefID` varchar( 20  )  default NULL ,
 `CCdigits` VARCHAR( 4 )  DEFAULT NULL ,
 `CCInProcess` TINYINT NOT NULL DEFAULT '0' , 
 `ReferringPhysician` varchar( 25  )  default NULL ,
 `ReferPhysNPI` varchar( 10  )  default NULL ,
 `ReferPhysQual` varchar( 2  )  NULL default '  ' ,
 `StatementMessage` MEDIUMTEXT NULL DEFAULT NULL ,
 `ResPartyName` VARCHAR(60) NULL DEFAULT NULL ,
 `ResPartyAddress` VARCHAR(80) NULL DEFAULT NULL ,
 `ResPartyCityStateZip` VARCHAR(60) NULL DEFAULT NULL ,
 `DoNotStoreCC` TINYINT NOT NULL DEFAULT '0' ,
 `XMLsoapNotes` MEDIUMTEXT NULL DEFAULT NULL ,
 `AKA` MEDIUMTEXT NULL DEFAULT NULL ,
 PRIMARY  KEY (  `Counter`  ) ,
 KEY  `ID` (  `ID`  ) ,
 KEY  `LastName` (  `LastName`  ) ,
 KEY  `LoginName` (  `LoginName`  ) ,
 KEY  `Password` (  `Password`  )  ) ENGINE  =  InnoDB  DEFAULT CHARSET  = latin1;
 </CFQuery>
 <cfcatch>
        <h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
        <cfoutput>
		Error encountered when creating "Patients#PractitionerNumber#" table<br>
            <!--- and the diagnostic message from the ColdFusion server --->
            <p>#cfcatch.message#</p>
            <p>Caught an exception, type = #CFCATCH.TYPE# </p>
            <p>The contents of the tag stack are:</p>
            <cfloop index = i from = 1 
                    to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
                <cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
                <br>#i# #sCurrent["ID"]# 
                    (#sCurrent["LINE"]#,#sCurrent["COLUMN"]#) 
                    #sCurrent["TEMPLATE"]#
            </cfloop>
        </cfoutput>
		<CFAbort>
    </cfcatch>
</cftry>


<CFTry> 
 <!---Create Claims directory---->
 <cfdirectory directory = "\\ewhnas\PsychSelect\clients\www.psychselect.com\wwwroot\cgi-bin\tac7-0\Claims\Claims#PractitionerNumber#\" action = "create">
 <cfcatch>
        <h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
        <cfoutput>
		Error encountered when creating claims directory<br>
            <!--- and the diagnostic message from the ColdFusion server --->
            <p>#cfcatch.message#</p>
            <p>Caught an exception, type = #CFCATCH.TYPE# </p>
            <p>The contents of the tag stack are:</p>
            <cfloop index = i from = 1 
                    to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
                <cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
                <br>#i# #sCurrent["ID"]# 
                    (#sCurrent["LINE"]#,#sCurrent["COLUMN"]#) 
                    #sCurrent["TEMPLATE"]#
            </cfloop>
        </cfoutput>
		<CFAbort>
    </cfcatch>
</cftry>

 <CFTry>
 <!---Create OfficeAlly directory ----->
 <cfdirectory directory = "\\ewhnas\PsychSelect\clients\www.psychselect.com\wwwroot\cgi-bin\tac7-0\OfficeAlly\OfficeAlly#PractitionerNumber#\" action = "create">
 <cfcatch>
        <h3>Database Creation <b>Error</b></h3>
		<p>Please report this to Technical support: wcw@psychselect.com<br>
			Please include the following information:<p>
        <cfoutput>
		Error encountered when creating Office Ally directory<br>
            <!--- and the diagnostic message from the ColdFusion server --->
            <p>#cfcatch.message#</p>
            <p>Caught an exception, type = #CFCATCH.TYPE# </p>
            <p>The contents of the tag stack are:</p>
            <cfloop index = i from = 1 
                    to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
                <cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
                <br>#i# #sCurrent["ID"]# 
                    (#sCurrent["LINE"]#,#sCurrent["COLUMN"]#) 
                    #sCurrent["TEMPLATE"]#
            </cfloop>
        </cfoutput>
		<CFAbort>
    </cfcatch>
</cftry>

<font face="arial" color="darkblue"><b>Your account is now ready for setup.<p>

<CFIf isDefined("GetTheName.Email")>
	<CFIf IsValid("Email",GetTheName.Email)>
		<CFMail To = "#GetTheName.Email#"
        From = "wcw@psychselect.com"
        Subject = "Your new TherapyAppointment.com account">
<CFMailParam File="C:\inetpub\wwwroot\Clients\www.psychselect.com\cgi-bin\cb\OfficeAllyApplication.pdf">
<CFMailParam File="C:\inetpub\wwwroot\Clients\www.psychselect.com\cgi-bin\cb\BusinessAssociateAgreement.pdf">
<CFMailParam File="C:\inetpub\wwwroot\Clients\www.psychselect.com\cgi-bin\cb\ApptReminderForm.doc">
		
Welcome aboard! Here is the information you will need to set up your account with
TherapyAppointment.com, if you have not done so already. 

(If you have already entered your practice information and set up your appointment
schedule, you can skip to step 5 below.)

Step 1: please use FireFox as your browser instead of Internet Explorer or Chrome
or Safari, whether you are using a PC or a Mac system. To download a free copy
of FireFox, go to: www.firefox.com Install the software and use it for the remainder
of the steps below.

Step 2: Using your office computer, go to the following web site:

https://www.psychselect.com/cgi-bin/cb/NewTherapist.cfm

(you can just click on the link after you copy down the login information below)

Enter this information when requested to do so:

Signup Number: #PractitionerNumber#

Validation code: #form.word#

(You'll only visit this website this one time to set up 
your account. After establishing your account, you'll go to
www.therapyappointment.com and click on "Therapist Login.")

Step 3: Enter the information requested. If you don't understand a particular question,
just leave the default selected--you can make "Preferences" changes later.

Step 4: Create your therapy schedule by checking the appropriate boxes on the page that
appears next--one checkmark for each available time slot in a typical week.

Step 5: Once you have logged in, you may want to view the tutorial videos. Click 
"More..." and then "Videos" to view them. They give instructions for using the schedule,
charting, preparing claims, and entering patient information.

Step 6: If you want to use the integrated electronic billing features instead of paper
billing (and we would strongly advise this), you will need to establish an account with
our preferred clearinghouse, Office Ally. A tip sheet for completing their online
application for an account is included as an attachment to this email. Their accounts
are either either low cost or free, according to the nature of your claims. 

Step 7: If you want to use the integrated charge card processing features of
TherapyAppointment.com, you will need to establish an account with Cayan or Payline
Data, the two services that are fully integrated with our service. Please call us at
800-242-2127 option 2 for help in setting this up. You may also use an independent
credit card service like Square (which may have lower rates for small practices);
however, their service is not fully integrated into our own service.

Step 8: Sign up for your first online class ("webinar") with our Software Orientation
Specialist, Denise Hoyt. The class schedule may be found on our main web page at 
www.therapyappointment.com - look for the "Webinars and Videos" link near the top right
corner. You may also contact Denise by email at: denise@therapyappointment.com

We've enclosed a form that you may use or modify or add to your current new patient forms;
it asks new patients how they would like to receive appointment reminders. We've also enclosed
a signed "Business Associate Agreement": complete this and keep it on file as proof that
you have ensured the security of your data. (This is a HIPAA requirement.) Finally, the
application for an Office Ally account is also attached.

If you have any questions, the fastest way to get technical support is through our
support ticket system. Visit www.psychselect.com/support to use this system.
You can also simply reply to this email.

Finally, if you are a part of a group practice, please learn from the group manager
who owns the chart records that will be contained in our system. A prior discussion
of this issue can help avoid confusion if a therapist leaves the group in the future. 

Thanks for choosing TherapyAppointment.com! 

Best regards,

Your TherapyAppointment support team

Email: https://therapyappointment.desk.com/customer/portal/emails/new
Phone: (800) 242-2127
Fax: (855) 336-7187
</CFMail>

	<CFElse>
		<cfoutput>Unfortunately, the email address you gave us, "#GetTheName.email#", does not appear to be valid.<br>
		This is not a problem if you want to set up your account right now. If you don't have the time now,<br>
		please <a href="https://therapyappointment.desk.com/customer/portal/emails/new" target="_blank">email us</a> and we will assist you with this problem.<p>
		</cfoutput>
		<CFSet Problem=1>
	</CFIf>
<CFElse>
	Unfortunately, you did not supply an email address when you gave your credit card information.<br>
	This is not a problem if you want to set up your account right now. If you don't have the time now,<br>
	please <a href="https://therapyappointment.desk.com/customer/portal/emails/new" target="_blank">email us</a> and we will assist you with this problem.<p>
	<CFSet Problem=1>
</CFIf>

<CFIf NOT isDefined("Problem")>

	If you have about 15 minutes available right now, you may set up your TherapyAppointment.com account<br>
	immediately. Simply press the button below. If you don't have time now, look for an email from us; it will<br>
	contain instructions for setting up your account later. The email will be sent to <cfoutput>"#GetTheName.email#".</cfoutput><p>
	
</CFIf>


<CFForm name="whoisit" action="HTTPS://www.psychselect.com/cgi-bin/cb/NewTherapist.cfm" method="post">
            <!--- Test to see if their browser has javascript enabled --->
            <Input type="hidden" name="JavascriptSupported" value="no">
            <Input type="hidden" name="CookiesSupported" value="no">
            <SCRIPT LANGUAGE="JAVASCRIPT" TYPE="TEXT/JAVASCRIPT">
            <!--

            document.whoisit.JavascriptSupported.value = "yes";

            //-->
            </SCRIPT>
            <!--- Test to see if their browser accepts cookies --->
            <SCRIPT LANGUAGE="JAVASCRIPT" TYPE="TEXT/JAVASCRIPT">
            <!--
            if ( navigator.cookiesAreEnabled() ) {
                document.whoisit.CookiesSupported.value = "yes";}
             //-->
            </SCRIPT>
     
     
    <CFInput Name="Word" Type="Hidden" Value="#form.Word#">
	<CFInput Name="Practitioner" Type="Hidden" Value="#PractitionerNumber#">
	<CFINPUT Name="Submit1" TYPE="SUBMIT" VALUE="Set Up Account Now">
</cfform>

</font>		
        
        
	</div>
	<div class="clearfix"></div>	
		
		<!-- Sidebar -->	
	</div>
</div>
	
	</div>
	
<!-- wp_footer() -->
	
</center>
</body>
</html>