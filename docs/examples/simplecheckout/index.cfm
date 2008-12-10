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
<cfimport taglib="../customtags" prefix="ct">
<!--- TODO:initialize form fields --->
<cfinclude template="_process.cfm">

<!--- set some defaults for the form fields --->
<cfset request.formdefaults=StructNew()>
<cfset request.formdefaults.divClass="formrow">
<cfset request.formdefaults.labelClass="width150">

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-type" content="text/html; charset=iso-8859-1" />
<title>Sample Credit Card Form - CFPayment - cfpayment.riaforge.org</title>
<style type="text/css">
.width150 {float:left; width:150px; margin:3px;}
.formrow {margin-bottom:5px; clear:left;}
.required {color:##f00;}
.radiobutton {width:auto; text-align:left;}
span.formerror {color: red; font-style: italic; margin-left: 10px; width: auto; /*display: -moz-inline-box; display: inline-block;*/}
input.formerror {border:thin red solid;}
fieldset {background-color: ##99CF8E; margin-top:10px;}
legend { padding:5px; background-color:##63865A; border:thin black solid; color:white; }
label {font-weight: bold;}
##messageboxerror { background: ##FAFAD2; color: ##F00; border: medium double; margin: 5px; padding: 5px; }
##messageboxerror h3 {margin:0;}
</style>
</head>
<body>
<h1>Sample Credit Card Form - CFPayment</h1>
<p>This is a test form using the Bogus gateway. Use a credit card number of "1" for success, "2" for decline, anything else for error.
Use "5000300020003003" as a test number that will pass the check digit algorthm.</p>
</cfoutput>
<!--- check for and display errors --->
<cfif structKeyExists(variables, "errors") and ArrayLen(errors)>
	<cfset numErrors=ArrayLen(errors)>
	<cfoutput><div id="creditcarderrors"><div id="messageboxerror">
		<h3>The following error<cfif numErrors NEQ 1>s were<cfelse> was</cfif> found with your submission:</h3><ul></cfoutput>
		<cfloop from="1" to="#NumErrors#" index="ctr">
			<cfset error=errors[ctr]>
			<cfif isStruct(error)>
				<cfoutput><li>#error.message#</li></cfoutput>
			<cfelse>
				<cfoutput><li>#error#</li></cfoutput>
			</cfif>
		</cfloop>
	<cfoutput></ul></div></div></cfoutput>
</cfif>
<cfoutput>
<form action="#URLSessionFormat(CGI.SCRIPT_NAME)#" method="post" name="mainform" id="mainform">
	<fieldset id="productinfo">
		<legend>Product Information</legend>
		<p>TODO: Product Fields for Checkout</p>
	</fieldset>
	<fieldset id="creditcardbillinginfo">
	<legend>Credit Card Billing Information</legend>
	</cfoutput>
	<ct:formedit title="First Name" name="BillingFirstName" required="true" value="#form.BillingFirstName#" size="25">
	<ct:formedit title="Last Name" name="BillingLastName" required="true" value="#form.BillingLastname#" size="25">
	<ct:formedit title="Address" name="BillingAddressOne" required="true" value="#form.BillingAddressOne#" size="57">
	<ct:formedit title="City" name="BillingCity" required="true" value="#form.BillingCity#">
	<ct:formselectbox title="State" name="BillingState" required="true" value="#form.BillingState#" listtype="state">
	<ct:formedit title="Zip" name="BillingZip" required="true" value="#form.BillingZip#" size="10">
	<ct:formedit title="Phone Number" name="BillingPhoneNumber" required="true" value="#form.BillingPhoneNumber#">
	<ct:formedit title="E-mail Address" name="BillingEmailAddress" required="false" value="#form.BillingEmailAddress#" size="57">
	<cfoutput>
	</fieldset>
	<fieldset id="creditcardinfo">
	<legend>Credit Card Information</legend>
	</cfoutput>
	<ct:formedit title="Amount" name="Amount" required="true" value="#form.Amount#" size="10">
	<ct:formselectbox title="Expiration Month" name="ExpirationMonth" displaylist="#creditcard.CREDITCARD_EXP_MONTH_DISPLAY_LIST#" valueslist="#creditcard.CREDITCARD_EXP_MONTH_VALUES_LIST#" required="true" value="#form.ExpirationMonth#">
	<ct:formselectbox title="Expiration Year" name="ExpirationYear" displaylist="#creditcard.CREDITCARD_EXP_YEAR_LIST#" required="true" value="#form.ExpirationYear#">
	<ct:formedit title="Card Number" name="CardNumber" required="true" value="#form.CardNumber#">
	<ct:formedit title="CVV2" name="cvv2" required="false" value="#form.cvv2#" size="4">
	<cfoutput></fieldset>
	<input type="submit" value="Submit Payment" name="submitBtn" id="submitBtn" />
	</form>
</form>
</body></html></cfoutput>

<cfsetting enablecfoutputonly="false">