<cfcomponent name="StripeTest" extends="mxunit.framework.TestCase" output="false">

<!---
	
	From https://stripe.com/docs/testing#cards :
	In test mode, you can use these test cards to simulate a successful transaction:
	
	Number	Card type
	4242424242424242	Visa
	4012888888881881	Visa
	5555555555554444	MasterCard
	5105105105105100	MasterCard
	378282246310005	American Express
	371449635398431	American Express
	6011111111111117	Discover
	6011000990139424	Discover
	30569309025904	Diner's Club
	38520000023237	Diner's Club
	3530111333300000	JCB
	3566002020360505	JCB
	In addition, these cards will produce specific responses that are useful for testing different scenarios:
	
	Number	Description
	4000000000000010	address_line1_check and address_zip_check will both fail.
	4000000000000028	address_line1_check will fail.
	4000000000000036	address_zip_check will fail.
	4000000000000101	cvc_check will fail.
	4000000000000341	Attaching this card to a Customer object will succeed, but attempts to charge the customer will fail.
	4000000000000002	Charges with this card will always be declined with a card_declined code.
	4000000000000069	Will be declined with an expired_card code.
	4000000000000119	Will be declined with a processing_error code.
	Additional test mode validation: By default, passing address or CVC data with the card number will cause the address and CVC checks to succeed. If not specified, the value of the checks will be null. Any expiration date in the future will be considered valid.
	
	How do I test specific error codes?
	
	Some suggestions:
	
	card_declined: Use this special card number - 4000000000000002.
	incorrect_number: Use a number that fails the Luhn check, e.g. 4242424242424241.
	invalid_expiry_month: Use an invalid month e.g. 13.
	invalid_expiry_year: Use a year in the past e.g. 1970.
	invalid_cvc: Use a two digit number e.g. 99.

--->
	<cffunction name="setUp" returntype="void" access="public">	

		<cfset var gw = structNew() />

		<cfscript>  
			gw.path = "stripe.stripe";
			gw.GatewayID = 2;
			gw.TestMode = true;		// defaults to true anyways

			// $CAD credentials (provided by support@stripe.com)
			gw.TestSecretKey = 'sk_test_Zx4885WE43JGqPjqGzaWap8a';
			gw.TestPublishableKey = '';

			variables.svc = createObject("component", "cfpayment.api.core").init(gw);
			variables.cad = variables.svc.getGateway();
			variables.cad.currency = "CAD"; // ONLY FOR UNIT TEST

			// $USD credentials - from PHP unit tests on github
			gw.TestSecretKey = 'tGN0bIwXnHdwOa85VABjPdSn8nWY7G7I';
			gw.TestPublishableKey = '';
			variables.svc = createObject("component", "cfpayment.api.core").init(gw);
			variables.usd = variables.svc.getGateway();
			variables.usd.currency = "USD"; // ONLY FOR UNIT TEST

			// create default
			variables.gw = variables.usd;
			
			// for dataprovider testing
			variables.gateways = [usd, cad];

		</cfscript>

		<!--- if set to false, will try to connect to remote service to check these all out --->
		<cfset localMode = false />

	</cffunction>


	<cffunction name="offlineInjector" access="private">
		<cfif localMode>
			<cfset injectMethod(argumentCollection = arguments) />
		</cfif>
		<!--- if not local mode, don't do any mock substitution so the service connects to the remote service! --->
	</cffunction>


	<cffunction name="testStripeSetters" output="false" access="public" returntype="any">
		<cfset assertTrue(gw.getTestSecretKey() EQ 'tGN0bIwXnHdwOa85VABjPdSn8nWY7G7I', "The test secret key was not set through the init config object, was: #gw.getTestSecretKey()#") />
	</cffunction>


	<cffunction name="testGatewayURL" output="false" access="public" returntype="any" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset assertTrue(gw.getGatewayURL() EQ 'https://api.stripe.com/v1', "The gateway URL was unexpected, was: #gw.getGatewayURL()#") />
	</cffunction>


	<cffunction name="testValidateSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		
		<cfset offlineInjector(gw, this, "mock_token_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "created"), "The validation did not succeed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Validation should not have errors but did") />
	</cffunction>
	

	<cffunction name="testValidateDeclineWillSucceed" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_token_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createCardThatWillBeDeclined()) />
		<cfset assertTrue(response.getSuccess(), "Validation did succeed but should have failed without errors") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Validation will not actually test card until it's converted to a customer so will not be declined") />
	</cffunction>


	<cffunction name="testValidateInvalidCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createInvalidCVCError()) />
		<cfset assertTrue(NOT response.getSuccess(), "Validation did succeed but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 402, "Status code should be 402, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.hasError(), "Validation should have errors but did not") />
	</cffunction>	
	
	
	<cffunction name="testValidateInvalidExpirationDate" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_invalid_expiry", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createInvalidYearCardError()) />
		<cfset assertTrue(NOT response.getSuccess(), "Validation did succeed but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 402, "Status code should be 402, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.hasError(), "Validation should have errors but did not") />
	</cffunction>	


	<cffunction name="testPurchaseWithCardSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />
		<cfset assertTrue(response.getSuccess(), "The #gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Purchase should not have errors but did") />
	</cffunction>
	
	
	<cffunction name="testPurchaseDecline" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(gw, this, "mock_incorrect_number", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createInvalidCard()) />
		<cfset assertTrue(NOT response.getSuccess(), "The #gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 402, "Status code should be 402, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.getParsedResult().error.code EQ "incorrect_number", "Should have been an invalid card, was: #response.getParsedResult().error.code#") />
	</cffunction>


	<cffunction name="testPurchaseInvalidCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createInvalidCVCError()) />
		<cfset debug(response.getMemento()) />
		<cfset debug(tostring(response.getResult())) />
		<cfset assertTrue(NOT response.getSuccess(), "The #gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 402, "Status code should be 402, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.getParsedResult().error.code EQ "invalid_cvc", "Should have been an invalid cvc, was: #response.getParsedResult().error.code#") />
	</cffunction>


	<cffunction name="testPurchaseNoMatchStreetAddress" access="public" returntype="void" output="false">
		<cfset var gw = variables.cad />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_invalid_address1", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createValidCardWithoutStreetMatch()) />
		<cfset assertTrue(response.getSuccess(), "The #gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.getParsedResult().card.address_line1_check EQ "fail", "Should have been an invalid address1, was: #response.getParsedResult().card.address_line1_check#") />
	</cffunction>


	<cffunction name="testPurchaseProcessingError" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_processing_error", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createCardThatWillBeProcessingError()) />
		<cfset assertTrue(NOT response.getSuccess(), "Purchase did succeed but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 402, "Status code should be 402, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.getParsedResult().error.code EQ "processing_error", "Should have been an processing_error, was: #response.getParsedResult().error.code#") />
	</cffunction>


	<cffunction name="testPurchaseWithoutCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createValidCardWithoutCVV()) />

		<cfset assertTrue(response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#response.getCVVCode()#'") />
		<cfset assertTrue(NOT response.getSuccess(), "The #gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(response.getStatusCode() EQ 402, "Status code for #gw.currency# should be 402, was: #response.getStatusCode()#") />
		<cfset assertTrue(response.getParsedResult().error.code EQ "invalid_cvc", "Should have been an invalid cvc, was: #response.getParsedResult().error.code#") />

		<cfset assertTrue(response.isValidCVV(), "Blank CVV should be valid") />
		<cfset assertTrue(NOT response.isValidCVV(AllowBlankCode = false), "CVV should not be valid") />
	</cffunction>


<!--- 
	<cffunction name="testValidate" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset response = gw.validate(money = money, account = createValidCard(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset assertTrue(response.getAVSCode() EQ "Y", "Exact match (street + zip) should be found") />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset response = gw.validate(money = money, account = createInvalidCard(), options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The invalid card validation did succeed") />

		<cfset response = gw.validate(money = money, account = createValidCardWithoutCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The card without cvv validation did not succeed") />
		<cfset assertTrue(response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#response.getCVVCode()#'") />

		<cfset response = gw.validate(money = money, account = createValidCardWithBadCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The card with bad cvv validation did not succeed") />
		<cfset assertTrue(response.getCVVCode() EQ "N", "Bad CVV was passed so non-matching answer should be provided but was: '#response.getCVVCode()#'") />

		<cfset response = gw.validate(money = money, account = createValidCardWithoutStreetMatch(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The card without street match validation did not succeed") />
		<cfset assertTrue(response.getAVSCode() EQ "Z", "AVS Zip match only should be found") />

		<cfset response = gw.validate(money = money, account = createValidCardWithoutZipMatch(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The card without zip match validation did not succeed") />
		<cfset assertTrue(response.getAVSCode() EQ "A", "AVS Street match only should be found") />

	</cffunction>
--->

	<cffunction name="testListChargesWithoutCount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_list_charges_count_10", "doHttpCall") />
		<cfset response = gw.listCharges() />

		<cfset assertTrue(response.getSuccess(), "The #gw.currency# list did not succeed but should have") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code for #gw.currency# should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(arrayLen(response.getParsedResult().data) EQ 10, "#gw.currency# list without count should have returned 10 results, was: #arrayLen(response.getParsedResult().data)#") />
	</cffunction>


	<cffunction name="testListChargesWithCountOf2" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_list_charges_count_2", "doHttpCall") />
		<cfset response = gw.listCharges(count = 2) />

		<cfset assertTrue(response.getSuccess(), "The #gw.currency# list did not succeed but should have") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code for #gw.currency# should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(arrayLen(response.getParsedResult().data) EQ 2, "#gw.currency# list without count should have returned 2 results, was: #arrayLen(response.getParsedResult().data)#") />
	</cffunction>


	<cffunction name="testStoreTokenSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var token = variables.svc.createToken() />
		
		<cfset offlineInjector(gw, this, "mock_token_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />
		<cfset token.setID(response.getTransactionId()) />
		<cfset offlineInjector(gw, this, "mock_store_ok", "doHttpCall") />
		<cfset response = gw.store(account = token) />
		
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "created"), "The store did not succeed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Store should not have errors but did") />
	</cffunction>


	<cffunction name="testMissingArgumentsThrowsException" access="public" returntype="void" output="false" mxunit:expectedException="any">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var options = structNew() />
		
		<cfset response = gw.purchase(options = options) />
		<cfset assertTrue(false, "No error was thrown") />

	</cffunction>
		

	<cffunction name="testPurchaseThenRefundFull" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />
		
		<cfset offlineInjector(gw, this, "mock_refund_full_ok", "doHttpCall") />
		<cfset response = gw.refund(transactionid = response.getTransactionID()) />
		<cfset assertTrue(response.getSuccess(), "You can refund a purchase in full") />
		<cfset assertTrue(response.getParsedResult().amount_refunded EQ 5000, "The full refund should be for $50.00") />
		
	</cffunction>


	<cffunction name="testPurchaseThenRefundPartial" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset response = gw.purchase(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />
		
		<cfset offlineInjector(gw, this, "mock_refund_partial_ok", "doHttpCall") />
		<cfset response = gw.refund(transactionid = response.getTransactionID(), money = variables.svc.createMoney(2500, gw.currency)) />
		<cfset assertTrue(response.getSuccess(), "You can refund a purchase in full") />
		<cfset assertTrue(response.getParsedResult().amount_refunded EQ 2500, "The partial refund should be for $25.00") />
		
	</cffunction>

		
		<!---
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.refund(transactionid = response.getTransactionID(), money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can refund a purchase in full") />


		<!--- try partial refunds and overage --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset transId = response.getTransactionID() />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset money = variables.svc.createMoney(2500) />
		<cfset response = gw.refund(transactionid = transId, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You should be able to partially refund a purchase ($25)") />

		<cfset response = gw.refund(transactionid = transId, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You should be able to partially refund second part of a purchase ($25)") />

		<cfset response = gw.refund(transactionid = transId, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "You can't refund a purchase more than the original price") />

	</cffunction>
		--->



	<cffunction name="test_date_conversion" output="false" access="public" returntype="void">
		<cfset var dte = createDateTime(2009, 12, 7, 16, 0, 0) />
		<cfset var dteNow = now() />
		<cfset var dteGMT = dateAdd('s', getTimeZoneInfo().utcTotalOffset, dteNow) />
		<cfset var conv = gw.dateToUTC(dte) />
		<cfset var str = "" />

		<cfset assertTrue(dte EQ gw.utcToDate(conv), "The converted date didn't match (#dte# != #conv#)") />
		<cfset assertTrue(gw.dateToUTC(dteNow) EQ gw.dateToUTC(dteGMT, false), "dateConvert() and dateAdd() should be equivalent: #gw.dateToUTC(dteNow)# != #gw.dateToUTC(dteGMT, false)#") />

		<!--- create a timestamp in GMT as though it came from Stripe in epoch offset "created" --->
		<cfset dteGMT = "2013-02-16 05:20:46" />
		<cfset str = 1360992046 />
		<cfset assertTrue(dteGMT EQ gw.utcToDate(str), "Stripe date should convert to local time: (#dteNow# != #gw.utcToDate(str)# / #str#)") />
	</cffunction>




	<!--- PRIVATE HELPERS, MOCKS, ETC --->

	<cffunction name="createValidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4242424242424242) />
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
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4242424242424241) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithoutCVV" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setVerificationValue() />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithFailedCVV" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000101) />
		<cfreturn account />	
	</cffunction>
	
	<cffunction name="createValidCardWithoutStreetMatch" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000028) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithoutZipMatch" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000036) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithoutAVSMatch" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000010) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createCardThatWillBeDeclined" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000002) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createCardThatWillBeExpired" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000069) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createCardThatWillBeProcessingError" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setAccount(4000000000000119) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createInvalidMonthCardError" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setMonth(13) />
		<cfreturn account />	
	</cffunction>

	<cffunction name="createInvalidYearCardError" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setYear(1970) />
		<cfreturn account />	
	</cffunction>
	
	<cffunction name="createInvalidCVCError" access="private" returntype="any" output="false">
		<cfset var account = createValidCard() />
		<cfset account.setVerificationValue(99) />
		<cfreturn account />	
	</cffunction>
	


	<cffunction name="mock_token_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "id": "tok_1IZvRgzvQlffjs", "livemode": false, "created": 1360974256, "used": false, "object": "token", "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "" } }' } />
		<cfreturn http />
	</cffunction>
	
	<cffunction name="mock_store_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "object": "customer", "created": 1360991479, "id": "cus_1IeYQ4dYTTI4Bt", "livemode": false, "description": null, "active_card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "email": null, "delinquent": false, "subscription": null, "discount": null, "account_balance": 0 }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_purchase_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IehV2hFFglF0v", "object": "charge", "created": 1360991963, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
		<cfreturn http />
	</cffunction>
	
	<cffunction name="mock_refund_full_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IfncE2zg8NMw9", "object": "charge", "created": 1360996094, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": true, "fee": 0, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 175 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 5000, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
		<cfreturn http />
	</cffunction>
	
	<cffunction name="mock_refund_partial_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IfpWrsmQSA3IA", "object": "charge", "created": 1360996197, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
		<cfreturn http />
	</cffunction>
	
	<cffunction name="mock_invalid_cvc" access="private">
		<cfset var http = { StatusCode = '402', FileContent = '{ "error": { "message": "Your card''s security code is invalid", "type": "card_error", "param": "cvc", "code": "invalid_cvc" } }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_invalid_expiry" access="private">
		<cfset var http = { StatusCode = '402', FileContent = '{ "error": { "message": "Your card''s expiration year is invalid", "type": "card_error", "param": "exp_year", "code": "invalid_expiry_year" } }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_incorrect_number" access="private">
		<cfset var http = { StatusCode = '402', FileContent = '{ "error": { "message": "Your card number is incorrect", "type": "card_error", "param": "number", "code": "incorrect_number" } }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_processing_error" access="private">
		<cfset var http = { StatusCode = '402', FileContent = '{ "error": { "message": "An error occurred while processing your card", "type": "card_error", "code": "processing_error", "charge": "ch_1Ie7BA4vAb8ZaF" } }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_invalid_address1" access="private">
		<cfset var http = { StatusCode = '200', FileContent = '{ "id": "ch_1IeAMjrHpnj7dV", "object": "charge", "created": 1360990030, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "0028", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "1YqKn8Y7DbGMP8a1", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "fail", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_list_charges_count_10" access="private">
		<cfset var http = { StatusCode = '200', FileContent = '{ "object": "list", "count": 31800, "url": "/v1/charges", "data": [ { "id": "ch_1IxL1nrwUu7kmF", "object": "charge", "created": 1361061326, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxLLW6cPV1kIK", "object": "charge", "created": 1361061323, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxL31sObDzpCv", "object": "charge", "created": 1361061320, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": true, "fee": 0, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 175 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 5000, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxK3Xh6I2xrNE", "object": "charge", "created": 1361061317, "livemode": false, "paid": false, "amount": 5000, "currency": "usd", "refunded": false, "fee": 0, "fee_details": [], "card": { "object": "card", "last4": "0119", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "YggjdcH7yERT93CL", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": "An error occurred while processing your card", "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1Iuelcm8fpWb5v", "object": "charge", "created": 1361051359, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By77C9AgMAIw2", "invoice": "in_1ItfkkOrk99sat", "description": null, "dispute": null }, { "id": "ch_1IueK7L83dUFhK", "object": "charge", "created": 1361051358, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By7tRmEv8zcqW", "invoice": "in_1Itf8IT0wEG9R8", "description": null, "dispute": null }, { "id": "ch_1IueGPyiGOsISV", "object": "charge", "created": 1361051356, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By6oVFxh4j0OR", "invoice": "in_1ItfCmqahj5CLg", "description": null, "dispute": null }, { "id": "ch_1Iuee3zxbf6Eez", "object": "charge", "created": 1361051355, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By6rD5aPmULnT", "invoice": "in_1ItfDCc2kbn7XF", "description": null, "dispute": null }, { "id": "ch_1IucE7qqbtaXng", "object": "charge", "created": 1361051232, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By5i2kAbTsaX3", "invoice": "in_1Iteod2vndXuD7", "description": null, "dispute": null }, { "id": "ch_1Iuc0z4PmscDT4", "object": "charge", "created": 1361051232, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By5b0y9bDVB7U", "invoice": "in_1IteiR0nvAU7ta", "description": null, "dispute": null } ] }' } />
		<cfreturn http />
	</cffunction>

	<cffunction name="mock_list_charges_count_2" access="private">
		<cfset var http = { StatusCode = '200', FileContent = '{ "object": "list", "count": 31800, "url": "/v1/charges", "data": [ { "id": "ch_1IxL1nrwUu7kmF", "object": "charge", "created": 1361061326, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxLLW6cPV1kIK", "object": "charge", "created": 1361061323, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null } ] } ' } />
		<cfreturn http />
	</cffunction>



</cfcomponent>
