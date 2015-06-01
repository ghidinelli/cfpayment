<cfcomponent name="StripeTest" extends="BaseStripeTest" output="false">

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
		<cfset assertTrue(local.response.getTransactionId() EQ local.response.getTokenID(), "The token ID should be put into the token field when created, was: #local.response.getTokenID()#") />
		<cfset assertTrue(local.response.getAVSCode() EQ "", "AVS isn't checked on validate, was: #local.response.getAVSCode()#") />
		<cfset assertTrue(local.response.getCVVCode() EQ "", "CVV isn't checked on validate, was: #local.response.getCVVCode()#") />
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


	<cffunction name="testPurchaseWithStripeJSToken" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset local.token = variables.svc.createToken() />

		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset local.token.setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = token) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Purchase should not have errors but did") />
	</cffunction>


	<cffunction name="testPurchaseWithCustomerAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_store_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.store(account = token) />
		<cfset assertTrue(local.response.getAVSCode() EQ "M", "AVS wasn't matched, was: #local.response.getAVSCode()#") />
		<cfset assertTrue(local.response.getCVVCode() EQ "M", "CVV wasn't matched, was: #local.response.getCVVCode()#") />
		<cfset assertTrue(local.response.getTransactionId() EQ local.response.getTokenID(), "The customer ID should be put into the token field when stored, was: #local.response.getTokenID()#") />
		<cfset local.customer = variables.svc.createToken().setId(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), options = {customer: local.customer}) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Purchase should not have errors but did") />
	</cffunction>


	<cffunction name="testPurchaseWithCardSuccess" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Purchase should not have errors but did") />
	</cffunction>


	<cffunction name="testPurchaseAuthorizeWithoutCapture" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_no_capture", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard(), options = {"capture": false}) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Purchase should not have errors but did") />
		<cfset assertTrue(NOT local.response.getParsedResult().captured, "Charge should be auth only, not captured") />
		<cfset assertTrue(local.response.getAVSCode() EQ "M", "Full match should be M, was: #local.response.getAVSCode()#") />
		<cfset assertTrue(local.response.getCVVCode() EQ "M", "CVV match should be M, was: #local.response.getCVVCode()#") />
		<cfset assertTrue(len(local.response.getAuthorization()), "For capture only, authorization should have a value") />
		<cfset assertTrue(local.response.getAuthorization() EQ local.response.getTransactionID(), "For capture only, authorization should = transaction id") />
	</cffunction>
	

	<cffunction name="testPurchaseWithStatementDescriptor" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard(), options = {"statement_descriptor": "Test <Descriptor>"}) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# purchase failed but should have succeeded") />
		<cfset assertTrue(structKeyExists(local.response.getParsedResult(), 'statement_descriptor'), 'statement_descriptor key doesnt exist') />
		<cfset assertTrue(local.response.getParsedResult().statement_descriptor EQ "Test Descriptor", "The statement descriptior should have returned 'Test Descriptor' (with invalid chars stripped), was: #local.response.getParsedResult().statement_descriptor#") />
	</cffunction>	

	
	<cffunction name="testPurchaseDecline" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_incorrect_number", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createInvalidCard()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "The #arguments.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().error.code EQ "incorrect_number", "Should have been an invalid card, was: #local.response.getParsedResult().error.code#") />
		<cfset assertTrue(NOT len(local.response.getAVSCode()), "AVS should be blank, was: #local.response.getAVSCode()#") />
	</cffunction>


	<cffunction name="testPurchaseInvalidCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset offlineInjector(arguments.gw, this, "mock_invalid_cvc", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createInvalidCVCError()) />
		<cfset assertTrue(NOT local.response.getSuccess(), "The #arguments.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 402, "Status code should be 402, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().error.code EQ "invalid_cvc", "Should have been an invalid cvc, was: #local.response.getParsedResult().error.code#") />
		<cfset assertTrue(NOT len(local.response.getCVVCode()), "CVV should be blank, was: #local.response.getCVVCode()#") />
	</cffunction>


	<cffunction name="testPurchaseNoMatchStreetAddress" access="public" returntype="void" output="false">
		<cfset local.gw = variables.cad />
		<cfset offlineInjector(local.gw, this, "mock_invalid_address1", "doHttpCall") />
		<cfset local.response = local.gw.purchase(money = variables.svc.createMoney(5000, local.gw.currency), account = createValidCardWithoutStreetMatch()) />
		<cfset assertTrue(local.response.getSuccess(), "The #local.gw.currency# purchase succeeded but should have failed") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(local.response.getParsedResult().source.address_line1_check EQ "fail", "Should have been an invalid address1, was: #local.response.getParsedResult().source.address_line1_check#") />
		<cfset assertTrue(local.response.getAVSCode() EQ "P", "Address1 match should be P, was: #local.response.getAVSCode()#") />
		<cfset assertTrue(local.response.getCVVCode() EQ "M", "CVV match should be M, was: #local.response.getCVVCode()#") />
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
		<cfset assertTrue(arrayLen(local.response.getParsedResult().data) GT 2, "#arguments.gw.currency# list without count should have returned more than 2 results, was: #arrayLen(local.response.getParsedResult().data)#") />
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
		<cfset assertTrue(structKeyExists(local.response.getParsedResult(), "object") AND local.response.getParsedResult().object EQ "customer", "Should be a customer response") />
		<cfset assertTrue(structKeyExists(local.response.getParsedResult(), "default_source"), "Should have default_source value") />
		<cfset assertTrue(structKeyExists(local.response.getParsedResult(), "sources"), "Should have sources key") />
		<cfset assertTrue(structKeyExists(local.response.getParsedResult().sources, "data"), "Should have data key") />
		<cfset assertTrue(arrayLen(local.response.getParsedResult().sources.data), "Data key should be an array with a length") />
		<cfset assertTrue(local.response.getParsedResult().sources.data[1].last4 EQ "4242", "Last4 should have been 4242") />
	</cffunction>


	<cffunction name="testTokenizeCardAndFetchResult" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var token = variables.svc.createToken() />
		
		<cfset offlineInjector(gw, this, "mock_token_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createValidCard()) />
		<cfset response = gw.getAccountToken(id = response.getTransactionID()) />

		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "created"), "The validate did not succeed") />
		<cfset assertTrue(left(response.getTransactionID(), 3) EQ "tok", "We did not get back a token ID begining with tok_") />
		<cfset assertTrue(response.getParsedResult().used EQ false, "The token should be new and unused") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
		<cfset assertTrue(NOT response.hasError(), "Store should not have errors but did") />
	</cffunction>


	<cffunction name="testTokenizeWithUndefinedAddressCheckIssue19" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_token_ok_unchecked_avs", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCardWithoutAddress()) />
		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# tokenization failed but should have succeeded even if address is unchecked") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Validate should not have errors but did") />
		<cfset assertTrue(local.response.getAVSCode() EQ "", "AVS should have been blank because AVS isn't checked for tokens, was: #local.response.getAVSCode()#") />
		<cfset assertTrue(local.response.getCVVCode() EQ "", "CVV should have been blank because CVV isn't checked for tokens, was: #local.response.getCVVCode()#") />
	</cffunction>


	<cffunction name="testTokenizeWithNullChecks" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_token_ok_null_checks", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCardWithoutAddress()) />

		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# tokenization failed but should have succeeded even if address is unchecked") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Validate should not have errors but did") />
		<cfset assertTrue(local.response.getAVSCode() EQ "", "AVS should have been blank because AVS isn't checked for tokens, was: #local.response.getAVSCode()#") />
		<cfset assertTrue(local.response.getCVVCode() EQ "", "CVV should have been blank because CVV isn't checked for tokens, was: #local.response.getCVVCode()#") />
	</cffunction>


	<cffunction name="testPurchaseWithNullChecks" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok_null_checks", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCardWithoutAVSMatch()) />

		<cfset assertTrue(local.response.getSuccess(), "The #arguments.gw.currency# tokenization failed but should have succeeded even if address is unchecked") />
		<cfset assertTrue(local.response.getStatusCode() EQ 200, "Status code should be 200, was: #local.response.getStatusCode()#") />
		<cfset assertTrue(NOT local.response.hasError(), "Validate should not have errors but did") />
		<cfset assertTrue(local.response.getAVSCode() EQ "", "AVS should have been blank because AVS isn't checked for tokens, was: #local.response.getAVSCode()#") />
	</cffunction>
	

	<cffunction name="testTokenizeBankAccountAndFetchResult" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var token = variables.svc.createToken() />
		
		<cfset offlineInjector(gw, this, "mock_banktoken_ok", "doHttpCall") />
		<cfset response = gw.validate(money = variables.svc.createMoney(5000, gw.currency), account = createValidBankAccount()) />
		<cfset response = gw.getAccountToken(id = response.getTransactionID()) />

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

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.purchase(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createValidCard()) />
		<cfset offlineInjector(arguments.gw, this, "mock_refund_full_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.refund(transactionid = local.response.getTransactionID()) />

		<cfset assertTrue(local.response.getParsedResult().object EQ "refund", "It was not a refund object") />
		<cfset assertTrue(local.response.getSuccess(), "You can refund a purchase in full") />
		<cfset assertTrue(local.response.getParsedResult().amount EQ 5000, "The full refund should be for $50.00") />
	</cffunction>


	<cffunction name="testPurchaseThenRefundPartialMultiple" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_purchase_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = variables.svc.createMoney(6000, arguments.gw.currency), account = createValidCard()) />
		
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.refund(transactionid = local.charge.getTransactionID(), money = variables.svc.createMoney(2500, arguments.gw.currency)) />
		<cfset assertTrue(local.response.getSuccess(), "You can refund a purchase partially") />
		<cfset assertTrue(local.response.getParsedResult().object EQ "refund", "It was not a refund object") />
		<cfset assertTrue(local.response.getParsedResult().amount EQ 2500, "The partial refund should be for $25.00") />
		
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.refund(transactionid = local.charge.getTransactionID(), money = variables.svc.createMoney(2500, arguments.gw.currency)) />
		<cfset assertTrue(local.response.getSuccess(), "You can refund a purchase partially more than once if it adds up less than the total") />
		<cfset assertTrue(local.response.getParsedResult().object EQ "refund", "It was not a refund object") />
		<cfset assertTrue(local.response.getParsedResult().amount EQ 2500, "The partial refund should be for $25.00") />
		
		
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_exceed_total", "doHttpCall") />
		<cfset local.response = arguments.gw.refund(transactionid = local.charge.getTransactionID(), money = variables.svc.createMoney(2500, arguments.gw.currency)) />
		<cfset assertTrue(NOT local.response.getSuccess(), "You can't refund more than the original amount") />
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


	<cffunction name="testBalance" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_balance_ok", "doHttpCall") />
		<cfset local.balance = arguments.gw.getBalance() />
		<cfset assertTrue(balance.getParsedResult().object EQ "balance", "A balance object wasn't returned") />

	</cffunction>


	<cffunction name="testNormalizeAVSCVV" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset makePublic(arguments.gw, "normalizeAVS") />
		<cfset makePublic(arguments.gw, "normalizeCVV") />
		
		<cfset local.response = {"object": "card", "country": arguments.gw.country, "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" } />
		<cfset assertTrue(gw.normalizeAVS(response) EQ "M", "AVS should have passed, was #gw.normalizeAVS(response)#") />
		<cfset assertTrue(gw.normalizeCVV(response) EQ "M", "CVV should have passed, was #gw.normalizeCVV(response)#") />

		<cfset local.response = {"object": "card", "country": arguments.gw.country, "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "fail" } />
		<cfset assertTrue(gw.normalizeAVS(response) EQ "B", "AVS should have passed, was #gw.normalizeAVS(response)#") />

		<cfset local.response = {"object": "card", "country": arguments.gw.country, "cvc_check": "pass", "address_line1_check": "fail", "address_zip_check": "pass" } />
		<cfset assertTrue(gw.normalizeAVS(response) EQ "P", "AVS should have passed, was #gw.normalizeAVS(response)#") />

		<cfset local.response = {"object": "card", "country": arguments.gw.country, "cvc_check": "unchecked", "address_line1_check": "unchecked", "address_zip_check": "unchecked" } />
		<cfif gw.country EQ "US">
			<cfset assertTrue(gw.normalizeAVS(response) EQ "S", "AVS should be marked as unsupported (US), was #gw.normalizeAVS(response)#") />
		<cfelse>
			<cfset assertTrue(gw.normalizeAVS(response) EQ "G", "AVS should be marked as unsupported (Foreign), was #gw.normalizeAVS(response)#") />
		</cfif>
		<cfset assertTrue(gw.normalizeCVV(response) EQ "U", "CVV should be marked as unsupported, was #gw.normalizeCVV(response)#") />


		<cfset local.response = {"object": "card", "country": arguments.gw.country, "cvc_check": "fail", "address_line1_check": "fail", "address_zip_check": "fail" } />
		<cfset assertTrue(gw.normalizeAVS(response) EQ "N", "AVS should have failed, was #gw.normalizeAVS(response)#") />
		<cfset assertTrue(gw.normalizeCVV(response) EQ "N", "CVV should have failed, was #gw.normalizeCVV(response)#") />

		<cfset local.response = {"object": "card", "country": arguments.gw.country } />
		<cfset assertTrue(gw.normalizeAVS(response) EQ "", "AVS should have failed, was #gw.normalizeAVS(response)#") />
		<cfset assertTrue(gw.normalizeCVV(response) EQ "", "CVV should have failed, was #gw.normalizeCVV(response)#") />

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
		<cfset local.account.setAddress("888 Anywhere Lane") />
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
	
	<cffunction name="createValidCardWithoutAddress" access="private" returntype="any" output="false">
		<cfset local.account = createValidCard() />
		<cfset local.account.setAddress("") />
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
		<cfset local.account.setAddress("") />
		<cfset local.account.setPostalCode("") />
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
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_6Lc9jlTa7yU2ky", "livemode": false, "created": 1433172850, "used": false, "object": "token", "type": "card", "card": { "id": "card_6Lc90vCQf7EDwh", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "unchecked", "address_line1_check": "unchecked", "address_zip_check": "unchecked", "dynamic_last4": null, "metadata": {} }, "client_ip": "127.0.0.1" }' } />
	</cffunction>

	<cffunction name="mock_token_ok_unchecked_avs" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_65NT77fCo4cCEO", "livemode": true, "created": 1429428006, "used": false, "object": "token", "type": "card", "card": { "id": "card_65NT1zXyit19Gk", "object": "card", "last4": "4001", "brand": "American Express", "funding": "unknown", "exp_month": 1, "exp_year": 2018, "fingerprint": "m4KxtLGciUBrRaMk", "country": null, "name": "Joe Blow", "address_line1": "123 Some Way", "address_line2": null, "address_city": "Calgary", "address_state": "AB ", "address_zip": "T3H2W6", "address_country": "CA", "cvc_check": "unchecked", "address_line1_check": "unchecked", "address_zip_check": "unchecked", "dynamic_last4": null }, "client_ip": "224.14.138.168" }' } />
	</cffunction>

	<cffunction name="mock_token_ok_null_checks" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_65NT77fCo4cCEO", "livemode": true, "created": 1429428006, "used": false, "object": "token", "type": "card", "card": { "id": "card_65NT1zXyit19Gk", "object": "card", "last4": "4001", "brand": "American Express", "funding": "unknown", "exp_month": 1, "exp_year": 2018, "fingerprint": "m4KxtLGciUBrRaMk", "country": null, "name": "Joe Blow", "address_line1": "123 Some Way", "address_line2": null, "address_city": "Calgary", "address_state": "AB ", "address_zip": "T3H2W6", "address_country": "CA", "cvc_check": null, "address_line1_check": null, "address_zip_check": null, "dynamic_last4": null }, "client_ip": "224.14.138.168" }' } />
	</cffunction>
	
	<cffunction name="mock_purchase_ok_null_checks" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_6LecnZjGNp3pHH", "object": "charge", "created": 1433182020, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_6LecB3TU5xmZEt", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888 Anywhere Lane", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": null, "address_line1_check": null, "address_zip_check": null, "dynamic_last4": null, "metadata": {}, "customer": "cus_6LecAtEEFyvRtx" }, "captured": true, "balance_transaction": "txn_6Lecqn02qYxb83", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": "cus_6LecAtEEFyvRtx", "invoice": null, "description": null, "dispute": null, "metadata": {}, "statement_descriptor": "TEST DESCRIPTOR", "fraud_details": {}, "receipt_email": null, "receipt_number": null, "shipping": null, "destination": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_6LecnZjGNp3pHH/refunds", "data": [] } }' } />
	</cffunction>


	<cffunction name="mock_banktoken_ok" access="private">
		<cfset var http = { StatusCode = '200 OK', FileContent = '{ "id": "btok_6LcgqhP4t39mYj", "livemode": false, "created": 1433174792, "used": false, "object": "token", "type": "bank_account", "bank_account": { "object": "bank_account", "id": "ba_6LcgvRGvZtugSp", "last4": "6789", "country": "US", "currency": "usd", "status": "new", "fingerprint": "MYme1jP2GEKoZ0xi", "routing_number": "110000000", "bank_name": "STRIPE TEST BANK" }, "client_ip": null } ' } />
		<cfreturn http />
	</cffunction>
	
	<cffunction name="mock_store_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "customer", "created": 1433173085, "id": "cus_6LcD0oto8ndYMz", "livemode": false, "description": null, "email": null, "delinquent": false, "metadata": {}, "subscriptions": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/customers/cus_6LcD0oto8ndYMz/subscriptions", "data": [] }, "discount": null, "account_balance": 0, "currency": null, "sources": { "object": "list", "total_count": 1, "has_more": false, "url": "/v1/customers/cus_6LcD0oto8ndYMz/sources", "data": [ { "id": "card_6LcDpYvajJeulk", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": {}, "customer": "cus_6LcD0oto8ndYMz" } ] }, "default_source": "card_6LcDpYvajJeulk" }' } />
	</cffunction>

	<cffunction name="mock_purchase_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_6LecnZjGNp3pHH", "object": "charge", "created": 1433182020, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_6LecB3TU5xmZEt", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888 Anywhere Lane", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": {}, "customer": "cus_6LecAtEEFyvRtx" }, "captured": true, "balance_transaction": "txn_6Lecqn02qYxb83", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": "cus_6LecAtEEFyvRtx", "invoice": null, "description": null, "dispute": null, "metadata": {}, "statement_descriptor": "TEST DESCRIPTOR", "fraud_details": {}, "receipt_email": null, "receipt_number": null, "shipping": null, "destination": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_6LecnZjGNp3pHH/refunds", "data": [] } }' } />
	</cffunction>

	<cffunction name="mock_purchase_no_capture" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_6LeebvuUK9psRD", "object": "charge", "created": 1433182109, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_6LeeNzLM92Plhm", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888 Anywhere Lane", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": {}, "customer": null }, "captured": false, "balance_transaction": null, "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "metadata": {}, "statement_descriptor": null, "fraud_details": {}, "receipt_email": null, "receipt_number": null, "shipping": null, "destination": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_6LeebvuUK9psRD/refunds", "data": [] } }' } />
	</cffunction>
	
	<cffunction name="mock_refund_full_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_6KvatBzwQDGk5H", "amount": 5000, "currency": "usd", "created": 1433014494, "object": "refund", "balance_transaction": "txn_6KvaD6WPm0mCFs", "metadata": {}, "charge": "ch_6KvaiViAHtNFQI", "receipt_number": null, "reason": null }' } />
	</cffunction>
	
	<cffunction name="mock_refund_partial_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_6KvcMiHdQozrMG", "amount": 2500, "currency": "usd", "created": 1433014617, "object": "refund", "balance_transaction": "txn_6Kvcbog0NEvfHR", "metadata": {}, "charge": "ch_6KvcKBRM9QcQJk", "receipt_number": null, "reason": null }' } />
	</cffunction>

	<cffunction name="mock_refund_partial_exceed_total" access="private">
		<cfreturn { StatusCode = '400', FileContent = '{ "error": { "type": "invalid_request_error", "message": "Refund amount ($25.00) is greater than unrefunded amount on charge ($10.00)", "param": "amount" } }' } />
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
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_1IeAMjrHpnj7dV", "object": "charge", "created": 1360990030, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "source": { "object": "card", "last4": "0028", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "1YqKn8Y7DbGMP8a1", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "fail", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }' } />
	</cffunction>

	<cffunction name="mock_list_charges_count_10" access="private">
		<cfsavecontent variable="local.response">
			{ "object": "list", "count": 31800, "url": "/v1/charges", "data": [ { "id": "ch_1IxL1nrwUu7kmF", "object": "charge", "created": 1361061326, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxLLW6cPV1kIK", "object": "charge", "created": 1361061323, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxL31sObDzpCv", "object": "charge", "created": 1361061320, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": true, "fee": 0
			, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 175 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 5000, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxK3Xh6I2xrNE", "object": "charge", "created": 1361061317, "livemode": false, "paid": false, "amount": 5000, "currency": "usd", "refunded": false, "fee": 0, "fee_details": [], "card": { "object": "card", "last4": "0119", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "YggjdcH7yERT93CL", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": "An error occurred while processing your card", "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1Iuelcm8fpWb5v", "object": "charge", "created": 1361051359, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder"
			, "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By77C9AgMAIw2", "invoice": "in_1ItfkkOrk99sat", "description": null, "dispute": null }, { "id": "ch_1IueK7L83dUFhK", "object": "charge", "created": 1361051358, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By7tRmEv8zcqW", "invoice": "in_1Itf8IT0wEG9R8", "description": null, "dispute": null }, { "id": "ch_1IueGPyiGOsISV", "object": "charge", "created": 1361051356, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA"
			, "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By6oVFxh4j0OR", "invoice": "in_1ItfCmqahj5CLg", "description": null, "dispute": null }, { "id": "ch_1Iuee3zxbf6Eez", "object": "charge", "created": 1361051355, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By6rD5aPmULnT", "invoice": "in_1ItfDCc2kbn7XF", "description": null, "dispute": null }, { "id": "ch_1IucE7qqbtaXng", "object": "charge", "created": 1361051232, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0
			, "customer": "cus_0By5i2kAbTsaX3", "invoice": "in_1Iteod2vndXuD7", "description": null, "dispute": null }, { "id": "ch_1Iuc0z4PmscDT4", "object": "charge", "created": 1361051232, "livemode": false, "paid": true, "amount": 100, "currency": "usd", "refunded": false, "fee": 33, "fee_details": [ { "amount": 33, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 12, "exp_year": 2015, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "Java Bindings Cardholder", "address_line1": "522 Ramona St", "address_line2": "Palo Alto", "address_city": null, "address_state": "CA", "address_zip": "94301", "address_country": "USA", "cvc_check": null, "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": "cus_0By5b0y9bDVB7U", "invoice": "in_1IteiR0nvAU7ta", "description": null, "dispute": null } ] }
		</cfsavecontent>
		<cfreturn { StatusCode = '200 OK', FileContent = response } />
	</cffunction>

	<cffunction name="mock_list_charges_count_2" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "list", "count": 31800, "url": "/v1/charges", "data": [ { "id": "ch_1IxL1nrwUu7kmF", "object": "charge", "created": 1361061326, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 175, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 0 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null }, { "id": "ch_1IxLLW6cPV1kIK", "object": "charge", "created": 1361061323, "livemode": false, "paid": true, "amount": 5000, "currency": "usd", "refunded": false, "fee": 102, "fee_details": [ { "amount": 175, "currency": "usd", "type": "stripe_fee", "description": "Stripe processing fees", "application": null, "amount_refunded": 73 } ], "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "Z0VUjeIIj0HObMhK", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass" }, "failure_message": null, "amount_refunded": 2500, "customer": null, "invoice": null, "description": null, "dispute": null } ] }' } />
	</cffunction>
	
	<cffunction name="mock_balance_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "pending": [ { "amount": -3090, "currency": "cad" } ], "available": [ { "amount": 13412, "currency": "cad" } ], "livemode": false, "object": "balance" }' } />
	</cffunction>
	
</cfcomponent>