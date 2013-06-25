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
<cfcomponent name="payflowtest" extends="mxunit.framework.TestCase" output="false">

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

		<cfset var gwParams = "">

		<cfset variables['lib'] = createObject("component", "payflowLibrary").init()>

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
				<cfset gwParams.password = lib.getPassword()>
			</cfcatch>
		</cftry>

		<!--- create global variables --->
		<cfset variables['svc'] = createObject("component", "cfpayment.api.core").init(gwParams)>
		<cfset variables['gw']  = svc.getGateway()> <!--- create gw and get reference --->
		<cfset variables['person'] = lib.getPerson()>
	</cffunction>

<!--- =======================================================================================================
	  testPurchaseForAllCardTypes                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "testPurchaseForAllCardTypes"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var AcceptedCardTypes = lib.getAcceptedCardTypes()>
		<cfset var type = "visa">

		<cfloop index="type" list="#AcceptedCardTypes#">
			<cfset testPurchase(type)>
		</cfloop>
	</cffunction>

<!--- =======================================================================================================
	  testAuthorizeAndCaptureForAllCardTypes                                                                =
	  ================================================================================================== --->
	<cffunction name       = "testAuthorizeAndCaptureForAllCardTypes"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var AcceptedCardTypes = lib.getAcceptedCardTypes()>
		<cfset var type = "visa">

		<cfloop index="type" list="#AcceptedCardTypes#">
			<cfset testAuthorizeAndCapture(type)>
		</cfloop>
	</cffunction>

<!--- =======================================================================================================
	  testCreditForAllCardTypes                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "testCreditForAllCardTypes"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var AcceptedCardTypes = lib.getAcceptedCardTypes()>
		<cfset var type = "visa">

		<cfloop index="type" list="#AcceptedCardTypes#">
			<cfset testCredit(type)>
		</cfloop>
	</cffunction>

<!--- =======================================================================================================
	  testStatusForAllCardTypes                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "testStatusForAllCardTypes"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var AcceptedCardTypes = lib.getAcceptedCardTypes()>
		<cfset var type = "visa">

		<cfloop index="type" list="#AcceptedCardTypes#">
			<cfset testStatus(type)>
		</cfloop>
	</cffunction>

<!--- =======================================================================================================
	  testVoidForAllCardTypes                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "testVoidForAllCardTypes"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var AcceptedCardTypes = lib.getAcceptedCardTypes()>
		<cfset var type = "visa">

		<cfloop index="type" list="#AcceptedCardTypes#">
			<cfset testVoid(type)>
		</cfloop>
	</cffunction>

<!--- -------------------------------------------------------------------------------------------------------------------------------------------------------
	  private test - These are individual test used by the xxxxAllCartType methods.  If you want to test just a single method change the access to public   -
	  -------------------------------------------------------------------------------------------------------------------------------------------------- --->


<!--- =======================================================================================================
	  testPurchase                                                                                          =
	  ================================================================================================== --->
	<cffunction name       = "testPurchase"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" default="Visa">

		<cfset var amount = lib.genAmount()>
		<cfset var creditcard = lib.genCreditCard( svc, arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = lib.genValidOptions()>
		<cfset var result = "">

		<cfset money.init(amount * 100, "USD")><!--- in cents --->

		<cfset response = gw.purchase(money, creditCard, options)>

		<cfset result = response.getParsedResult()>
		<cfset assertTrue(response.getSuccess(), "The gateway purcahse response not successful for #cardtype#.")>

		<cfset assertTrue( structKeyExists(result, "BillToFirstName") and result.BillToFirstName EQ person.firstName, "The PayPal customer first name should have been #person.firstName#." )>
		<cfset assertTrue( structKeyExists(result, "BillToLastName") and result.BillToLastName EQ person.lastName, "The PayPal customer last name should have been #person.lastName#." )>
		<cfset assertTrue( structKeyExists(result, "AMT") and result.AMT EQ amount, "The transaction amount should have been #amount#." )>
	</cffunction>

<!--- =======================================================================================================
	  testAuthorizeAndCapture                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "testAuthorizeAndCapture"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" default="Visa">

		<cfset var amount = lib.genAmount()>
		<cfset var creditcard = lib.genCreditCard( svc, arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = lib.genValidOptions()>
		<cfset var result = "">
		<cfset var TransactionID = 0>

		<cfset money.init(amount * 100, "USD")><!--- in cents --->

		<!--- Authorization --->
		<cfset response = gw.authorize(money, creditCard, options)>
		<cfset assertTrue(response.getSuccess(), "The gateway authorize response not successful for #cardtype#.")>

		<cfset TransactionID = response.getTransactionId()>
		<cfset assertTrue( Len(TransactionID) GT 0, "The TransactionID not returned by Authorize transaction.")>

		<cfset result = response.getParsedResult()>

		<cfset assertTrue( structKeyExists(result, "BillToFirstName") and result.BillToFirstName EQ person.firstName, "The PayPal customer first name should have been #person.firstName#." )>
		<cfset assertTrue( structKeyExists(result, "BillToLastName") and result.BillToLastName EQ person.lastName, "The PayPal customer last name should have been #person.lastName#." )>
		<cfset assertTrue( structKeyExists(result, "AMT") and result.AMT EQ amount, "The transaction amount should have been #amount#." )>

		<!--- Capture --->
		<cfset response = gw.capture(money, TransactionID, options)>
		<cfset assertTrue( response.getSuccess(), "The gateway capture response not successful for #cardtype# TransactionID: #TransactionID#." )>
	</cffunction>

<!--- =======================================================================================================
	  testCredit                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "testCredit"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" default="Visa">

		<cfset var amount = lib.genAmount()>
		<cfset var creditcard = lib.genCreditCard( svc, arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = lib.genValidOptions()>
		<cfset var result = "">
		<cfset var TransactionID = 0>

		<cfset money.init(amount * 100, "USD")><!--- in cents --->

		<!--- purchase --->
		<cfset response = gw.purchase(money, creditCard, options)>
		<cfset assertTrue(response.getSuccess(), "The gateway purchase response not successful for #cardtype#.")>

		<cfset result = response.getParsedResult()>
		<cfset assertTrue( structKeyExists(result, "AMT") and result.AMT EQ amount, "The transaction amount should have been #amount#." )>

		<cfset TransactionID = response.getTransactionId()>

		<!--- credit --->
		<cfset response = gw.credit(money, TransactionID, options)>
		<cfset assertTrue( response.getSuccess(), "The gateway credit response not successful for #cardtype# TransactionID: #TransactionID#." )>
	</cffunction>

<!--- =======================================================================================================
	  testStatus                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "testStatus"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" default="Visa">

		<cfset var amount = lib.genAmount()>
		<cfset var creditcard = lib.genCreditCard( svc, arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = lib.genValidOptions()>
		<cfset var result = "">
		<cfset var TransactionID = 0>

		<cfset money.init(amount * 100, "USD")><!--- in cents --->

		<!--- Authorization --->
		<cfset response = gw.authorize(money, creditCard, options)>
		<cfset assertTrue(response.getSuccess(), "The gateway authorize response not successful for #cardtype#.")>

		<cfset TransactionID = response.getTransactionId()>
		<cfset assertTrue( Len(TransactionID) GT 0, "The TransactionID not returned by Authorize transaction.")>

		<!--- Status --->
		<cfset response = gw.status(money, TransactionID, options)>
		<cfset assertTrue( response.getSuccess(), "The gateway status response not successful for #cardtype# TransactionID: #TransactionID#." )>

		<cfset result = response.getParsedResult()>

		<cfset assertTrue( structKeyExists(result, "FirstName") and result.FirstName EQ person.firstName, "The PayPal customer first name should have been #person.firstName#." )>
		<cfset assertTrue( structKeyExists(result, "LastName") and result.LastName EQ person.lastName, "The PayPal customer last name should have been #person.lastName#." )>
		<cfset assertTrue( structKeyExists(result, "AMT") and result.AMT EQ amount, "The transaction amount should have been #amount#." )>
		<cfset assertTrue( structKeyExists(result, "ORIGPNREF") and result.ORIGPNREF EQ TransactionID, "The original transaction ID not returned." )>
	</cffunction>

<!--- =======================================================================================================
	  testVoid                                                                                              =
	  ================================================================================================== --->
	<cffunction name       = "testVoid"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" default="Visa">

		<cfset var amount = lib.genAmount()>
		<cfset var creditcard = lib.genCreditCard( svc, arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = lib.genValidOptions()>
		<cfset var result = "">
		<cfset var TransactionID = 0>

		<cfset money.init(amount * 100, "USD")><!--- in cents --->

		<!--- Authorization --->
		<cfset response = gw.authorize(money, creditCard, options)>
		<cfset assertTrue(response.getSuccess(), "The gateway authorize response not successful for #cardtype#.")>

		<cfset TransactionID = response.getTransactionId()>
		<cfset assertTrue( Len(TransactionID) GT 0, "The TransactionID not returned by Authorize transaction.")>

		<!--- Status --->
		<cfset response = gw.void(TransactionID, options)>
		<cfset assertTrue( response.getSuccess(), "The gateway status response not successful for #cardtype# TransactionID: #TransactionID#." )>
	</cffunction>

</cfcomponent>
