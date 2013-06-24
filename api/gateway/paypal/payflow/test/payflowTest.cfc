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
		<cfset var userConfig = StructNew()>

		<!--- BEGIN *** These values MUST be configured according to the info sent to you from Paypal *** --->
		<cfset userConfig['acceptCardTypes'] = "Visa,AmEx,Discover,MasterCard">	<!--- Card Types your account accepts.  Possible values: AmEx,AmExCorp,DinersClub,Discover,JCB,MasterCard,Visa --->
		<cfset userConfig['Partner']         = "">
		<cfset userConfig['MerchantAccount'] = "">
		<cfset userConfig['userName']        = "">
		<cfset userConfig['password']        = "">
		<!--- END   *** These values MUST be configured according to the info sent to you from Paypal *** --->

		<cftry>
			<!--- create a config that is not in svn --->
			<cfset gwParams = createObject("component", "cfpayment.localconfig.config").init("developer")>

			<cfcatch>
				<!--- if gwParams doesn't exist (or otherwise bombs), create a generic structure with blank values --->
				<cfset gwParams = StructNew() />
				<cfset gwParams.Path = "paypal.payflow.payflowGateway">

				<!--- Account Information from Paypal.  This should be the developer (test) account information. --->
				<cfset gwParams.Partner = userConfig.Partner>
				<cfset gwParams.MerchantAccount = userConfig.MerchantAccount>
				<cfset gwParams.userName = userConfig.userName>
				<cfset gwParams.password = userConfig.password>
			</cfcatch>
		</cftry>

		<!--- create global variables --->
		<cfset variables['acceptCardTypes'] = userConfig.acceptCardTypes>
		<cfset variables['svc'] = createObject("component", "cfpayment.api.core").init(gwParams)>
		<cfset variables['gw']  = svc.getGateway()> <!--- create gw and get reference --->

		<cfset variables['person']  = genPerson()>	<!--- create test person. override data points here if you don't like the default ones --->
	</cffunction>

<!--- =======================================================================================================
	  testPurchaseForAllCardTypes                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "testPurchaseForAllCardTypes"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = "purchase (sale) test of all accepted card types.  See acceptCardTypes for list of cards being processed"
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfloop index="type" list="#acceptCardTypes#">
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
				purpose    = "Authoirze and Capture test of all accepted card types.  See acceptCardTypes for list of cards being processed"
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfloop index="type" list="#acceptCardTypes#">
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
				purpose    = "Purchase and Credit test of all accepted card types.  See acceptCardTypes for list of cards being processed"
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfloop index="type" list="#acceptCardTypes#">
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
				purpose    = "Authoirze and Status (inquiry) test of all accepted card types.  See acceptCardTypes for list of cards being processed"
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfloop index="type" list="#acceptCardTypes#">
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
				purpose    = "Purchase and Void test of all accepted card types.  See acceptCardTypes for list of cards being processed"
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfloop index="type" list="#acceptCardTypes#">
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
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" default="Visa">

		<cfset var amount = genAmount()>
		<cfset var creditcard = genCreditCard( arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = genValidOptions()>
		<cfset var result = "">

		<cfset money.init(amount * 100, "USD")><!--- in cents --->

		<cfset response = gw.purchase(money, creditCard, options)>
		<cfset assertTrue(response.getSuccess(), "The gateway purcahse response not successful for #cardtype#.")>

		<cfset result = response.getParsedResult()>

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

		<cfset var amount = genAmount()>
		<cfset var creditcard = genCreditCard( arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = genValidOptions()>
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

		<cfset var amount = genAmount()>
		<cfset var creditcard = genCreditCard( arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = genValidOptions()>
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

		<cfset var amount = genAmount()>
		<cfset var creditcard = genCreditCard( arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = genValidOptions()>
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

		<cfset var amount = genAmount()>
		<cfset var creditcard = genCreditCard( arguments.cardtype )>
		<cfset var money   = svc.createMoney()>
		<cfset var options = genValidOptions()>
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


<!--- ------------------------------------------------------------------------------------------------------------------------------------------------
	  private methods                                                                                                                                -
	  ------------------------------------------------------------------------------------------------------------------------------------------- --->


<!--- =======================================================================================================
	  genCreditCard                                                                                         =
	  ================================================================================================== --->
	<cffunction name       = "genCreditCard"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="cardtype" type="string" required="true">

		<cfset card = genValidCard()>

		<cfswitch expression="#LCase(arguments.cardtype)#">
			<cfcase value="AmEx,AmericanExpress,American Express">
				<cfset card = genAmEx()>
			</cfcase>

			<cfcase value="AmExCorp,AmericanExpressCorp,American Express Corp">
				<cfset card = genAmExCorp()>
			</cfcase>

			<cfcase value="DinersClub,Diners Club">
				<cfset card = genDinersClub()>
			</cfcase>

			<cfcase value="Discover">
				<cfset card = genDiscover()>
			</cfcase>

			<cfcase value="JCB">
				<cfset card = genJCB()>
			</cfcase>

			<cfcase value="MasterCard">
				<cfset card = genMasterCard()>
			</cfcase>

			<cfcase value="Visa">
				<cfset card = genVisa()>
			</cfcase>
		</cfswitch>

		<cfreturn card>
	</cffunction>

<!--- =======================================================================================================
	  genAmEx                                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "genAmEx"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("371449635398431")>
	</cffunction>

<!--- =======================================================================================================
	  genAmExCorp                                                                                        =
	  ================================================================================================== --->
	<cffunction name       = "genAmExCorp"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("378734493671000")>
	</cffunction>

<!--- =======================================================================================================
	  genDinersClub                                                                                      =
	  ================================================================================================== --->
	<cffunction name       = "genDinersClub"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("38520000023237")>
	</cffunction>

<!--- =======================================================================================================
	  genDiscover                                                                                        =
	  ================================================================================================== --->
	<cffunction name       = "genDiscover"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("6011000990139424")>
	</cffunction>

<!--- =======================================================================================================
	  genJCB                                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "genJCB"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("3566002020360505")>
	</cffunction>

<!--- =======================================================================================================
	  genMasterCard                                                                                      =
	  ================================================================================================== --->
	<cffunction name       = "genMasterCard"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("5105105105105100")>
	</cffunction>

<!--- =======================================================================================================
	  genVisa                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "genVisa"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfreturn genValidCard("4012888888881881")>
	</cffunction>

<!--- =======================================================================================================
	  genValidCard                                                                                       =
	  ================================================================================================== --->
	<cffunction name       = "genValidCard"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood based on code by Brian Ghidinelli"
				created    = "06/22/2013">

		<cfargument name="cardNumber" type="string" default="4111111111111111">

		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var creditcard = svc.createCreditCard()>

		<!--- who --->
		<cfset creditcard.setFirstName( person.FirstName )>
		<cfset creditcard.setLastName( person.LastName )>
		<cfset creditcard.setAddress( person.address.Address1 )>
		<cfset creditcard.setPostalCode( person.address.Postalcode )>

		<!--- account info --->
		<cfset creditcard.setAccount( arguments.cardNumber )>
		<cfset creditcard.setMonth( Month(now()) )>
		<cfset creditcard.setYear( year(now())+1 )>
		<cfset creditcard.setVerificationValue(123)>

		<cfreturn creditcard>
	</cffunction>

<!--- =======================================================================================================
	  genValidOptions                                                                                    =
	  ================================================================================================== --->
	<cffunction name       = "genValidOptions"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="orderID" type="string" default="1234Order">

		<cfset var options = StructNew()>

		<cfset options['address']  = person.address>
		<cfset options['email']    = person.email>
		<cfset options['order_id'] = arguments.orderID>

		<cfreturn options>
	</cffunction>

<!--- =======================================================================================================
	  genPerson                                                                                          =
	  ================================================================================================== --->
	<cffunction name       = "genPerson"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="FirstName"  type="string" default="Fred">
		<cfargument name="LastName"   type="string" default="Flintstone">
		<cfargument name="domain"     type="string" default="bogus.com">

		<!--- if you are wonder this address is for Paypal, Inc --->
		<cfargument name="phone"      type="string" default="402-935-2050">
		<cfargument name="Address"    type="string" default="2211 N 1st St">
		<cfargument name="City"       type="string" default="San Jose">
		<cfargument name="State"      type="string" default="CA">
		<cfargument name="PostalCode" type="string" default="95131">
		<cfargument name="Country"    type="string" default="USA">

		<cfset var person = StructNew()>

		<cfset person['FirstName'] = arguments.FirstName>
		<cfset person['LastName']  = arguments.LastName>
		<cfset person['email']     =  person.Firstname & "." & person.LastName & "@" & arguments.domain>

		<cfset person.address = StructNew()>
		<cfset person.address['phone']      = arguments.phone>
		<cfset person.address['Address1']   = arguments.Address>
		<cfset person.address['City']       = arguments.City>
		<cfset person.address['State']      = arguments.State>
		<cfset person.address['PostalCode'] = arguments.PostalCode>
		<cfset person.address['Country']    = arguments.Country>

		<cfreturn person>
	</cffunction>

<!--- =======================================================================================================
	  genAmount                                                                                          =
	  ================================================================================================== --->
	<cffunction name       = "genAmount"
				access     = "private"
				returntype = "numeric"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var dollars = RandRange(10,1000,"SHA1PRNG")>
		<cfset var cents   = RandRange(10,99,"SHA1PRNG") / 100>

		<cfreturn dollars + cents>
	</cffunction>

</cfcomponent>
