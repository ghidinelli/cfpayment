<!---
	$Id$

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
<cfcomponent name="skipjacktest" extends="mxunit.framework.TestCase" output="false">

	<!--- shared variables --->
	<cfset svc="">
	<cfset gw="">
	<cfset testdata="">
	<cfset gwParams = "" />

 	<cffunction name="setUp" returntype="void" access="public">
		<cftry>
			<!--- create a config that is not in svn --->
			<cfset gwParams = createObject("component", "cfpayment.localconfig.config").init() />
		<cfcatch>
			<!--- if gwParams doesn't exist (or otherwise bombs), create a generic structure with blank values --->
			<cfset gwParams = StructNew() />
			<cfset gwParams.Path = "skipjack.skipjack_cc" />
			<cfset gwParams.MerchantAccount = "" /><!--- skipjack html serial number --->
			<!--- username and password only used for reporting in SkipJack --->
			<cfset gwParams.userName = "" />
			<cfset gwParams.password = "" />
		</cfcatch>
		</cftry>
		<cfset svc = createObject("component", "cfpayment.api.core") />

		<!--- create gw and get reference --->
		<cfset svc.init(gwParams) />
		<cfset gw = svc.getGateway() />

		<!--- test data for skipjack development --->
		<cfset testdata=StructNew() />
		<cfset testdata.visa_card_number = "4445999922225" />
		<cfset testdata.visa_cvv2 = "999" />
		<cfset testdata.mastercard_card_number = "5499990123456781" />
		<cfset testdata.mastercard_cvv2 = "" />
		<cfset testdata.discover_card_number = "6011000999314523" />
		<cfset testdata.discover_cvv2 = "767" /><!--- 11/07, $1, 2500 Main Street, Anywhere, IL 60015 --->
	</cffunction>

	<!--- <cffunction name="testParseAuthorizeResponse" output="false" access="public" returntype="any" hint="">
		<cfset var response="">
		<!--- add a generic result to the response object --->
		<cfset var result="">

		<!--- these methods are private, so use mxunit to make it public for testing --->
		<cfset makePublic(gw, "ParseResponse", "ParseResponsePub") />
		<cfset makePublic(gw, "getMerchantAccount", "getMerchantAccountPub") />
		<cfset makePublic(gw, "setGatewayAction", "setGatewayActionPub") />

		<!--- "-68" is an empty city error --->
		<cfset response=svc.createResponse()>
		<cfsavecontent variable="result"><cfoutput>"AUTHCODE","szSerialNumber","szTransactionAmount","szAuthorizationDeclinedMessage","szAVSResponseCode","szAVSResponseMessage","szOrderNumber","szAuthorizationResponseCode","szIsApproved","szCVV2ResponseCode","szCVV2ResponseMessage","szReturnCode","szTransactionFileName","szCAVVResponseCode"
"EMPTY","#gw.getMerchantAccountPub()#","9666","","","","0506543597","","0","","","-68","",""</cfoutput></cfsavecontent>
		<cfset response.setResult(result)>
		<cfset gw.setGatewayActionPub("Authorize")>
		<cfset debug(gw.getMemento())>
		<cfset gw.ParseResponsePub(response)>
		<cfset debug(response.getMemento())>
		<cfset assertEquals(response.getMessage(),  "Error empty city", "ParseAuthorizeResponse returned the wrong message for a missing city error.") />

		<!--- "-82" is an empty state error --->
		<cfset response=svc.createResponse()>
		<cfsavecontent variable="result"><cfoutput>"AUTHCODE","szSerialNumber","szTransactionAmount","szAuthorizationDeclinedMessage","szAVSResponseCode","szAVSResponseMessage","szOrderNumber","szAuthorizationResponseCode","szIsApproved","szCVV2ResponseCode","szCVV2ResponseMessage","szReturnCode","szTransactionFileName","szCAVVResponseCode"
"EMPTY","#gw.getMerchantAccount()#","2026","","","","1154213758","","0","","","-82","",""</cfoutput></cfsavecontent>
		<cfset response.setResult(result)>
		<cfset gw.setGatewayAction("Authorize")>
		<cfset gw.ParseResponse(response)>
		<cfset debug(response.getMemento())>
		<cfset assertEquals(response.getMessage(),  "Length or value state", "ParseAuthorizeResponse returned the wrong message for a missing state error.") />
	</cffunction> --->


	<cffunction name="testInvalidOptions" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var response = "" />
		<cfset var invalidOptions = "" />
		<cfset var options = getTestRequiredOptions() />

		<!--- missing e-mail address --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "Email")>
		<cftry>
			<cfset response =  gw.authorize(money = money, account = account, options = invalidOptions) />
			<cfset fail("The authorize call did not fail with missing e-mail address.") />
		<cfcatch>
			<cfset assertEquals(cfcatch.type,  "cfpayment.MissingParameter.Option", "The authorize call returned the wrong cfcatch type with missing e-mail address.") />
		</cfcatch>
		</cftry>

		<!--- missing phone number --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions.address, "Phone")>
		<cfset response =  gw.authorize(money = money, account = account, options = invalidOptions) />
		<cfset assertEquals(response.getMessage(),  "length or value shiptophone", "The authorize call did not properly fail with missing phone number.") />
	</cffunction>

	<cffunction name="testInvalidAuthorizations" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var response = "" />
		<cfset var options = getTestRequiredOptions() />

		<!--- try invalid card number --->
		<cfset account.setAccount(testdata.visa_card_number & "1") />
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento())>
		<cfset assertEquals(response.getStatus(), "3", "The authorize call did not fail with invalid CC number") />
		<cfset assertEquals(response.getMessage(), "Invalid credit card number", "The authorize call did not fail with invalid CC number") />

		<!--- set valid test card --->
		<cfset account.setAccount(testdata.visa_card_number) />

		<!--- the developer system does not fail on invalid month/year on the developer gateway, so these tests are useless --->
		<!--- try invalid expiration --->
		<!--- <cfset account.setMonth(13) />
		<cfset account.setYear(year(now()) + 1) />
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento())>
		<cfset assertEquals(response.getStatus(), "3", "The authorize call did not fail with invalid expiration month") />
		<cfset assertEquals(response.getMessage(), "Invalid ??", "The authorize call did not fail with invalid expiration month") /> --->

		<!--- try expired card --->
		<!--- <cfset account.setMonth(5) />
		<cfset account.setYear(year(now()) - 1) />
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento())>
		<cfset assertEquals(response.getStatus(), "3", "The authorize call did not fail with an expired date") />
		<cfset assertEquals(response.getMessage(), "Invalid ??", "The authorize call did not fail with an expired date") /> --->
	</cffunction>

	<cffunction name="testValidAuthorizations" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var response = "" />
		<cfset var options = getTestRequiredOptions() />

		<!--- card should result in success --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid authorize attempt was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertTrue(response.getSuccess(), "The valid authorize did not return successful") />
		</cfif>
	</cffunction>

	<cffunction name="testValidPurchase" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var response = "" />
		<cfset var options = getTestRequiredOptions() />
		<!--- developer serial number required to settle --->
		<cfset options.DeveloperSerialNumber=gwParams.DeveloperSerialNumber>

		<!--- card should result in success --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid purchase attempt was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertTrue(response.getSuccess(), "The valid purchase test did not return successful") />
		</cfif>
	</cffunction>

	<cffunction name="testValidAuthorizeCreditCapture" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var options = getTestRequiredOptions() />
		<cfset var response = "" />
		<cfset var transId = "" />

		<!--- card should result in success --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid authorize attempt was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertTrue(response.getSuccess(), "The valid authorize test did not return successful") />
		</cfif>

		<!--- capture the transaction id for further processing --->
		<cfset transId=response.getTransactionId()>
		<cfset options.DeveloperSerialNumber=gwParams.DeveloperSerialNumber>

		<!--- let's give them a $5 credit --->
		<cfset money.setCents(money.getCents()-500)>
		<cfset response = gw.credit(money = money, identification = transId, options = options) />
		<cfset debug(response.getMemento()) />
		<!--- <cfset assertTrue(response.getSuccess(), "The valid capture test did not return successful") /> --->
		<!--- <cfset assertEquals(response.getMessage(), "UNSUCCESSFUL: Status Mismatch", "The valid credit test did not return the proper response.") /> --->
		<cfset assertEquals(response.getMessage(), "The transaction succeeded, but one or more individual items failed.", "The valid credit test did not return the proper response.") />

		<!---  flag the authorization for settlement into your bank account --->
		<cfset response = gw.capture(money = money, authorization = transId, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid capture test did not return successful") />

		<!--- NOTE: once captured, you cannot void --->
	</cffunction>

	<cffunction name="testValidAuthorizeGetStatus" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var options = getTestRequiredOptions() />
		<cfset var response = "" />
		<cfset var originalOrderNumber = "" />

		<!--- card should result in success --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid authorize attempt was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertTrue(response.getSuccess(), "The valid authorize test did not return successful") />
		</cfif>

		<!--- attempt to get status of this transaction --->
		<cfset originalOrderNumber = options.order_id />
		<cfset options.DeveloperSerialNumber = gwParams.DeveloperSerialNumber />
		<cfset response = gw.status(transactionId = originalOrderNumber, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid Get Transaction Status test did not return successful") />
		<cfset assertTrue(structKeyExists(response.getParsedResult(), "ResultDataQuery") and isQuery(response.getParsedResult().ResultDataQuery), "The valid Get Transaction Status test did not return  a valid ResultDataQuery.") />
		<cfset assertEquals(response.getParsedResult().ResultDataQuery.TransactionStatusMessage, "Approved", "The valid Get Transaction Status test did not return an approved message in the ResultDataQuery.") />
	</cffunction>

	<cffunction name="testValidAuthorizeAdditionalChargeVoid" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var options = getTestRequiredOptions() />
		<cfset var response = "" />
		<cfset var transId = "" />

		<!--- card should result in success --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid authorize attempt was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertTrue(response.getSuccess(), "The valid authorize test did not return successful") />
		</cfif>

		<!--- capture the transaction id for further processing --->
		<cfset transId=response.getTransactionId()>
		<cfset options.DeveloperSerialNumber=gwParams.DeveloperSerialNumber>

		<!--- TODO: add "additional authorization" test --->

		<!---  changed my mind, let's void it --->
		<cfset response = gw.void(authorization = transId, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid void test did not return successful") />
	</cffunction>

	<!--- <cffunction name="testParseAddRecurringResponse" output="false" access="public" returntype="any" hint="">
		<cfset var response="">
		<!--- add a generic result to the response object --->
		<cfset var result="">

		<!--- "-2" is a missing parameter error --->
		<cfset response=svc.createResponse()>
		<cfsavecontent variable="result"><cfoutput>"1234567890","-2","1","","","","","","","","",""
Parameter Missing: (rtName)</cfoutput></cfsavecontent>
		<cfset response.setResult(result)>
		<cfset gw.setGatewayAction("Recurring")>
		<cfset gw.ParseResponse(response)>
		<cfset debug(response.getMemento())>
		<cfset assertEquals(response.getMessage(),  "Parameter Missing: (rtName)", "testParseAddRecurringResponse returned the wrong message for a missing rtName error.") />
	</cffunction> --->

	<cffunction name="testInvalidRecurring" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var response = "" />
		<cfset var invalidOptions = "" />
		<cfset var options = getTestRequiredOptions() />

		<!--- extra fields for recurring transactions --->
		<cfset options.DeveloperSerialNumber=gwParams.DeveloperSerialNumber>
		<cfset options.ItemNumber="12345">
		<cfset options.ItemDescription="Dark Blue Widget">
		<cfset options.StartingDate=DateFormat(DateAdd("d", 60, now()), "mm/dd/yyyy")>
		<cfset options.Periodicity="weekly">
		<cfset options.TotalTransactions="12">

		<!--- missing DeveloperSerialNumber --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "DeveloperSerialNumber")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<!--- just check this on the first one in this test --->
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid add recurring payment test was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertEquals(response.getMessage(), "Parameter Missing: (szDeveloperSerialNumber)", "The missing DeveloperSerialNumber test did not return the correct response message.") />
		</cfif>

		<!--- missing ItemDescription --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "ItemDescription")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<cfset assertEquals(response.getMessage(), "Parameter Missing: (rtItemDescription)", "The missing ItemDescription test did not return the correct response message.") />

		<!--- missing ItemNumber --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "ItemNumber")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<cfset assertEquals(response.getMessage(), "Parameter Missing: (rtItemNumber)", "The missing ItemNumber test did not return the correct response message.") />

		<!--- missing StartingDate --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "StartingDate")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<cfset assertEquals(response.getMessage(), "Parameter Missing: (rtStartingDate)", "The missing StartingDate test did not return the correct response message.") />

		<!--- missing Frequency --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "Periodicity")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<cfset assertEquals(response.getMessage(), "Parameter Missing: (rtFrequency)", "The missing Frequency test did not return the correct response message.") />

		<!--- missing TotalTransactions --->
		<cfset invalidOptions=duplicate(options)>
		<cfset StructDelete(invalidOptions, "TotalTransactions")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<cfset assertEquals(response.getMessage(), "Parameter Missing: (rtTotalTransactions)", "The missing TotalTransactions test did not return the correct response message.") />

		<!--- starting date too early --->
		<cfset invalidOptions=duplicate(options)>
		<cfset invalidOptions.StartingDate=DateFormat(DateAdd("m", -3, now()), "mm/dd/yyyy")>
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<!--- check just the first 96 characters, because the error ends with dynamic data (the date passed in) --->
		<cfset assertEquals(left(response.getMessage(), 96), "invalid starting date entered.  date must not be more than 60 days earlier than the current date", "The starting date too early test did not return the correct response message.") />

		<!--- invalid frequency --->
		<cfset invalidOptions=duplicate(options)>
		<cfset invalidOptions.Periodicity="daily"><!--- daily is not supported by skipjack --->
		<cfset response = gw.recurring(money = money, account = account, options = invalidOptions) />
		<cfset debug(response.getMemento()) />
		<cfset assertEquals(response.getMessage(), "Parameter Missing: (rtFrequency)", "The invalid frequency test did not return the correct response message.") />
	</cffunction>

	<cffunction name="testValidRecurring" access="public" returntype="void" output="false">
		<cfset var account =  getTestCreditCard() />
		<cfset var money = svc.createMoney(getRandomCents()) />
		<cfset var options = getTestRequiredOptions() />
		<cfset var response = "" />
		<cfset var PaymentId1 = "" />
		<cfset var PaymentId2 = "" />

		<!--- extra fields for recurring transactions --->
		<cfset options.DeveloperSerialNumber=gwParams.DeveloperSerialNumber>
		<cfset options.ItemNumber="12345">
		<cfset options.ItemDescription="Dark Blue Widget">
		<cfset options.StartingDate=DateFormat(DateAdd("d", 60, now()), "mm/dd/yyyy")>
		<cfset options.Periodicity="bimonthly">
		<cfset options.TotalTransactions="12">

		<!--- ADD RECURRING --->
		<cfset options.mode="add">
		<cfset response = gw.recurring(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfif response.GetMessage() EQ "Length or value of HTML Serial Number">
			<cfset fail("The valid authorize attempt was stopped because you have supplied an invalid SkipJack HTML Serial Number.")>
		<cfelse>
			<cfset assertTrue(response.getSuccess(), "The valid 'add recurring 1' method did not return successful") />
		</cfif>
		<!--- get the payment id to use in further testing --->
		<cfset PaymentId1=StructFind(response.GetParsedResult(), "RecurringPaymentId")>
		<cfset options.PaymentId=PaymentId1>

		<!--- EDIT RECURRING --->
		<cfset options.mode="edit">
		<!--- change the starting date --->
		<cfset options.StartingDate=DateFormat(DateAdd("yyyy", 1, options.StartingDate), "mm/dd/yyyy")>
		<cfset response = gw.recurring(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid 'edit recurring' method did not return successful") />

		<!--- GET RECURRING BY RecurringPaymentId --->
		<cfset options.mode="get">
		<cfset response = gw.recurring(options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid 'get recurring' method did not return successful") />

		<!--- ADD ANOTHER RECURRING --->
		<cfset options.mode="add">
		<cfset options.ItemNumber="54321">
		<cfset options.ItemDescription="Bright Red Widget">
		<cfset options.StartingDate=DateFormat(DateAdd("d", 14, now()), "mm/dd/yyyy")>
		<cfset options.Periodicity="biweekly">
		<cfset options.TotalTransactions="12">
		<cfset response = gw.recurring(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid 'add recurring 2' method did not return successful") />
		<cfset PaymentId2=StructFind(response.GetParsedResult(), "RecurringPaymentId")>

		<!--- GET ALL RECURRING TRANSACTIONS --->
		<cfset options.mode="get">
		<cfset StructDelete(options, "paymentid")>
		<cfset response = gw.recurring(options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid 'get recurring' method did not return successful") />

		<!--- DELETE BOTH RECURRING --->
		<cfset options.mode="delete">
		<cfset options.PaymentId=PaymentId1>
		<cfset response = gw.recurring(options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid 'delete recurring 1' method did not return successful") />

		<cfset options.PaymentId=PaymentId2>
		<cfset response = gw.recurring(options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The valid 'delete recurring 2' method did not return successful") />
	</cffunction>

	<!---

	helpers

	--->
	<cffunction name="getRandomOrderNumber" output="false" access="private" returntype="any" hint="">
		<cfreturn TimeFormat(now(), "hhmmsslll") & RandRange(0,9)>
	</cffunction>

	<cffunction name="getRandomCents" output="false" access="private" returntype="any" hint="">
		<cfreturn Rand("SHA1PRNG") * 100 * 100><!--- return cents --->
	</cffunction>

	<cffunction name="getTestCreditCard" output="false" access="private" returntype="any" hint="">
		<cfargument name="cardtype" type="string" default="visa"/><!--- visa or mastercard --->
		<cfset var account=svc.createCreditCard()>
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
 		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfif arguments.cardtype eq "visa">
			<cfset account.setAccount(testdata.visa_card_number) />
			<cfset account.setVerificationValue(testdata.visa_cvv2) />
		<cfelseif arguments.cardtype eq "mastercard">
			<cfset account.setAccount(testdata.mastcard_card_number) />
			<cfset account.setVerificationValue(testdata.mastcard_cvv2) />
		<cfelse>
			<cfset account.setAccount(testdata.discover_card_number) />
			<cfset account.setVerificationValue(testdata.discover_cvv2) />
		</cfif>
		<cfreturn account>
	</cffunction>

	<cffunction name="getTestRequiredOptions" output="false" access="private" returntype="any" hint="">
		<cfset var options = StructNew() />
		<cfset options.Email = "someone@somewhere.org" />
		<cfset options.order_id = getRandomOrderNumber() />
		<cfset options.address=StructNew() />
		<cfset options.address.FirstName="John" />
		<cfset options.address.LastName="Doe" />
		<cfset options.address.Address1="123 Some Street" />
		<cfset options.address.City="Anywhere" />
		<cfset options.address.State="OH" />
		<cfset options.address.PostalCode="45314" />
		<cfset options.address.Phone = "123-123-1234" />
		<cfreturn duplicate(options) />
	</cffunction>

</cfcomponent>
