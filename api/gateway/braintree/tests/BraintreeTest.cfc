<cfcomponent name="BraintreeTest" extends="mxunit.framework.TestCase" output="false">

<!---
	
	To authenticate using the Direct Post method of authentication, user demo:password.
	
	For key-based authentication, use: * *Key: * Zydpf74pK59Gc85vpu6r9My286BUYw3q * *Key ID: * 557218
	
	Test transactions can be submitted with the following information:
	
	Visa 4111111111111111 
	MasterCard 5431111111111111 
	DiscoverCard 6011601160116611 
	American Express 341111111111111 
	Credit Card Expiration 10/10 
	eCheck Acct & Routing: 123123123 
	Amount >1.00 
	
	Triggering Errors in Test Mode
	To cause a declined message, pass an amount less than 1.00. 
	To trigger a fatal message, pass an invalid card number. 
	To simulate an AVS Match, pass 77777 in the zip field for a �Z � 5 Character Zip match only�. Pass 888 in the address1 field to generate an �A � Address match only�. Pass them both for a �Y � Exact match, 5-character numeric ZIP� match. 
	To simulate a CVV Match, pass 999 in the cvv field. 

--->
	<cffunction name="setUp" returntype="void" access="public">	

		<cfset var gw = structNew() />

		<cfscript>  
			gw.path = "braintree.braintree";
			gw.Username = 'testapi';
			gw.Password = 'password1';
			gw.SecurityKey = 'zjhh9UAS7d4UkBVqa6sagBvpeT733U88';
			gw.SecurityKeyID = '1084547';
			gw.TestMode = true;		// defaults to true anyways

			// create gw and get reference			
			variables.svc = createObject("component", "cfpayment.api.core").init(gw);
			variables.gw = variables.svc.getGateway();
			
		</cfscript>
	</cffunction>

	<cffunction name="testPurchase" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<!--- test the purchase method --->
		<cfset response = gw.purchase(money = money, account = createValidCard(), options = options) />
		<cfset debug("CC success trans ID: " & response.getTransactionID()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<!--- amounts less than 1.00 generate declines --->
		<cfset response = gw.purchase(money = variables.svc.createMoney(50), account = createValidCard(), options = options) />
		<cfset debug("CC decline trans ID: " & response.getTransactionID()) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did succeed") />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset response = gw.purchase(money = money, account = createInvalidCard(), options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did succeed") />


		<cfset response = gw.purchase(money = money, account = createValidCardWithoutCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getCVVMessage()) />
		<cfset assertTrue(response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#response.getCVVCode()#'") />

		<cfset response = gw.purchase(money = money, account = createValidCardWithBadCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getCVVMessage()) />
		<cfset assertTrue(response.getCVVCode() EQ "N", "Bad CVV was passed so non-matching answer should be provided but was: '#response.getCVVCode()#'") />

		<cfset response = gw.purchase(money = money, account = createValidCardWithoutStreetMatch(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.getAVSCode() EQ "Z", "AVS Zip match only should be found") />

		<cfset response = gw.purchase(money = money, account = createValidCardWithoutZipMatch(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.getAVSCode() EQ "A", "AVS Street match only should be found") />


		<!--- test the purchase method for EFT --->
		<cfset response = gw.purchase(money = money, account = createValidEFT(), options = options) />
		<cfset debug("EFT trans ID: " & response.getTransactionID()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<!--- amounts less than 1.00 generate declines --->
		<cfset response = gw.purchase(money = variables.svc.createMoney(50), account = createValidEFT(), options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did succeed") />

	</cffunction>


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


	<cffunction name="testValidateFailsEFT" access="public" returntype="void" output="false" mxunit:expectedException="cfpayment.MethodNotImplemented">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<!--- test the validate method for EFT - should fail --->
		<cfset response = gw.validate(money = money, account = createValidEFT(), options = options) />

	</cffunction>


	<cffunction name="testAuthorizeOnly" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset response = gw.authorize(money = money, account = createValidCard(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.getAVSCode() EQ "Y", "Exact match (street + zip) should be found") />

		<!--- amounts less than 1.00 generate declines --->
		<cfset response = gw.authorize(money = variables.svc.createMoney(50), account = createValidCard(), options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did succeed") />

		<!--- this will be rejected by gateway because the card number is not valid --->
		<cfset response = gw.authorize(money = money, account = createInvalidCard(), options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did succeed") />


		<cfset response = gw.authorize(money = money, account = createValidCardWithoutCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getCVVMessage()) />
		<cfset assertTrue(response.getCVVCode() EQ "", "No CVV was passed so no answer should be provided but was: '#response.getCVVCode()#'") />

		<cfset response = gw.authorize(money = money, account = createValidCardWithBadCVV(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getCVVMessage()) />
		<cfset assertTrue(response.getCVVCode() EQ "N", "Bad CVV was passed so non-matching answer should be provided but was: '#response.getCVVCode()#'") />

		<cfset response = gw.authorize(money = money, account = createValidCardWithoutStreetMatch(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.getAVSCode() EQ "Z", "AVS Zip match only should be found") />

		<cfset response = gw.authorize(money = money, account = createValidCardWithoutZipMatch(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />
		<cfset debug(response.getAVSMessage()) />
		<cfset assertTrue(response.getAVSCode() EQ "A", "AVS Street match only should be found") />

	</cffunction>


	<cffunction name="testAuthorizeFailsEFT" access="public" returntype="void" output="false" mxunit:expectedException="cfpayment.MethodNotImplemented">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<!--- test the authorize method for EFT - should fail --->
		<cfset response = gw.authorize(money = money, account = createValidEFT(), options = options) />

	</cffunction>


	<cffunction name="testAuthorizeAndStoreThenPurchase" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var token = variables.svc.createToken(createUUID()) />
		<cfset var response = "" />
		<cfset var options = structNew() />
		<cfset var vault = structNew() />
		<cfset options["tokenId"] = token.getID() />
		<cfset options["tokenize"] = true />
		
		<cfset response = gw.authorize(money = money, account = createValidCard(), options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.purchase(money = money, account = token, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The token-based purchase did not succeed") />

	</cffunction>


	<cffunction name="testStoreAndUnstoreCreditCard" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		<cfset var token = variables.svc.createToken(createUUID()) />

		<!--- try storing withOUT a populated token value --->
		<cfset response = gw.store(account = createValidCard(), options = options) />
		<cfset token.setID(response.getTokenID()) />
		<cfset assertTrue(response.getSuccess(), "The store did not succeed") />
		
		
		<!--- get the masked details --->
		<cfset options = { tokenId = token.getID(), report_type = "customer_vault" } />
		<cfset response = gw.status(options = options) />
		<cfset debug(response.getParsedResult()) />
		<cfset options = { } />
		 
		<!--- unstore, using whatever they gave us as a token ID --->
		<cfset response = gw.unstore(account = token, options = options) />
		<cfset assertTrue(response.getSuccess(), "The unstore did not succeed") />


		<!--- try storing with a populated token value --->
		<cfset token = variables.svc.createToken(createUUID()) />
		<cfset options["tokenId"] = token.getID() />
		<cfset response = gw.store(account = createValidCard(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The store did not succeed") />
		<cfset assertTrue(response.getTokenID() EQ token.getID(), "The submitted token ID was not returned, sent #token.getID()#, received: #response.getParsedResult().customer_vault_id#") />
		
		<cfset response = gw.unstore(account = token, options = options) />
		<cfset assertTrue(response.getSuccess(), "The unstore did not succeed") />

	</cffunction>
	

	<cffunction name="testStoreAndUnstoreEFT" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5100) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		<cfset var token = variables.svc.createToken(createUUID()) />

		<!--- try storing withOUT a populated token value --->
		<cfset response = gw.store(account = createValidEFT(), options = options) />
		<cfset token.setID(response.getTokenID()) />
		<cfset assertTrue(response.getSuccess(), "The store did not succeed") />
		
		
		<!--- get the masked details --->
		<cfset options = { tokenId = token.getID(), report_type = "customer_vault" } />
		<cfset response = gw.status(options = options) />
		<cfset debug(response.getParsedResult()) />
		<cfset options = { } />
		 
		<!--- unstore, using whatever they gave us as a token ID --->
		<cfset response = gw.unstore(account = token, options = options) />
		<cfset assertTrue(response.getSuccess(), "The unstore did not succeed") />


		<!--- try storing with a populated token value --->
		<cfset token = variables.svc.createToken(createUUID()) />
		<cfset options["tokenId"] = token.getID() />
		<cfset response = gw.store(account = createValidEFT(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The store did not succeed") />
		<cfset assertTrue(response.getTokenID() EQ token.getID(), "The submitted token ID was not returned, sent #token.getID()#, received: #response.getParsedResult().customer_vault_id#") />
		
		<cfset response = gw.unstore(account = token, options = options) />
		<cfset assertTrue(response.getSuccess(), "The unstore did not succeed") />

	</cffunction>


	<cffunction name="testSecondTransUsingTransactionID" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		<cfset var txid = "" />
		
		<!--- PURCHASE, then auth / purchase / validate --->
		<cfset response = gw.purchase(money = money, account = createValidCard(), options = options) />
		<cfset txid = response.getTransactionID() />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.validate(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The purchase + validate did not succeed") />

		<cfset response = gw.authorize(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The purchase + authorization did not succeed") />

		<cfset response = gw.purchase(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The purchase + purchase did not succeed") />


		<!--- AUTH, then auth / purchase / validate --->
		<cfset response = gw.authorize(money = money, account = createValidCard(), options = options) />
		<cfset txid = response.getTransactionID() />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.validate(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The auth + validate did not succeed") />

		<cfset response = gw.authorize(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The auth + authorization did not succeed") />

		<cfset response = gw.purchase(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The auth + purchase did not succeed") />


		<!--- VALIDATE, then auth / purchase / validate --->
		<cfset response = gw.validate(money = money, account = createValidCard(), options = options) />
		<cfset txid = response.getTransactionID() />
		<cfset assertTrue(response.getSuccess(), "The validate did not succeed") />

		<cfset response = gw.validate(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The validate + validate did not succeed") />

		<cfset response = gw.authorize(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The validate + authorization did not succeed") />

		<cfset response = gw.purchase(money = money, transactionID = txid, options = options) />
		<cfset assertTrue(response.getSuccess(), "The validate + purchase did not succeed") />

	</cffunction>


	<cffunction name="testMissingArgumentsThrowsException" access="public" returntype="void" output="false" mxunit:expectedException="cfpayment.Gateway.Error">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var options = structNew() />
		
		<cfset response = gw.purchase(money = money, options = options) />
		<cfset assertTrue(false, "The error was not thrown") />

	</cffunction>
		

	<!--- confirm authorize throws error --->
	<cffunction name="testAuthorizeThrowsException" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<!--- authorize will throw an error for e-check --->
		<cftry>
			<cfset response = gw.authorize(money = money, account = createValidEFT(), options = options) />
			<cfset assertTrue(false, "EFT authorize() should fail but did not") />
			<cfcatch type="cfpayment.MethodNotImplemented">
				<cfset assertTrue(true, "EFT authorize() threw cfpayment.MethodNotImplemented") />
			</cfcatch>
		</cftry>

	</cffunction>


	<cffunction name="testAuthorizeThenCaptureThenReport" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var oid = createUUID() />
		<cfset var options = { orderId = oid } />
		<cfset var tid = "" />
		

		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<!--- braintree (like itransact), uses its own transaction/InternalID for capturing an authorization.  Is authorization even used by anyone? --->
		<cfset response = gw.capture(money = money, authorization = response.getTransactionId(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The capture did not succeed") />

		<!--- now run a detail report on this transaction --->
		<cfset report = gw.status(transactionid = response.getTransactionID()) />
		<cfset assertTrue(report.getSuccess() AND NOT report.hasError(), "Successful transactionid should have success = true") />

		<!--- look up by orderid --->
		<cfset report = gw.status(orderId = oid) />
		<cfset assertTrue(report.getSuccess() AND NOT report.hasError(), "Valid orderid should result in returned match") />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(arrayLen(report.getParsedResult().xmlRoot.xmlChildren) GT 0, "Valid orderid should result in returned match") />

		
		<!--- pass a non-existent id to see how error is handled --->
		<cfset report = gw.status(transactionid = "11111111") />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.getSuccess() AND arrayLen(report.getParsedResult().xmlRoot.xmlChildren) EQ 0, "Invalid transactionid should result in no returned matches") />


		<!--- use a broken request to see how error is handled
		<cfset options["condition"] = 'unknown' />
		<cfset options["cc_number"] = '5454' />
		<cfset options["start_date"] = '2008-03-10' />
		<cfset options["end_date"] = '2008-03-08' />
		<cfset report = gw.status(options = options) />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.hasError(), "Invalid options should trigger a gateway failure (response code 3)") />
		--->

	</cffunction>


	<cffunction name="testAuthorizeThenCredit" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />

		
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.credit(transactionid = response.getTransactionID(), money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "You cannot credit a preauth") />

	</cffunction>


	<cffunction name="testAuthorizeThenVoid" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />

		
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

		
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.credit(transactionid = response.getTransactionID(), money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can credit a purchase") />

	</cffunction>


	<cffunction name="testPurchaseThenRefund" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var transId = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />

		
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
		

	<cffunction name="testPurchaseThenVoidThenReport" access="public" returntype="void" output="false">
	
		<cfset var account = createValidCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />

		
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can void a purchase") />

		<cfset report = gw.status(transactionid = response.getTransactionID()) />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.getSuccess() AND arrayLen(report.getParsedResult().xmlRoot.xmlChildren) GT 0, "Transactionid should result in matches") />

	</cffunction>	


	<cffunction name="testDirectDepositWithEFT" access="public" returntype="void" output="false">
	
		<cfset var account = createValidEFT() />
		<cfset var money = variables.svc.createMoney(500) /><!--- in cents, $5000.00 --->
		<cfset var response = "" />
		<cfset var report = "" />

		<cfset response = gw.credit(money = money, account = account, options = {"dup_seconds": 0}) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The direct deposit did not succeed") />

	</cffunction>


	<cffunction name="testDirectDepositWithToken" access="public" returntype="void" output="false">

		<cfset local.token = variables.svc.createToken(createUUID()) />
		<cfset local.response = gw.store(account = createValidEFT()) />
		<cfset token.setID(response.getTokenID()) />
		<cfset assertTrue(response.getSuccess(), "The store did not succeed") />

		<cfset local.money = variables.svc.createMoney(500) /><!--- in cents, $5000.00 --->
	
		<cfset response = gw.credit(money = money, account = token, options = {"dup_seconds": 0}) />
		<cfset assertTrue(response.getSuccess(), "The direct deposit did not succeed") />

	</cffunction>
	

	<cffunction name="testDirectDepositWithTokenID" access="public" returntype="void" output="false">

		<cfset local.response = gw.store(account = createValidEFT()) />
		<cfset assertTrue(response.getSuccess(), "The store did not succeed") />
		<cfset local.money = variables.svc.createMoney(500) /><!--- in cents, $5000.00 --->

		<cfset local.response = gw.credit(money = money, options = {"tokenId": response.getTokenID(), "dup_seconds": 0}) />
		<cfset assertTrue(response.getSuccess(), "The direct deposit did not succeed") />

	</cffunction>
			

	<cffunction name="testDirectDepositWithoutAccountThrowsError" access="public" returntype="void" output="false" mxunit:expectedException="cfpayment.InvalidAccount">
	
		<cfset local.money = variables.svc.createMoney(500) /><!--- in cents, $5000.00 --->
		<cfset local.response = gw.credit(money = money) />
		<cfset assertTrue(false, "Should have thrown an error") />

	</cffunction>
	

	<cffunction name="testPurchaseThenVoidEFT" access="public" returntype="void" output="false">
	
		<cfset var account = createValidEFT() />
		<cfset var money = variables.svc.createMoney(4400) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() /><!--- required for EFT voids --->
		
		<!--- validate object --->
		<cfset assertTrue(account.getIsValid(), "EFT is not valid") />

		<!--- first try to purchase --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<!--- then try to void transaction --->
		<cfset options["payment"] = "check" />
		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The void did not succeed") />

	</cffunction>


	
	<cffunction name="testPurchaseThenCreditEFT" access="public" returntype="void" output="false">
	
		<cfset var account = createValidEFT() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />

		
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.credit(account = account, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can credit a purchase") />

	</cffunction>


	<cffunction name="testPurchaseThenRefundEFT" access="public" returntype="void" output="false">
	
		<cfset var account = createValidEFT() />
		<cfset var money = variables.svc.createMoney(randRange(40, 100) * 100) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var transId = "" />
		<cfset var options = structNew() />
		<cfset options["payment"] = "check" />

		
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.refund(transactionid = response.getTransactionID(), money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can refund a purchase") />


		<!--- try multi-partial refund and overage --->
		<cfset money = variables.svc.createMoney(randRange(40, 100) * 100) />
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset transId = response.getTransactionID() />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset money = variables.svc.createMoney(money.getAmount()*100/2) />
		<cfset response = gw.refund(transactionid = transID, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can partially refund a purchase") />

		<cfset response = gw.refund(transactionid = transID, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "You can partial refund the remaining balance of a purchase") />

		<cfset response = gw.refund(transactionid = transID, money = money, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "You can't refund for more than the original charge") />

	</cffunction>


	<cffunction name="testUpperCaseParameters" access="public" returntype="void" output="false">
	
		<!--- gateway will lower-case all params per BT requirements: transactionId not valid, but transactionid valid --->
		<cfset report = gw.status(TransactionId = "11111111") />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.getSuccess() AND arrayLen(report.getParsedResult().xmlRoot.xmlChildren) EQ 0, "Invalid transactionid should result in no returned matches") />

	</cffunction>

<!---
	<cffunction name="testInvalidPurchases" access="public" returntype="void" output="false">
	
		<cfset var account = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset account.setAccount(5454545454545451) />
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- 5451 card will result in an error --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase did not fail with invalid CC") />

		<cfset account.setAccount(5454545454545454) />

		<!--- try invalid expiration --->
		<cfset account.setMonth(13) />
		<cfset account.setYear(year(now()) + 1) />
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase did not fail with invalid expiration date") />

		<!--- try expired card --->
		<cfset account.setMonth(5) />
		<cfset account.setYear(year(now()) - 1) />
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "iTransact gateway does not validate the expiration date so test gateway won't throw error; it is the acquiring bank's responsibility to validate/enforce it") />

	</cffunction>	
--->
	
	<cffunction name="testReportFirstDirectDeposit" access="public" returntype="void" output="false">
	
		<cfset var response = "" />
		<cfset var transactionId = 1146695977  /><!--- run testEFTDirectDeposit() and grab the ID from there --->
		<cfset var options = structNew() />

		<!--- get masked details --->
		<cfset response = gw.status(transactionId = transactionId, options = options) />
		<cfset debug(response.getParsedResult()) />
		<cfset assertTrue(response.getSuccess(), "The status report did not succeed, get a new transaction Id from EFTDirectDeposit?") />
		<cfset assertTrue(arrayLen(response.getParsedResult().xmlRoot.xmlChildren) GT 0, "No record was returned from gateway, get a new transaction Id from EFTDirectDeposit?") />

	</cffunction>


	<cffunction name="testReportFirstVault" access="public" returntype="void" output="false">
	
		<cfset var response = "" />
		<cfset var options = { tokenId = '3E9A2107-1D72-822B-795B7BC564D749BF' } /><!--- the id of our GGC test token --->

		<!--- get masked details --->
		<cfset response = gw.status(options = options) />
		<cfset debug(response.getParsedResult()) />
		<cfset assertTrue(gw.hasTransaction(response.getParsedResult()), "The tokenId should generate a vault record (but may not under demo account which has different permissions)") />

	</cffunction>


	<cffunction name="responseFromStatus_success" access="public" returntype="void" output="false">
	
		<cfset var response = "" />
		<cfset var transactionId = 1538331236 /><!--- run testPurchase() and grab the ID from there --->
		<cfset var options = structNew() />

		<!--- get masked details --->
		<cfset response = gw.getResponseFromStatus(transactionId = transactionId, options = options) />
		<cfset assertTrue(isArray(response) AND arrayLen(response) EQ 1, "The result was not an array or had no children") />
		
		<cfset response = response[1] />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getStatus() NEQ variables.svc.getStatusUnprocessed(), "Transaction wasn't processed meaning the ID wasn't found at Braintree - re-run purchase() and get a new ID since Braintree cleans out their test db frequently") />
		<cfset assertTrue(response.hasError() EQ false, "There should not be a transaction error") />
		<cfset assertTrue(response.getSuccess(), "The (original) transaction should have succeeded but didn't") />
		<cfset assertTrue(response.getAVSCode() EQ "Y" AND len(response.getAVSMessage()), "AVS should have returned a 'Y' with 888/77777 values passed") />

	</cffunction>


	<cffunction name="responseFromStatus_decline" access="public" returntype="void" output="false">
	
		<cfset var response = "" />
		<cfset var transactionId = 1538331247 /><!--- run testPurchase() and grab the ID from there --->
		<cfset var options = structNew() />

		<!--- get masked details --->
		<cfset response = gw.getResponseFromStatus(transactionId = transactionId, options = options) />
		<cfset assertTrue(isArray(response) AND arrayLen(response) EQ 1, "The result was not an array or had no children") />
		
		<cfset response = response[1] />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getStatus() NEQ variables.svc.getStatusUnprocessed(), "Transaction wasn't processed meaning the ID wasn't found at Braintree - re-run purchase() and get a new ID since Braintree cleans out their test db frequently") />
		<cfset assertTrue(response.hasError() EQ false, "There should not be a transaction error") />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusDeclined(), "The (original) transaction should have been declined") />

	</cffunction>


	<cffunction name="responseFromStatus_error" access="public" returntype="void" output="false" mxunit:expectedException="cfpayment.Gateway.Error">
	
		<cfset var response = "" />
		<cfset var transactionId = 1139955126 /><!--- run testPurchase() and grab the ID from there --->
		<cfset var options = { } />

		<!--- get masked details --->
		<cfset gw.setTestMode(false) /><!--- should error out here since this transaction id doesn't exist for this user --->
		<cfset response = gw.getResponseFromStatus(transactionId = transactionId, options = options) />
		<cfset debug(response[1].getMemento()) />
		<!--- no assertions, using mxunit:expectedException --->

	</cffunction>


	<cffunction name="check_braintree_setters" output="false" access="public" returntype="any">
		<cfset gw.setTestMode(false) />
		<cfset assertTrue(gw.getSecurityKey() EQ 'zjhh9UAS7d4UkBVqa6sagBvpeT733U88', "The security key was not set through the init config object, was: #gw.getSecurityKey()#") />
		<cfset assertTrue(gw.getSecurityKeyID() EQ '1084547', "The security key id was not set through the init config object") />
	</cffunction>


	<cffunction name="test_date_conversion" output="false" access="public" returntype="void">
		<cfset var dte = createDateTime(2009, 12, 7, 16, 0, 0) />
		<cfset var dteNow = now() />
		<cfset var dteGMT = dateAdd('s', getTimeZoneInfo().utcTotalOffset, dteNow) />
		<cfset var conv = gw.dateToBraintree(dte) />
		<cfset var str = "" />

		<cfset assertTrue(dte EQ gw.braintreeToDate(conv), "The converted date didn't match (#dte# != #conv#)") />
		<cfset assertTrue(gw.dateToBraintree(dteNow) EQ gw.dateToBraintree(dteGMT, false), "dateConvert() and dateAdd() should be equivalent: #gw.dateToBraintree(dteNow)# != #gw.dateToBraintree(dteGMT, false)#") />

		<!--- create a timestamp in GMT as though it came from  Braintree --->
		<cfset dteGMT = dateConvert("local2utc", dteNow) />
		<cfset str = dateFormat(dteGMT, "yyyymmdd") & timeFormat(dteGMT, "HHmmss") />
		<cfset assertTrue(dteNow EQ gw.braintreeToDate(str), "Braintree date should convert to local time: (#dteNow# != #gw.braintreeToDate(str)# / #str#)") />
	</cffunction>


	<cffunction name="test_hash_compare" output="false" access="public" returntype="void">
		<cfset var res = "" />
		
		<cfset gw.setTestMode(false) /><!--- requires non test mode --->
		<cfset res = gw.verifyHash(orderId = '6BB3F54A-1D72-822B-79A10EF9D945F308'
									,amount = 2.50
									,response = '1' <!--- response, NOT responsetext 'SUCCESS' --->
									,transactionid = '1145735536'
									,avsresponse = 'Y'
									,cvvresponse = ''
									,time = '20091208003338'
									,hash = '68ef3051c3ffb0c106499ccd87ab5db3') />
		<cfset assertTrue(res, "The provided hash was a valid transaction and should calculate properly") />
	
		<!--- now make it fail --->
		<cfset res = gw.verifyHash(orderId = '6BB3F54A-1D72-822B-79A10EF9D945F308'
									,amount = 1.50
									,response = '1'
									,transactionid = '1145735536'
									,avsresponse = 'Y'
									,cvvresponse = ''
									,time = '20091208003338'
									,hash = '68ef3051c3ffb0c106499ccd87ab5db3') />
		<cfset assertTrue(NOT res, "Changing one character of the input values should break the hash (1.50 instead of 2.50)") />

	</cffunction>


	<cffunction name="test_hash_generate" output="false" access="public" returntype="any">
		<cfset var id = createUUID() />
		<cfset var notoken = gw.generateHash(orderId = id
										,amount = 2.50
										,date = createDateTime(2009, 12, 7, 16, 0, 0)) />
		<cfset var withtoken = gw.generateHash(orderId = id
										,amount = 2.50
										,date = createDateTime(2009, 12, 7, 16, 0, 0)
										,tokenId = 5023023) />
										
		<cfset assertTrue(len(notoken) AND len(withtoken), "Both versions should generate a hash") />
		<cfset assertTrue(notoken NEQ withtoken, "Hashes should not be equal") />
		
		<cfset withtoken = gw.generateHash(orderId = id
										,amount = 2.50
										,date = createDateTime(2009, 12, 7, 16, 0, 0)) />
		<cfset assertTrue(notoken EQ withtoken, "The same inputs should generate the same hash multiple times") />
	
	</cffunction>


	<cffunction name="testArbitraryReport" access="public" returntype="void" output="false">
	
		<cfset var report = "" />

		<cfset report = gw.status(transactionid = '1239899682') />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.getSuccess() AND arrayLen(report.getParsedResult().xmlRoot.xmlChildren) GT 0, "Transactionid should result in matches") />

	</cffunction>	




	<!--- PRIVATE HELPERS, MOCKS, ETC --->

	<cffunction name="createValidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(2010) />
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
		<cfset account.setYear(2010) />
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
		<cfset account.setYear(2010) />
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
		<cfset account.setYear(2010) />
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
		<cfset account.setYear(2010) />
		<cfset account.setVerificationValue() />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />	
	</cffunction>

	<cffunction name="createValidCardWithoutZipMatch" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.svc.createCreditCard() />
		<cfset account.setAccount(4111111111111111) />
		<cfset account.setMonth(10) />
		<cfset account.setYear(2010) />
		<cfset account.setVerificationValue() />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("95030") />

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
