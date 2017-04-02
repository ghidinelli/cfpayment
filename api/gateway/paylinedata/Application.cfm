<cfapplication
  name = "TherapyAppointmentBilling"
  sessionManagement = "Yes"
  ScriptProtect = "all">

<!---CFError Template="ErrorMessage.cfm" Type="request"--->
<CFSet PathRef = "www.psychselect.com">
<CFSet DBDSN = "TherapyAppoint">
<!---<CFSet DBDSN = "tasandbox">--->


<CFSet form.DateAndTime = "#now()#">
<CFSet form.REMOTE_ADDR = "#CGI.REMOTE_ADDR#">
<CFSet form.SCRIPT_NAME = "#CGI.SCRIPT_NAME#">

<cfparam name="session.firstname" default=""/>
<cfparam name="session.lastname" default=""/>
<cfparam name="session.ccaddress" default=""/>
<cfparam name="session.cccity" default=""/>
<cfparam name="session.ccstate" default=""/>
<cfparam name="session.ccemail" default=""/>
<cfparam name="session.code" default=""/>
<cfparam name="session.postal" default=""/>
<cfparam name="session.amount" default=""/>
<cfparam name="session.appointments" default=""/>
<cfparam name="session.redirecturl" default=""/>
<cfparam name="session.transactionid" default=""/>
<cfparam name="session.others" default=""/>
<cfparam name="session.appointments" default=""/>
<cfparam name="session.secondary" default=""/>

<cfif !StructKeyExists(application,'paymentservice') OR StructKeyExists(url,'reload')>
	<cflock scope="application" type="exclusive" timeout="10">
		<cfset application.paymentService = createObject('component','paymentService').init('dv637Zh3r2sRdrXDzWjq97KCY2WY6aR5')>
	</cflock>
</cfif>
<!----
<CFInsert datasource = "#DBDSN#" tablename = "AccessLog" formfields = "DateAndTime,REMOTE_ADDR,SCRIPT_NAME">--->


