<!---
	$Id$
	
	Port of Phil Cruz's Stripe.cfc from https://github.com/philcruz/Stripe.cfc/blob/master/stripe/Stripe.cfc
	Copyright 2011 Phil Cruz (http://www.philcruz.com/), Brian Ghidinelli (http://www.ghidinelli.com)
	
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
<cfcomponent displayname="Stripe Gateway" extends="cfpayment.api.gateway.base" hint="Stripe Gateway" output="false">

	<cfset variables.cfpayment.GATEWAY_NAME = "Stripe" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0.6" />
	<cfset variables.cfpayment.API_VERSION = "2015-02-18" />
	<!--- stripe test mode uses different credentials instead of different urls --->
	<cfset variables.cfpayment.GATEWAY_URL = "https://api.stripe.com/v1" />

	
	<cffunction name="getSecretKey" access="public" output="false" returntype="string">		
		<cfif getTestMode()>
			<cfreturn variables.cfpayment.TestSecretKey />
		<cfelse>
			<cfreturn variables.cfpayment.LiveSecretKey />
		</cfif>
	</cffunction>
	<cffunction name="getLiveSecretKey" access="public" output="false" returntype="string">
		<cfreturn variables.cfpayment.LiveSecretKey />
	</cffunction>
	<cffunction name="setLiveSecretKey" access="public" output="false" returntype="void">
		<cfargument name="LiveSecretKey" type="string" required="true" />
		<cfset variables.cfpayment.LiveSecretKey = arguments.LiveSecretKey />
	</cffunction>
	<cffunction name="getTestSecretKey" access="public" output="false" returntype="string">
		<cfreturn variables.cfpayment.TestSecretKey />
	</cffunction>
	<cffunction name="setTestSecretKey" access="public" output="false" returntype="void">
		<cfargument name="TestSecretKey" type="string" required="true" />
		<cfset variables.cfpayment.TestSecretKey = arguments.TestSecretKey />
	</cffunction>
	
	<cffunction name="getPublishableKey" access="public" output="false" returntype="string">		
		<cfif getTestMode()>
			<cfreturn variables.cfpayment.TestPublishableKey />
		<cfelse>
			<cfreturn variables.cfpayment.LivePublishableKey />
		</cfif>
	</cffunction>
	
	<cffunction name="getLivePublishableKey" access="public" output="false" returntype="string">
		<cfreturn variables.cfpayment.LivePublishableKey />
	</cffunction>
	<cffunction name="setLivePublishableKey" access="public" output="false" returntype="void">
		<cfargument name="LivePublishableKey" type="string" required="true" />
		<cfset variables.cfpayment.LivePublishableKey = arguments.LivePublishableKey />
	</cffunction>	
	<cffunction name="getTestPublishableKey" access="public" output="false" returntype="string">
		<cfreturn variables.cfpayment.TestPublishableKey />
	</cffunction>
	<cffunction name="setTestPublishableKey" access="public" output="false" returntype="void">
		<cfargument name="TestPublishableKey" type="string" required="true" />
		<cfset variables.cfpayment.TestPublishableKey = arguments.TestPublishableKey />
	</cffunction>	

	<cffunction name="getApiVersion" access="public" output="false" returntype="string">
		<cfreturn variables.cfpayment.API_VERSION />
	</cffunction>
	<cffunction name="setApiVersion" access="public" output="false" returntype="void">
		<cfset variables.cfpayment.API_VERSION = arguments[1] />
	</cffunction>

	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Authorize + Capture in one step - only approach supported by Stripe">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="false" />		
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />				
		
		<cfset var post = {} />
		<cfset var response = "" />

		<cfset post["amount"] = arguments.money.getCents() />		
		<cfset post["currency"] = lCase(arguments.money.getCurrency()) /><!--- iso currency code must be lower case? --->
		
		<cfif structKeyExists(arguments, "account")>
		
			<cfswitch expression="#getService().getAccountType(arguments.account)#">
				<cfcase value="creditcard">
					<cfset post = addCreditCard(post = post, account = arguments.account) />
				</cfcase>
				<cfcase value="token">
					<cfset post = addToken(post = post, account = arguments.account) />
				</cfcase>
				<cfdefaultcase>
					<cfthrow type="cfpayment.InvalidAccount" message="The account type #getService().getAccountType(arguments.account)# is not supported by this gateway." />
				</cfdefaultcase>
			</cfswitch>
		
		</cfif>
		
		<cfreturn process(gatewayUrl = getGatewayUrl("/charges"), payload = post, options = options) />
	</cffunction>


	<cffunction name="refund" access="public" output="false" returntype="any" hint="Returns an amount back to the previously charged account.  Default is to refund the full amount.">
		<cfargument name="money" type="any" required="false" />
		<cfargument name="transactionId" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		
		<!--- default is to refund full amount --->
		<cfif structKeyExists(arguments, "money")>
			<cfset post["amount"] = abs(arguments.money.getCents()) />
		</cfif>

		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#trim(arguments.transactionId)#/refund"), payload = post, options = options) />
	</cffunction>


	<cffunction name="search" access="public" output="false" returntype="any" hint="Find transactions using gateway-supported criteria">
		<cfargument name="options" type="struct" required="true" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>


	<cffunction name="status" access="public" output="false" returntype="any" hint="Reconstruct a response object for a previously executed transaction">
		<cfargument name="transactionId" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.transactionId#"), method = "get", options = options) />
	</cffunction>

	
	<cffunction name="validate" output="false" access="public" returntype="any" hint="Convert credit card details to a one-time token for charging later.  To store payment details for use later, use a customer object with store().">
		<cfargument name="account" type="any" required="true" />
		<cfargument name="money" type="any" required="false" />

		<cfset var post = "" />

		<cfif getService().getAccountType(account) EQ "creditcard">
			<cfset post = addCreditCard(post = structNew(), account = arguments.account) />
		<cfelseif getService().getAccountType(account) EQ "eft">
			<cfset post = addBankAccount(post = structNew(), account = arguments.account) />
		</cfif>
		
		<cfreturn process(gatewayUrl = getGatewayURL("/tokens"), payload = post) />
	</cffunction>


	<cffunction name="store" output="false" access="public" returntype="any" hint="Convert a one-time token (from validate() or Stripe.js) into a Customer object for charging one or more times in the future">
		<cfargument name="account" type="any" required="true" /><!--- must be type of "token"? --->
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = {} />
		
		<cfif getService().getAccountType(account) EQ "creditcard">
			<cfset post = addCreditCard(post = post, account = account) />
		<cfelseif getService().getAccountType(account) EQ "eft">
			<cfset post = addBankAccount(post = post, account = account) />
		<cfelse>
			<cfset post["card"] = arguments.account.getID() />
		</cfif>

		<!--- optional things to add --->
		<cfif structKeyExists(arguments.options, "coupon")>
			<cfset post["coupon"] = arguments.options.coupon />
		</cfif>
		<cfif structKeyExists(arguments.options, "account_balance")>
			<cfset post["account_balance"] = arguments.options.account_balance />
		</cfif>
		<cfif structKeyExists(arguments.options, "plan")>
			<cfset post["plan"] = arguments.options.plan />
		</cfif>
		<cfif structKeyExists(arguments.options, "trial_end")>
			<cfset post["trial_end"] = dateToUTC(arguments.options.trial_end) />
		</cfif>
		<cfif structKeyExists(arguments.options, "quantity")>
			<cfset post["quantity"] = arguments.options.quantity />
		</cfif>
		
		<cfreturn process(gatewayUrl = getGatewayURL("/customers"), payload = post, options = options) />
	</cffunction>


	<cffunction name="unstore" output="false" access="public" returntype="any">
		<cfargument name="tokenId" type="string" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/customers/#arguments.tokenId#"), method = "delete") />
	</cffunction>


	<cffunction name="listCharges" output="false" access="public" returntype="any">
		<cfargument name="count" type="numeric" required="false" />
		<cfargument name="offset" type="numeric" required="false" />
		<cfargument name="tokenId" type="string" required="false" />
	
		<cfset var payload = {} />
		
		<cfloop collection="#arguments#" item="key">
			<cfif structKeyExists(arguments, key)>
				<cfset payload[lcase(key)] = arguments[key] />
			</cfif>
		</cfloop>
	
		<cfreturn process(gatewayUrl = getGatewayUrl("/charges"), method = "get", payload = payload) />
	</cffunction>


	<cffunction name="getToken" output="false" access="public" returntype="any" hint="Retrieve details about a one-time use token">
		<cfargument name="id" type="any" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/tokens/#arguments.id#"), payload = {}, options = {}, method = "get") />
	</cffunction>


	<cffunction name="createToken" output="false" access="public" returntype="any" hint="Convert a credit card or bank account into a one-time Stripe token for charging/attaching to a customer, or disbursing/attaching to a recipient (note, using this rather than Stripe.js means you are responsible for ALL PCI DSS compliance)">
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = {} />
		
		<cfswitch expression="#getService().getAccountType(arguments.account)#">
			<cfcase value="creditcard">
				<cfset post = addCreditCard(post = post, account = arguments.account) />
			</cfcase>
			<cfcase value="eft">
				<cfset post = addBankAccount(post = post, account = arguments.account) />
			</cfcase>
			<cfdefaultcase>
				<cfthrow type="cfpayment.InvalidAccount" message="The account type #getService().getAccountType(arguments.account)# is not supported by createToken()" />
			</cfdefaultcase>
		</cfswitch>
		
		<cfreturn process(gatewayUrl = getGatewayURL("/tokens"), payload = post, options = options) />
	</cffunction>
	
	<cffunction name="getCustomerTokenForSpecificAccount" output="false" access="public" returntype="any" hint="Get a token for an existing customer)">
		<cfargument name="customer" type="any" required="true" />
		<cfargument name="connectedAccount" type="any" required="true" />

		<cfset var headers = {} />
		<cfset headers["authorization"] = arguments.connectedAccount />
		<cfset var post = {} />
		<cfset post["customer"] = arguments.customer />
		
		<cfreturn process(gatewayUrl = getGatewayURL("/tokens"), payload = post, headers = headers) />
	</cffunction>

	<cffunction name="createAccount" output="false" access="public" returntype="any" hint="Provisions a marketplace account">
		<cfargument name="country" type="string" required="true" />
		<cfargument name="managed" type="boolean" required="false" default="" />
		<cfargument name="transfers_only" type="boolean" required="false" default="" />
		<cfargument name="email" type="string" required="false" default="" />
		<cfargument name="statement_descriptor" type="string" required="false" default="" />
		<cfargument name="display_name" type="string" required="false" default="" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset local.post = {} />
		
		<!--- three set-only and important fields: country, managed, transfers_only.  We will do managed = true, transfers_only = false --->
		<cfset post["country"] = arguments.country />
		<cfset post["managed"] = arguments.managed />
		<cfset post["transfers_only"] = arguments.transfers_only />
		<cfset post["email"] = arguments.email />
		<cfset post["statement_descriptor"] = arguments.statement_descriptor />
		<cfset post["display_name"] = arguments.display_name />

		<cfreturn process(gatewayUrl = getGatewayURL("/accounts"), payload = post, options = options) />
	</cffunction>

	

	<!--- determine capability of this gateway --->
	<cffunction name="getIsCCEnabled" access="public" output="false" returntype="boolean" hint="determine whether or not this gateway can accept credit card transactions">
		<cfreturn true />
	</cffunction>


	<!--- process wrapper with gateway/transaction error handling --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="gatewayUrl" type="string" required="true" />
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="method" type="string" required="false" default="post" />
		<cfargument name="files" type="struct" required="false" default="#structNew()#" />

		<cfset var results = "" />
		<cfset var response = "" />
		<cfset var p = arguments.payload /><!--- shortcut (by reference) --->

		<!--- add authentication, if its not provided --->
		<cfif structKeyExists(headers,"authorization") AND headers["authorization"] neq "">
			<cfset headers["authorization"] = "Bearer #headers['authorization']#" />
		<cfelse>
			<cfset headers["authorization"] = "Bearer #getSecretKey()#" />
		</cfif>
		<!--- if we want to override the stripe API version, we can set it in the config with "ApiVersion".  Using 'latest' overrides to current version --->
		<cfif len(getApiVersion())>
			<!--- https://groups.google.com/a/lists.stripe.com/forum/#!topic/api-discuss/V4sYRlHwalc --->
			<cfset headers["Stripe-Version"] = getApiVersion() />
		</cfif>
		<!--- help track where this request was made from --->
		<cfset headers["User-Agent"] = "Stripe/v1 cfpayment/#variables.cfpayment.GATEWAY_VERSION#" />

		<!--- process standard and common CFPAYMENT mappings into Braintree-specific values --->
		<cfif structKeyExists(arguments.options, "description")>
			<cfset p["description"] = arguments.options.description />
		</cfif>
		<cfif structKeyExists(arguments.options, "tokenId")>
			<cfset p["customer"] = arguments.options.tokenId />
		</cfif>

		<!--- add dynamic statement descriptors which show up on CC statement alongside merchant name: https://stripe.com/docs/api#create_charge --->
		<cfif structKeyExists(arguments.options, "statement_descriptor")>
			<cfset p["statement_descriptor"] = reReplace(arguments.options.statement_descriptor, "[<>""']", "", "ALL") />
		</cfif>

		<!--- Stripe returns errors with http status like 400,402 or 404 (https://stripe.com/docs/api#errors) --->		
		<cfset response = createResponse(argumentCollection = super.process(url = arguments.gatewayUrl, payload = payload, headers = headers, method = arguments.method, files = files)) />


		<cfif isJSON(response.getResult())>

			<cfset results = deserializeJSON(response.getResult()) />
			<cfset response.setParsedResult(results) />
			
			<!--- handle common response fields --->
			<cfif structKeyExists(results, "card") OR structKeyExists(results, "active_card")>

				<!--- have the same fields below but different depending on context from charging or creating customers --->
				<cfif structKeyExists(results, "active_card")>
					<cfset results.card = results.active_card />
				</cfif>

				<!--- translate to normalized cfpayment CVV codes --->			
				<cfif structKeyExists(results.card, "cvc_check")>
					<cfif results.card.cvc_check EQ "pass">
						<cfset response.setCVVCode("M") />
					<cfelseif results.card.cvc_check EQ "fail">
						<cfset response.setCVVCode("N") />
					<cfelse>
						<cfset response.setCVVCode("P") />
					</cfif>
				</cfif>

				<!--- translate to normalized cfpayment AVS codes --->
				<cfif structKeyExists(results.card, "address_zip_check")>
					<cfif results.card.address_zip_check EQ "pass" AND results.card.address_line1_check EQ "pass">
						<cfset response.setAVSCode("M") />
					<cfelseif results.card.address_zip_check EQ "pass">
						<cfset response.setAVSCode("P") />
					<cfelseif results.card.address_line1_check EQ "pass">
						<cfset response.setAVSCode("B") />
					<cfelseif results.card.address_zip_check EQ "unchecked" OR results.card.address_line1_check EQ "unchecked">
						<cfif results.card.country EQ "US">
							<cfset response.setAVSCode("S") />
						<cfelse>
							<cfset response.setAVSCode("G") />
						</cfif>
					<cfelse>
						<cfset response.setAVSCode("N") />
					</cfif>
				</cfif>
				
				<cfif structKeyExists(results.card, "fingerprint")>
					<cfset response.setAuthorization(results.card.fingerprint) />
				</cfif>
			</cfif>
			
			<cfif structKeyExists(results, "id")>
				<cfset response.setTransactionID(results.id) />
			</cfif>
				
			<cfif structKeyExists(results, "customer") AND results.customer NEQ "null">
				<cfset response.setTokenID(results.customer) />
			</cfif>
			
			<!--- not sure if this is right? 
			<cfif structKeyExists(results, "bank_account") AND structKeyExists(results.bank_account, "id")>
				<cfset response.setTransactionId(results.bank_account.id) />
			</cfif> --->

		</cfif>
		
		<!--- now add custom handling of status codes for Stripe which overrides base.cfc --->
		<cfset handleHttpStatus(response = response) />

		<cfreturn response />
	</cffunction>


	<!--- 
	//Stripe returns errors with http status like 400, 402 or 404 (https://stripe.com/docs/api#errors)
	//so we need to override http status handling in base.cfc process()
	 --->
	<cffunction name="handleHttpStatus" access="private" returntype="any" output="false" hint="Override base HTTP status code handling with Stripe-specific results">
		<cfargument name="response" type="any" required="true" />		

		<!--- 
			HTTP Status Code Summary
			200 OK - Everything worked as expected.
			400 Bad Request - Often missing a required parameter.
			401 Unauthorized - No valid API key provided.
			402 Request Failed - Parameters were valid but request failed.
			404 Not Found - The requested item doesn't exist.
			500, 502, 503, 504 Server errors - something went wrong on Stripe's end.

			Errors
			Invalid Request Errors
			Type: invalid_request_error

			API Errors
			Type: api_error

			Card Errors
			Type: card_error

			Code	Details
			incorrect_number	The card number is incorrect
			invalid_number	The card number is not a valid credit card number
			invalid_expiry_month	The card's expiration month is invalid
			invalid_expiry_year	The card's expiration year is invalid
			invalid_cvc	The card's security code is invalid
			expired_card	The card has expired
			incorrect_cvc	The card's security code is incorrect
			card_declined	The card was declined.
			missing	There is no card on a customer that is being charged.
			processing_error	An error occurred while processing the card.		
		--->
		<cfscript>
			var status = response.getStatusCode();
			var res = response.getParsedResult();

			switch(status)
			{
				case "200": // OK - Everything worked as expected.
					response.setStatus(getService().getStatusSuccessful());
					break;

				case "401": // Unauthorized - No valid API key provided.
					response.setMessage("There is a configuration error preventing the transaction from completing successfully.  Please call 415.462.5603 for customer service.  (Original issue: Invalid API key)");
					response.setStatus(getService().getStatusFailure());
					break;

				case "402": //  Request Failed - Parameters were valid but request failed. e.g. invalid card, cvc failed, etc.
					response.setStatus(getService().getStatusDeclined());
					break;

				case "400": // Bad Request - Often missing a required parameter, includes parameter not allowed or params not lowercase
				case "404": // Not Found - The requested item doesn't exist.  i.e. no charge for that id
					response.setStatus(getService().getStatusFailure());
					break;

				case "500": // Server errors - something went wrong on Stripe's end.
				case "502":
				case "503":
				case "504":
					response.setStatus(getService().getStatusFailure());
					break;
			}

			if (response.hasError() AND isStruct(res) AND structKeyExists(res, "error"))
			{
				if (structKeyExists(res.error, "message"))
					response.setMessage(res.error.message);

				if (structKeyExists(res.error, "code"))
				{
					switch (res.error.code)
					{
						case "incorrect_number":
						case "invalid_number":
						case "invalid_expiry_month":
						case "invalid_expiry_year":
						case "invalid_cvc":
						case "expired_card":
						case "incorrect_cvc":
						case "card_declined":
						case "missing":
						case "processing_error":
							// can do more involved translation to human-speak here
							response.setMessage(response.getMessage() & " [#res.error.code#]");
							break;
						default:
							response.setMessage(response.getMessage() & " [#res.error.code#]");
					}
				}
				else
				{
					response.setMessage("Gateway returned unknown response: #status#");
				}
			}
		</cfscript>
		
		<cfreturn response />
	</cffunction>


	<cffunction name="getGatewayURL" access="public" output="false" returntype="any" hint="Append to Gateway URL to return the appropriate url for the API endpoint">
		<cfargument name="endpoint" type="string" required="false" default="" />
		<cfreturn variables.cfpayment.GATEWAY_URL & arguments.endpoint />
	</cffunction>
 

	<!--- HELPER FUNCTIONS  --->
	<cffunction name="addCreditCard" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />

		<cfscript>
			post["card[number]"] = arguments.account.getAccount();
			post["card[exp_month]"] = arguments.account.getMonth();
			post["card[exp_year]"] = arguments.account.getYear();
			post["card[cvc]"] = arguments.account.getVerificationValue();
			post["card[name]"] = arguments.account.getName();
			post["card[address_line1]"] = arguments.account.getAddress();
			post["card[address_line2]"] = arguments.account.getAddress2();
			post["card[address_zip]"] = arguments.account.getPostalCode();
			post["card[address_state]"] = arguments.account.getRegion();
			post["card[address_country]"] = arguments.account.getCountry();
		</cfscript>
	
		<cfreturn post />
	</cffunction>


	<cffunction name="addBankAccount" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />

		<cfscript>
			post["bank_account[country]"] = arguments.account.getCountry();
			post["bank_account[routing_number]"] = arguments.account.getRoutingNumber();
			post["bank_account[account_number]"] = arguments.account.getAccount();
		</cfscript>
	
		<cfreturn post />
	</cffunction>
	

	<cffunction name="addToken" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />
		
		<!--- required when using as a payment source --->
		<cfif findNoCase("cus_", arguments.account.getID())>
			<cfset arguments.post["customer"] = arguments.account.getID() />
		<cfelse>
			<cfset arguments.post["source"] = arguments.account.getID() />
		</cfif>

		<cfreturn arguments.post />
	</cffunction>


	<cffunction name="dateToUTC" output="false" access="public" returntype="any" hint="Take a date and return the number of seconds since the Unix Epoch">
		<cfargument name="date" type="any" required="true" />
		<cfreturn dateDiff("s", dateConvert("utc2Local", "January 1 1970 00:00"), arguments.date) />
	</cffunction>
	
	<cffunction name="UTCToDate" output="false" access="public" returntype="date" hint="Take a UTC timestamp and convert it to a ColdFusion date object">
		<cfargument name="utcdate" required="true" />
		<cfreturn dateAdd("s", arguments.utcDate, dateConvert("utc2Local", "January 1 1970 00:00")) />
	</cffunction>


	<!--- stripe createResponse() overrides the getSuccess/hasError() responses --->
	<cffunction name="createResponse" access="public" output="false" returntype="any" hint="Create a Braintree response object with status set to unprocessed">
		<cfreturn createObject("component", "cfpayment.api.gateway.stripe.response").init(argumentCollection = arguments, service = getService()) />
	</cffunction>



<!--- Marketplace --->

	<!--- Accounts --->
	<cffunction name="marketplaceCreateConnectedAccount" output="false" access="public" returntype="any" hint="">
		<cfset local.post = addCreateManagedAccountData(post = structNew()) />
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts"), payload = local.post) />
	</cffunction>
	
	<cffunction name="marketplaceUpdateConnectedAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="updates" type="any" required="true" />
		<cfset local.post = updateAccountData(post = structNew(), updates = arguments.updates) />
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#"), payload = local.post) />
	</cffunction>
	
	<cffunction name="marketplaceListConnectedAccounts" output="false" access="public" returntype="any" hint="">
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts"), payload = structNew(), method="get") />
	</cffunction>

	<!--- Bank Accounts --->
	<cffunction name="marketplaceFetchBankAccounts" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#/bank_accounts"), payload = structNew(), method="get") />
	</cffunction>

	<cffunction name="marketplaceCreateBankAccountWithToken" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="token" type="any" required="false" />		
		<cfset local.post = structNew() />
		<cfset local.post["bank_account"] = arguments.token />
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#/bank_accounts"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceUpdateBankAccountDefaultForCurrency" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="bankAccountId" type="any" required="false" />		
		<cfset local.post = structNew() />
		<cfif structKeyExists(arguments, "money")>
			<cfset local.post["default_for_currency"] = true />
		</cfif>
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#/bank_accounts/#arguments.bankAccountId#"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceDeleteBankAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="bankAccountId" type="any" required="false" />		
		<cfset local.post = structNew() />
		<!---<cfset post["DELETE"] = "" />--->
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#/bank_accounts/#arguments.bankAccountId#"), payload = local.post, method="delete") />
	</cffunction>

	<cffunction name="marketplaceCreateBankAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />
		<cfargument name="account" type="any" required="false" />
		<cfset local.post = structNew() />
		<cfset local.post["bank_account[country]"] = getCountryCodeFromCountry(arguments.account.getCountry()) />
		<cfset local.post["bank_account[currency]"] = 'cad' />
		<cfset local.post["bank_account[account_number]"] = arguments.account.getAccount() />
		<cfset local.post["bank_account[routing_number]"] = arguments.account.getRoutingNumber() />
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#/bank_accounts"), payload = local.post) />
	</cffunction>

	<!--- Identity Verification --->
	<cffunction name="marketplaceUploadIdentityFile" output="false" access="public" returntype="any" hint="">
		<cfargument name="accountSecret" type="any" required="false" />
		<cfargument name="file" type="any" required="false" />
		<cfset local.files = structNew() />
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
		<cfset local.files["file"] = arguments.file />
		<cfset local.post["purpose"] = "identity_document" />
		<cfif structKeyExists(arguments, "accountSecret") AND arguments.accountSecret neq "">
			<cfset local.headers["authorization"] = arguments.accountSecret />
		</cfif>
		<cfreturn process(gatewayUrl = "https://uploads.stripe.com/v1/files", payload = local.post, headers = local.headers, files = local.files) />
	</cffunction>

	<cffunction name="marketplaceAttachFileToAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="accountSecret" type="any" required="false" />
		<cfargument name="fileId" type="any" required="false" />		
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
		<cfif structKeyExists(arguments, "accountSecret") AND arguments.accountSecret neq "">
			<cfset local.headers["authorization"] = arguments.accountSecret />
		</cfif>
		<cfset local.post["legal_entity[verification][document]"] = arguments.fileId />
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.connectedAccount#"), payload = local.post, headers = local.headers) />
	</cffunction>

	<!--- Charges --->
	<cffunction name="charge" output="false" access="public" returntype="any" hint="">
		<cfargument name="amount" type="any" required="false" />		
		<cfargument name="source" type="any" required="false" />		
		<cfargument name="description" type="any" required="false" />		
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
  		<cfset local.post["amount"] = arguments.amount.getCents() />
  		<cfset local.post["currency"] = lCase(arguments.amount.getCurrency()) />
  		<cfset local.post["source"] = arguments.source />
  		<cfset local.post["description"] = arguments.description />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges"), payload = local.post, headers = local.headers) />
	</cffunction>

	<cffunction name="marketplaceDirectCharge" output="false" access="public" returntype="any" hint="">
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="amount" type="any" required="false" />		
		<cfargument name="token" type="any" required="false" />		
		<cfargument name="application_fee" type="any" required="false" />		
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
  		<cfset local.headers["authorization"] = arguments.connectedAccount />
		<cfset local.post["amount"] = arguments.amount.getCents() />		
		<cfset local.post["currency"] = lCase(arguments.amount.getCurrency()) />
  		<cfset local.post["source"] = arguments.token />
  		<cfset local.post["application_fee"] = arguments.application_fee.getCents() />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges"), payload = local.post, headers = local.headers) />
	</cffunction>

	<cffunction name="marketplaceDestinationCharge" output="false" access="public" returntype="any" hint="">
		<cfargument name="destination" type="any" required="false" />		
		<cfargument name="amount" type="any" required="false" />		
		<cfargument name="cardToken" type="any" required="false" />		
		<cfargument name="application_fee" type="any" required="false" />		
		<cfset local.post = structNew() />
  		<cfset local.post["destination"] = arguments.destination />
  		<cfset local.post["amount"] = arguments.amount.getCents() />
  		<cfset local.post["currency"] = lCase(arguments.amount.getCurrency()) />
  		<cfset local.post["card"] = arguments.cardToken />
  		<cfset local.post["application_fee"] = arguments.application_fee.getCents() />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceRefundCharge" output="false" access="public" returntype="any" hint="">
		<cfargument name="paymentId" type="any" required="false" />		
		<cfargument name="refundAmount" type="any" required="false" />		
		<cfset local.post = structNew() />
		<cfset local.post["amount"] = arguments.refundAmount.getCents() />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.paymentId#/refunds"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceRefundChargeToConnectedAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="paymentId" type="any" required="false" />		
		<cfargument name="refundAmount" type="any" required="false" />		
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
		<cfset local.headers["Stripe-Account"] = arguments.connectedAccount />
		<cfset local.post["amount"] = arguments.refundAmount.getCents() />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.paymentId#/refunds"), payload = local.post, headers = local.headers) />
	</cffunction>

	<cffunction name="marketplaceRefundToAccountPullingBackFundsFromConnectedAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="paymentId" type="any" required="false" />		
		<cfargument name="refundAmount" type="any" required="false" />		
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
		<cfset local.post["amount"] = arguments.refundAmount.getCents() />
		<cfset local.post["reverse_transfer"] = "true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.paymentId#/refunds"), payload = local.post, headers = local.headers) />
	</cffunction>

	<!--- Transfers --->
	<cffunction name="marketplaceTransferFromPlatformStripeAccountToConnectedStripeAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="sourceTransaction" type="any" required="false" />
		<cfargument name="destination" type="any" required="false" />
		<cfargument name="transferAmount" type="any" required="false" />
		<cfset local.post = structNew() />
		<cfset local.post["amount"] = arguments.transferAmount.getCents() />
		<cfset local.post["currency"] = lCase(arguments.transferAmount.getCurrency()) />
		<cfset local.post["destination"] = arguments.destination />
		<cfif structKeyExists(arguments, "sourceTransaction") AND arguments.sourceTransaction neq "">
			<cfset local.post["source_transaction"] = arguments.sourceTransaction />
		</cfif>
		<cfreturn process(gatewayUrl = getGatewayURL("/transfers"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceAssociateTransferWithCharge" output="false" access="public" returntype="any" hint="">
		<cfargument name="sourceTransaction" type="any" required="false" />		
		<cfargument name="transferAmount" type="any" required="false" />		
		<cfset local.post = structNew() />
		<cfset local.post["amount"] = arguments.transferAmount.getCents() />		
		<cfset local.post["currency"] = lCase(arguments.transferAmount.getCurrency()) />
		<cfset local.post["source_transaction"] = arguments.sourceTransaction />
		<cfreturn process(gatewayUrl = getGatewayURL("/transfers"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceTransferWithApplicationFee" output="false" access="public" returntype="any" hint="">
		<cfargument name="destination" type="any" required="false" />		
		<cfargument name="transferAmount" type="any" required="false" />		
		<cfargument name="applicationFee" type="any" required="false" />		
		<cfset local.post = structNew() />
		<cfset local.post["amount"] = arguments.transferAmount.getCents() />		
		<cfset local.post["currency"] = lCase(arguments.transferAmount.getCurrency()) />
		<cfset local.post["destination"] = arguments.destination />
		<cfset local.post["application_fee"] = arguments.applicationFee.getCents() />		
		<cfreturn process(gatewayUrl = getGatewayURL("/transfers"), payload = local.post) />
	</cffunction>

	<cffunction name="marketplaceReversingTransfer" output="false" access="public" returntype="any" hint="">
		<cfargument name="paymentId" type="any" required="false" />		
		<cfargument name="connectedAccount" type="any" required="false" />		
		<cfargument name="amount" type="any" required="false" />		
		<cfset local.headers = structNew() />
		<cfset local.post = structNew() />
		<cfset local.headers["Stripe-Account"] = arguments.connectedAccount />
		<cfset local.post["amount"] = arguments.amount.getCents() />
		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.paymentId#/refunds"), payload = local.post, headers = local.headers) />
	</cffunction>

	<!--- Helper Functions --->
	<cffunction name="getCountryCodeFromCountry" output="false" access="private" returntype="any" hint="">
		<cfargument name="country" type="string" required="true" />
		<cfset rVar = "">
		
		<cfswitch expression="#arguments.country#">
			<cfcase value="USA,United States,US">
				<cfset rVar = "US" />
			</cfcase>
			<cfcase value="Canada">
				<cfset rVar = "CA" />
			</cfcase>
		</cfswitch>
		
		<cfreturn rVar />
	</cffunction>

	<cffunction name="addCreateManagedAccountData" output="false" access="private" returntype="any" hint="">
		<cfargument name="post" type="struct" required="true" />

		<cfscript>
			arguments.post["managed"] = true;
			arguments.post["country"] = 'CA';
			arguments.post["email"] = 'test#dateFormat(now(),"yyyymmdd")##timeFormat(now(),"HHmmss")#@test.tst';
			arguments.post["default_currency"] = 'CAD';
			//These properties can be set when creating the account, and changed later if the account is managed, but are only relevant if the account has charges being made directly on it:
			//arguments.post["statement_descriptor"] = '';
			//arguments.post["business_name"] = '';
			//arguments.post["support_phone"] = '';
		</cfscript>
	
		<cfreturn arguments.post />
	</cffunction>

	<cffunction name="updateAccountData" output="false" access="private" returntype="any" hint="">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="updates" type="array" required="true" />

		<cfloop from="1" to="#arrayLen(arguments.updates)#" index="local.ii">
			<cfset local.key = listFirst(arguments.updates[local.ii], "=")>
			<cfset local.value = listRest(arguments.updates[local.ii], "=")>
			<cfset arguments.post[local.key] = local.value>
		</cfloop>
	
		<cfreturn arguments.post />
	</cffunction>

</cfcomponent>
