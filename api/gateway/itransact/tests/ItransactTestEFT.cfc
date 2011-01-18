<cfcomponent name="ItransactTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">	

		<cfset var gw = structNew() />

		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.core");
			
			gw.path = "itransact.itransact_eft";
			// THESE TEST CREDENTIALS ARE PROVIDED AS A COURTESY BY ITRANSACT TO THE CFPAYMENT PROJECT
			// THERE IS NO GUARANTEE THEY WILL REMAIN ACTIVE
			// CONTACT SUPPORT@ITRANSACT.COM FOR YOUR OWN TEST ACCOUNT
			gw.MerchantAccount = 376;
			gw.Username = 'externalTest';
			gw.Password = 'externalTest123';
			gw.TestMode = true;		// defaults to true anyways

			// create gw and get reference			
			variables.svc.init(gw);
			variables.gw = variables.svc.getGateway();

			// create eft to use
			account = variables.svc.createEFT();
			account.setAccount("12345-12345");
			account.setRoutingNumber("222371863");
			account.setFirstName("John");
			account.setLastName("Doe");
			account.setAddress("236 N. Santa Cruz Ave");
			account.setPostalCode("95030");
			account.setPhoneNumber("415-555-1212");
			
		</cfscript>
	</cffunction>


	<!--- confirm authorize throws error --->
	<cffunction name="testAuthorizeThrowsException" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset options.ExternalID = createUUID() />

		<!--- authorize will throw an error for e-check --->
		<cftry>
			<cfset response = gw.authorize(money = money, account = account, options = options) />
			<cfset assertTrue(false, "EFT authorize() should fail but did not") />
			<cfcatch type="cfpayment.MethodNotImplemented">
				<cfset assertTrue(true, "EFT authorize() threw cfpayment.MethodNotImplemented") />
			</cfcatch>
		</cftry>

	</cffunction>


	<cffunction name="testPurchaseThenVoid" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(10000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset options.ExternalID = createUUID() />

		<!--- validate object --->
		<cfset assertTrue(account.getIsValid(), "EFT is not valid") />

		<!--- first try to purchase --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<!--- then try to void transaction --->
		<cfset response = gw.void(transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The void did not succeed") />

	</cffunction>


	<cffunction name="testPurchaseThenCredit" access="public" returntype="void" output="false">
	
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset options.ExternalID = createUUID() />

		<!--- first try to purchase --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<!--- now try to credit more than we charged --->
		<cfset money.setCents(15000) />
		<cfset response = gw.credit(money = money, transactionid = response.getTransactionID(), options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "Credits can't exceed original charge value") />
		
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
		<cfset assertTrue(NOT response.getSuccess(), "EFTs do not accept a direct settlement request; it is implicit") />

	</cffunction>


	<!---
	<cffunction name="testInvalidPurchases" access="public" returntype="void" output="false">
	
		<cfset var cc = variables.svc.createCreditCard() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<cfset cc.setAccount(5454545454545451) />
		<cfset cc.setMonth(12) />
		<cfset cc.setYear(year(now())+1) />
		<cfset cc.setVerificationValue(123) />
		<cfset cc.setFirstName("John") />
		<cfset cc.setLastName("Doe") />
		<cfset cc.setAddress("236 N. Santa Cruz Ave") />
		<cfset cc.setPostalCode("95030") />
		
		<cfset options.ExternalID = createUUID() />

		<!--- 5451 card will result in an error --->
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase did not fail with invalid CC") />

		<cfset cc.setAccount(5454545454545454) />

		<!--- try invalid expiration --->
		<cfset cc.setMonth(13) />
		<cfset cc.setYear(year(now()) + 1) />
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase did not fail with invalid expiration date") />

		<!--- try expired card --->
		<cfset cc.setMonth(5) />
		<cfset cc.setYear(year(now()) - 1) />
		<cfset response = gw.purchase(money = money, account = account, options = options) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase did not fail with expired card") />

	</cffunction>	
	--->
	
</cfcomponent>
