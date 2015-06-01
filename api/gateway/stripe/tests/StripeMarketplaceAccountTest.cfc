<cfcomponent name="StripeMarketplaceAccountTest" extends="BaseStripeTest" output="false">

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

		<cfset super.setup() />

		<cfscript>
			// local resources
			variables.filePathToSampleLicence = getDirectoryFromPath(getCurrentTemplatePath()) & 'sample_driving_license_usa.jpg';
		</cfscript>

	</cffunction>


	<cffunction name="testCreateAndUpdateConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset local.origEmail = "test20150406173055@test.tst" />
		<cfset local.newEmail = "test1234@testing123.tst" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country, email = local.origEmail) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />
		<cfset assertTrue(local.connectedAccount.getParsedResult().managed, "Account is not managed") />
		<cfset assertTrue(local.connectedAccount.getParsedResult().email EQ "test20150406173055@test.tst", "Email did not match") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_account_ok", "doHttpCall") />
		<cfset local.options = {"legal_entity[first_name]": "John", "legal_entity[last_name]": "Smith", "email": local.newEmail, "decline_charge_on[cvc_failure]": true} />
		<cfset local.update = arguments.gw.updateConnectedAccount(connectedAccount = connectedAccountToken, options = options) />
		<cfset standardResponseTests(response = local.update, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(local.update.getParsedResult().legal_entity.first_name EQ "John", "Legal entity update did not take, first name was not John") />
		<cfset assertTrue(local.update.getParsedResult().decline_charge_on.cvc_failure, "Decline on cvc failure should be on after update") />
		<cfset assertTrue(local.update.getParsedResult().email EQ local.newEmail, "Email did not match") />
	</cffunction>


	<cffunction name="testListConnectedAccounts" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- List Connected Accounts --->
		<cfset offlineInjector(arguments.gw, this, "mock_account_list_ok", "doHttpCall") />
		<cfset local.list = arguments.gw.listConnectedAccounts() />
		<cfset standardResponseTests(response = local.list, expectedObjectName = "list", expectedIdPrefix="") />
		<cfset assertTrue(structKeyExists(local.list.getParsedResult(), "data") AND isArray(local.list.getParsedResult().data), "Invalid account list") />
	</cffunction>
	

	<cffunction name="testUpdatingConnectedAccountWithInvalidFieldsThrowsError" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Update Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_account_failed", "doHttpCall") />
		<cfset local.update = arguments.gw.updateConnectedAccount(connectedAccount = local.connectedAccountToken, options = {"legal_entity[invalid_field]": "fail"}) />
		<cfset standardErrorResponseTests(response = local.update, expectedStatusCode = "400", expectedErrorType = "invalid_request_error") />
	</cffunction>


	<cffunction name="testCanadaIndividualConnectedAccountLegalEntityFields" access="public" returntype="void" output="false">
		<cfargument name="gw" type="any" required="false" default="#variables.cad#" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = "CA", options = {"legal_entity[type]": "individual"}) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.connectedAccount.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.connectedAccount.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.connectedAccount.getParsedResult().verification["fields_needed"]) GT 0, "Fields_Needed array is empty") />
		<cfloop list="legal_entity.first_name,legal_entity.last_name,legal_entity.dob.day,legal_entity.dob.month,legal_entity.dob.year,legal_entity.address.line1,legal_entity.address.city,legal_entity.address.state,legal_entity.address.postal_code,bank_account,tos_acceptance.ip,tos_acceptance.date" index="local.fieldNeeded">
			<cfset assertTrue(listFindNoCase(arrayToList(local.connectedAccount.getParsedResult().verification["fields_needed"]), local.fieldNeeded), "Missing Fields_needed value: #local.fieldNeeded#") />
		</cfloop>
		
		
		<!--- now update the account and check it no longer requests anything --->

		<!--- Create Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = createBankAccountHelper(arguments.gw.country), currency = "cad") />
		<cfset standardResponseTests(response = local.bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_account_validation_passes_ok", "doHttpCall") />
		<cfset local.fieldsNeeded = {
			"legal_entity[first_name]": "John",
			"legal_entity[last_name]": "Smith",
			"legal_entity[dob][day]": "20",
			"legal_entity[dob][month]": "5",
			"legal_entity[dob][year]": "1990",
			"legal_entity[type]": "company",
			"legal_entity[address][line1]": "123 Another Street",
			"legal_entity[address][city]": "Some City",
			"legal_entity[address][state]": "A State",
			"legal_entity[address][postal_code]": "123ABC",
			"tos_acceptance[date]": "1428338336",
			"tos_acceptance[ip]": "127.0.0.1"
		} />
		<cfset local.update = arguments.gw.updateConnectedAccount(connectedAccount = local.connectedAccountToken, options = local.fieldsNeeded) />
		<cfset standardResponseTests(response = local.update, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.update.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.update.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.update.getParsedResult().verification["fields_needed"]) EQ 0, "Fields_Needed array should be empty") />		
	</cffunction>


	<cffunction name="testCanadaCompanyConnectedAccountLegalEntityFields" access="public" returntype="void" output="false">
		<cfargument name="gw" type="any" required="false" default="#variables.cad#" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = "CA", options = {"legal_entity[type]": "company", "business_name": "ACME, Inc."}) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.connectedAccount.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.connectedAccount.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.connectedAccount.getParsedResult().verification["fields_needed"]) GT 0, "Fields_Needed array is empty") />
		<cfloop list="legal_entity.first_name,legal_entity.last_name,legal_entity.dob.day,legal_entity.dob.month,legal_entity.dob.year,legal_entity.address.line1,legal_entity.address.city,legal_entity.address.state,legal_entity.address.postal_code,bank_account,tos_acceptance.ip,tos_acceptance.date" index="local.fieldNeeded">
			<cfset assertTrue(listFindNoCase(arrayToList(local.connectedAccount.getParsedResult().verification["fields_needed"]), local.fieldNeeded), "Missing Fields_needed value: #local.fieldNeeded#") />
		</cfloop>
		
		
		<!--- now update the account and check it no longer requests anything --->

		<!--- Create Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = createBankAccountHelper(arguments.gw.country), currency = "cad") />
		<cfset standardResponseTests(response = local.bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_account_validation_passes_ok", "doHttpCall") />
		<cfset local.fieldsNeeded = {
			"legal_entity[first_name]": "John",
			"legal_entity[last_name]": "Smith",
			"legal_entity[dob][day]": "20",
			"legal_entity[dob][month]": "5",
			"legal_entity[dob][year]": "1990",
			"legal_entity[type]": "company",
			"legal_entity[address][line1]": "123 Another Street",
			"legal_entity[address][city]": "Some City",
			"legal_entity[address][state]": "A State",
			"legal_entity[address][postal_code]": "123ABC",
			"tos_acceptance[date]": "1428338336",
			"tos_acceptance[ip]": "127.0.0.1"
		} />
		<cfset local.update = arguments.gw.updateConnectedAccount(connectedAccount = local.connectedAccountToken, options = local.fieldsNeeded) />
		<cfset standardResponseTests(response = local.update, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.update.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.update.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.update.getParsedResult().verification["fields_needed"]) EQ 0, "Fields_Needed array should be empty") />		
	</cffunction>


	<cffunction name="testUSIndividualConnectedAccountLegalEntityFields" access="public" returntype="void" output="false">
		<cfargument name="gw" type="any" required="false" default="#variables.usd#" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = "US", options = {"legal_entity[type]": "individual"}) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.connectedAccount.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.connectedAccount.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.connectedAccount.getParsedResult().verification["fields_needed"]) GT 0, "Fields_Needed array is empty") />
		<cfloop list="legal_entity.first_name,legal_entity.last_name,legal_entity.dob.day,legal_entity.dob.month,legal_entity.dob.year,bank_account,tos_acceptance.ip,tos_acceptance.date" index="local.fieldNeeded">
			<cfset assertTrue(listFindNoCase(arrayToList(local.connectedAccount.getParsedResult().verification["fields_needed"]), local.fieldNeeded), "Missing Fields_needed value: #local.fieldNeeded#") />
		</cfloop>
		
		
		<!--- now update the account and check it no longer requests anything --->

		<!--- Create Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = createBankAccountHelper(arguments.gw.country), currency = "usd") />
		<cfset standardResponseTests(response = local.bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_account_validation_passes_ok", "doHttpCall") />
		<cfset local.fieldsNeeded = {
			"legal_entity[first_name]": "John",
			"legal_entity[last_name]": "Smith",
			"legal_entity[dob][day]": "20",
			"legal_entity[dob][month]": "5",
			"legal_entity[dob][year]": "1990",
			"legal_entity[type]": "company",
			"legal_entity[address][line1]": "123 Another Street",
			"legal_entity[address][city]": "Some City",
			"legal_entity[address][state]": "CA",
			"legal_entity[address][postal_code]": "94903",
			"tos_acceptance[date]": "1428338336",
			"tos_acceptance[ip]": "127.0.0.1"
		} />
		<cfset local.update = arguments.gw.updateConnectedAccount(connectedAccount = local.connectedAccountToken, options = local.fieldsNeeded) />
		<cfset standardResponseTests(response = local.update, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.update.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.update.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.update.getParsedResult().verification["fields_needed"]) EQ 0, "Fields_Needed array should be empty") />		
	</cffunction>
	
	
	<cffunction name="testUSCompanyConnectedAccountLegalEntityFields" access="public" returntype="void" output="false">
		<cfargument name="gw" type="any" required="false" default="#variables.usd#" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = "US", options = {"legal_entity[type]": "company", "business_name": "ACME, Inc."}) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.connectedAccount.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.connectedAccount.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.connectedAccount.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.connectedAccount.getParsedResult().verification["fields_needed"]) GT 0, "Fields_Needed array is empty") />
		<cfloop list="legal_entity.first_name,legal_entity.last_name,legal_entity.dob.day,legal_entity.dob.month,legal_entity.dob.year,bank_account,tos_acceptance.ip,tos_acceptance.date" index="local.fieldNeeded">
			<cfset assertTrue(listFindNoCase(arrayToList(local.connectedAccount.getParsedResult().verification["fields_needed"]), local.fieldNeeded), "Missing Fields_needed value: #local.fieldNeeded#") />
		</cfloop>
		
		
		<!--- now update the account and check it no longer requests anything --->

		<!--- Create Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = createBankAccountHelper(arguments.gw.country), currency = "usd") />
		<cfset standardResponseTests(response = local.bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Update Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_account_validation_passes_ok", "doHttpCall") />
		<cfset local.fieldsNeeded = {
			"legal_entity[first_name]": "John",
			"legal_entity[last_name]": "Smith",
			"legal_entity[dob][day]": "20",
			"legal_entity[dob][month]": "5",
			"legal_entity[dob][year]": "1990",
			"legal_entity[type]": "company",
			"legal_entity[address][line1]": "123 Another Street",
			"legal_entity[address][city]": "Some City",
			"legal_entity[address][state]": "CA",
			"legal_entity[address][postal_code]": "94903",
			"tos_acceptance[date]": "1428338336",
			"tos_acceptance[ip]": "127.0.0.1"
		} />
		<cfset local.update = arguments.gw.updateConnectedAccount(connectedAccount = local.connectedAccountToken, options = local.fieldsNeeded) />
		<cfset standardResponseTests(response = local.update, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult(), "verification"), "Verification missing in return data") />
		<cfset assertTrue(isStruct(local.update.getParsedResult().verification), "Verification data is not a struct") />
		<cfset assertTrue(structKeyExists(local.update.getParsedResult().verification, "fields_needed"), "Fields_Needed missing in return data") />
		<cfset assertTrue(isArray(local.update.getParsedResult().verification["fields_needed"]), "Fields_Needed data is not an array") />
		<cfset assertTrue(arrayLen(local.update.getParsedResult().verification["fields_needed"]) EQ 0, "Fields_Needed array should be empty") />		
	</cffunction>	
	

	<!--- Bank Account Tests --->
	<cffunction name="testListBankAccounts" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = "US") />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Fetch Attached Bank Accounts --->
		<cfset offlineInjector(arguments.gw, this, "mock_fetch_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccounts = arguments.gw.listBankAccounts(connectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.bankAccounts, expectedObjectName = "list", expectedIdPrefix="") />
		<cfset assertTrue(structKeyExists(local.bankAccounts.getParsedResult(), "data") AND isArray(local.bankAccounts.getParsedResult().data), "Invalid bank account list") />
	</cffunction>
	

	<cffunction name="testCreateBankAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset local.account = createBankAccountHelper(arguments.gw.country) />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Create Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = account, currency = arguments.gw.currency) />
		<cfset standardResponseTests(response = local.bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />
		
		<cfset assertTrue(bankAccount.getParsedResult().object EQ "bank_account", "Object type wasn't bank_account") />
		<cfset assertTrue(bankAccount.getParsedResult().last4 EQ "6789", "last4 didn't match") />
		<cfset assertTrue(bankAccount.getTransactionId() EQ bankAccount.getTokenID(), "The token ID should be put into the token field when created, was: #bankAccount.getTokenID()#") />
	</cffunction>


	<cffunction name="testUpdateBankAccountDefaultForCurrencyAndDelete" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Create Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = createBankAccountHelper(arguments.gw.country), currency = arguments.gw.currency) />
		<cfset standardResponseTests(response = local.bankAccount, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />

		<!--- Create Another Bank Account; Creating two bank account because you can't delete the account that is 'default for currency' --->
		<cfset local.second = createBankAccountHelper(arguments.gw.country) />
		<cfset second.setFirstName("Jane") />
		<cfset offlineInjector(arguments.gw, this, "mock_create_second_bank_accounts_ok", "doHttpCall") />
		<cfset local.bankAccount2 = arguments.gw.createBankAccount(connectedAccount = local.connectedAccountToken, account = second, currency = arguments.gw.currency) />
		<cfset standardResponseTests(response = local.bankAccount2, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />
		<cfset assertTrue(local.bankAccount2.getTransactionId() NEQ local.bankaccount.getTransactionId(), "Second account wasn't created separately from the first") />

		<!--- try to Delete default Bank Account, should fail --->
		<cfset offlineInjector(arguments.gw, this, "mock_delete_bank_accounts_fail", "doHttpCall") />
		<cfset local.delete = arguments.gw.deleteBankAccount(connectedAccount = local.connectedAccountToken, bankAccountId = local.bankAccount.getTransactionId()) />
		<cfset standardErrorResponseTests(response = local.delete, expectedStatusCode="400", expectedErrorType = "invalid_request_error") />

		<!--- Make second Bank Account Default For Currency --->
		<cfset offlineInjector(arguments.gw, this, "mock_update_bank_account_default_for_currency_ok", "doHttpCall") />
		<cfset local.update = arguments.gw.setDefaultBankAccountForCurrency(connectedAccount = local.connectedAccountToken, bankAccountId = local.bankAccount2.getTransactionId()) />
		<cfset standardResponseTests(response = local.update, expectedObjectName = "bank_account", expectedIdPrefix="ba_") />
		<cfset assertTrue(local.update.getSuccess(), "Request didn't succeed") />
		<cfset assertTrue(local.update.getParsedResult().default_for_currency EQ true, "Default for currency not set to true") />

		<!--- Now Delete Original Bank Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_delete_bank_accounts_ok", "doHttpCall") />
		<cfset local.delete = arguments.gw.deleteBankAccount(connectedAccount = local.connectedAccountToken, bankAccountId = local.bankAccount.getTransactionId()) />
		<cfset standardResponseTests(response = local.delete, expectedObjectName = "", expectedIdPrefix="ba_") />
		<cfset assertTrue(local.delete.getSuccess(), "Delete did not succeed") />
		<cfset assertTrue(local.delete.getParsedResult().deleted EQ true, "Failed to delete the original (not default for currency) bank account") />

	</cffunction>


	<!--- Identity Verification Tests --->
	<cffunction name="testUploadIdentityFile" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset local.uploadFile = arguments.gw.uploadFile(file = variables.filePathToSampleLicence, purpose = "identity_document") />
		<cfset standardResponseTests(response = local.uploadFile, expectedObjectName = "file_upload", expectedIdPrefix="file_") />
	</cffunction>


	<cffunction name="testUploadFileWithoutPurposeThrowsError" access="public" returntype="void" output="false" mxunit:dataprovider="gateways" mxunit:expectedexception="cfpayment.invalidarguments">
		<cfargument name="gw" type="any" required="true" />

		<cfset offlineInjector(arguments.gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset local.uploadFile = arguments.gw.uploadFile(file = variables.filePathToSampleLicence, purpose = "bogus") />
		<cfset assertTrue(false, "Should have thrown an exception") />
	</cffunction>


	<cffunction name="testUploadAndAttachIdentityFileToAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Upload Identity File --->
		<cfset offlineInjector(arguments.gw, this, "mock_upload_identity_file_ok", "doHttpCall") />
		<cfset local.uploadFile = arguments.gw.uploadFile(file = variables.filePathToSampleLicence, purpose = "identity_document") />
		<cfset standardResponseTests(response = local.uploadFile, expectedObjectName = "file_upload", expectedIdPrefix="file_") />

		<!--- Attach Identity File to Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_attach_file_to_account_ok", "doHttpCall") />
		<cfset local.attachFile = arguments.gw.attachIdentityFile(ConnectedAccount = local.connectedAccountToken, fileId = local.uploadFile.getTransactionId()) />
		<cfset standardResponseTests(response = local.attachFile, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset assertTrue(local.uploadFile.getTransactionId() EQ local.attachFile.getParsedResult()["legal_entity"]["verification"]["document"], "Identity file not attached to account") />
		

	</cffunction>



	<!--- HELPERS --->
	<cffunction name="createBankAccountHelper" access="private" returntype="any" output="false">
		<cfargument name="country" type="string" required="true" />

		<cfset local.account = variables.svc.createEFT() />
		<cfset local.account.setFirstName("John") />
		<cfset local.account.setLastName("Doe") />
		<cfset local.account.setAddress("123 Comox Street") />
		<cfset local.account.setPhoneNumber("0123456789") />
		<cfset local.account.setAccount(000123456789) />
		<cfset local.account.setRoutingNumber(110000000) />
		
		<cfif lcase(arguments.country) EQ "ca">
			<cfset local.account.setAddress2("West End") />
			<cfset local.account.setCity("Vancouver") />
			<cfset local.account.setRegion("BC") />
			<cfset local.account.setPostalCode("V6G1S2") />
			<cfset local.account.setCountry("CA") />
		<cfelseif lcase(arguments.country) EQ "us">
			<cfset local.account.setAddress2("") />
			<cfset local.account.setCity("San Francisco") />
			<cfset local.account.setRegion("CA") />
			<cfset local.account.setPostalCode("94107") />
			<cfset local.account.setCountry("US") />		
		</cfif>
		
		<cfreturn local.account />	
	</cffunction>



	<cffunction name="createCardHelper" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset local.account = variables.svc.createCreditCard() />
		<cfset local.account.setAccount(4000000000000077) />
		<cfset local.account.setMonth(10) />
		<cfset local.account.setYear(year(now())+1) />
		<cfset local.account.setVerificationValue(999) />
		<cfset local.account.setFirstName("John") />
		<cfset local.account.setLastName("Doe") />
		<cfset local.account.setAddress("888") />
		<cfset local.account.setPostalCode("77777") />
		<cfreturn local.account />	
	</cffunction>



	<!--- MOCKS --->
	<cffunction name="mock_create_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15oe3nHQ9U3jyomi", "email": "test20150406173055@test.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "business_url": null, "support_phone": null, "metadata": {}, "managed": true, "product_description": null, "debit_negative_balances": false, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15oe3nHQ9U3jyomi/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.first_name", "legal_entity.last_name", "legal_entity.dob.day", "legal_entity.dob.month", "legal_entity.dob.year", "legal_entity.type", "legal_entity.address.line1", "legal_entity.address.city", "legal_entity.address.state", "legal_entity.address.postal_code", "bank_account", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "ip": null, "date": null, "user_agent": null }, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false }, "keys": { "secret": "sk_test_kSx0VSZW6TvnoHCfBoVMFXpq", "publishable": "pk_test_MjuNj3ynAShrhv2OgvHoi46X" } }' } />
	</cffunction>

	<cffunction name="mock_update_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_167t3LFmyHUsZLgr", "email": "test1234@testing123.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "usd", "aed", "afn", "all", "amd", "ang", "aoa", "ars", "aud", "awg", "azn", "bam", "bbd", "bdt", "bgn", "bif", "bmd", "bnd", "bob", "brl", "bsd", "bwp", "bzd", "cad", "cdf", "chf", "clp", "cny", "cop", "crc", "cve", "czk", "djf", "dkk", "dop", "dzd", "eek", "egp", "etb", "eur", "fjd", "fkp", "gbp", "gel", "gip", "gmd", "gnf", "gtq", "gyd", "hkd", "hnl", "hrk", "htg", "huf", "idr", "ils", "inr", "isk", "jmd", "jpy", "kes", "kgs", "khr", "kmf", "krw", "kyd", "kzt", "lak", "lbp", "lkr", "lrd", "lsl", "ltl", "lvl", "mad", "mdl", "mga", "mkd", "mnt", "mop", "mro", "mur", "mvr", "mwk", "mxn", "myr", "mzn", "nad", "ngn", "nio", "nok", "npr", "nzd", "pab", "pen", "pgk", "php", "pkr", "pln", "pyg", "qar", "ron", "rsd", "rub", "rwf", "sar", "sbd", "scr", "sek", "sgd", "shp", "sll", "sos", "srd", "std", "svc", "szl", "thb", "tjs", "top", "try", "ttd", "twd", "tzs", "uah", "ugx", "uyu", "uzs", "vnd", "vuv", "wst", "xaf", "xcd", "xof", "xpf", "yer", "zar", "zmw" ], "default_currency": "usd", "country": "US", "object": "account", "business_name": null, "business_url": null, "support_phone": null, "metadata": {}, "managed": true, "product_description": null, "debit_negative_balances": false, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_167t3LFmyHUsZLgr/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.dob.day", "legal_entity.dob.month", "legal_entity.dob.year", "legal_entity.type", "bank_account", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 2, "interval": "daily" }, "decline_charge_on": { "cvc_failure": true, "avs_failure": false }, "tos_acceptance": { "ip": null, "date": null, "user_agent": null }, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "US" }, "first_name": "John", "last_name": "Smith", "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unverified", "document": null, "details": null } } }' } />
	</cffunction>

	<cffunction name="mock_account_list_ok" access="private">
		<cfsavecontent variable="local.response">
			{ "object": "list", "has_more": false, "url": "/v1/accounts", "data": [ { "id": "acct_15c27zIZh3r4vhIW", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c27zIZh3r4vhIW/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }, { "id": "acct_15c25oAiIdhH6A9Z", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null
				, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null
				, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c25oAiIdhH6A9Z/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }, { "id": "acct_15c1qTLoeW7UuY75", "email": null, "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": false, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "managed": true, "product_description": null, "legal_entity": { "type": null, "business_name": null, "address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": "CA" }, "first_name": null, "last_name": null, "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": null, "month": null, "year": null }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "bank_accounts": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/accounts/acct_15c1qTLoeW7UuY75/bank_accounts", "data": [] }, "verification": { "fields_needed": [ "legal_entity.type", "tos_acceptance.ip", "tos_acceptance.date" ], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "date": null, "ip": null, "user_agent": null }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } } ] 
			}
		</cfsavecontent>
		<cfreturn { StatusCode = '200 OK', FileContent = response } />
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

	<cffunction name="mock_create_second_bank_accounts_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "object": "bank_account", "id": "ba_9999N2HEZw7xP8G6coTn3y2U", "last4": "6789", "country": "CA", "currency": "cad", "status": "new", "fingerprint": "e98PVX2dQLLJ1Bw9", "routing_number": "11000-000", "bank_name": null, "default_for_currency": true }' } />
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