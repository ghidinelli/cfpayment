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
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Patua+One" >----->

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
<center>
<CFSet PathRef = "www.psychselect.com">
		<!-- #Header -->
		<header id="Header">
			<div id="top_bar">
				<div class="container">
					<div class="sixteen columns">
						<!-- #logo -->
						<a id="logo" href="http://therapyappointment.com" title="TherapyAppointment">
							<img src="https://www.psychselect.com/wp-stuff/wp-content/uploads/2013/07/logo.png" alt="TherapyAppointment" />
						</a>
					</div>		
				</div>
			</div>
			
			<div id="Subheader"><div class="container"><div class="sixteen columns"><h1 style="font-family:arial;color:#B8B8B8;">Sign up for an account</h1></div></div></div>
			<!---display error message if it exists--->
			<cfif structKeyExists(url,'result')>
				<p style="color:darkred;font-family:arial;font-size:18pt;font-weight:bold;align:center;">
				Sorry...but there was a problem:<br />
				<cfoutput>#htmleditformat(urlDecode(url.result))#<br />
				Please try again below:</font></cfoutput></p>
			</cfif>
		</header>	
<CFIf structkeyexists(form,'others') OR structKeyExists(url,'reset')> <!---If this is not the first pass through or returning after an error------>
	
	<cfif structKeyExists(form,'others')>
		<cfloop collection="#form#" item="i">
			<cfset session[i] = evaluate('form.' & i)>
		</cfloop>
	</cfif>
	
  <CFIf session.others IS 0>
	<cfcookie name = "GroupNumber" value = 0 secure = "Yes">
	<CFIf session.Appointments is 500>
		<CFSet PayRate = 57.50>
	<CFElse>
		<CFSet PayRate = 30.00><!---since there are no others in the group, there is no $10.00 rate---->
	</CFIf>
	<Table border=0 cellpadding=8 bgcolor="lightgrey" style="-moz-border-radius: 40px;-webkit-border-radius: 40px;-khtml-border-radius: 40px;border-radius: 40px;"><tr><td align=center colspan=2>
	<font face="arial" color="darkblue">
	Your fee will be <b><cfoutput>#DollarFormat(PayRate)#</cfoutput> per month</b> of service. You will be charged<br>
	this amount each month until you discontinue the service. If you decide to<br>
	discontinue the service within the first 30 days, and you have attended one<br>
	or more training classes, your total payment will be refunded to you.<p>
	
	There is also a one-time <b>$39.00 setup fee</b> which pays for unlimited attendance of<br>
	online training classes ("webinars"). In these classes, you will receive full instructions<br>
	on using TherapyAppointment.com to streamline and simplify your psychotherapy practice.<p>
	
	<CFIf PayRate IS 30>
		If your practice grows in the future, and you begin to schedule more than 40 appointments<br>
		per month, your fee will automatically increase. You will be notified by email if this occurs.<p>
	</CFIf>

	If you want to <b>set up a multi-therapist practice account</b> (in which you will pay for the<br>
	accounts of other therapists), first set up your own account. After it has been established,<br>
	look in your "Preferences" for instructions on adding the other therapists.<p>
	</font></td></tr>

	<CFForm Name="FirstPass" ACTION="NewPaymentPortal2.cfm" target="_top" METHOD="POST" style="margin-bottom:0;">
	<CFInput type="hidden" Name="Appointments" value=#session.appointments#>
	<CFIf PayRate IS 57.50>
		<CFInput type="hidden" Name="Amount" Value="96.50">
	<CFElse>
		<CFInput type="hidden" Name="Amount" Value="69.00">
	</CFIf>
	<tr><td align=right><font color="darkblue" face="arial">First Name (as it appears on charge card):</font></td>
	<td align=left><CFInput type="Text" id="firstname" name="firstname" style="width:220;" Maxlength=70  value="#trim(session.firstname)#" required="true" message="Please enter first name"/></td></tr>
	<tr><td align=right><font color="darkblue" face="arial">Last Name (as it appears on charge card):</font></td>
	<td align=left><CFInput type="Text" id="lastname" name="lastname" style="width:220;" Maxlength=70 value="#trim(session.lastname)#"  required="true" message="Please enter last name"/></td></tr>
	
	<tr><td align=right><font color="darkblue" face="arial">Your email address:</font></td>
	<td align=left><CFInput type="Text" id="ccemail" name="ccemail" style="width:220;" Maxlength=50  value="#trim(session.ccemail)#" required="true" message="Please enter email" /></td></tr>
	
	<tr><td align=right><font color="darkblue" face="arial">Street address (billing address for charge card):</font></td>
	<td align=left><CFInput type="text" style="width:220;" id="ccaddress"  Maxlength=70 name="ccaddress"  value="#trim(session.ccaddress)#"  required="true" message="Please enter billing address"/></td></tr>

	<tr><td align=right><font color="darkblue" face="arial">City (of billing address for charge card):</font></td>
	<td align=left><CFInput type="text" id="cccity" name="cccity" style="width:220;" maxlength=70  value="#trim(session.cccity)#"  required="true" message="Please enter billing city"/></td></tr></font>
	
	<tr><td align=right><font color="darkblue" face="arial">State (of billing address for charge card):</font></td>
	<td align=left><CFInput type="text" id="ccstate" name="ccstate" style="width:220;" maxlength=2  value="#trim(session.ccstate)#"  required="true" message="Please enter billing state"/></td></tr></font>
	
	<tr><td align=right><font color="darkblue" face="arial">Zip code (of billing address for charge card):</font></td>
	<td align=left><CFInput type="text" id="Zip" name="postal" style="width:220;" maxlength=5  value="#trim(session.postal)#"  required="true" message="Please enter billing zip"/></td></tr></font>

	<tr><td align=right><font color="darkblue" face="arial">If you are a GoodTherapy.org member, enter your code here:</font></td>
	<td align=left><CFInput type="Text" id="Code" name="Code" style="width:220;" Maxlength=50  value="#trim(session.code)#" /></td></tr>

	<tr><td align=center colspan=2>				
	<CFInput type="submit" name="SubmitThis" Value="Sign me up!">
	</td></tr>
	</cfform>
	</td></tr></table>
	</center>
	</body>
	</html>
	
  <CFElseIf session.Others IS 1>
	<CFSet CB = hash(left(hash(session.secondary),20))>
	<CFSet Zip = left(trim(session.ZipCode),5)>
	<CFQuery Name="SharedSecondary" datasource="#DBDSN#">
		SELECT Practitioner,FormalName,SetRate,GroupNumber,payrate,maxhourspermonth,formalname,zip,p2hash
		FROM UserLogin
		WHERE P2Hash = '#CB#'
			AND Zip like '#Zip#%'
			AND Access = 'T'
		ORDER BY maxhourspermonth DESC
		LIMIT 1
	</CFQuery>

	
	<!------  <cfdump var="#form#"><cfdump var="#sharedsecondary#"><cfoutput>---#cb#---#hash(left(hash(LCase(form.secondary)),20))#----</cfoutput><br /> ------->
	
	<CFQuery Name="FullFee" datasource="#DBDSN#">
		SELECT Practitioner,FormalName,SetRate
		FROM UserLogin
		WHERE P2Hash = '#CB#'
			AND Access = 'T'
			AND MaxHoursPerMonth = 500
	</CFQuery>
	
	<CFIf NOT SharedSecondary.recordcount>
		<Table border=0 cellpadding=8 bgcolor="lightgrey" style="-moz-border-radius: 40px;-webkit-border-radius: 40px;-khtml-border-radius: 40px;border-radius: 40px;"><tr><td align=center colspan=2 border=0><font face="arial" color="darkblue">
		<br />
		Sorry, but we cannot locate other practitioners with that secondary password within that zip code.
		<p>A secondary password is case-senstive, meaning that "PassWord" is not the same as "password".<br>
		Make sure that you have entered the SECONDARY password used by others in that group, and that<br>
		you have entered the office zip code that will be shared by you and the others in that group.
		<p><button onClick="history.go(-1);" style="margin-top:10px;">Try again</button>
		</td></tr></table><cfabort>
	</CFIf>
	
	<CFIf session.Appointments IS 40 OR (session.Appointments IS 10 AND FullFee.RecordCount IS 0)>
		<CFSet NewFullFee = 30>
	<CFElseIf session.Appointments is 10>
		<CFSet NewFullFee = 10>
	<CFElseIf FullFee.RecordCount Greater Than 3>
		<CFSet NewFullFee = 40>
		<cfcookie name = "FFP" value = "#ValueList(FullFee.Practitioner)#" secure = "Yes">
	<CFElse>
		<CFSet NewFullFee = ListGetAt("57.50,52.50,47.50,42.50",FullFee.RecordCount + 1)>
		<cfcookie name = "FFP" value = "#ValueList(FullFee.Practitioner)#" secure = "Yes">
	</CFIf>
	<cfcookie name = "NFF" value = "#NewFullFee#" secure = "Yes">
	<cfcookie name = "GroupNumber" value = #SharedSecondary.GroupNumber# secure = "Yes">

	<Table border=0 cellpadding=8 bgcolor="lightgrey" style="-moz-border-radius: 40px;-webkit-border-radius: 40px;-khtml-border-radius: 40px;border-radius: 40px;"><tr><td align=center colspan=2>
	<font face="arial" color="darkblue">
	Your fee will be <b><cfoutput>#DollarFormat(NewFullFee)#</cfoutput> per month</b> of service. You will be charged<br>
	this amount each month until you discontinue the service. If you decide to<br>
	discontinue the service within the first 30 days, and you have attended one<br>
	or more training classes, your total payment will be refunded to you.<p>
	
	There is also a one-time <b>$39.00 setup fee</b> which pays for unlimited attendance of<br>
	online training classes ("webinars"). In these classes, you will receive full instructions<br>
	on using TherapyAppointment to streamline and simplify your psychotherapy practice.<p>
	
	<CFIf NewFullFee LESS THAN 35>
		If your practice grows in the future, and you begin to schedule more than <cfoutput>#session.Appointments#</cfoutput> appointments<br>
		per month, your fee will increase. Please notify us when this occurs.<p>
	</CFIf>

	If you want to <b>set up a multi-therapist practice account</b> (in which you will pay<br>
	for the accounts of other therapists), first set up your own account. Within that account,<br>
	click "More..." and then "Preferences" for instructions on adding the other therapists.<p>
	</font></td></tr>

	<CFForm Name="FirstPass" ACTION="NewPaymentPortal2.cfm" target="_top" METHOD="POST" style="margin-bottom:0;">
	<CFInput type="hidden" Name="Appointments" value=#session.appointments#>
	<CFInput type="hidden" Name="Amount" Value="#decimalFormat(NewFullFee + 39.00)#">

	<!----// Seth Johnson ~ Payline data changes ~ 3/11/15---->
	<tr><td align=right><font color="darkblue" face="arial">First Name (as it appears on charge card):</font></td>
	<td align=left><CFInput type="Text" id="firstname" name="firstname" style="width:220;" Maxlength=70  value="#trim(session.firstname)#" required="true" message="Please enter first name"/></td></tr>
	<tr><td align=right><font color="darkblue" face="arial">Last Name (as it appears on charge card):</font></td>
	<td align=left><CFInput type="Text" id="lastname" name="lastname" style="width:220;" Maxlength=70 value="#trim(session.lastname)#"  required="true" message="Please enter last name"/></td></tr>
	
	<tr><td align=right><font color="darkblue" face="arial">Your email address:</font></td>
	<td align=left><CFInput type="Text" id="ccemail" name="ccemail" style="width:220;" Maxlength=50  value="#trim(session.ccemail)#" required="true" message="Please enter email" /></td></tr>
	
	<tr><td align=right><font color="darkblue" face="arial">Street address (billing address for charge card):</font></td>
	<td align=left><CFInput type="text" style="width:220;" id="ccaddress"  Maxlength=70 name="ccaddress"  value="#trim(session.ccaddress)#"  required="true" message="Please enter billing address"/></td></tr>

	<tr><td align=right><font color="darkblue" face="arial">City (of billing address for charge card):</font></td>
	<td align=left><CFInput type="text" id="cccity" name="cccity" style="width:220;" maxlength=70  value="#trim(session.cccity)#"  required="true" message="Please enter billing city"/></td></tr></font>
	
	<tr><td align=right><font color="darkblue" face="arial">State (of billing address for charge card):</font></td>
	<td align=left><CFInput type="text" id="ccstate" name="ccstate" style="width:220;" maxlength=2  value="#trim(session.ccstate)#"  required="true" message="Please enter billing state"/></td></tr></font>
	
	<tr><td align=right><font color="darkblue" face="arial">Zip code (of billing address for charge card):</font></td>
	<td align=left><CFInput type="text" id="Zip" name="postal" style="width:220;" maxlength=5  value="#trim(session.postal)#"  required="true" message="Please enter billing zip"/></td></tr></font>

	<tr><td align=right><font color="darkblue" face="arial">If you are a GoodTherapy.org member, enter the code here:</font></td>
	<td align=left><CFInput type="Text" id="Code" name="Code" style="width:220;" Maxlength=50  value="#trim(session.code)#" /></td></tr>

	<tr><td align=center colspan=2>				
		
	<CFInput type="submit" name="SubmitThis" Value="Sign me up!">
	</td></tr>
	</cfform>
	</td></tr></table>
	</center>
  <CFElse>
	Error; you must start the signup process over again.<cfabort>
  </CFIf>
<CFElse> 
	<!---if this is a form submission copy all form vars into session--->
	<cfif StructKeyExists(form,'firstname')> 
		<cfloop collection="#form#" item="i">
			<cfset session[i] = evaluate('form.' & i)>
		</cfloop>
			<!---software comes here in second pass ----->
		<CFIf ParameterExists(session.code) AND trim(session.code) IS "45202">
			<CFSet session.Amount = "49.00">
			<Script>
				alert('The discount code was entered correctly.\nYou will be charged $49.00 for the first two months of service\n($10.00 plus the $39.00 signup fee).');
			</Script>
			<cfcookie name = "GoodTherapy" value = "#session.appointments#" secure = "Yes">
		<CFElseIf ParameterExists(session.code) AND trim(session.code) IS NOT "">
			<font face="arial" color="darkblue" size="+2">Sorry, but that is not a valid discount code.<br>
			Please <a href="NewPaymentPortal.cfm">CLICK HERE</a> to try again or to sign up without a code.<br>
			To sign up without a code, leave the "code" blank empty.
			<cfabort>
			<cfcookie name = "GoodTherapy" value = "0" secure = "Yes">
		<CFElse>
			<cfcookie name = "GoodTherapy" value = "0" secure = "Yes">
		</CFIf>

		<!----//  Seth Johnson ~ Payline Data ~ 3/11/15 ~ changed CardHolder, to firstname & lastname---->
		<cfquery name="ThisInsert" datasource="#DBDSN#" Result="MyResult"> 
	         INSERT INTO TransactionLog (Amount,CardHolder,Email)
	         VALUES (
			         	 <cfqueryparam cfsqltype="CF_SQL_CHAR" value="#session.Amount#">,
			             <cfqueryparam cfsqltype="CF_SQL_CHAR" value="#session.firstname# #session.lastname#">,
						 <cfqueryparam cfsqltype="CF_SQL_CHAR" value="#session.ccemail#">
					)
	    </cfquery>
	    <cfset session.transactionid = MyResult.GENERATED_KEY> 
	</cfif>

		<!----//  Seth Johnson ~ Payline Data ~ 3/11/15---->

		<!---use customer information to add customer to payline database--->
		
		<cfset session.redirecturl = 'https://www.psychselect.com/cgi-bin/paylinedatanew/complete.cfm'/>

		<cfset result = application.paymentService.addCustomer(attributecollection=session)/>
		
		<cfset resultApproved = XmlSearch(result.response, 'result')[1]/>

		<cfif resultApproved.xmltext eq 1>
			<!---result was successful--->
			<cfset getAction = XmlSearch(result.response, 'form-url')[1]>
			<cfset formaction = getAction[1].xmltext>

			<CFForm Name="paylinedata" ACTION="#formaction#" target="_top" METHOD="POST" style="margin-bottom:0;">
				<Table border=0 cellpadding=8 bgcolor="lightgrey" style="-moz-border-radius: 40px;-webkit-border-radius: 40px;-khtml-border-radius: 40px;border-radius: 40px;">
				<tr><td colspan="2" align=center>
				<font face="arial" color="darkblue">
				<p>The term "CVV" below refers to the security code on<br>
				the back of the credit card (on the front for Amex).<p></font></td></tr>

	            <tr><td align=right><font color="darkblue" face="arial">Credit Card Number</font></td><td><CFINPUT required="true" message="Please enter your credit card number." type ="text" name="billing-cc-number" value=""> </td></tr>
	            <tr><td align=right><font color="darkblue" face="arial">Expiration Date</font></td><td><CFINPUT required="true" message="Please enter your credit card expiration (expiry) date." type ="text" size="5" name="billing-cc-exp" value="" maxlength="8"><font color="grey" face="arial"> &nbsp; (e.g. 01/17)</font></td></tr>
	            <tr><td align=right><font color="darkblue" face="arial">CVV</font></td><td><CFINPUT required="true" message="Please enter your credit card CVV (security) code." type = "text" size="5" name="cvv" maxlength="4"><font color="grey" face="arial"> &nbsp; (e.g. 123) </font></td></tr>
				<tr><td colspan="2" align=center>
					<CFInput type="submit" Name="SubMitItAlready" Value="Proceed">
				</td></tr></table>	
			</CFForm>
		<cfelse>
			<!---result was NOT successful--->
			<cfset error = XmlSearch(result.response, 'result-text')[1]>
			<cfset resultcode = error.xmltext/>
				<p style="color:darkred;font-family:arial;font-size:18pt;font-weight:bold;">
				Sorry...but that charge did not go through.<br />
				
				<cfif structKeyExists(url,'result')>
					Here is what is reported as the problem:<br />
					<cfoutput>#htmleditformat(urlDecode(url.result))#<br />
					#htmleditformat(urlDecode(resultcode))#</cfoutput>
				</cfif>
				</font>
					<br /><br /><a href="NewPaymentPortal.cfm"><button>Try Again</button></a></p>

		</cfif>
	</cfif>
	</center>
	</body>
</html>