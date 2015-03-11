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
			//gw.TestSecretKey = 'sk_test_Zx4885WE43JGqPjqGzaWap8a';
			gw.TestSecretKey = 'sk_test_zHQajGEqUithBnfId6C2pkzq';
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
			variables.gw = variables.cad;
			
			// for dataprovider testing
			variables.gateways = [cad];

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




	<!--- Tests --->

		<!--- Marketplace Account Tests --->
	<cffunction name="testMarketplaceCreateConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "account", "Account creation failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testMarketplaceUpdateConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_update_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceUpdateConnectedAccount(connectedAccount = connectedAccount.getParsedResult().id, updates = ["legal_entity[first_name]=John","legal_entity[last_name]=Smith","email=#newEmail#"]) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "account", "Account update failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testMarketplaceListConnectedAccounts" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_account_list_ok", "doHttpCall") />
		<cfset response = gw.marketplaceListConnectedAccounts() />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "list", "No account list") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
	
	<cffunction name="testMarketplaceConnectedAccountUserDataPopulation" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_update_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceUpdateConnectedAccount(connectedAccount = connectedAccount.getParsedResult().id, updates = ["legal_entity[first_name]=John","legal_entity[last_name]=Smith","email=#newEmail#"]) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "account", "Account update failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testMarketplaceConnectedAccountUserDataPopulationWithInvalidFieldsThrowsError" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_update_account_failed", "doHttpCall") />
		<cfset response = gw.marketplaceUpdateConnectedAccount(connectedAccount = connectedAccount.getParsedResult().id, updates = ["legal_entity[invalid_field]=fail"]) />
		<cfset assertTrue(structKeyExists(response.getParsedResult(), "error"), "There should be an error but there wasnt") />
	</cffunction>

		<!--- Bank Account Tests --->
	<cffunction name="testFetchBankAccounts" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_fetch_bank_accounts_ok", "doHttpCall") />
		<cfset response = gw.marketplaceFetchBankAccounts(connectedAccount = connectedAccount.getParsedResult().id) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "list", "Failed to list bank accounts") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code while fetching bank account list should be 200, was: #response.getStatusCode()#") />
	</cffunction>
	
	<cffunction name="testCreateBankAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset response = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "bank_account", "Failed to create bank account") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
	
	<cffunction name="testUpdateBankAccountDefaultForCurrency" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset assertTrue(bankAccount.getSuccess() AND structKeyExists(bankAccount.getParsedResult(), "object") AND bankAccount.getParsedResult().object eq "bank_account", "Failed to create bank account") />
		<cfset assertTrue(bankAccount.getStatusCode() EQ 200, "Status code should be 200, was: #bankAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_update_bank_account_default_for_currency_ok", "doHttpCall") />
		<cfset response = gw.marketplaceUpdateBankAccountDefaultForCurrency(connectedAccount = connectedAccount.getParsedResult().id, bankAccountId = bankAccount.getParsedResult().id) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "bank_account", "Failed to update bank account") />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "default_for_currency") AND response.getParsedResult().default_for_currency eq true, "Default for currency not set to true") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
	
	<cffunction name="testDeleteBankAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create first (default for currency) connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset assertTrue(bankAccount.getSuccess() AND structKeyExists(bankAccount.getParsedResult(), "object") AND bankAccount.getParsedResult().object eq "bank_account", "Failed to create bank account") />
		<cfset assertTrue(bankAccount.getStatusCode() EQ 200, "Status code should be 200, was: #bankAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<!--- Creating two bank account because you can't delete the account that is default for currency' --->
		<cfset assertTrue(bankAccount.getSuccess() AND structKeyExists(bankAccount.getParsedResult(), "object") AND bankAccount.getParsedResult().object eq "bank_account", "Failed to create second (not default for currency) bank account") />
		<cfset assertTrue(bankAccount.getStatusCode() EQ 200, "Status code should be 200, was: #bankAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_delete_bank_accounts_ok", "doHttpCall") />
		<cfset response = gw.marketplaceDeleteBankAccount(connectedAccount = connectedAccount.getParsedResult().id, bankAccountId = bankAccount.getParsedResult().id) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "deleted") AND response.getParsedResult().deleted eq true, "Failed to delete the second (not default for currency) bank account") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
	
	<cffunction name="testDeleteDefaultForCurrencyBankAccountFails" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create first (default for currency) connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset assertTrue(bankAccount.getSuccess() AND structKeyExists(bankAccount.getParsedResult(), "object") AND bankAccount.getParsedResult().object eq "bank_account", "Failed to create bank account") />
		<cfset assertTrue(bankAccount.getStatusCode() EQ 200, "Status code should be 200, was: #bankAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_delete_bank_accounts_ok", "doHttpCall") />
		<cfset response = gw.marketplaceDeleteBankAccount(connectedAccount = connectedAccount.getParsedResult().id, bankAccountId = bankAccount.getParsedResult().id) />
		<cfset assertTrue(NOT (response.getSuccess() AND structKeyExists(response.getParsedResult(), "error") AND response.getParsedResult().error.type eq 'invalid_request_error'), "Expected error from api service not received") />
		<cfset assertTrue(response.getStatusCode() EQ 400, "Status code should be 400, was: #response.getStatusCode()#") />
	</cffunction>

		<!--- Identity Verification Tests --->
	<cffunction name="testUploadIdentityFile" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset response = gw.marketplaceUploadIdentityFile(file = "C:\inetpub\pukka\msr\shared\cfpayment\api\gateway\stripe\tests\sample_driving_license_usa.jpg") />
		<cfset apiResponse = deserializeJson(response.fileContent)>
		<cfset assertTrue(structKeyExists(apiResponse, "created"), "File upload failed") />
		<cfset assertTrue(response.responseHeader.status_code EQ 200, "Status code should be 200, was: #response.responseHeader.status_code#") />
	</cffunction>

	<cffunction name="AttachFileToAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset response = gw.marketplaceUploadIdentityFile(file = "C:\inetpub\pukka\msr\shared\cfpayment\api\gateway\stripe\tests\sample_driving_license_usa.jpg") />
		<cfset apiResponse = deserializeJson(response.fileContent)>

		<cfset offlineInjector(gw, this, "mock_attach_file_to_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceAttachFileToAccount(connectedAccount = connectedAccount.getParsedResult().id, fileId = apiResponse.id) />
		<cfset assertFalse(structKeyExists(response.getParsedResult(), "error"), "#response.getParsedResult().error.message#") />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "account"), "File connection to account failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

		<!--- Test Bank Charges --->
	<cffunction name="testCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>

		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset response = gw.charge(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "charge", "Charge Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testDirectCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>

		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset response = gw.charge(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "charge", "Charge Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset response = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "charge"), "Charge Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testDestinationCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_destination_charge_ok", "doHttpCall") />
		<cfset response = gw.marketplaceDestinationCharge(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "charge"), "Charge Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testRefundCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset assertTrue(charge.getSuccess() AND structKeyExists(charge.getParsedResult(), "charge"), "Charge Failed") />
		<cfset assertTrue(charge.getStatusCode() EQ 200, "Status code should be 200, was: #charge.getStatusCode()#") />
		<cfset refundAmount = variables.svc.createMoney(300, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_refund_charge_ok", "doHttpCall") />
		<cfset response = gw.marketplaceRefundCharge(refundAmount) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "refund"), "Refund Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testRefundChargeToConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset assertTrue(charge.getSuccess() AND structKeyExists(charge.getParsedResult(), "charge"), "Charge Failed") />
		<cfset assertTrue(charge.getStatusCode() EQ 200, "Status code should be 200, was: #charge.getStatusCode()#") />
		<cfset refundAmount = variables.svc.createMoney(300, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_refund_charge_to_connected_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceRefundChargeToConnectedAccount(charge.getParsedResult().transfer, refundAmount, connectedAccount.getParsedResult().id) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "refund"), "Refund Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>

	<cffunction name="testRefundToAccountPullingBackFundsFromConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset assertTrue(charge.getSuccess() AND structKeyExists(charge.getParsedResult(), "charge"), "Charge Failed") />
		<cfset assertTrue(charge.getStatusCode() EQ 200, "Status code should be 200, was: #charge.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_refund_to_account_pulling_back_funds_from_connected_account_ok", "doHttpCall") />
		<cfset refundAmount = variables.svc.createMoney(300, gw.currency)>
		<cfset response = gw.marketplaceRefundToAccountPullingBackFundsFromConnectedAccount(charge.getParsedResult().transfer, refundAmount, connectedAccount.getParsedResult().id) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "refund"), "Refund Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
  
		<!--- Test Bank Transfers --->
	<cffunction name="testTransferFromPlatformStripeAccountToConnectedStripeAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>

		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset response = gw.charge(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "charge", "Charge Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "transfer", "Transfer Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
  
	<cffunction name="testAssociateTransferWithCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

			<!--- charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = createCard()>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset assertTrue(charge.getSuccess() AND structKeyExists(charge.getParsedResult(), "charge"), "Charge Failed") />
		<cfset assertTrue(charge.getStatusCode() EQ 200, "Status code should be 200, was: #charge.getStatusCode()#") />

			<!--- associate transfer with charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.sourceTransaction = charge.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(1000, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset response = gw.marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "transfer"), "Transfer Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
  
	<cffunction name="testTransferWithApplicationFee" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>

		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset response = gw.charge(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "charge", "Charge Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>
		<cfset argumentCollection.applicationFee = variables.svc.createMoney(200, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_transfer_with_application_fee_ok", "doHttpCall") />
		<cfset response = gw.marketplaceTransferWithApplicationFee(argumentCollection = argumentCollection) />
		<cfset assertTrue(response.getSuccess() AND structKeyExists(response.getParsedResult(), "object") AND response.getParsedResult().object eq "transfer", "Transfer Failed") />
		<cfset assertTrue(response.getStatusCode() EQ 200, "Status code should be 200, was: #response.getStatusCode()#") />
	</cffunction>
  
	<cffunction name="testReversingTransfer" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var response = "" />

		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset assertTrue(connectedAccount.getSuccess() AND structKeyExists(connectedAccount.getParsedResult(), "object") AND connectedAccount.getParsedResult().object eq "account", "Failed to create connected account") />
		<cfset assertTrue(connectedAccount.getStatusCode() EQ 200, "Status code while creating connected account should be 200, was: #connectedAccount.getStatusCode()#") />

		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset assertTrue(token.getSuccess() AND structKeyExists(token.getParsedResult(), "object") AND token.getParsedResult().object eq "token", "Failed to create card token") />
		<cfset assertTrue(token.getStatusCode() EQ 200, "Status code while creating card token should be 200, was: #token.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>

		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset assertTrue(charge.getSuccess() AND structKeyExists(charge.getParsedResult(), "object") AND charge.getParsedResult().object eq "charge", "Charge Failed") />
		<cfset assertTrue(charge.getStatusCode() EQ 200, "Status code should be 200, was: #charge.getStatusCode()#") />

		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset transfer = gw.marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount(argumentCollection = argumentCollection) />
		<cfset assertTrue(transfer.getSuccess() AND structKeyExists(transfer.getParsedResult(), "object") AND transfer.getParsedResult().object eq "transfer", "Transfer Failed") />
		<cfset assertTrue(transfer.getStatusCode() EQ 200, "Status code should be 200, was: #transfer.getStatusCode()#") />

			<!--- reverse the transfer --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.paymentId = transfer.getParsedResult().destination_payment>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(400, gw.currency)>

		<cfset offlineInjector(gw, this, "mock_reversing_transfer_ok", "doHttpCall") />
		<cfset refund = gw.marketplaceReversingTransfer(argumentCollection = argumentCollection) />
		<cfset assertTrue(refund.getSuccess() AND structKeyExists(refund.getParsedResult(), "object") AND refund.getParsedResult().object eq "refund", "Transfer Refund Failed") />
		<cfset assertTrue(refund.getStatusCode() EQ 200, "Status code should be 200, was: #refund.getStatusCode()#") />
	</cffunction>

	<!--- Helpers --->
	<cffunction name="createAccount" access="private" returntype="any" output="false">
		<cfset var account = variables.svc.createEFT() />

		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("123 Comox Street") />
		<cfset account.setAddress2("West End") />
		<cfset account.setCity("Vancouver") />
		<cfset account.setRegion("BC") />
		<cfset account.setPostalCode("V6G1S2") />
		<cfset account.setCountry("Canada") />
		<cfset account.setPhoneNumber("0123456789") />
		<cfset account.setAccount(000123456789) />
		<cfset account.setRoutingNumber(110000000) />
		<cfset account.setCheckNumber() />
		<cfset account.setAccountType() />
		<cfset account.setSEC() />

		<cfreturn account />	
	</cffunction>

	<cffunction name="createCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4000000000000077) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(999) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>
	<!--- Mocks --->
	<cffunction name="mock_create_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15c2AnD8ot0g87U6", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c2AnD8ot0g87U6/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false }, "keys": { "secret": "sk_test_XKbx1Hen8Jjq10228rZzWAhq", "publishable": "pk_test_LlsNZLlVL8mULhbnBO8Y9wXp" } }' } />
	</cffunction>

	<cffunction name="mock_update_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15cJ4VK0jmJaz75d", "email": "test1234@testing123.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": false, "keys": { "secret": "sk_test_z6VCZ5FR280ARLWeu9CTOhOn", "publishable": "pk_test_n7FdGGD8Umlcui6TAOOVQaUg" } }' } />
	</cffunction>

	<cffunction name="mock_account_list_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "list", "has_more": false, "url": "/v1/accounts", "data": [ { "id": "acct_15c27zIZh3r4vhIW", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c27zIZh3r4vhIW/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }, { "id": "acct_15c25oAiIdhH6A9Z", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c25oAiIdhH6A9Z/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }, { "id": "acct_15c1qTLoeW7UuY75", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c1qTLoeW7UuY75/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } } ] }' } />
	</cffunction>

	<cffunction name="mock_update_account_failed" access="private">
		<cfreturn { StatusCode = '400', FileContent = '{ "error": { "type": "invalid_request_error", "message": "Received unknown parameter: invalid_field", "param": "legal_entity[invalid_field]" } }' } />
	</cffunction>

	<cffunction name="mock_fetch_bank_accounts_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "list", "has_more": false, "url": "/v1/accounts/acct_15evLLHaSSWBs4PJ/bank_accounts", "data": [] }' } />
	</cffunction>

	<cffunction name="mock_create_bank_accounts_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "bank_account", "id": "ba_15evN2HEZw7xP8G6coTn3y2U", "last4": "6789", "country": "CA", "currency": "cad", "status": "new", "fingerprint": "e98PVX2dQLLJ1Bw9", "routing_number": "11000-000", "bank_name": null, "default_for_currency": true }' } />
	</cffunction>

	<cffunction name="mock_update_bank_account_default_for_currency_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "bank_account", "id": "ba_15evOMFGW0X7HhxV2gbtrn5V", "last4": "6789", "country": "CA", "currency": "cad", "status": "new", "fingerprint": "EUxpUGhRCfb41TLf", "routing_number": "11000-000", "bank_name": null, "default_for_currency": true }' } />
	</cffunction>

	<cffunction name="mock_delete_bank_accounts_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "deleted": true, "id": "ba_15evOqJNkvLfahU0w4cHM6jU", "currency": "cad" }' } />
	</cffunction>

	<cffunction name="mock_upload_identity_file_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "file_5qcgorzwjf7RgR", "created": 1426024967, "size": 65264, "purpose": "identity_document", "object": "file_upload", "url": null, "type": "jpg" }' } />
	</cffunction>

	<cffunction name="mock_create_card_token_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_5qdFdkEadGlyLE", "livemode": false, "created": 1426027056, "used": false, "object": "token", "type": "card", "card": { "id": "card_5qdFxMBYbFKN4K", "object": "card", "last4": "0077", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "NZ56hJ5g3nSG1X1f", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "unchecked", "address_line1_check": "unchecked", "address_zip_check": "unchecked", "dynamic_last4": null }, "client_ip": "184.66.107.116" }' } />
	</cffunction>

	<cffunction name="mock_attach_file_to_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '' } />
	</cffunction>
	
	<cffunction name="mock_charge_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_5qdkfZcTB6Z29E", "object": "charge", "created": 1426028918, "livemode": false, "paid": true, "status": "succeeded", "amount": 1000, "currency": "cad", "refunded": false, "source": { "id": "card_5qdkgctPOLlZi3", "object": "card", "last4": "0077", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "NZ56hJ5g3nSG1X1f", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": {}, "customer": null }, "captured": true, "balance_transaction": "txn_5qdkXWc0zYCeP9", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": "unit-test charge", "dispute": null, "metadata": {}, "statement_descriptor": null, "fraud_details": {}, "receipt_email": null, "receipt_number": null, "shipping": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_5qdkfZcTB6Z29E/refunds", "data": [] } }' } />
	</cffunction>
	
	<cffunction name="mock_direct_charge_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_5m7WiasFMFf5A5", "object": "charge", "created": 1424986511, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_5m7WAou95fVC5b", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": { }, "customer": null }, "captured": true, "balance_transaction": "txn_1IeEOass2YWqgM", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "metadata": { }, "statement_descriptor": null, "fraud_details": { }, "receipt_email": null, "receipt_number": null, "shipping": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_5m7WiasFMFf5A5/refunds", "data": [  ] } }' } />
	</cffunction>
	
	<cffunction name="mock_destination_charge_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_5m7WiasFMFf5A5", "object": "charge", "created": 1424986511, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_5m7WAou95fVC5b", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": { }, "customer": null }, "captured": true, "balance_transaction": "txn_1IeEOass2YWqgM", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "metadata": { }, "statement_descriptor": null, "fraud_details": { }, "receipt_email": null, "receipt_number": null, "shipping": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_5m7WiasFMFf5A5/refunds", "data": [  ] } }' } />
	</cffunction>
	
	<cffunction name="mock_refund_charge_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_1hd2eEhc0a2gF2", "amount": 46000, "currency": "cad", "created": 1366751825, "object": "refund", "balance_transaction": "txn_1hd2bCSoaEP0e5", "metadata": { }, "charge": "ch_1hCcxjT1gTWGWz", "receipt_number": null, "reason": null }' } />
	</cffunction>
	
	<cffunction name="mock_refund_charge_to_connected_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_1hd2eEhc0a2gF2", "amount": 46000, "currency": "cad", "created": 1366751825, "object": "refund", "balance_transaction": "txn_1hd2bCSoaEP0e5", "metadata": { }, "charge": "ch_1hCcxjT1gTWGWz", "receipt_number": null, "reason": null }' } />
	</cffunction>
	
	<cffunction name="mock_refund_to_account_pulling_back_funds_from_connected_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_1hd2eEhc0a2gF2", "amount": 46000, "currency": "cad", "created": 1366751825, "object": "refund", "balance_transaction": "txn_1hd2bCSoaEP0e5", "metadata": { }, "charge": "ch_1hCcxjT1gTWGWz", "receipt_number": null, "reason": null }' } />
	</cffunction>
	
	<cffunction name="mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tr_5mD4P4n9gxR2vq", "object": "transfer", "created": 1425007150, "date": 1425081600, "livemode": false, "amount": 9730, "currency": "cad", "reversed": false, "status": "paid", "type": "bank_account", "reversals": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/transfers/tr_5mD4P4n9gxR2vq/reversals", "data": [ ] }, "balance_transaction": "txn_1IeEOass2YWqgM", "bank_account": { "object": "bank_account", "id": "ba_3gRSQF1Zd1Mleb", "last4": "1510", "country": "CA", "currency": "cad", "status": "new", "fingerprint": null, "routing_number": "01043-003", "bank_name": "ROYAL BANK OF CANADA", "default_for_currency": true }, "destination": "ba_3gRSQF1Zd1Mleb", "description": "STRIPE TRANSFER", "failure_message": null, "failure_code": null, "amount_reversed": 0, "metadata": { }, "statement_descriptor": null, "recipient": null, "source_transaction": null, "application_fee": null }' } />
	</cffunction>
	
	<cffunction name="mock_transfer_with_application_fee_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tr_5mD4P4n9gxR2vq", "object": "transfer", "created": 1425007150, "date": 1425081600, "livemode": false, "amount": 9730, "currency": "cad", "reversed": false, "status": "paid", "type": "bank_account", "reversals": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/transfers/tr_5mD4P4n9gxR2vq/reversals", "data": [ ] }, "balance_transaction": "txn_1IeEOass2YWqgM", "bank_account": { "object": "bank_account", "id": "ba_3gRSQF1Zd1Mleb", "last4": "1510", "country": "CA", "currency": "cad", "status": "new", "fingerprint": null, "routing_number": "01043-003", "bank_name": "ROYAL BANK OF CANADA", "default_for_currency": true }, "destination": "ba_3gRSQF1Zd1Mleb", "description": "STRIPE TRANSFER", "failure_message": null, "failure_code": null, "amount_reversed": 0, "metadata": { }, "statement_descriptor": null, "recipient": null, "source_transaction": null, "application_fee": null }' } />
	</cffunction>
	
	<cffunction name="mock_reversing_transfer_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tr_5mD4P4n9gxR2vq", "object": "transfer", "created": 1425007150, "date": 1425081600, "livemode": false, "amount": 9730, "currency": "cad", "reversed": false, "status": "paid", "type": "bank_account", "reversals": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/transfers/tr_5mD4P4n9gxR2vq/reversals", "data": [ ] }, "balance_transaction": "txn_1IeEOass2YWqgM", "bank_account": { "object": "bank_account", "id": "ba_3gRSQF1Zd1Mleb", "last4": "1510", "country": "CA", "currency": "cad", "status": "new", "fingerprint": null, "routing_number": "01043-003", "bank_name": "ROYAL BANK OF CANADA", "default_for_currency": true }, "destination": "ba_3gRSQF1Zd1Mleb", "description": "STRIPE TRANSFER", "failure_message": null, "failure_code": null, "amount_reversed": 0, "metadata": { }, "statement_descriptor": null, "recipient": null, "source_transaction": null, "application_fee": null }' } />
	</cffunction>
</cfcomponent>
