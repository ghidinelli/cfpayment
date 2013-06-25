<!---
	$Id$

	Copyright 2013 Andrew Penhorwood (http://www.coldbits.com/)

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
<cfcomponent name="payflowBasicAccess" extends="mxunit.framework.TestCase" output="false">

<!--- =======================================================================================================
	  setUp                                                                                                 =
	  ================================================================================================== --->
	<cffunction name       = "setUp"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset variables['lib'] = createObject("component", "payflowLibrary").init()>
	</cffunction>

<!--- =======================================================================================================
	  testPurchase                                                                                          =
	  ================================================================================================== --->
	<cffunction name       = "testGatewayAccess"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var creditcard = 0>
		<cfset var gwParams = 0>
		<cfset var options = 0>
		<cfset var result = 0>
		<cfset var money = 0>
		<cfset var svc = 0>
		<cfset var gw = 0>
		<cfset var amount = 56.78>

		<cftry>
			<!--- create a config that is not in svn --->
			<cfset gwParams = createObject("component", "cfpayment.localconfig.config").init("developer")>

			<cfcatch>
				<!--- if gwParams doesn't exist (or otherwise bombs), create a generic structure with blank values --->
				<cfset gwParams = StructNew() />
				<cfset gwParams.Path = "paypal.payflow.payflowGateway">

				<!--- Account Information from Paypal.  This should be the developer (test) account information. --->
				<cfset gwParams.Partner = lib.getPartner()>
				<cfset gwParams.MerchantAccount = lib.getMerchantAccount()>
				<cfset gwParams.userName = lib.getUserName()>
				<cfset gwParams.password = "bogusPassword">
			</cfcatch>
		</cftry>

		<!--- Failure to Authenticate --->
		<cfset svc = createObject("component", "cfpayment.api.core").init(gwParams)>
		<cfset gw  = svc.getGateway()> <!--- create gw and get reference --->

		<cfset creditcard = lib.genCreditCard(svc)>
		<cfset money   = svc.createMoney()>
		<cfset options = lib.genValidOptions()>

		<cfset money.init(amount * 100, "USD")><!--- in cents --->
		<cfset response = gw.purchase(money, creditCard, options)>

		<cfset result = response.getParsedResult()>
		<cfset assertTrue( structKeyExists(result, "RESPMSG") and result.RESPMSG EQ "User authentication failed", "Authentication passed but should have failed." )>

		<!--- Authenticate and handle purchase transaction --->
		<cfset gwParams.password = lib.getPassword()>
		<cfset svc = createObject("component", "cfpayment.api.core").init(gwParams)>
		<cfset gw  = svc.getGateway()> <!--- create gw and get reference --->

		<!--- create items for a purchase transation --->
		<cfset creditcard = lib.genCreditCard(svc)>
		<cfset money   = svc.createMoney()>
		<cfset options = lib.genValidOptions()>

		<cfset money.init(amount * 100, "USD")><!--- in cents --->
		<cfset response = gw.purchase(money, creditCard, options)>
		<cfset assertTrue(response.getSuccess(), "The gateway response not successful for #cardtype#.")>
	</cffunction>

</cfcomponent>
