<cfcomponent name="StripeMarketplaceTransactionTest" extends="BaseStripeTest" output="false">

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


	<!--- Test Marketplace Charges --->
	<cffunction name="testConnectedChargeViaPlatform" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token and then customer on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset local.customer = arguments.gw.store(local.token) />
		<cfset standardResponseTests(response = local.customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />
		<cfset local.customerPlatformToken = variables.svc.createToken().setID(customer.getTransactionId()) />

		<!--- Direct charges require a sub-account-specific customer - you can't share the platform customers --->
		<cfset offlineInjector(arguments.gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset local.sharedToken = arguments.gw.createTokenInConnectedAccount(customer = local.customerPlatformToken, ConnectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.sharedToken, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.connectedToken = variables.svc.createToken().setID(sharedToken.getTransactionId()) />

		<!--- Direct Charge To Connected Account --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset local.application_fee = variables.svc.createMoney(200, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = connectedToken, options = {"ConnectedAccount": connectedAccountToken}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />


		<!--- tokens only used once so create another token --->
		<cfset offlineInjector(arguments.gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset local.sharedToken = arguments.gw.createTokenInConnectedAccount(customer = local.customerPlatformToken, ConnectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.sharedToken, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.connectedToken = variables.svc.createToken().setID(sharedToken.getTransactionId()) />

		<!--- now perform charge with an application fee --->
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_with_application_fee_ok", "doHttpCall") />
		<cfset local.fee = variables.svc.createMoney(100, arguments.gw.currency) />
		<cfset local.charge = arguments.gw.purchase(money = money, account = connectedToken, options = {"ConnectedAccount": connectedAccountToken, "application_fee": fee}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(structKeyExists(charge.getParsedResult(), "application_fee"), "There should be an application fee") />
		<cfset assertTrue(charge.getParsedResult().application_fee GT 0, "The application fee should be non-zero") />

	</cffunction>


	<cffunction name="testDestinationCharge" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.createToken(account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<!--- Destination Charge --->
		<cfset local.money  = variables.svc.createMoney(1000, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_destination_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {destination: ConnectedAccountToken }) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

		<!--- tokens only used once so create another token --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.createToken(account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<!--- Destination Charge with Application Fee --->
		<cfset local.money  = variables.svc.createMoney(1000, arguments.gw.currency)>
		<cfset local.application_fee = variables.svc.createMoney(100, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_destination_charge_with_application_fee_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {destination: ConnectedAccountToken, application_fee: application_fee }) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(structKeyExists(charge.getParsedResult(), "application_fee"), "There should be an application fee") />
		<cfset assertTrue(charge.getParsedResult().application_fee GT 0, "The application fee should be non-zero") />

	</cffunction>


	<cffunction name="testDestinationRefundFull" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<!--- Destination Charge --->
		<cfset local.money  = variables.svc.createMoney(1000, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_destination_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {destination: ConnectedAccountToken }) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

		<!--- Refund Charge To Destination Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_refund_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.refund(transactionId = charge.getTransactionID(), reverse_transfer = true) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 1000, "Refund should have been full") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

	</cffunction>


	<cffunction name="testDestinationRefundPartial" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<!--- Destination Charge --->
		<cfset local.money  = variables.svc.createMoney(1000, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_destination_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {destination: ConnectedAccountToken }) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

		<!--- Refund Charge To Destination Account --->
		<cfset local.refundMoney = variables.svc.createMoney(250, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.refund(money = refundMoney, transactionId = charge.getTransactionID(), reverse_transfer = true) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 250, "Refund should have been full") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

	</cffunction>

	<cffunction name="testDestinationRefundFullApplicationFeeReversed" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<!--- Destination Charge --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset local.application_fee = variables.svc.createMoney(100, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_with_application_fee_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {"destination": connectedAccountToken, "application_fee": application_fee}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(structKeyExists(charge.getParsedResult(), "application_fee"), "There should be an application fee") />

		<!--- Refund Charge To Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_refund_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.refund(transactionId = charge.getTransactionID(), refund_application_fee = true, reverse_transfer = true) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 1000, "Refund should have been full") />

		<!--- verify fee was refunded --->
		<cfset offlineInjector(arguments.gw, this, "mock_application_fee_reversal_full", "doHttpCall") />
		<cfset local.fee = arguments.gw.getApplicationFee(local.charge.getParsedResult().application_fee) />
		<cfset standardResponseTests(response = local.fee, expectedObjectName = "application_fee", expectedIdPrefix="fee_") />
		<cfset assertTrue(fee.getParsedResult().refunded, "Application fee wasn't refunded") />
		<cfset assertTrue(fee.getParsedResult().amount_refunded EQ 100, "Application fee wasn't fully refunded") />

	</cffunction>


	<cffunction name="testDestinationRefundPartialApplicationFeeReversed" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<!--- Destination Charge --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset local.application_fee = variables.svc.createMoney(100, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_with_application_fee_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {"destination": connectedAccountToken, "application_fee": application_fee}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(structKeyExists(charge.getParsedResult(), "application_fee"), "There should be an application fee") />

		<!--- Refund Charge To Destination Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refundMoney = variables.svc.createMoney(250, arguments.gw.currency) />
		<cfset local.refund = arguments.gw.refund(money = refundMoney, transactionId = charge.getTransactionID(), refund_application_fee = true, reverse_transfer = true) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 250, "Refund should have been partial") />

		<!--- verify fee was refunded --->
		<cfset offlineInjector(arguments.gw, this, "mock_application_fee_reversal_partial", "doHttpCall") />
		<cfset local.fee = arguments.gw.getApplicationFee(local.charge.getParsedResult().application_fee) />
		<cfset standardResponseTests(response = local.fee, expectedObjectName = "application_fee", expectedIdPrefix="fee_") />
		<cfset assertTrue(NOT fee.getParsedResult().refunded, "Application fee is only marked as refunded if FULLY refunded") />
		<cfset assertTrue(fee.getParsedResult().amount NEQ fee.getParsedResult().amount_refunded, "Application fee was fully refunded") />
		<cfset assertTrue(fee.getParsedResult().amount_refunded EQ 25, "Application fee wasn't partially refunded") />

	</cffunction>


	<cffunction name="testConnectedRefundFull" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset local.customer = arguments.gw.store(local.token) />
		<cfset standardResponseTests(response = local.customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />
		<cfset local.customerPlatformToken = variables.svc.createToken().setID(customer.getTransactionId()) />

		<!--- Direct charges require a sub-account-specific customer - you can't share the platform customers --->
		<cfset offlineInjector(arguments.gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset local.sharedToken = arguments.gw.createTokenInConnectedAccount(customer = local.customerPlatformToken, ConnectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.sharedToken, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.connectedToken = variables.svc.createToken().setID(sharedToken.getTransactionId()) />

		<!--- Direct Charge To Connected Account --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = connectedToken, options = {"ConnectedAccount": connectedAccountToken}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

		<!--- Refund Charge To Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_refund_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.refund(transactionId = charge.getTransactionID(), options = {ConnectedAccount: connectedAccountToken}) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 1000, "Refund should have been full") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

	</cffunction>


	<cffunction name="testConnectedRefundPartial" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset local.customer = arguments.gw.store(local.token) />
		<cfset standardResponseTests(response = local.customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />
		<cfset local.customerPlatformToken = variables.svc.createToken().setID(customer.getTransactionId()) />

		<!--- Direct charges require a sub-account-specific customer - you can't share the platform customers --->
		<cfset offlineInjector(arguments.gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset local.sharedToken = arguments.gw.createTokenInConnectedAccount(customer = local.customerPlatformToken, ConnectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.sharedToken, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.connectedToken = variables.svc.createToken().setID(sharedToken.getTransactionId()) />

		<!--- Direct Charge To Connected Account --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = connectedToken, options = {"ConnectedAccount": connectedAccountToken}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

		<!--- Refund Charge To Connected Account --->
		<cfset local.refundMoney = variables.svc.createMoney(250, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.refund(money = refundMoney, transactionId = charge.getTransactionID(), options = {ConnectedAccount: connectedAccountToken}) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 250, "Refund should have been full") />
		<cfset assertTrue(NOT structKeyExists(charge.getParsedResult(), "application_fee"), "There should not be an application fee") />

	</cffunction>

	<cffunction name="testConnectedRefundFullApplicationFeeReversed" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset local.customer = arguments.gw.store(local.token) />
		<cfset standardResponseTests(response = local.customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />
		<cfset local.customerPlatformToken = variables.svc.createToken().setID(customer.getTransactionId()) />

		<!--- Direct charges require a sub-account-specific customer - you can't share the platform customers --->
		<cfset offlineInjector(arguments.gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset local.sharedToken = arguments.gw.createTokenInConnectedAccount(customer = local.customerPlatformToken, ConnectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.sharedToken, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.connectedToken = variables.svc.createToken().setID(sharedToken.getTransactionId()) />

		<!--- Direct Charge To Connected Account --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset local.application_fee = variables.svc.createMoney(100, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_with_application_fee_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = connectedToken, options = {"ConnectedAccount": connectedAccountToken, "application_fee": application_fee}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(structKeyExists(charge.getParsedResult(), "application_fee"), "There should be an application fee") />

		<!--- Refund Charge To Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_refund_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.refund(transactionId = charge.getTransactionID(), refund_application_fee = true, options = {ConnectedAccount: connectedAccountToken}) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 1000, "Refund should have been full") />

		<!--- verify fee was refunded --->
		<cfset offlineInjector(arguments.gw, this, "mock_application_fee_reversal_full", "doHttpCall") />
		<cfset local.fee = arguments.gw.getApplicationFee(local.charge.getParsedResult().application_fee) />
		<cfset standardResponseTests(response = local.fee, expectedObjectName = "application_fee", expectedIdPrefix="fee_") />
		<cfset assertTrue(fee.getParsedResult().refunded, "Application fee wasn't refunded") />
		<cfset assertTrue(fee.getParsedResult().amount_refunded EQ 100, "Application fee wasn't fully refunded") />

	</cffunction>


	<cffunction name="testConnectedRefundPartialApplicationFeeReversed" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- create a token on the platform account --->
		<cfset offlineInjector(arguments.gw, this, "mock_token_ok", "doHttpCall") />
		<cfset local.response = arguments.gw.validate(money = variables.svc.createMoney(5000, arguments.gw.currency), account = createCardHelper()) />
		<cfset standardResponseTests(response = local.response, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.token = variables.svc.createToken().setID(local.response.getTransactionId()) />

		<cfset offlineInjector(arguments.gw, this, "mock_create_customer_ok", "doHttpCall") />
		<cfset local.customer = arguments.gw.store(local.token) />
		<cfset standardResponseTests(response = local.customer, expectedObjectName = "customer", expectedIdPrefix="cus_") />
		<cfset local.customerPlatformToken = variables.svc.createToken().setID(customer.getTransactionId()) />

		<!--- Direct charges require a sub-account-specific customer - you can't share the platform customers --->
		<cfset offlineInjector(arguments.gw, this, "mock_get_token_for_customer_ok", "doHttpCall") />
		<cfset local.sharedToken = arguments.gw.createTokenInConnectedAccount(customer = local.customerPlatformToken, ConnectedAccount = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.sharedToken, expectedObjectName = "token", expectedIdPrefix="tok_") />
		<cfset local.connectedToken = variables.svc.createToken().setID(sharedToken.getTransactionId()) />

		<!--- Direct Charge To Connected Account --->
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset local.application_fee = variables.svc.createMoney(100, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_direct_charge_with_application_fee_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = connectedToken, options = {"ConnectedAccount": connectedAccountToken, "application_fee": application_fee}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />
		<cfset assertTrue(structKeyExists(charge.getParsedResult(), "application_fee"), "There should be an application fee") />

		<!--- Refund Charge To Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_refund_partial_charge_to_connected_account_ok", "doHttpCall") />
		<cfset local.refundMoney = variables.svc.createMoney(250, arguments.gw.currency) />
		<cfset local.refund = arguments.gw.refund(money = refundMoney, transactionId = charge.getTransactionID(), refund_application_fee = true, options = {ConnectedAccount: connectedAccountToken}) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "refund", expectedIdPrefix="re_") />
		<cfset assertTrue(refund.getParsedResult().amount EQ 250, "Refund should have been partial") />

		<!--- verify fee was refunded --->
		<cfset offlineInjector(arguments.gw, this, "mock_application_fee_reversal_partial", "doHttpCall") />
		<cfset local.fee = arguments.gw.getApplicationFee(local.charge.getParsedResult().application_fee) />
		<cfset standardResponseTests(response = local.fee, expectedObjectName = "application_fee", expectedIdPrefix="fee_") />
		<cfset assertTrue(NOT fee.getParsedResult().refunded, "Application fee is only marked as refunded if FULLY refunded") />
		<cfset assertTrue(fee.getParsedResult().amount NEQ fee.getParsedResult().amount_refunded, "Application fee was fully refunded") />
		<cfset assertTrue(fee.getParsedResult().amount_refunded EQ 25, "Application fee wasn't partially refunded") />

	</cffunction>


	<!--- Test Bank Transfers --->
	<cffunction name="testTransferArbitraryAmountToConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Create Token --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset local.token = arguments.gw.createToken(createCardHelper()) />
		<cfset standardResponseTests(response = local.token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge on Platform Account --->
		<cfset local.token = variables.svc.createToken().setID(local.token.getTransactionID()) />
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {description: 'unit-test charge'}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer To Connected Account --->
		<cfset local.transferAmount = variables.svc.createMoney(500, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset local.transfer = arguments.gw.transfer(money = transferAmount, destination = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />
	</cffunction>
  

	<cffunction name="testTransferChargeToConnectedAccount" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Create Token --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset local.token = arguments.gw.createToken(createCardHelper()) />
		<cfset standardResponseTests(response = local.token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset local.token = variables.svc.createToken().setID(local.token.getTransactionID()) />
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {description: 'unit-test charge'}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer To Connected Account --->
		<cfset local.transferAmount = variables.svc.createMoney(500, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset local.transfer = arguments.gw.transfer(money = transferAmount, destination = local.connectedAccountToken, options = {source_transaction: local.charge.getTransactionId()}) />
		<cfset standardResponseTests(response = local.transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />
	</cffunction>
  

	<cffunction name="testTransferWithApplicationFee" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Create Token --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset local.token = arguments.gw.createToken(createCardHelper()) />
		<cfset standardResponseTests(response = local.token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset local.token = variables.svc.createToken().setID(local.token.getTransactionID()) />
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {description: 'unit-test charge'}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer With Application Fee --->
		<cfset local.transferAmount = variables.svc.createMoney(500, arguments.gw.currency)>
		<cfset local.applicationFee = variables.svc.createMoney(200, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_transfer_with_application_fee_ok", "doHttpCall") />
		<cfset local.transfer = arguments.gw.transfer(money = transferAmount, destination = local.connectedAccountToken, options = {application_fee: local.applicationFee}) />
		<cfset standardResponseTests(response = local.transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />

		<!--- Reverse The Transfer WITH application_fee --->
		<cfset local.reverseAmount = variables.svc.createMoney(400, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_reversing_transfer_with_application_fee_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.transferReverse(transferId = transfer.getTransactionId(), money = reverseAmount, options = {refund_application_fee: true}) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "transfer_reversal", expectedIdPrefix="trr_") />

	</cffunction>
  

	<cffunction name="testReversingTransfer" access="public" returntype="void" output="false" mxunit:dataprovider="gateways">
		<cfargument name="gw" type="any" required="true" />

		<!--- Create Connected Account --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_account_ok", "doHttpCall") />
		<cfset local.connectedAccount = arguments.gw.createConnectedAccount(managed = true, country = arguments.gw.country) />
		<cfset standardResponseTests(response = local.connectedAccount, expectedObjectName = "account", expectedIdPrefix="acct_") />
		<cfset local.connectedAccountToken = variables.svc.createToken().setID(local.connectedAccount.getTransactionId()) />

		<!--- Create Token --->
		<cfset offlineInjector(arguments.gw, this, "mock_create_card_token_ok", "doHttpCall") />
		<cfset local.token = arguments.gw.createToken(createCardHelper()) />
		<cfset standardResponseTests(response = local.token, expectedObjectName = "token", expectedIdPrefix="tok_") />

		<!--- Charge --->
		<cfset local.token = variables.svc.createToken().setID(local.token.getTransactionID()) />
		<cfset local.money = variables.svc.createMoney(1000, arguments.gw.currency) />
		<cfset offlineInjector(arguments.gw, this, "mock_charge_ok", "doHttpCall") />
		<cfset local.charge = arguments.gw.purchase(money = money, account = token, options = {description: 'unit-test charge'}) />
		<cfset standardResponseTests(response = local.charge, expectedObjectName = "charge", expectedIdPrefix="ch_") />

		<!--- Transfer From Platform To Connected Account --->
		<cfset local.transferAmount = variables.svc.createMoney(500, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_transfer_from_platform_stripe_account_to_connected_stripe_account_ok", "doHttpCall") />
		<cfset local.transfer = arguments.gw.transfer(money = transferAmount, destination = local.connectedAccountToken) />
		<cfset standardResponseTests(response = local.transfer, expectedObjectName = "transfer", expectedIdPrefix="tr_") />

		<!--- Reverse The Transfer --->
		<cfset local.reverseAmount = variables.svc.createMoney(400, arguments.gw.currency)>
		<cfset offlineInjector(arguments.gw, this, "mock_reversing_transfer_ok", "doHttpCall") />
		<cfset local.refund = arguments.gw.transferReverse(transferId = transfer.getTransactionId(), money = reverseAmount) />
		<cfset standardResponseTests(response = local.refund, expectedObjectName = "transfer_reversal", expectedIdPrefix="trr_") />
	</cffunction>





	<!--- HELPERS --->
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

	<cffunction name="mock_direct_charge_with_application_fee_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_5m7WiasFMFf5A5", "object": "charge", "created": 1424986511, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_5m7WAou95fVC5b", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": { }, "customer": null }, "captured": true, "balance_transaction": "txn_1IeEOass2YWqgM", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "metadata": { }, "statement_descriptor": null, "fraud_details": { }, "receipt_email": null, "receipt_number": null, "shipping": null, "application_fee": "fee_5tv0IlPjoHmF8M", "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_5m7WiasFMFf5A5/refunds", "data": [  ] } }' } />
	</cffunction>
	
	<cffunction name="mock_destination_charge_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_5m7WiasFMFf5A5", "object": "charge", "created": 1424986511, "livemode": false, "paid": true, "status": "succeeded", "amount": 5000, "currency": "cad", "refunded": false, "source": { "id": "card_5m7WAou95fVC5b", "object": "card", "last4": "4242", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": { }, "customer": null }, "captured": true, "balance_transaction": "txn_1IeEOass2YWqgM", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "metadata": { }, "statement_descriptor": null, "fraud_details": { }, "receipt_email": null, "receipt_number": null, "shipping": null, "application_fee": null, "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_5m7WiasFMFf5A5/refunds", "data": [  ] } }' } />
	</cffunction>
	
	<cffunction name="mock_destination_charge_with_application_fee_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "ch_6KwJitWr4UhhGP", "object": "charge", "created": 1433017215, "livemode": false, "paid": true, "status": "succeeded", "amount": 1000, "currency": "usd", "refunded": false, "source": { "id": "card_6KwJQeV9SrjUFf", "object": "card", "last4": "0077", "brand": "Visa", "funding": "credit", "exp_month": 10, "exp_year": 2016, "fingerprint": "g9TMHGodJg3y3bPf", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "", "cvc_check": "pass", "address_line1_check": "pass", "address_zip_check": "pass", "dynamic_last4": null, "metadata": {}, "customer": null }, "captured": true, "balance_transaction": "txn_6KwJRBe0EdUhsv", "failure_message": null, "failure_code": null, "amount_refunded": 0, "customer": null, "invoice": null, "description": null, "dispute": null, "metadata": {}, "statement_descriptor": null, "fraud_details": {}, "transfer": "tr_6KwJBmgnps2mxA", "receipt_email": null, "receipt_number": null, "shipping": null, "destination": "acct_168GRDEPQLPOH7Lc", "application_fee": "fee_6KwJ1B5kGl9tkl", "refunds": { "object": "list", "total_count": 0, "has_more": false, "url": "/v1/charges/ch_6KwJitWr4UhhGP/refunds", "data": [] } }' } />
	</cffunction>
	 
	<cffunction name="mock_refund_charge_to_connected_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_1hd2eEhc0a2gF2", "amount": 1000, "currency": "cad", "created": 1366751825, "object": "refund", "balance_transaction": "txn_1hd2bCSoaEP0e5", "metadata": { }, "charge": "ch_1hCcxjT1gTWGWz", "receipt_number": null, "reason": null }' } />
	</cffunction>

	<cffunction name="mock_application_fee_reversal_full" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "fee_6Kw2F2UYTTE0HR", "object": "application_fee", "created": 1433016173, "livemode": false, "amount": 100, "currency": "usd", "refunded": true, "amount_refunded": 100, "refunds": { "object": "list", "total_count": 1, "has_more": false, "url": "/v1/application_fees/fee_6Kw2F2UYTTE0HR/refunds", "data": [ { "id": "fr_6Kw2d0iNIz2vnh", "amount": 100, "currency": "usd", "created": 1433016174, "object": "fee_refund", "balance_transaction": "txn_6Kw2jbKb4srJwA", "metadata": {}, "fee": "fee_6Kw2F2UYTTE0HR" } ] }, "balance_transaction": "txn_6Kw2aZCuHXnEHr", "account": "acct_168GAQGaTtOjJ24S", "application": "ca_6KX23cyOabAfQUeyU6Qp8M1vc221RG2c", "charge": "ch_168GATGaTtOjJ24SHXAezgtI", "originating_transaction": null }' } />
	</cffunction> 

	<cffunction name="mock_application_fee_reversal_partial" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "fee_6Kw676LQSoyNu0", "object": "application_fee", "created": 1433016412, "livemode": false, "amount": 100, "currency": "cad", "refunded": false, "amount_refunded": 25, "refunds": { "object": "list", "total_count": 1, "has_more": false, "url": "/v1/application_fees/fee_6Kw676LQSoyNu0/refunds", "data": [ { "id": "fr_6Kw6NJ6zdmkr4c", "amount": 50, "currency": "cad", "created": 1433016413, "object": "fee_refund", "balance_transaction": "txn_6Kw6ni6Dp6zcux", "metadata": {}, "fee": "fee_6Kw676LQSoyNu0" } ] }, "balance_transaction": "txn_6Kw6hFdC6tzDJN", "account": "acct_168GEHJOqQ1BzVqF", "application": "ca_5RWA5Y5BtyGpY2EZ3Lomyd5BBbWSfjhQ", "charge": "ch_168GEKJOqQ1BzVqFbA95vfdG", "originating_transaction": null }' } />
	</cffunction> 

	<cffunction name="mock_refund_partial_charge_to_connected_account_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "re_1hd2eEhc0a2gF2", "amount": 250, "currency": "cad", "created": 1366751825, "object": "refund", "balance_transaction": "txn_1hd2bCSoaEP0e5", "metadata": { }, "charge": "ch_1hCcxjT1gTWGWz", "receipt_number": null, "reason": null }' } />
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
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "trr_6LFmN4iXIyJXRn", "amount": 400, "currency": "usd", "created": 1433089601, "object": "transfer_reversal", "balance_transaction": "txn_6LFmfe6M036xBi", "metadata": {}, "transfer": "tr_6LFmp9o75ZTRwW" }' } />
	</cffunction>

	<cffunction name="mock_reversing_transfer_with_application_fee_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "trr_6LFjuyYGLitcYH", "amount": 400, "currency": "usd", "created": 1433089408, "object": "transfer_reversal", "balance_transaction": "txn_6LFjaWciOV1ysS", "metadata": {}, "transfer": "tr_6LFjfPdhi0XkWJ" }' } />
	</cffunction>
	
	<cffunction name="mock_update_account_validation_passes_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "acct_15odyvFUmKIEYcf3", "email": "test20150406172553@test.tst", "statement_descriptor": null, "display_name": null, "timezone": "Etc/UTC", "details_submitted": false, "charges_enabled": true, "transfers_enabled": true, "currencies_supported": [ "cad", "usd" ], "default_currency": "cad", "country": "CA", "object": "account", "business_name": null, "business_url": null, "support_phone": null, "metadata": {}, "managed": true, "product_description": null, "debit_negative_balances": false, "bank_accounts": { "object": "list", "total_count": 1, "has_more": false, "url": "/v1/accounts/acct_15odyvFUmKIEYcf3/bank_accounts", "data": [ { "object": "bank_account", "id": "ba_15odywFUmKIEYcf3q2ZDAw0L", "last4": "6789", "country": "CA", "currency": "cad", "status": "new", "fingerprint": "Z3T7RQTuRWxBOKav", "routing_number": "11000-000", "bank_name": null, "default_for_currency": true } ] }, "verification": { "fields_needed": [], "due_by": null, "contacted": false }, "transfer_schedule": { "delay_days": 7, "interval": "daily" }, "tos_acceptance": { "ip": "184.66.107.116", "date": 1428338336, "user_agent": null }, "legal_entity": { "type": "company", "business_name": null, "address": { "line1": "123 Another Street", "line2": null, "city": "Some City", "state": "A State", "postal_code": "123ABC", "country": "CA" }, "first_name": "John", "last_name": "Smith", "personal_address": { "line1": null, "line2": null, "city": null, "state": null, "postal_code": null, "country": null }, "dob": { "day": 20, "month": 5, "year": 1990 }, "additional_owners": null, "verification": { "status": "unchecked", "document": null, "details": null } }, "decline_charge_on": { "cvc_failure": false, "avs_failure": false } }' } />
	</cffunction>

	<cffunction name="mock_token_ok" access="private">
		<cfreturn { StatusCode = '200 OK', FileContent = '{ "id": "tok_1IZvRgzvQlffjs", "livemode": false, "created": 1360974256, "used": false, "object": "token", "card": { "object": "card", "last4": "4242", "type": "Visa", "exp_month": 10, "exp_year": 2014, "fingerprint": "sBxTyx7XVdjznwyt", "country": "US", "name": "John Doe", "address_line1": "888", "address_line2": "", "address_city": null, "address_state": "", "address_zip": "77777", "address_country": "" } }' } />
	</cffunction>


</cfcomponent>