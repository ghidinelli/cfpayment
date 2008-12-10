<cfsetting enablecfoutputonly="true">
<!---
	$Id

	Copyright 2008 Mark Mazelin (http://www.mkville.com/)

	Licensed under the Apache License, Version 2.0 (the "License"); you
	may not use this file except in compliance with the License. You may
	obtain a copy of the License at:

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--->
<cfparam name="URL.UseLogging" type="boolean" default="true" />

<!--- create structure to hold defaults for use in coldspring config file --->
<cfset gwParams = StructNew() />
<cfset gwParams.Path = "bogus.gateway" />
<cfset gwParams.MerchantAccount = "" />
<cfset gwParams.userName = "" />
<cfset gwParams.password = "" />

<cfset myfactory = createObject("component","coldspring.beans.DefaultXmlBeanFactory").init(structNew(), gwParams)/>
<cfset myfactory.loadBeansFromXmlFile(expandPath("coldspring.xml.cfm"),true)/>
<cfset svc = myFactory.getBean("cfpaymentCore")>
<cfif URL.UseLogging>
	<cfset gw=myFactory.getBean("cfpaymentGWlogging")>
<cfelse>
	<cfset gw=myFactory.getBean("cfpaymentGW")>
</cfif>

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-type" content="text/html; charset=iso-8859-1" />
<title>Using ColdSpring - CFPayment Example - cfpayment.riaforge.org</title>
</head>

<body>
	<h1>CFPayment Example - Using ColdSpring</h1>
	<p>&raquo;
		<cfif URL.UseLogging>
			<a href="#CGI.SCRIPT_NAME#?UseLogging=false">Disable Gateway Logging</a>
		<cfelse>
			<a href="#CGI.SCRIPT_NAME#?UseLogging=true">Enable Gateway Logging</a>
		</cfif>
	</p>
	<ul>
		<li>Gateway Name = #gw.getGatewayName()#</li>
		<li>Gateway Version = #gw.getGatewayVersion()#</li>
		<li>Gateway URL = #gw.getGatewayUrl()#</li>
	</ul>
	<cfif structKeyExists(request, "logData")>
		<cfdump var="#request.logData#" label="Gateway Method Logging Result">
	<cfelse>
		<p>NO GATEWAY LOGGING DATA FOUND</p>
	</cfif>
	<cfdump var="#svc#">
	<cfdump var="#gw#">
</body>
</html></cfoutput>
<cfsetting enablecfoutputonly="false">