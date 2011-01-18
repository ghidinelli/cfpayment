<cfcomponent name="ItransactTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">	

		<cfset var gw = structNew() />

		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.core");
			
			gw.path = "itransact.itransact_cc";
			// THESE TEST CREDENTIALS ARE PROVIDED AS A COURTESY BY ITRANSACT TO THE CFPAYMENT PROJECT
			// THERE IS NO GUARANTEE THEY WILL REMAIN ACTIVE
			// CONTACT SUPPORT@ITRANSACT.COM FOR YOUR OWN TEST ACCOUNT
			gw.MerchantAccount = 375;
			gw.Username = 'externalTest';
			gw.Password = 'externalTest123';
			gw.TestMode = true;		// defaults to true anyways

			// create gw and get reference			
			variables.svc.init(gw);
			variables.gw = variables.svc.getGateway();
			
		</cfscript>
	</cffunction>


	<cffunction name="testAuthorizeOnly" access="public" returntype="void" output="false">
	
		<cfset var account = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset account.setAccount(5454545454545454) />
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- do some debugging --->
		<cfset debug("Endpoint: " & gw.getGatewayURL()) />

		<!--- 5454 card will result in an error for bogus gateway --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

	</cffunction>


	<cffunction name="testAuthorizeThenCaptureThenReport" access="public" returntype="void" output="false">
	
		<cfset var account = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		
		<cfset account.setAccount(5454545454545454) />
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- do some debugging --->
		<cfset debug("Endpoint: " & gw.getGatewayURL()) />

		<!--- 5454 card will result in an error for bogus gateway --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<!--- cfset debug(response.getMemento()) / --->
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<!--- now try to settle it --->
		<cfset options.InternalId = response.getTransactionId() />

		<!--- itransact doesn't actually use the authorization value, which I think is an anomaly --->
		<cfset response = gw.capture(money = money, authorization = response.getAuthorization(), options = options) />
		<!--- cfset debug(response.getMemento()) / --->
		<cfset assertTrue(response.getSuccess(), "The capture did not succeed") />

		<!--- now run a detail report on this transaction --->
		<cfset report = gw.status(transactionid = response.getTransactionID()) />
		<cfset assertTrue(report.getSuccess() AND NOT report.hasError(), "Successful transactionid should have success = true") />
		
		<!--- try getting detail with externalid --->
		<cfset report = gw.status(options = options) />
		<cfset assertTrue(report.getSuccess() AND NOT report.hasError(), "Successful externalid should have success = true") />

		<!--- pass an invalid id to see how error is handled --->
		<cfset report = gw.status(transactionid = "123456") />
		<cfset assertTrue(report.hasError(), "Invalid transactionid should result in ReportResponseFail") />
		<cfset debug(report.getMemento()) />

	</cffunction>
	

	<cffunction name="testAuthorizeThenVoid" access="public" returntype="void" output="false">
	
		<cfset var account = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset account.setAccount(5454545454545454) />
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- do some debugging --->
		<cfset debug("Endpoint: " & gw.getGatewayURL()) />

		<!--- 5454 card will result in an error for bogus gateway --->
		<cfset response = gw.authorize(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<!--- now try to void it --->
		<!--- itransact doesn't actually use the authorization value, which I think is an anomaly --->
		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "You cannot void a preauth") />

	</cffunction>
	
	
	<cffunction name="testPurchaseThenVoidThenReport" access="public" returntype="void" output="false">
	
		<cfset var account = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(10000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var id = "" />
		<cfset var report = "" />
		<cfset var options = structNew() />
		
		<cfset account.setAccount(5454545454545454) />
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- do some debugging --->
		<cfset debug("Endpoint: " & gw.getGatewayURL()) />

		<!--- 5454 card will result in an error for bogus gateway --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset id = response.getTransactionID() />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<!--- now try to void transaction --->
		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The void did not succeed") />

		<!--- now run a detail report on original transaction and void --->
		<cfset report = gw.status(transactionid = id) />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.getSuccess() AND NOT report.hasError(), "Being the original response, this should be successful even if since voided") />

		<cfset report = gw.status(transactionid = response.getTransactionID()) />
		<cfset debug(report.getMemento()) />
		<cfset assertTrue(report.getSuccess() AND NOT report.hasError(), "A successful response means the void was successfully applied") />
		

	</cffunction>


	<cffunction name="testPurchaseThenCredit" access="public" returntype="void" output="false">
	
		<cfset var account = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(10000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset account.setAccount(5454545454545454) />
		<cfset account.setMonth(12) />
		<cfset account.setYear(year(now())+1) />
		<cfset account.setVerificationValue(123) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- do some debugging --->
		<cfset debug("Endpoint: " & gw.getGatewayURL()) />

		<!--- 5454 card will result in an error for bogus gateway --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<!--- now try to credit more than we charged 
		this apparently varies based upon the merchant bank so in test mode, itransact does not validate this and returns OK
		<cfset money.setCents(15000) />
		<cfset response = gw.credit(money = money, transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "Credits can't exceed original charge value") />
		--->
		
		<!--- now perform partial credit --->
		<cfset money.setCents(5000) />
		<cfset response = gw.credit(money = money, transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "Partial credit did not succeed") />
		
	</cffunction>

	
	<cffunction name="testSettle" access="public" returntype="void" output="false">
	
		<cfset var response = "" />
		<cfset var options = structNew() />

		<cfset options.ExternalID = createUUID() />

		<cfset response = gw.settle(options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The settlement did not succeed") />

	</cffunction>


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
	
</cfcomponent>
