<cfcomponent name="CoreTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">	

		<cfset var gw = structNew() />

		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.core");
			
			gw.path = "bogus.gateway";
			gw.GatewayID = 1;
			gw.MerchantAccount = 101010101;
			gw.Username = 'test';
			gw.Password = 'test';
			
			variables.svc.init(gw);
			
		</cfscript>
	</cffunction>


	<cffunction name="testCoreService" access="public" returntype="void" output="false">
	
		<cfset assertTrue(isObject(variables.svc.createCreditCard()), "Credit card fails") />
		<cfset assertTrue(isObject(variables.svc.createEFT()), "EFT fails") />
		<cfset assertTrue(isObject(variables.svc.getGateway()), "Gateway failed") />
		
		<cfset assertTrue(variables.svc.getVersion() EQ "SVN", "Test version method") />
		<cfset assertTrue(variables.svc.getStatusPending() EQ 1, "Status method returns wrong value") />
		
	</cffunction>


	<cffunction name="testBogusGateway" access="public" returntype="void" output="false">
	
		<cfset var cc = getValidCreditCard() />
		<cfset var gw = variables.svc.getGateway() />
		<cfset var money = variables.svc.createMoney(5000) /><!--- in cents, $50.00 --->
		<cfset var response = "" />
		<cfset var options = structNew() />
		
		<!--- verify this is a legit CC --->
		<cfset assertTrue(arrayLen(cc.validate()) EQ 0) />

		<cfset options.ExternalID = createUUID() />

		<!--- 5454 card will result in an error for bogus gateway --->
		<cfset response = gw.authorize(money = money, account = cc, options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization did not fail") />
		<cfset assertTrue(listFind(variables.svc.getStatusErrors(), response.getStatus()), "The authorization did not fail") />

		<cfset response = gw.purchase(money = money, account = cc, options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase did not fail") />
		<cfset assertTrue(listFind(variables.svc.getStatusErrors(), response.getStatus()), "The purchase did not fail") />


		<!--- now try with card numbers "1" (success) and "2" (decline) --->
		<cfset cc.setAccount(1) />
		<cfset response = gw.authorize(money = money, account = cc, options = options) />
		<cfset assertTrue(response.getSuccess(), "The authorization  did not succeed") />
		<cfset assertTrue(variables.svc.getStatusSuccessful() EQ response.getStatus(), "The authorization  was not successful") />

		<cfset response = gw.purchase(money = money, account = cc, options = options) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />
		<cfset assertTrue(variables.svc.getStatusSuccessful() EQ response.getStatus(), "The purchase was not successful") />

		
		<cfset cc.setAccount(2) />
		<cfset response = gw.authorize(money = money, account = cc, options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The authorization was not declined") />
		<cfset assertTrue(variables.svc.getStatusDeclined() EQ response.getStatus(), "The authorization  was not declined") />

		<cfset response = gw.purchase(money = money, account = cc, options = options) />
		<cfset assertTrue(NOT response.getSuccess(), "The purchase was not declined") />
		<cfset assertTrue(variables.svc.getStatusDeclined() EQ response.getStatus(), "The purchase was not declined") />

		<!--- test getting a few values from the gateway --->
		<cfset debug("Gateway ID: #variables.svc.getGateway().getGatewayID()#") />

	</cffunction>


	<cffunction name="getValidCreditCard" output="false" access="private" returntype="any">
		<cfset var cc = variables.svc.createCreditCard() />
		
		<cfset cc.setAccount(5454545454545454) />
		<cfset cc.setMonth(12) />
		<cfset cc.setYear(year(now())+1) />
		<cfset cc.setVerificationValue(123) />
		<cfset cc.setFirstName("John") />
		<cfset cc.setLastName("Doe") />
		<cfset cc.setAddress("236 N. Santa Cruz Ave") />
		<cfset cc.setPostalCode("95030") />
		
		<cfreturn cc />
	</cffunction>


</cfcomponent>
