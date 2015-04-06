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
			variables.gw = variables.cad;
			
			// for dataprovider testing
			variables.gateways = [cad];

			// local resources
			variables.filePathToSampleLicence = getDirectoryFromPath(getCurrentTemplatePath()) & 'sample_driving_license_usa.jpg';
		</cfscript>

		<!--- if set to false, will try to connect to remote service to check these all out --->
		<cfset localMode = true />
		<cfset debugMode = false />
	</cffunction>


	<cffunction name="offlineInjector" access="private">
		<cfif localMode>
			<cfset injectMethod(argumentCollection = arguments) />
		</cfif>
		<!--- if not local mode, don't do any mock substitution so the service connects to the remote service! --->
	</cffunction>

	<cffunction name="standardResponseTests" access="private">
		<cfargument name="response" type="any" required="true" />
		<cfargument name="expectedObjectName" type="any" required="true" />
		<cfargument name="expectedIdPrefix" type="any" required="true" />

		<cfif debugMode>
			<cfset debug(arguments.expectedObjectName)>
			<cfset debug(arguments.response.getParsedResult())>
			<cfset debug(arguments.response.getResult())>
		</cfif>

		<cfif isSimpleValue(arguments.response)>
			<cfset assertTrue(false, "Response returned a simple value: '#arguments.response#'") />
		</cfif>
		<cfif NOT isObject(arguments.response)>
			<cfset assertTrue(false, "Invalid: response is not an object") />
		<cfelseif isStruct(arguments.response.getParsedResult()) AND structIsEmpty(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response structure returned is empty") />
		<cfelseif isSimpleValue(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response is a string, expected a structure. Returned string = '#arguments.response.getParsedResult()#'") />
		<cfelseif arguments.response.getStatusCode() neq 200>
			<!--- Test status code and remote error messages --->
			<cfif structKeyExists(arguments.response.getParsedResult(), "error")>
				<cfset assertTrue(false, "Error From Stripe: (Type=#arguments.response.getParsedResult().error.type#) #arguments.response.getParsedResult().error.message#") />
			</cfif>
			<cfset assertTrue(false, "Status code should be 200, was: #arguments.response.getStatusCode()#") />
		<cfelse>
			<!--- Test returned data (for object and valid id) --->
			<cfset assertTrue(arguments.response.getSuccess(), "Response not successful") />
			<cfif arguments.expectedObjectName neq "">
				<cfset assertTrue(structKeyExists(arguments.response.getParsedResult(), "object") AND arguments.response.getParsedResult().object eq arguments.expectedObjectName, "Invalid #expectedObjectName# object returned") />
			</cfif>
			<cfif arguments.expectedIdPrefix neq "">
				<cfset assertTrue(len(arguments.response.getParsedResult().id) gt len(arguments.expectedIdPrefix) AND left(arguments.response.getParsedResult().id, len(arguments.expectedIdPrefix)) eq arguments.expectedIdPrefix, "Invalid account ID prefix returned, expected: '#arguments.expectedIdPrefix#...', received: '#response.getParsedResult().id#'") />
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="standardErrorResponseTests" access="private">
		<cfargument name="response" type="any" required="true" />
		<cfargument name="expectedErrorType" type="any" required="true" />
		<cfargument name="expectedStatusCode" type="any" required="true" />

		<cfif debugMode>
			<cfset debug(arguments.expectedErrorType)>
			<cfset debug(arguments.expectedStatusCode)>
			<cfset debug(arguments.response.getParsedResult())>
			<cfset debug(arguments.response.getResult())>
		</cfif>

		<cfif isSimpleValue(arguments.response)>
			<cfset assertTrue(false, "Response returned a simple value: '#arguments.response#'") />
		</cfif>
		<cfif NOT isObject(arguments.response)>
			<cfset assertTrue(false, "Invalid: response is not an object") />
		<cfelseif isStruct(arguments.response.getParsedResult()) AND structIsEmpty(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response structure returned is empty") />
		<cfelseif isSimpleValue(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response is a string, expected a structure. Returned string = '#arguments.response.getParsedResult()#'") />
		<cfelseif arguments.response.getStatusCode() neq arguments.expectedStatusCode>
			<cfset assertTrue(false, "Status code should be #arguments.expectedStatusCode#, was: #arguments.response.getStatusCode()#") />
		<cfelse>
			<cfif structKeyExists(arguments.response.getParsedResult(), "error")>
				<cfif structKeyExists(arguments.response.getParsedResult().error, "message") AND structKeyExists(arguments.response.getParsedResult().error, "type")>
					<cfset assertTrue(arguments.response.getParsedResult().error.type eq arguments.expectedErrorType, "Received error type (#arguments.response.getParsedResult().error.type#), expected error type (#arguments.expectedErrorType#) from API") />
				<cfelse>
					<cfset assertTrue(false, "Error message from API missing details") />
				</cfif>
			<cfelse>
				<cfset assertTrue(false, "Object returned did not have an error") />
			</cfif>
		</cfif>
	</cffunction>

<!--- Tests --->

	<!--- Marketplace Account Tests --->
	<cffunction name="testMarketplaceCreateConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
	</cffunction>

	<cffunction name="testMarketplaceUpdateConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(gw, this, "mock_update_account_ok", "doHttpCall") />
		<cfset update = gw.marketplaceUpdateConnectedAccount(connectedAccount = connectedAccount.getParsedResult().id, updates = ["legal_entity[first_name]=John","legal_entity[last_name]=Smith","email=#newEmail#"]) />
		<cfset standardResponseTests(response = update, expectedObjectName = "account", expectedIdPrefix="acct_") />
	</cffunction>

	<cffunction name="testMarketplaceListConnectedAccounts" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- List Connected Accounts --->
		<cfset offlineInjector(gw, this, "mock_account_list_ok", "doHttpCall") />
		<cfset list = gw.marketplaceListConnectedAccounts() />
		<cfset standardResponseTests(response = list, expectedObjectName = "list", expectedIdPrefix="") />
		<cfset assertTrue(structKeyExists(list.getParsedResult(), "data") AND isArray(list.getParsedResult().data), "Invalid account list") />
	</cffunction>
	
	<cffunction name="testMarketplaceConnectedAccountUserDataPopulation" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(gw, this, "mock_update_account_ok", "doHttpCall") />
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id />
		<cfset argumentCollection.updates = ["legal_entity[first_name]=John","legal_entity[last_name]=Smith","email=#newEmail#"] />
		<cfset update = gw.marketplaceUpdateConnectedAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = update, expectedObjectName = "account", expectedIdPrefix="acct_") />
	</cffunction>

	<cffunction name="testMarketplaceConnectedAccountUserDataPopulationWithInvalidFieldsThrowsError" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(gw, this, "mock_update_account_failed", "doHttpCall") />
		<cfset update = gw.marketplaceUpdateConnectedAccount(connectedAccount = connectedAccount.getParsedResult().id, updates = ["legal_entity[invalid_field]=fail"]) />
		<cfset standardErrorResponseTests(response = update, expectedStatusCode="400", expectedErrorType = "invalid_request_error") />
	</cffunction>

	<cffunction name="testMarketplaceNewlyCreatedConnectedAccountHasCorrectLegalEntityFieldsNeeded" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(structKeyExists(connectedAccount.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(connectedAccount.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(connectedAccount.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(connectedAccount.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(connectedAccount.getParsedResult().verification["fields_needed"]) gt 0, "Fields_Needed array is empty") />
		<cfloop list="legal_entity.first_name,legal_entity.last_name,legal_entity.dob.day,legal_entity.dob.month,legal_entity.dob.year,legal_entity.type,legal_entity.address.line1,legal_entity.address.city,legal_entity.address.state,legal_entity.address.postal_code,bank_account,tos_acceptance.ip,tos_acceptance.date" index="fieldNeeded">
			<cfset assertTrue(listFindNoCase(arrayToList(connectedAccount.getParsedResult().verification["fields_needed"]), fieldNeeded), "Missing Fields_needed value: #fieldNeeded#") />
		</cfloop>
	</cffunction>

	<cffunction name="testMarketplaceNewlyCreatedConnectedAccountCorrectlyPopulatedReturnsNoValidationFieldsNeeded" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />
		<cfset var newEmail = "test#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#@test.test" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Bank Account --->
		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset standardResponseTests(response = bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(gw, this, "mock_update_account_validation_passes_ok", "doHttpCall") />
		<cfset fieldsNeeded = [
			"legal_entity[first_name]=John",
			"legal_entity[last_name]=Smith",
			"legal_entity[dob][day]=20",
			"legal_entity[dob][month]=5",
			"legal_entity[dob][year]=1990",
			"legal_entity[type]=company",
			"legal_entity[address][line1]=123 Another Street",
			"legal_entity[address][city]=Some City",
			"legal_entity[address][state]=A State",
			"legal_entity[address][postal_code]=123ABC",
			"tos_acceptance[date]=1428338336",
			"tos_acceptance[ip]=184.66.107.116"
		] />
		<cfset update = gw.marketplaceUpdateConnectedAccount(connectedAccount = connectedAccount.getParsedResult().id, updates = fieldsNeeded) />
		<cfset standardResponseTests(response = update, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(structKeyExists(update.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(update.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(update.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(update.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(update.getParsedResult().verification["fields_needed"]) eq 0, "Fields_Needed array should be empty") />
	</cffunction>

	<!--- Bank Account Tests --->
	<cffunction name="testFetchBankAccounts" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Fetch Attached Bank Accounts --->
		<cfset offlineInjector(gw, this, "mock_fetch_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccounts = gw.marketplaceFetchBankAccounts(connectedAccount = connectedAccount.getParsedResult().id) />
		<cfset standardResponseTests(response = bankAccounts, expectedObjectName = "list", expectedIdPrefix="") />
		<cfset assertTrue(structKeyExists(bankAccounts.getParsedResult(), "data") AND isArray(bankAccounts.getParsedResult().data), "Invalid bank account list") />
	</cffunction>
	
	<cffunction name="testCreateBankAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Bank Account --->
		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset standardResponseTests(response = bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />
	</cffunction>
	
	<cffunction name="testUpdateBankAccountDefaultForCurrency" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Bank Account --->
		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset standardResponseTests(response = bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Make Bank Account Default For Currency --->
		<cfset offlineInjector(gw, this, "mock_update_bank_account_default_for_currency_ok", "doHttpCall") />
		<cfset update = gw.marketplaceUpdateBankAccountDefaultForCurrency(connectedAccount = connectedAccount.getParsedResult().id, bankAccountId = bankAccount.getParsedResult().id) />
		<cfset standardResponseTests(response = update, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />
		<cfset assertTrue(update.getSuccess() AND structKeyExists(update.getParsedResult(), "default_for_currency") AND update.getParsedResult().default_for_currency eq true, "Default for currency not set to true") />
	</cffunction>
	
	<cffunction name="testDeleteBankAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Bank Account --->
		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset standardResponseTests(response = bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Create Another Bank Account; Creating two bank account because you can't delete the account that is 'default for currency' --->
		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset standardResponseTests(response = bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Delete Bank Account --->
		<cfset offlineInjector(gw, this, "mock_delete_bank_accounts_ok", "doHttpCall") />
		<cfset delete = gw.marketplaceDeleteBankAccount(connectedAccount = connectedAccount.getParsedResult().id, bankAccountId = bankAccount.getParsedResult().id) />
		<cfset standardResponseTests(response = delete, expectedObjectName = "", expectedIdPrefix="ba_") />
		<cfset assertTrue(delete.getSuccess() AND structKeyExists(delete.getParsedResult(), "deleted") AND delete.getParsedResult().deleted eq true, "Failed to delete the second (not default for currency) bank account") />
	</cffunction>
	
	<cffunction name="testDeleteDefaultForCurrencyBankAccountFails" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Bank Account --->
		<cfset offlineInjector(gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset bankAccount = gw.marketplaceCreateBankAccount(connectedAccount = connectedAccount.getParsedResult().id, account = createAccount()) />
		<cfset standardResponseTests(response = bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Delete Bank Account --->
		<cfset offlineInjector(gw, this, "mock_delete_bank_accounts_fail", "doHttpCall") />
		<cfset delete = gw.marketplaceDeleteBankAccount(connectedAccount = connectedAccount.getParsedResult().id, bankAccountId = bankAccount.getParsedResult().id) />
		<cfset standardErrorResponseTests(response = delete, expectedStatusCode="400", expectedErrorType = "invalid_request_error") />
	</cffunction>

	<!--- Identity Verification Tests --->
	<cffunction name="testUploadIdentityFile" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset uploadFile = gw.marketplaceUploadIdentityFile(file = variables.filePathToSampleLicence) />
		<cfset standardResponseTests(response = uploadFile, expectedObjectName = "file_upload", expectedIdPrefix="file_") />
	</cffunction>

	<cffunction name="testAttachFileToAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Upload Identity File --->
		<cfset offlineInjector(gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.file = variables.filePathToSampleLicence />
		<cfset argumentCollection.accountSecret = connectedAccount.getParsedResult().keys.secret />
		<cfset uploadFile = gw.marketplaceUploadIdentityFile(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = uploadFile, expectedObjectName = "file_upload", expectedIdPrefix="file_") />

		<!--- Attach Identity File to Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id />
		<cfset argumentCollection.accountSecret = connectedAccount.getParsedResult().keys.secret />
		<cfset argumentCollection.fileId = uploadFile.getParsedResult().id />
		<cfset offlineInjector(gw, this, "mock_attach_file_to_account_ok", "doHttpCall") />
		<cfset attachFile = gw.marketplaceAttachFileToAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = attachFile, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(uploadFile.getParsedResult().id eq attachFile.getParsedResult()["legal_entity"]["verification"]["document"], "Identity file not attached to account") />
	</cffunction>

	<!--- Test Bank Charges --->
	<cffunction name="testCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create CC Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>
		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
	</cffunction>

	<cffunction name="testDirectCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!---Create a customer--->
		<cfset offlineInjector(gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset customer = gw.store(createCard()) />
		<cfset standardResponseTests(response = customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!---Create a token for the customer with the connected account--->
		<cfset offlineInjector(gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset customerToken = gw.getCustomerTokenForSpecificAccount(customer = customer.getParsedResult().id, connectedAccount = connectedAccount.getParsedResult().keys.secret) />
		<cfset standardResponseTests(response = customerToken, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Direct Charge To Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().keys.secret />
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency) />
		<cfset argumentCollection.token = customerToken.getParsedResult().id />
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency) />
		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
	</cffunction>

	<cffunction name="testDestinationCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Destination Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_destination_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDestinationCharge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
	</cffunction>

	<cffunction name="testRefundCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create CC Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>
		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Refund Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.paymentId = charge.getParsedResult().id />
		<cfset argumentCollection.refundAmount = variables.svc.createMoney(300, gw.currency) />
		<cfset offlineInjector(gw, this, "mock_refund_charge_ok", "doHttpCall") />
		<cfset refund = gw.marketplaceRefundCharge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
	</cffunction>

	<cffunction name="testRefundChargeToConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!---Create a customer--->
		<cfset offlineInjector(gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset customer = gw.store(createCard()) />
		<cfset standardResponseTests(response = customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!---Create a token for the customer with the connected account--->
		<cfset offlineInjector(gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset customerToken = gw.getCustomerTokenForSpecificAccount(customer = customer.getParsedResult().id, connectedAccount = connectedAccount.getParsedResult().keys.secret) />
		<cfset standardResponseTests(response = customerToken, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Direct Charge To Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().keys.secret />
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency) />
		<cfset argumentCollection.token = customerToken.getParsedResult().id />
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency) />
		<cfset offlineInjector(gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDirectCharge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Refund Charge To Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.paymentId = charge.getParsedResult().id />
		<cfset argumentCollection.refundAmount = variables.svc.createMoney(250, gw.currency) />
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id />
		<cfset offlineInjector(gw, this, "mock_refund_charge_to_connected_account_ok", "doHttpCall") />
		<cfset refund = gw.marketplaceRefundChargeToConnectedAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
	</cffunction>

	<cffunction name="testRefundToAccountPullingBackFundsFromConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Destination Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.cardToken = token.getParsedResult().id>
		<cfset argumentCollection.application_fee = variables.svc.createMoney(200, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_destination_charge_ok", "doHttpCall") />
		<cfset charge = gw.marketplaceDestinationCharge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Refund Charge By Pulling Back Required Funds From Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.paymentId = charge.getParsedResult().id />
		<cfset argumentCollection.refundAmount = variables.svc.createMoney(400, gw.currency) />
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id />
		<cfset offlineInjector(gw, this, "mock_refund_to_account_pulling_back_funds_from_connected_account_ok", "doHttpCall") />
		<cfset refund = gw.marketplaceRefundToAccountPullingBackFundsFromConnectedAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
	</cffunction>

	<!--- Test Bank Transfers --->
	<cffunction name="testTransferFromPlatformStripeAccountToConnectedStripeAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>
		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer To Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset transfer = gw.marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />
	</cffunction>
  
	<cffunction name="testAssociateTransferWithCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>
		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer To Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.sourceTransaction = charge.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset transfer = gw.marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />
	</cffunction>
  
	<cffunction name="testTransferWithApplicationFee" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>
		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer With Application Fee --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>
		<cfset argumentCollection.applicationFee = variables.svc.createMoney(200, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_transfer_with_application_fee_ok", "doHttpCall") />
		<cfset transfer = gw.marketplaceTransferWithApplicationFee(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />
	</cffunction>
  
	<cffunction name="testReversingTransfer" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset connectedAccount = gw.marketplaceCreateConnectedAccount() />
		<cfset standardResponseTests(response = connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />

		<!--- Create Token --->
		<cfset offlineInjector(gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset token = gw.createToken(createCard()) />
		<cfset standardResponseTests(response = token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.amount = variables.svc.createMoney(1000, gw.currency)>
		<cfset argumentCollection.source = token.getParsedResult().id>
		<cfset argumentCollection.description = 'unit-test charge'>
		<cfset offlineInjector(gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset charge = gw.charge(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer From Platform To Connected Account --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.destination = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.transferAmount = variables.svc.createMoney(500, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset transfer = gw.marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />

		<!--- Reverse The Transfer --->
		<cfset argumentCollection = structNew()>
		<cfset argumentCollection.paymentId = transfer.getParsedResult().destination_payment>
		<cfset argumentCollection.connectedAccount = connectedAccount.getParsedResult().id>
		<cfset argumentCollection.amount = variables.svc.createMoney(400, gw.currency)>
		<cfset offlineInjector(gw, this, "mock_reversing_transfer_ok", "doHttpCall") />
		<cfset refund = gw.marketplaceReversingTransfer(argumentCollection = argumentCollection) />
		<cfset standardResponseTests(response = refund, expectedObjectName = "refund", expectedIdPrefix="pyr_") />
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
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15oe3nHQ9U3jyomi", "email": "test20150406173055@test.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "business_url": null, "support_phone": null, "metadata": {}, "managed": true, "product_description": null, "debit_negative_balances": false, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15oe3nHQ9U3jyomi/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.first_name", "legal_entity.last_name", "legal_entity.dob.day", "legal_entity.dob.month", "legal_entity.dob.year", "legal_entity.type", "legal_entity.address.line1", "legal_entity.address.city", "legal_entity.address.state", "legal_entity.address.postal_code", "bank_account", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "ip": null, "date": null, "user_agent": null }, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false }, "keys": { "secret": "sk_test_kSx0VSZW6TvnoHCfBoVMFXpq", "publishable": "pk_test_MjuNj3ynAShrhv2OgvHoi46X" } }' } />
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

	<cffunction name="mock_delete_bank_accounts_fail" access="private">
		<cfreturn { StatusCode = '400 OK', FileContent = '{ "error": { "type": "invalid_request_error", "message": "You cannot delete the default bank account for your default currency. Please make another bank account the default using the `default_for_currency` param, and then delete this one." } }' } />
	</cffunction>
	
	<cffunction name="mock_upload_identity_file_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "file_15iCG7D8ot0g87U6Wxb15c1r", "created": 1426024967, "size": 65264, "purpose": "identity_document", "object": "file_upload", "url": null, "type": "jpg" }' } />
	</cffunction>

	<cffunction name="mock_attach_file_to_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15i6p8KgBEwCAJe8", "email": "test20150319094848@test.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "business_url": null, "support_phone": null, "managed": true, "product_description": null, "debit_negative_balances": false, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15i6p8KgBEwCAJe8/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.first_name", "legal_entity.last_name", "legal_entity.dob.day", "legal_entity.dob.month", "legal_entity.dob.year", "legal_entity.type", "legal_entity.address.line1", "legal_entity.address.city", "legal_entity.address.state", "legal_entity.address.postal_code", "bank_account", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "ip": null, "date": null, "user_agent": null }, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": "file_15iCG7D8ot0g87U6Wxb15c1r", "details": null } }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }' } />
	</cffunction>

	<cffunction name="mock_create_card_token_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_5qdFdkEadGlyLE", "livemode": false, "created": 1426027056, "used": false, "object": "token", "type": "card", "card": { "id": "card_5qdFxMBYbFKN4K", "object": "card", "last4": "0077", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "NZ56hJ5g3nSG1X1f", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "unchecked", "address_line1_check": "unchecked", "address_zip_check": "unchecked", "dynamic_last4": null }, "client_ip": "184.66.107.116" }' } />
	</cffunction>

	<cffunction name="mock_create_customer_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "customer", "created": 1426783987, "id": "cus_5tui4CxfSIMCPh", "livemode": false, "description": null, "email": null, "delinquent": false, "metadata": {}, "subscriptions": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/customers/cus_5tui4CxfSIMCPh/subscriptions", "data": [] }, "discount": null, "account_balance": 0, "currency": null, "sources": { "object": "list", "total_count": 1, "has_more": false, "url": "/v1/customers/cus_5tui4CxfSIMCPh/sources", "data": [ { "id": "card_5tuiNbFo56IX17", "object": "card", "last4": "0077", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "NZ56hJ5g3nSG1X1f", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": {}, "customer": "cus_5tui4CxfSIMCPh" } ] }, "default_source": "card_5tuiNbFo56IX17" }' } />
	</cffunction>
	
	<cffunction name="mock_get_token_for_customer_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_15i6vOBzXo04pSHuixVMHcTl", "livemode": false, "created": 1426784114, "used": false, "object": "token", "type": "card", "card": { "id": "card_15i6vOBzXo04pSHuW1cb74Cy", "object": "card", "last4": "0077", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "l8rbA7VqfygKBhfJ", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "unchecked", "address_line1_check": "unchecked", "address_zip_check": "unchecked", "dynamic_last4": null }, "client_ip": "184.66.107.116" }' } />
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
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tr_5tush9wjXsddbe", "object": "transfer", "created": 1426784550, "date": 1426784550, "livemode": false, "amount": 500, "currency": "cad", "reversed": false, "status": "pending", "type": "stripe_account", "reversals": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/transfers/tr_5tush9wjXsddbe/reversals", "data": [] }, "balance_transaction": "txn_5tusPLMfovpTbD", "destination": "acct_15i72LBYaeaZycDD", "destination_payment": "py_15i72QBYaeaZycDDmMwTmIJB", "description": null, "failure_message": null, "failure_code": null, "amount_reversed": 0, "metadata": {}, "statement_descriptor": null, "recipient": null, "source_transaction": null, "application_fee": null }' } />
	</cffunction>
	
	<cffunction name="mock_transfer_with_application_fee_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tr_5tv0QCDmEcYE7R", "object": "transfer", "created": 1426785025, "date": 1426785025, "livemode": false, "amount": 500, "currency": "cad", "reversed": false, "status": "pending", "type": "stripe_account", "reversals": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/transfers/tr_5tv0QCDmEcYE7R/reversals", "data": [] }, "balance_transaction": "txn_5tv0uxCGuEPTa6", "destination": "acct_15i7A0GTR51tuS9z", "destination_payment": "py_15i7A5GTR51tuS9z12wPQbnF", "description": null, "failure_message": null, "failure_code": null, "amount_reversed": 0, "metadata": {}, "statement_descriptor": null, "recipient": null, "source_transaction": null, "application_fee": "fee_5tv0IlPjoHmF8M" }' } />
	</cffunction>
	
	<cffunction name="mock_reversing_transfer_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "pyr_15i77sFzV7U7txffAAvDxyqa", "amount": 400, "currency": "cad", "created": 1426784888, "object": "refund", "balance_transaction": "txn_15i77sFzV7U7txffQ6nxf0Hp", "metadata": {}, "charge": "py_15i77rFzV7U7txffRp9gEQaF", "receipt_number": null, "reason": null }' } />
	</cffunction>
	
	<cffunction name="mock_update_account_validation_passes_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15odyvFUmKIEYcf3", "email": "test20150406172553@test.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": true, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "business_url": null, "support_phone": null, "metadata": {}, "managed": true, "product_description": null, "debit_negative_balances": false, "bank_accounts": { "object": "list", "total_count": 1, "has_more": false, "url": "/v1/accounts/acct_15odyvFUmKIEYcf3/bank_accounts", "data": [ { "object": "bank_account", "id": "ba_15odywFUmKIEYcf3q2ZDAw0L", "last4": "6789", "country": "CA", "currency": "cad", "status": "new", "fingerprint": "Z3T7RQTuRWxBOKav", "routing_number": "11000-000", "bank_name": null, "default_for_currency": true } ] }, "verification": { "fields_needed": [], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "ip": "184.66.107.116", "date": 1428338336, "user_agent": null }, "legal_entity": { "type": "company", "business_name": null, "address": { "line1": "123 Another Street", "line2": null, "city": "Some City", "state": "A State", "postal_code": "123ABC", "country": "CA" }, "first_name": "John", "last_name": "Smith", "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": 20, "month": 5, "year": 1990 }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }' } />
	</cffunction>
</cfcomponent>
