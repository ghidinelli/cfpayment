<cfsetting enablecfoutputonly="true">
<!---
Copyright 2008 Brian Ghidelli and Mark Mazelin.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

$Id$
--->
<!--- for testing, set the gateway you want to use here --->
<cftry>
	<!--- create a config that is not in svn --->
	<cfset gwParams = createObject("component", "cfpayment.localconfig.config").init("developer") />
<cfcatch>
	<!--- if gwParams doesn't exist (or otherwise bombs), create a generic structure with blank values --->
	<cfset gwParams = StructNew() />
	<cfset gwParams.Path = "bogus.gateway" />
	<!--- these following params aren't needed for the bogus gateway, but should normally be filled in --->
	<cfset gwParams.MerchantAccount = "" />
	<cfset gwParams.userName = "" />
	<cfset gwParams.password = "" />
</cfcatch>
</cftry>
<cfset svc = createObject("component", "cfpayment.api.core") />
<!--- create gw and get reference --->
<cfset svc.init(gwParams) />
<cfset gw = svc.getGateway() />
<cfset creditcard = svc.createCreditCard()>
<cfset money = svc.createMoney()>
<cfset errors=ArrayNew(1)>
<cftry>
	<!--- Initialize Form Variables --->
	<cfparam name="form.BillingFirstName" default="">
	<cfparam name="form.BillingLastName" default="">
	<cfparam name="form.BillingAddressOne" default="">
	<cfparam name="form.BillingCity" default="">
	<cfparam name="form.BillingState" default="">
	<cfparam name="form.BillingZip" default="">
	<cfparam name="form.BillingCountry" default="">
	<cfparam name="form.BillingPhoneNumber" default="">
	<cfparam name="form.BillingEmailAddress" default="">

	<cfparam name="form.Amount" default="">
	<cfparam name="form.CardNumber" default="">
	<cfparam name="form.CardType" default="">
	<cfparam name="form.ExpirationMonth" default="">
	<cfparam name="form.ExpirationYear" default="">
	<cfparam name="form.TransactionType" default="SALE">
	<cfparam name="form.cvv2" default="">

	<cfif structKeyExists(form, "submitBtn")>
		<!--- PROCESS --->
		<cftry>
			<!--- populate credit card object with passed data --->
			<cfset ccObjList="Account,Month,Year,VerificationValue,FirstName,LastName,Address,PostalCode">
			<cfset formFieldList="CardNumber,ExpirationMonth,ExpirationYear,cvv2,BillingFirstName,BillingLastName,BillingAddressOne,BillingZip">
			<cfset numFields=ListLen(ccObjList)>
			<cfloop from="1" to="#numFields#" index="idx">
				<cfset currCCField=ListGetAt(ccObjList, idx)>
				<cfset currFormField=ListGetAt(formFieldList, idx)>
				<cfinvoke component="#creditcard#" method="set#currCCField#">
					<cfinvokeargument name="#currCCField#" value="#form[currFormField]#" />
				</cfinvoke>
			</cfloop>
			<!--- validate credit card --->
			<cfset errors=creditCard.validate()>
			<cfif not ArrayLen(errors)>

				<!--- gateway specific parameters --->
				<!--- for example, the skipjack gateway requires email, phonenumber and ordernumber; these are passed in the options struct --->
				<cfset options=StructNew()>
				<cfset options.address=StructNew()>
				<cfset options.email=form.BillingEmailAddress>
				<!--- send through generic address structure --->
				<cfset options.address.phone=form.BillingPhoneNumber>
				<cfset options.address.Address1=form.BillingAddressOne>
				<cfset options.address.City=form.BillingCity>
				<cfset options.address.State=form.BillingState>
				<cfset options.address.PostalCode=form.BillingZip>
				<cfset options.address.Country=form.BillingCountry>
				<cfset options.order_id="1234ORDER">

				<!--- setup the money object with the amount --->
				<cfset money.init(form.amount * 100)><!--- in cents --->

				<!--- send authorize command --->
				<!--- pass in the money object, the creditcard object, extra parameters required by the specific gateway --->
				<cfset authResponse=gw.authorize(money, creditCard, options)>

				<!--- process response --->
				<!--- <cfset authResponse.dumpInstance()><cfabort> --->
				<cfif authResponse.getSuccess()>
					<cfoutput>The credit card payment was successfully processed. Record it somewhere (using the authResponse object data) and record to a receipt page...</cfoutput>
					<!--- TODO: you should now do something (record, redirect, etc.) --->
					<cfdump var="#authResponse.getMemento()#">
					<cfabort>
				<cfelse>
					<!--- add the gateway errors to any existing errors we are tracking (eg. creditcard object errors) --->
					<cfset ArrayAppend(errors, authResponse.getMessage())>
				</cfif>
			</cfif>
			<!--- if we get here, there were errors --->
			<!--- <cfdump var="#errors.getErrors()#"> --->
		<cfcatch type="cfpayment">
			<!--- <cfdump var="#cfcatch#"><cfabort> --->
			<cfset ArrayAppend(errors, cfcatch.message)>
		</cfcatch>
		<cfcatch>
			<!--- <cfdump var="#cfcatch#"><cfabort> --->
			<cfset ArrayAppend(errors, cfcatch.message)>
		</cfcatch>
		</cftry>
	</cfif>

<cfcatch>
	<cfoutput>Initialization Error - Credit Card Payment Form</cfoutput>
	<!--- TODO: this should be e-mailed or logged somewhere --->
	<cfdump var="#CFCatch#" label="CFCatch Scope">
	<cfif isdefined("arguments")><cfdump var="#arguments#" label="Arguments Scope"></cfif>
	<cfif isdefined("attributes")><cfdump var="#attributes#" label="Attributes Scope"></cfif>
	<cfif isdefined("CGI")><cfdump var="#CGI#" label="CGI Scope"></cfif>
	<cfif isdefined("Request")><cfdump var="#Request#" label="Request Scope"></cfif>
	<cfif isdefined("URL")><cfdump var="#URL#" label="URL Scope"></cfif>
	<cfif isdefined("Form")><cfdump var="#Form#" label="Form Scope"></cfif>
	<cfif isdefined("session")><cfdump var="#Session#" label="Session Scope"></cfif>
	<cfabort>
</cfcatch>
</cftry>
<cfsetting enablecfoutputonly="false">