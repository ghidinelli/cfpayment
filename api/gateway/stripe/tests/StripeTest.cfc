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
		<cfscript>  
			local.gw = structNew();
			local.gw.path = "stripe.stripe";
			local.gw.GatewayID = 2;
			local.gw.TestMode = true; // defaults to true anyways

			// $CAD credentials (provided by support@stripe.com)
			gw.TestSecretKey = 'sk_test_Zx4885WE43JGqPjqGzaWap8a';
			local.gw.TestPublishableKey = '';

			variables.svc = createObject("component", "cfpayment.api.core").init(local.gw);
			variables.cad = variables.svc.getGateway();
			variables.cad.currency = "CAD"; // ONLY FOR UNIT TEST

			// $USD credentials - from PHP unit tests on github
			local.gw.TestSecretKey = 'tGN0bIwXnHdwOa85VABjPdSn8nWY7G7I';
			local.gw.TestPublishableKey = '';
			variables.svc = createObject("component", "cfpayment.api.core").init(local.gw);
			variables.usd = variables.svc.getGateway();
			variables.usd.currency = "USD"; // ONLY FOR UNIT TEST

			// create default
			variables.gw = variables.usd;
			
			// for dataprovider testing
			variables.gateways = [usd, cad];
		</cfscript>

		<!--- if set to false, will try to connect to remote service to check these all out --->
		<cfset variables.localMode = false />
	</cffunction>


	<cffunction name="offlineInjector" access="private">
		<cfif variables.localMode>
			<cfset injectMethod(argumentCollection = arguments) />
		</cfif>
		<!--- if not local mode, don't do any mock substitution so the service connects to the remote service! --->
	</cffunction>


	<cffunction name="testStripeSetters" output="false" access="public" returntype="any">
		<cfset assertTrue(variables.gw.getTestSecretKey() EQ 'tGN0bIwXnHdwOa85VABjPdSn8nWY7G7I', "The test secret key was not set through the init config object, was: #variables.gw.getTestSecretKey()#") />
	</cffunction>


	<cffunction name="testGatewayURL" output="false" access="public" returntype="any" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset assertTrue(arguments.gw.getGatewayURL() EQ 'https://api.stripe.com/v1', "The gateway URL was unexpected, was: #arguments.gw.getGatewayURL()#") />
	</cffunction>


	<cffunction name="testValidateSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset assertTrue(local.response.getSuccess() AND structKeyExists(local.response.getParsedResult(), "created"), "The validation did not succeed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Validation should not have errors but did") />
	</cffunction>
	

	<cffunction name="testValidateDeclineWillSucceed" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardThatWillBeDeclined()) />
		<cfset assertTrue(local.response.getSuccess(), "Validation did succeed but should have failed without errors") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Validation will not actually test card until it's converted to a customer so will not be declined") />
	</cffunction>


	<cffunction name="testValidateInvalidCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createInvalidCVCError()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "Validation did succeed but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.hasError(), "Validation should have errors but did not") />
	</cffunction>	
	
	
	<cffunction name="testValidateInvalidExpirationDate" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_invalid_expiry", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createInvalidYearCardError()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "Validation did succeed but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.hasError(), "Validation should have errors but did not") />
	</cffunction>	


	<cffunction name="testPurchaseWithCustomerAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset local.token = variables.svc.createToken() />

		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset local.token.setID(local.response.getTransactionId()) />
		<cfset offlineInjector(arguments.gw, this, "mock_store_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.store(account = token) />

		<cfset local.customer = variables.svc.createToken() />
		<cfset local.customer.setId(local.response.getTransactionId()) />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = local.customer) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Purchase should not have errors but did") />
	</cffunction>


	<cffunction name="testPurchaseWithCardSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Purchase should not have errors but did") />
	</cffunction>


	<cffunction name="testPurchaseWithStatementDescriptor" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard(), options = {"statement_descriptor": "Test <Descriptor>"}) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(structKeyExists(local.response.getParsedResult(), 'statement_descriptor'), 'statement_descriptor key doesnt exist') />
		<cfset assertTrue(local.response.getParsedResult().statement_descriptor EQ "Test Descriptor", "The statement descriptior should have returned 'Test Descriptor' (with invalid chars stripped), was: #local.response.getParsedResult().statement_descriptor#") />
	</cffunction>	

	
	<cffunction name="testPurchaseDecline" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(arguments.gw, this, "mock_incorrect_number", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createInvalidCard()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "The #arguments.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().error.code EQ "incorrect_number", "Should have been an invalid card, was: #local.response.getParsedResult().error.code#") />
	</cffunction>


	<cffunction name="testPurchaseInvalidCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createInvalidCVCError()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "The #arguments.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().error.code EQ "invalid_cvc", "Should have been an invalid cvc, was: #local.response.getParsedResult().error.code#") />
	</cffunction>


	<cffunction name="testPurchaseNoMatchStreetAddress" access="public" returntype="void" output="false">
		<cfset local.gw = variables.cad />
		<cfset offlineInjector(local.gw, this, "mock_invalid_address1", "doHttpCall") />
		<cfset local.response = local.gw.purchase(money = variables.svc.createMoney(5000, local.gw.currency), account = createValidCardWithoutStreetMatch()) />
		<cfset assertTrue(local.response.getSuccess(), "The #local.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().source.address_line1_check EQ "fail", "Should have been an invalid address1, was: #local.response.getParsedResult().source.address_line1_check#") />
	</cffunction>


	<cffunction name="testPurchaseProcessingError" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_processing_error", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardThatWillBeProcessingError()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "Purchase did succeed but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().error.code EQ "processing_error", "Should have been an processing_error, was: #local.response.getParsedResult().error.code#") />
	</cffunction>


	<cffunction name="testPurchaseWithoutCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCardWithoutCVV()) />

		<cfset assertTrue(local.response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#local.response.getCVVCode()#'") />
		<cfset assertTrue(NOT local.response.getSuccess(), "The #arguments.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code for #arguments.gw.currency# should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().error.code EQ "invalid_cvc", "Should have been an invalid cvc, was: #local.response.getParsedResult().error.code#") />

		<cfset assertTrue(local.response.isValidCVV(), "Blank CVV should be valid") />
		<cfset assertTrue(NOT local.response.isValidCVV(AllowBlankCode = false), "CVV should not be valid") />
	</cffunction>


	<cffunction name="testListChargesWithoutCount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_list_charges_count_10", "doHttpCall") />
		<cfset local.response = arguments.gw.listCharges() />

		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# list did not succeed but should have") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code for #arguments.gw.currency# should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(arrayLen(local.response.getParsedResult().data) EQ 10, "#arguments.gw.currency# list without count should have returned 10 results, was: #arrayLen(local.response.getParsedResult().data)#") />
	</cffunction>


	<cffunction name="testListChargesWithCountOf2" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_list_charges_count_2", "doHttpCall") />
		<cfset local.response = arguments.gw.listCharges(count = 2) />

		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# list did not succeed but should have") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code for #arguments.gw.currency# should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(arrayLen(local.response.getParsedResult().data) EQ 2, "#arguments.gw.currency# list without count should have returned 2 results, was: #arrayLen(local.response.getParsedResult().data)#") />
	</cffunction>


	<cffunction name="testStoreTokenSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset local.token = variables.svc.createToken() />
		
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset local.token.setID(local.response.getTransactionId()) />
		<cfset offlineInjector(arguments.gw, this, "mock_store_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.store(account = local.token) />
		
		<cfset assertTrue(local.response.getSuccess() AND structKeyExists(local.response.getParsedResult(), "created"), "The store did not succeed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Store should not have errors but did") />
	</cffunction>


	<cffunction name="testTokenizeCardAndFetchResult" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var token = variables.svc.createToken() />
		
		<cfset offlineInjector(gw, this, "mock_token_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />

		<cfset response = gw.getToken(id = response.getTransactionID()) />

		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "created"), "The validate did not succeed") />
		<cfset assertTrue(left(response.getTransactionID(), 3) EQ "tok", "We did not get back a token ID begining with tok_") />
		<cfset assertTrue(response.getParsedResult().used EQ false, "The token should be new and unused") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Store should not have errors but did") />
	</cffunction>


	<cffunction name="testTokenizeBankAccountAndFetchResult" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var token = variables.svc.createToken() />
		
		<cfset offlineInjector(gw, this, "mock_banktoken_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createValidBankAccount()) />

		<cfset response = gw.getToken(id = response.getTransactionID()) />

		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "created"), "The validate did not succeed") />
		<cfset assertTrue(left(response.getTransactionID(), 4) EQ "btok", "We did not get back a token ID begining with btok_") />
		<cfset assertTrue(response.getParsedResult().used EQ false, "The token should be new and unused") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Store should not have errors but did") />
	</cffunction>


	<cffunction name="testMissingArgumentsThrowsException" access="public" returntype="void" output="false" mxunit:expectedException="any">
		<cfset local.money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset local.options = structNew() />
		
		<cfset local.response = variables.gw.purchase(options = local.options) />
		<cfset assertTrue(false, "No error was thrown") />
	</cffunction>
		

	<cffunction name="testPurchaseThenRefundFull" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset offlineInjector(arguments.gw, this, "mock_refund_full_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.refund(transactionid = local.response.getTransactionID()) />
		<cfset assertTrue(local.response.getSuccess(), "You can refund a purchase in full") />
		<cfset assertTrue(local.response.getParsedResult().amount_refunded EQ 5000, "The full refund should be for $50.00") />
	</cffunction>


	<cffunction name="testPurchaseThenRefundPartial" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.refund(transactionid = local.response.getTransactionID(), money = variables.svc.createMoney(2500, arguments.gw.currency)) />
		<cfset assertTrue(local.response.getSuccess(), "You can refund a purchase in full") />
		<cfset assertTrue(local.response.getParsedResult().amount_refunded EQ 2500, "The partial refund should be for $25.00") />
	</cffunction>


	<cffunction name="testConvertDateToStripe" output="false" access="public" returntype="void">
		<cfset local.dte = createDateTime(2009, 12, 7, 16, 0, 0) />
		<cfset local.dteNow = now() />

		<cfset assertTrue(variables.gw.utcToDate(variables.gw.dateToUTC(local.dte)) EQ local.dte, "A round trip should return the original value") />
	</cffunction>


	<cffunction name="testConvertStripeToDate" output="false" access="public" returntype="void">
		<!--- create a timestamp in GMT as though it came from Stripe in epoch offset "created" --->
		<cfset local.dteKnownStripeEquivalent = "2013-02-16 05:20:46" />
		<cfset local.stripeUTC = 1360992046 />

		<!--- first convert the stripe epoch value into a local time value --->
		<cfset local.dteLocalTime = variables.gw.utcToDate(local.stripeUTC) />

		<!--- if the coldfusion server is running in UTC, the utcTotalOffset = 0, otherwise we need to add the UTC offset for comparison so this test can run on any CF install anywhere --->
		<cfset local.dteGMT = castToUTC(local.dteLocalTime) />

		<!--- now they should be identical --->		
		<cfset assertTrue(local.dteKnownStripeEquivalent EQ local.dteGMT, "Stripe date should convert to local time: (#local.dteKnownStripeEquivalent# != #local.dteGMT# / #local.stripeUTC#)") />
	</cffunction>




	<!--- PRIVATE HELPERS, MOCKS, ETC --->
	<cffunction name="castToUTC" output="false" access="private" returntype="any">
		<cfargument name="dtm" required="yes" type="any" />

		<cfset local.jTimeZone = createObject("java","java.util.TimeZone") />
		<cfset local.timezone = local.jTimeZone.getDefault() />

		<cfscript>
			local.tYear = javacast("int", Year(arguments.dtm));
			local.tMonth = javacast("int", Month(arguments.dtm)-1); //java months are 0 based
			local.tDay = javacast("int", Day(arguments.dtm));
			local.tDOW = javacast("int", DayOfWeek(arguments.dtm));	//day of week
			local.thisOffset = (timezone.getOffset(1, local.tYear, local.tMonth, local.tDay, local.tDOW, 0) / 1000) * -1.00;
			return dateAdd("s", local.thisOffset, arguments.dtm);
		</cfscript>
	</cffunction>

	<cffunction name="createValidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset local.account = variables.svc.createCreditCard() />
		<cfset local.account.setAccount(4242424242424242) />
		<cfset local.account.setMonth(10) />
		<cfset local.account.setYear(year(now())+1) />
		<cfset local.account.setVerificationValue(999) />
		<cfset local.account.setFirstName("John") />
		<cfset local.account.setLastName("Doe") />
		<cfset local.account.setAddress("888") />
		<cfset local.account.setPostalCode("77777") />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createInvalidCard" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4242424242424241) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createValidCardWithoutCVV" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4111111111111111) />
		<cfset local.account.setVerificationValue() />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createValidCardWithFailedCVV" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000101) />
		<cfreturn local.account />	
	</cffunction>
	
	<cffunction name="createValidCardWithoutStreetMatch" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000028) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createValidCardWithoutZipMatch" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000036) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createValidCardWithoutAVSMatch" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000010) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createCardThatWillBeDeclined" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000002) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createCardThatWillBeExpired" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000069) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createCardThatWillBeProcessingError" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAccount(4000000000000119) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createInvalidMonthCardError" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setMonth(13) />
		<cfreturn local.account />	
	</cffunction>

	<cffunction name="createInvalidYearCardError" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setYear(1970) />
		<cfreturn local.account />	
	</cffunction>
	
	<cffunction name="createInvalidCVCError" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setVerificationValue(99) />
		<cfreturn local.account />	
	</cffunction>
	
	<cffunction name="createValidBankAccount" access="private" returntype="any" output="false">
		<cfset var account = variables.svc.createEFT() />
		<cfset account.setAccount("000123456789") />
		<cfset account.setRoutingNumber("110000000") />
		<cfset account.setAccountType("checking") />
		<cfset account.setSEC("CCD") />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("123 Business Lane") />
		<cfset account.setPostalCode("77777") />
		<cfset account.setCountry("US") />

		<cfreturn account />	
	</cffunction>


	<cffunction name="mock_token_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_1IZvRgzvQlffjs", "livemode": false, "created": 1360974256, "used": false, "object": "token", "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "" } }' } />
	</cffunction>

	<cffunction name="mock_banktoken_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "id": "btok_61uQEmLSSGMlgg", "livemode": false, "created": 1428628004, "used": false, "object": "token", "type": "bank_account", "bank_account": { "object": "bank_account", "id": "ba_61uQcOc8nQmcpz", "last4": "6789", "country": "US", "currency": "usd", "status": "new", "fingerprint": "qkcoF3CJjVSJl0g2", "routing_number": "110000000", "bank_name": "STRIPE TEST BANK", "default_for_currency": false } }' } />
		<cfreturn http />
	</cffunction>
	
	<cffunction name="mock_store_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "customer", "created": 1360991479, "id": "cus_1IeYQ4dYTTI4Bt", "livemode": false, "description": null, "active_card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "email": null, "delinquent": false, "subscription": null, "discount": null, "account_balance": 0 }' } />
	</cffunction>

	<cffunction name="mock_purchase_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IehV2hFFglF0v", "object": "charge", "created": 1360991963, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "statement_descriptor": "TEST DESCRIPTOR" }' } />
	</cffunction>
	
	<cffunction name="mock_refund_full_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IfncE2zg8NMw9", "object": "charge", "created": 1360996094, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": true, "fee": 0, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 175 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 5000, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
	</cffunction>
	
	<cffunction name="mock_refund_partial_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IfpWrsmQSA3IA", "object": "charge", "created": 1360996197, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
	</cffunction>
	
	<cffunction name="mock_invalid_cvc" access="private">
		<cfreturn { StatusCode = '402', FileContent = '{ "error": { "message": "Your card''s security code is invalid", "type": "card_error", "param": "cvc", "code": "invalid_cvc" } }' } />
	</cffunction>

	<cffunction name="mock_invalid_expiry" access="private">
		<cfreturn { StatusCode = '402', FileContent = '{ "error": { "message": "Your card''s expiration year is invalid", "type": "card_error", "param": "exp_year", "code": "invalid_expiry_year" } }' } />
	</cffunction>

	<cffunction name="mock_incorrect_number" access="private">
		<cfreturn { StatusCode = '402', FileContent = '{ "error": { "message": "Your card number is incorrect", "type": "card_error", "param": "number", "code": "incorrect_number" } }' } />
	</cffunction>

	<cffunction name="mock_processing_error" access="private">
		<cfreturn { StatusCode = '402', FileContent = '{ "error": { "message": "An error occurred while processing your card", "type": "card_error", "code": "processing_error", "charge": "ch_1Ie7BA4vAb8ZaF" } }' } />
	</cffunction>

	<cffunction name="mock_invalid_address1" access="private">
		<cfreturn { StatusCode = '200', FileContent = '{ "id": "ch_1IeAMjrHpnj7dV", "object": "charge", "created": 1360990030, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "source": { "object": "card", "last4": "0028", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "1YqKn8Y7DbGMP8a1", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "fail", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
	</cffunction>

	<cffunction name="mock_list_charges_count_10" access="private">
	<cfreturn { StatusCode = '200', FileContent = '{ "object": "list", "count": 31800, "url": "/v1/charges", "data": [ { "id": "ch_1IxL1nrwUu7kmF", "object": "charge", "created": 1361061326, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxLLW6cPV1kIK", "object": "charge", "created": 1361061323, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxL31sObDzpCv", "object": "charge", "created": 1361061320, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": true, "fee": 0, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 175 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 5000, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxK3Xh6I2xrNE", "object": "charge", "created": 1361061317, "livemode": false, "paid": false, "amount": 5000, "currency": "usd", "refunded": false, "fee": 0, "fee_details": [], "card": { "object": "card", "last4": "0119", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "YggjdcH7yERT93CL", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": "An error occurred while processing your card", "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1Iuelcm8fpWb5v", "object": "charge", "created": 1361051359, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By77C9AgMAIw2", "invoice": "in_1ItfkkOrk99sat", "description": null, "dispute": null }, { "id": "ch_1IueK7L83dUFhK", "object": "charge", "created": 1361051358, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By7tRmEv8zcqW", "invoice": "in_1Itf8IT0wEG9R8", "description": null, "dispute": null }, { "id": "ch_1IueGPyiGOsISV", "object": "charge", "created": 1361051356, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By6oVFxh4j0OR", "invoice": "in_1ItfCmqahj5CLg", "description": null, "dispute": null }, { "id": "ch_1Iuee3zxbf6Eez", "object": "charge", "created": 1361051355, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By6rD5aPmULnT", "invoice": "in_1ItfDCc2kbn7XF", "description": null, "dispute": null }, { "id": "ch_1IucE7qqbtaXng", "object": "charge", "created": 1361051232, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By5i2kAbTsaX3", "invoice": "in_1Iteod2vndXuD7", "description": null, "dispute": null }, { "id": "ch_1Iuc0z4PmscDT4", "object": "charge", "created": 1361051232, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By5b0y9bDVB7U", "invoice": "in_1IteiR0nvAU7ta", "description": null, "dispute": null } ] }' } />
	</cffunction>

	<cffunction name="mock_list_charges_count_2" access="private">
		<cfreturn { StatusCode = '200', FileContent = '{ "object": "list", "count": 31800, "url": "/v1/charges", "data": [ { "id": "ch_1IxL1nrwUu7kmF", "object": "charge", "created": 1361061326, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxLLW6cPV1kIK", "object": "charge", "created": 1361061323, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null } ] } ' } />
	</cffunction>
</cfcomponent>