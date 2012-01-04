<cfcomponent name="AuthorizenetTest" extends="mxunit.framework.TestCase" output="false" hint="Basically the Braintree tests, but a couple additions">
	<!---
		Test transactions can be submitted with the following information:
		
		Visa 4111111111111111 
		MasterCard 5431111111111111 
		DiscoverCard 6011601160116611 
		American Express 341111111111111 
		Credit Card Expiration 10/10 
		eCheck Acct & Routing: 123123123 
		Amount >1.00 
		

		By placing the merchant’s payment gateway account in Test Mode in the Merchant Interface. 
		New payment gateway accounts are placed in Test Mode by default. For more information 
		about Test Mode, see the Merchant Integration Guide at 
		http://www.authorize.net/support/Merchant/default.htm. Please note that when processing 
		test transactions in Test Mode, the payment gateway will return a transaction ID of “0.” 
		This means you cannot test follow-on transactions, e.g. credits, voids, etc., while in 
		Test Mode. To test follow-on transactions, you can either submit x_test_request=TRUE as 
		indicated above, or process a test transaction with any valid credit card number in live 
		mode, as explained below.
	--->
	<cffunction name="setUp" returntype="void" access="public" output="false">	
		<cfscript>  
			var gw = structNew();
			
			variables.svc = createObject("component", "cfpayment.api.core");
			
			gw.path = "authorizenet.authorizenet";
			// Request a test account here: http://developer.authorize.net/testaccount/
			gw.MerchantAccount = "2JC6bA988aq2s7Vk"; // Insert your developer or production merchant account number here.
			gw.Username = "4ffrBT36La"; // Insert your developer or production username here.
			gw.TestMode = true; // defaults to true

			// create gw and get reference			
			variables.svc.init(gw);
			variables.gw = variables.svc.getGateway();			
		</cfscript>
	</cffunction>

	<cffunction name="testPurchase" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		<cfset options.orderid = getTickCount() /><!---Authorize.net requires a unique order id for each transaction.--->
		
		<!--- test the purchase method --->
		<cfset response = gw.purchase(money = money, account = createValidCard(), options = options) />
		<!---<cfset debug(response.getMemento()) />--->
		<cfset debug("AVSMessage: #response.getAVSMessage()#") />
		<cfset assertTrue(response.getSuccess(), "The purchase failed (1)") />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset response = gw.purchase(money = money, account = createInvalidCard(), options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did succeed (3)") />


		<cfset response = gw.purchase(money = variables.svc.createMoney(5010), account = createValidCardWithoutCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed (4)") />
		<cfset debug("No CVV Message: " & response.getCVVMessage()) />
		<cfset assertTrue(response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#response.getCVVCode()#'") />


		<cfset response = gw.purchase(money = variables.svc.createMoney(5020), account = createValidCardWithBadCVV(), options = options) />
		<cfset debug("Bad CVV Message:" & response.getCVVMessage()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed (5)") />
		<cfset assertTrue(NOT response.isValidCVV(), "Bad CVV was passed so non-matching answer should be provided but was: '#response.getCVVCode()#'") />


		<cfset response = gw.purchase(money = variables.svc.createMoney(5030), account = createValidCardWithoutStreetMatch(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed (6)") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.isValidAVS(), "AVS Zip match only should be found") />
		

		<cfset response = gw.purchase(money = variables.svc.createMoney(5040), account = createValidCardWithoutZipMatch(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed (7)") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.isValidAVS(), "AVS Street match only should be found") />


		<!--- test specific response codes, requires enabling psuedo-test mode --->
		<cfset options["x_test_request"] = true />

		<!--- pass in 2.00 for a decline code --->
		<cfset response = gw.purchase(money = variables.svc.createMoney(200), account = createCardForErrorResponse(), options = options) />
		<cfset debug(response.getMessage()) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase should have failed (2)") />

	</cffunction>

	<cffunction name="testAuthorizeOnly" access="public" returntype="void" output="false">
		<cfset var money = variables.svc.createMoney(5132) /><!--- in cents --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset options.orderid = getTickCount() />
		
		<cfset response = gw.authorize(money = money, account = createValidCard(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset debug("Status=#response.getStatus()#, #response.getMessage()#") />
		<cfset debug("AVS1=#response.getAVSCode()#, #response.getAVSMessage()#") />
		<cfset assertTrue(response.getSuccess(), "The authorization failed") />
		<cfset assertTrue(response.getAVSCode() EQ "Y", "Street address + zip should match (Y)") />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset options.orderid++ />
		<cfset response = gw.authorize(money = money, account = createInvalidCard(), options = options) />
		<cfset debug("Success2=#response.getSuccess()#") />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization shouldn't have succeeded (2)") />

		<!---Test mode doesn't appear to fail on cvv or avs--->
		<!---<cfset options.orderid++ />
		<cfset response = gw.authorize(money = variables.svc.createMoney(2700), account = createCardForErrorResponse(), options = options) /><!---invalid avs--->
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed 3") />
		<cfset debug("CVV1=#response.getCVVCode()#, #response.getCVVMessage()#") />
		<cfset assertTrue(response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#response.getCVVCode()#'") />--->

		<!---<cfset options.orderid++ />
		<cfset response = gw.authorize(money = money, account = createValidCardWithBadCVV(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset debug("Success3=#response.getSuccess()#") />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed 4") />
		<cfset debug("CVV2=#response.getCVVCode()#, #response.getCVVMessage()#") />	
		<cfset assertTrue(response.getCVVCode() EQ "N", "Bad CVV was passed so non-matching answer should be provided but was: '#response.getCVVCode()#'") />--->

	<!---	<cfset options.orderid++ />
		<cfset response = gw.authorize(money = money, account = createValidCardWithoutStreetMatch(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed 5") />
		<cfset debug("AVS2=#response.getAVSCode()#, #response.getAVSMessage()#") />
		<cfset assertTrue(response.getAVSCode() EQ "Z", "AVS Zip match only should be found") />

		<cfset options.orderid++ />
		<cfset response = gw.authorize(money = money, account = createValidCardWithoutZipMatch(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed 6") />
		<cfset debug("AVS3=#response.getAVSCode()#, #response.getAVSMessage()#") />
		<cfset assertTrue(response.getAVSCode() EQ "A", "AVS Street match only should be found") />--->
	</cffunction>

	<cffunction name="testAuthorizeThenCapture" access="public" returntype="void" output="false">
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		<cfset var tid = "" />
		<cfset options.orderid = getTickCount() />
		

		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.capture(money = money, authorization = response.getTransactionId(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The capture did not succeed") />

	</cffunction>


	<cffunction name="testAuthorizeThenCredit" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		<cfset options.orderid = getTickCount() />

		
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.credit(transactionid = response.getTransactionID(), money = money, account = createValidCard(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "You cannot credit a preauth") />

	</cffunction>


	<cffunction name="testAuthorizeThenVoid" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		<cfset options.orderid = getTickCount() />

		
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can void a preauth") />

	</cffunction>
	
	
	<cffunction name="testPurchaseThenCredit" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		<cfset options.orderid = getTickCount() />

		
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.credit(transactionid = response.getTransactionID(), money = money, account = account, options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "You can not full credit a purchase (should void since it's not settled?)") />

		<cfset response = gw.credit(transactionid = response.getTransactionID(), money = variables.svc.createMoney(4500), account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can partial credit a purchase") />

	</cffunction>
	

	<cffunction name="testPurchaseThenVoid" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		<cfset options.orderid = getTickCount() />

		
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can void a purchase") />

	</cffunction>	




	<cffunction name="createValidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(999) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>
	<cffunction name="createCardForErrorResponse" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4222222222222) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(999) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>

	<cffunction name="createInvalidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4100000000000000) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz") />
		<cfset account.setPostalCode("95030") />

		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithoutCVV" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue() />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithBadCVV" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(111) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>
	
	<cffunction name="createValidCardWithoutStreetMatch" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue() />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("N. Santa Cruz") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithoutZipMatch" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue() />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("00000") />

		<cfreturn account />	
	</cffunction>



	<cffunction name="createValidEFT" access="private" returntype="any" output="false">
		<!--- these values simulate a valid eft with matching avs/cvv --->
		<cfset var account = variables.svc.createEFT() />
		<cfset account.setAccount("123123123") />
		<cfset account.setRoutingNumber("123123123") />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		<cfset account.setPhoneNumber("415-555-1212") />
		
		<cfset account.setAccountType("checking") />

		<cfreturn account />	
	</cffunction>
	

</cfcomponent>
