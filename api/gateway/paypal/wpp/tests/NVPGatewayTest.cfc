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


	Create gateway configuration file: NVPGatewayTest.properties (remove leading whitespace):
		gateway.username=paypal_99999999_biz_api1.paypal.com
		gateway.password=abc123xyz789
		gateway.credentialType=signature
		gateway.signature=random_character_string
		gateway.certificate=
		gateway.apiVersion=56.0
		gateway.returnURL=http://localhost/cfpayment/api/gateway/paypal/wpp/tests/NVPGatewayTest.cfc?method=testRemote&method=testCompleteExpressCheckout
		gateway.cancelURL=http://localhost/cfpayment/api/gateway/paypal/wpp/tests/NVPGatewayTest.cfc?method=testRemote&method=testCancelExpressCheckout
		gateway.testMode=true

		validCustomer.firstName=Jeff
		validCustomer.lastName=Lebowski
		validCustomer.address=609 Venenzia Ave.
		validCustomer.city=Venice
		validCustomer.region=CA
		validCustomer.postalCode=90291

		validCard.account=4111111111111111
		validCard.expMonth=10
		validCard.expYear=2010
		validCard.verificationValue=000

		invalidCard.account=4111111111111111
		invalidCard.expMonth=10
		invalidCard.expYear=2010
		invalidCard.verificationValue=000

		purchase.amount=4995
		purchase.bogusAmount=0
		purchase.currency=USD
		purchase.bogusCurrency=XXX
		purchase.ipAddress=10.1.1.1
		purchase.bogusIPAddress=ipaddr

		paypalCustomer.firstName=Test
		paypalCustomer.lastName=User
		paypalCustomer.email=paypal_99999999_per@paypal.com
--->
<cfcomponent extends="mxunit.framework.TestCase">

	<cfset variables.core = "null" />
	<cfset variables.gateway = "null" />
	<cfset variables.configFile = reReplaceNoCase(getMetaData(this).path, "\.cfc$", ".properties") />

	<cffunction name="setUp" returntype="void" access="public" output="false">
		<cfset var gatewayConfig = readProperties("gateway") />

		<cfset gatewayConfig.path = "paypal.wpp.NVPGateway" />
		<cfset variables.core = createObject("component", "cfpayment.api.core").init(config=gatewayConfig) />
		<cfset variables.gateway = variables.core.getGateway() />
	</cffunction>

	<cffunction name="testPurchase" returntype="void" access="public" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var response = "null" />
		<cfset var money = "null" />
		<cfset var options = structNew() />

		<!--- Valid card, proper amount --->
		<cfset options.ipAddress = purchase.ipAddress />
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.purchase(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The purchase should have succeeded.") />

		<!--- Invalid card --->
		<cfset response = variables.gateway.purchase(money=money, account=createInvalidCard(), options=options) />
		<cfset assertTrue(not response.getSuccess(), "The purchase should not have succeeded, due to invalid credit card.") />

		<!--- Bad IP Address --->
		<cfset options.ipAddress = purchase.bogusIPAddress />
		<cfset response = variables.gateway.purchase(money=money, account=createInvalidCard(), options=options) />
		<cfset assertTrue(not response.getSuccess(), "The purchase should not have succeeded, due to a bogus IP address.") />

		<!--- Bad purchase amount --->
		<cfset money = variables.core.createMoney(cents=purchase.bogusAmount, currency=purchase.currency) />
		<cfset response = variables.gateway.purchase(money=money, account=createInvalidCard(), options=options) />
		<cfset assertTrue(not response.getSuccess(), "The purchase should not have succeeded, due to invalid amount.") />

		<!--- Bogus currency --->
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.bogusCurrency) />
		<cfset response = variables.gateway.purchase(money=money, account=createInvalidCard(), options=options) />
		<cfset assertTrue(not response.getSuccess(), "The purchase should not have succeeded, due to a bogus currency.") />

		<!--- Duplicate Invoices --->

		<!--- AVS Validation --->

		<!--- CVV2 Validation --->

		<!--- Expiration Validation --->
	</cffunction>




	<cffunction name="testBeginExpressCheckout" returntype="void" access="public" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var response = "null" />
		<cfset var money = "null" />
		<cfset var tokenId = "" />

		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.setExpressCheckout(money) />
		<cfset assertTrue(response.getSuccess(), "The gateway response should have been successful.") />
		<cfset tokenId = response.getTokenId() />
		<cfset assertTrue(tokenId neq "", "The response token should not be an empty string.") />
		<cflocation url="#variables.gateway.getExpressCheckoutForward(tokenId)#" addtoken="false" />
	</cffunction>

	<cffunction name="testCompleteExpressCheckout" returntype="void" access="public" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var customer = readProperties("paypalCustomer") />
		<cfset var response = "null" />
		<cfset var money = "null" />
		<cfset var data = "null" />
		<cfset var options = structNew() />

		<cfset assertTrue(structKeyExists(url, "token"), "The URL should contain the PayPal Express Checkout token parameter.") />
		<cfset assertTrue(structKeyExists(url, "payerId"), "The URL should contain the PayPal Express Checkout payerId parameter.") />
		<cfset options.tokenId = URL.token />
		<cfset options.payerId = URL.payerId />

		<!--- Get the details of the PayPal customer --->
		<cfset response = variables.gateway.getExpressCheckoutDetails(options) />
		<cfset assertTrue(response.getSuccess(), "The gateway response should have been successful.") />
		<cfset data = response.getParsedResult() />
		<cfset assertTrue(structKeyExists(data, "email") and data.email eq customer.email, "The PayPal customer e-mail address should have been #customer.email#.") />
		<cfset assertTrue(structKeyExists(data, "firstName") and data.firstName eq customer.firstName, "The PayPal customer first name should have been #customer.firstName#.") />
		<cfset assertTrue(structKeyExists(data, "lastName") and data.lastName eq customer.lastName, "The PayPal customer last name should have been #customer.lastName#.") />

		<!--- Complete the payment --->
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.doExpressCheckoutPayment(money, options) />
		<cfset assertTrue(response.getSuccess(), "The gateway response should have been successful.") />
		<cfset assertTrue(response.getTransactionId() neq "", "The response transactionId should not be an empty string.") />
	</cffunction>

	<cffunction name="testCancelExpressCheckout" returntype="void" access="public" output="false">
		<cfset var options = structNew() />

		<cfset options.tokenId = URL.token />
		<cfset assertTrue(options.tokenId neq "", "The token should be passed in as a URL parameter.") />
		<cfset variables.gateway.cancelExpressCheckout(options) />
	</cffunction>

	<cffunction name="testAuthorizeOnly" access="public" returntype="void" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var response = "null" />
		<cfset var money = "null" />
		<cfset var options = structNew() />

		<cfset options.ipAddress = purchase.ipAddress />
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.authorize(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorize did not succeed") />
	</cffunction>

	<cffunction name="testAuthorizeThenCapture" access="public" returntype="void" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var money = "null" />
		<cfset var response = "null" />
		<cfset var options = structNew() />

		<cfset options.ipAddress = purchase.ipAddress />
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.authorize(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = variables.gateway.capture(money=money, authorization=response.getTransactionId(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The capture did not succeed") />
	</cffunction>

	<cffunction name="testAuthorizeThenCredit" access="public" returntype="void" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var money = "null" />
		<cfset var response = "null" />
		<cfset var options = structNew() />

		<cfset options.ipAddress = purchase.ipAddress />
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.authorize(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = variables.gateway.credit(transactionid=response.getTransactionID(), money=money, options=options) />
		<cfset assertTrue(NOT response.getSuccess(), "You cannot credit a preauth") />
	</cffunction>

	<cffunction name="testAuthorizeThenVoid" access="public" returntype="void" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var money = "null" />
		<cfset var response = "null" />
		<cfset var options = structNew() />
		<cfset var account = createValidCard() />

		<cfset options.ipAddress = purchase.ipAddress />
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.authorize(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The authorization did not succeed") />

		<cfset response = variables.gateway.void(transactionid=response.getTransactionID(), options=options) />
		<cfset assertTrue(NOT response.getSuccess(), "The void of an authorization did not succeed") />
	</cffunction>

	<cffunction name="testPurchaseThenCredit" access="public" returntype="void" output="false">
		<cfset var purchase = readProperties("purchase") />
		<cfset var money = "null" />
		<cfset var response = "null" />
		<cfset var options = structNew() />

		<cfset options.ipAddress = purchase.ipAddress />
		<cfset money = variables.core.createMoney(cents=purchase.amount, currency=purchase.currency) />
		<cfset response = variables.gateway.purchase(money=money, account=createValidCard(), options=options) />
		<cfset assertTrue(response.getSuccess(), "The purchase did not succeed") />

		<cfset response = variables.gateway.credit(transactionid=response.getTransactionID(), money=money, options=options) />
		<cfset assertTrue(response.getSuccess(), "The credit of a purchase did not succeed") />
	</cffunction>



	<cffunction name="createValidCard" access="private" returntype="any" output="false">
		<cfset var account = variables.core.createCreditCard() />
		<cfset var validCustomer = readProperties("validCustomer") />
		<cfset var validCard = readProperties("validCard") />

		<cfset account.setAccount(validCard.account) />
		<cfset account.setMonth(validCard.expMonth) />
		<cfset account.setYear(validCard.expYear) />
		<cfset account.setFirstName(validCustomer.firstName) />
		<cfset account.setLastName(validCustomer.lastName) />
		<cfset account.setAddress(validCustomer.address) />
		<cfset account.setPostalCode(validCustomer.postalCode) />
		<cfreturn account />
	</cffunction>

	<cffunction name="createInvalidCard" access="private" returntype="any" output="false">
		<cfset var account = variables.core.createCreditCard() />
		<cfset var validCustomer = readProperties("validCustomer") />
		<cfset var invalidCard = readProperties("invalidCard") />

		<cfset account.setAccount(invalidCard.account) />
		<cfset account.setMonth(invalidCard.expMonth) />
		<cfset account.setYear(invalidCard.expYear) />
		<cfset account.setFirstName(validCustomer.firstName) />
		<cfset account.setLastName(validCustomer.lastName) />
		<cfset account.setAddress(validCustomer.address) />
		<cfset account.setPostalCode(validCustomer.postalCode) />
		<cfreturn account />
	</cffunction>


	<cffunction name="readProperties" returntype="struct" access="private" output="false">
		<cfargument name="prefix" type="string" required="false" default="" />

		<cfset var file = variables.configFile />
		<cfset var properties = structNew() />
		<cfset var line = "" />
		<cfset var name = "" />

		<cfif not fileExists(file)>
			<cfthrow type="FileNotFoundException" message="The properties file (#file#) was not found" />
		</cfif>

		<cfloop file="#file#" index="line">
			<cfif reFindNoCase("^[\._a-z0-9]+=", line) eq 1>
				<cfset name = listFirst(line, "=") />
				<cfif arguments.prefix neq "">
					<cfif findNoCase(arguments.prefix & ".", name) eq 1>
						<cfset properties[listLast(name, ".")] = listRest(line, "=") />
					</cfif>
				<cfelse>
					<cfset properties[name] = listRest(line, "=") />
				</cfif>
			</cfif>
		</cfloop>
		<cfreturn properties />
	</cffunction>


</cfcomponent>
