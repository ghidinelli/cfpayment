<!---

	Copyright 2009 Joseph Lamoree (http://www.lamoree.com/)
	Copyright 2008 Brian Ghidinelli (http://www.ghidinelli.com/)

	Licensed under the Apache License, Version 2.0 (the "License"); you
	may not use this file except in compliance with the License. You may
	obtain a copy of the License at:

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

--->
<cfcomponent name="NVPGatewayTest" extends="mxunit.framework.TestCase" output="false">

	<cfset variables.cfpaymentCore = "null" />
	<cfset variables.gateway = "null" />

	<cffunction name="setUp" returntype="void" access="public">

		<cfset var config = structNew() />

		<cfscript>
			config.path = "paypal.wpp.NVPGateway";
			config.username = "paypal_1243142215_biz_api1.lamoree.com";
			config.password = "1243142227";
			config.signature = "AFcWxV21C7fd0v3bYYYRCpSSRl31AD632SuLIOLLihiymINoOCODKW62";
			config.testmode = true;

			variables.cfpaymentCore = createObject("component", "cfpayment.api.core").init(config=config);
			variables.gateway = variables.cfpaymentCore.getGateway();
		</cfscript>
	</cffunction>

	<cffunction name="testPurchase" access="public" returntype="void" output="false">

		<cfset var money = variables.cfpaymentCore.createMoney(cents=5000) />
		<cfset var gw = variables.gateway />
		<cfset var response = "null" />
		<cfset var options = structNew() />

		<cfset options.email = "unittest@lamoree.com" />
		<cfset options.ipAddress = "64.81.35.1" />
		<cfset options.company = "Lamoree Software" />
		<cfset options.description = "Test Transaction" />

		<cfset response = gw.purchase(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The purchase should have succeeded.") />

		<cfset response = gw.purchase(money=money, account=createInvalidCard(), options=options) />
		<cfset assertTrue(not response.getSuccess(), "The purchase should not have succeeded, due to invalid credit card.") />

	</cffunction>

	<cffunction name="testAuthorizeOnly" access="public" returntype="void" output="false">

		<cfset var money = variables.cfpaymentCore.createMoney(cents=5000) />
		<cfset var gw = variables.gateway />
		<cfset var response = "null" />
		<cfset var options = structNew() />

		<cfset response = gw.authorize(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

	</cffunction>

	<cffunction name="testAuthorizeThenCapture" access="public" returntype="void" output="false">

		<cfset var money = variables.cfpaymentCore.createMoney(cents=5000) />
		<cfset var gw = variables.gateway />
		<cfset var response = "null" />
		<cfset var options = structNew() />
		<cfset var account = createValidCard() />

		<cfset response = gw.authorize(money=money, account=account, options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.capture(money=money, authorization=response.getTransactionId(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The capture did not succeed") />
	</cffunction>

	<cffunction name="testAuthorizeThenCredit" access="public" returntype="void" output="false">

		<cfset var money = variables.cfpaymentCore.createMoney(cents=5000) />
		<cfset var gw = variables.gateway />
		<cfset var response = "null" />
		<cfset var options = structNew() />
		<cfset var account = createValidCard() />

		<cfset response = gw.authorize(money=money, account=account, options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.credit(transactionid=response.getTransactionID(), money=money, options=options) />
		<cfset assertTrue(NOT response.getSuccess(), "You cannot credit a preauth") />
	</cffunction>

	<cffunction name="testAuthorizeThenVoid" access="public" returntype="void" output="false">

		<cfset var money = variables.cfpaymentCore.createMoney(cents=5000) />
		<cfset var gw = variables.gateway />
		<cfset var response = "null" />
		<cfset var options = structNew() />
		<cfset var account = createValidCard() />

		<cfset response = gw.authorize(money=money, account=account, options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = gw.void(transactionid=response.getTransactionID(), options=options) />
		<cfset assertTrue(NOT response.getSuccess(), "The void of an authorization did not succeed") />
	</cffunction>

	<cffunction name="testPurchaseThenCredit" access="public" returntype="void" output="false">

		<cfset var money = variables.cfpaymentCore.createMoney(cents=5000) />
		<cfset var gw = variables.gateway />
		<cfset var response = "null" />
		<cfset var options = structNew() />
		<cfset var account = createValidCard() />

		<cfset response = gw.purchase(money=money, account=account, options=options) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = gw.credit(transactionid=response.getTransactionID(), money=money, options=options) />
		<cfset assertTrue(response.getSuccess(), "The credit of a purchase did not succeed") />
	</cffunction>



	<cffunction name="createValidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.cfpaymentCore.createCreditCard() />
		<cfset account.setAccount(4940702861332472) />
		<cfset account.setMonth(05) />
		<cfset account.setYear(2019) />
		<cfset account.setVerificationValue(999) />
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("Doe") />
		<cfset account.setAddress("888") />
		<cfset account.setPostalCode("77777") />

		<cfreturn account />
	</cffunction>

	<cffunction name="createInvalidCard" access="private" returntype="any" output="false">
		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var account = variables.cfpaymentCore.createCreditCard() />
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

</cfcomponent>
