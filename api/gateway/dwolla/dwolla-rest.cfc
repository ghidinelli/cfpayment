<!---
	$Id$
	
	Dwolla OAuth + REST Payments API
	Copyright 2013 Brian Ghidinelli (http://www.ghidinelli.com)
	
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
<cfcomponent displayname="Dwolla OAuth + REST Gateway" extends="cfpayment.api.gateway.base" hint="Dwolla OAuth+REST Gateway" output="false">

	<cfset variables.cfpayment.GATEWAY_NAME = "Dwolla" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<!--- stripe test mode uses different credentials instead of different urls --->
	<cfset variables.cfpayment.GATEWAY_URL = "https://www.dwolla.com/oauth/rest" />

	<cfset variables.cfpayment.ConsumerKey = "" />
	<cfset variables.cfpayment.ConsumerSecret = "" />
	
	<cffunction name="getConsumerKey" access="public" output="false" returntype="string">		
		<cfreturn variables.cfpayment.ConsumerKey />
	</cffunction>
	<cffunction name="setConsumerKey" access="public" output="false" returntype="void">
		<cfargument name="ConsumerKey" type="string" required="true" />
		<cfset variables.cfpayment.ConsumerKey = arguments.ConsumerKey />
	</cffunction>
	
	<cffunction name="getConsumerSecret" output="false" access="public" returntype="any">
		<cfreturn variables.cfpayment.ConsumerSecret />
	</cffunction>
	<cffunction name="setConsumerSecret" access="public" output="false" returntype="void">
		<cfargument name="ConsumerSecret" type="string" required="true" />
		<cfset variables.cfpayment.ConsumerSecret = arguments.ConsumerSecret />
	</cffunction>
	
	
	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Request money from an account">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="false" />		
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />				
		
		<cfthrow message="Not Implemented" />	
	</cffunction>


	<cffunction name="credit" output="false" access="public" returntype="any" hint="Send money to an account">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="false" />		
		<cfargument name="destinationId" type="string" required="true" hint="Identification of the user to send funds to. Must be the Dwolla identifier, Facebook identifier, Twitter identifier, phone number, or email address." />
		<!--- optional --->
		<cfargument name="destinationType" type="string" required="false" default="Dwolla" hint="Possible values: 'Dwolla', 'Facebook', 'Twitter', 'Email', 'Phone'" />
		<cfargument name="facilitatorAmount" type="numeric" required="false" default="0" />
		<cfargument name="assumeCosts" type="boolean" required="false" />
		<cfargument name="notes" type="string" required="false" />
		<cfargument name="fundsSource" type="string" required="false" hint="Defaults to Balance" />
		<cfargument name="additionalFees" type="array" required="false" hint="Array of additional facilitator fees each like: { destinationId = '', amount = ''}" default="#arrayNew(1)#" />
		<cfargument name="assumeAdditionalFees" type="boolean" required="false" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var response = "" />
		<cfset var post = structNew() />
		
		<!--- case case-sensitive struct to serialize --->
		<cfset post["amount"] = arguments.money.getAmount() />
		<cfset post["pin"] = arguments.account.getSecret() />
		<cfset post["destinationId"] = arguments.destinationId />
		<cfif structKeyExists(arguments, "destinationType")><cfset post["destinationType"] = arguments.destinationType /></cfif>
		<cfif structKeyExists(arguments, "facilitatorAmount")><cfset post["facilitatorAmount"] = arguments.facilitatorAmount /></cfif>
		<cfif structKeyExists(arguments, "assumeCosts")><cfset post["assumeCosts"] = arguments.assumeCosts /></cfif>
		<cfif structKeyExists(arguments, "notes")><cfset post["notes"] = arguments.notes /></cfif>
		<cfif structKeyExists(arguments, "fundsSource")><cfset post["fundsSource"] = arguments.fundsSource /></cfif>
		<cfif structKeyExists(arguments, "additionalFees")><cfset post["additionalFees"] = arguments.additionalFees /></cfif>
		<cfif structKeyExists(arguments, "assumeAdditionalFees")><cfset post["assumeAdditionalFees"] = arguments.assumeAdditionalFees /></cfif>

		<cfset response = process(gatewayUrl = getGatewayUrl("/transactions/send", arguments.account.getAccessToken()), payload = serializeJson(post), headers = {"Content-Type" = "application/json"}, options = options) />
		
		<cfif response.getSuccess()>
			<!--- parse fields --->
			<cfset response.setTransactionId(response.getParsedResult().Response) />
		</cfif>
		
		<cfreturn response />
	</cffunction>
	
	
	<cffunction name="withdraw" output="false" access="public" returntype="any">
		<cfthrow message="Not Implemented" />	
	</cffunction>

	<cffunction name="deposit" output="false" access="public" returntype="any">
		<cfthrow message="Not Implemented" />	
	</cffunction>
	
	<cffunction name="fundingsources" output="false" access="public" returntype="any">
		<cfargument name="account" type="any" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/fundingsources/", arguments.account.getAccessToken()), payload = {}, method = "get") />
	</cffunction>
	
	<cffunction name="fundingsource" output="false" access="public" returntype="any">
		<cfargument name="sourceId" type="string" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/fundingsources/#arguments.sourceId#", arguments.account.getAccessToken()), payload = {}, method = "get") />
	</cffunction>

	<cffunction name="contacts" output="false" access="public" returntype="any">
		<cfthrow message="Not Implemented" />	
	</cffunction>

	<cffunction name="balance" output="false" access="public" returntype="any">
		<cfargument name="account" type="any" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/balance/", arguments.account.getAccessToken()), payload = {}, method = "get") />
	</cffunction>

	<cffunction name="request" output="false" access="public" returntype="any">
		<cfthrow message="Not Implemented" />	
	</cffunction>

	<cffunction name="register" output="false" access="public" returntype="any">
		<cfthrow message="Not Implemented" />	
	</cffunction>

	<cffunction name="basicinfo" output="false" access="public" returntype="any">
		<cfargument name="tokenId" type="string" required="true" hint="Dwolla account ID or Email address" />
		
		<cfset var payload = {"client_id" = getConsumerKey(), "client_secret" = getConsumerSecret()} />
		<cfreturn process(gatewayUrl = getGatewayURL("/users/#arguments.tokenId#"), payload = payload, method="get") />
	</cffunction>

	<cffunction name="fullinfo" output="false" access="public" returntype="any">
		<cfargument name="account" type="any" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/users/", arguments.account.getAccessToken()), payload = {}, method = "get") />
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
		<cfargument name="account" type="any" required="true" />
		<cfargument name="groupId" type="string" required="false" />
		<cfargument name="types" type="string" required="false" hint="Possible values: 'money_sent', 'money_received', 'deposit', 'withdrawal', 'fee'. Defaults to: 'money_sent,money_received,deposit,withdrawal,fee'" />
		<cfargument name="sinceDate" type="date" required="false" />
		<cfargument name="endDate" type="date" required="false" />
		<cfargument name="limit" type="numeric" required="false" />
		<cfargument name="skip" type="numeric" required="false" />
		<cfargument name="options" type="struct" required="true" />

		<cfreturn process(gatewayUrl = getGatewayURL("/transactions", arguments.account.getAccessToken()), method = "get", options = options) />
	</cffunction>


	<cffunction name="status" access="public" output="false" returntype="any" hint="Reconstruct a response object for a previously executed transaction">
		<cfargument name="transactionId" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />

		<!--- needs clientkey/clientsecret OR oauth --->
		<cfreturn process(gatewayUrl = getGatewayURL("/transactions/#arguments.transactionId#", arguments.account.getAccessToken()), payload = {}, method = "get") />
	</cffunction>

	
	<cffunction name="validate" output="false" access="public" returntype="any" hint="Convert credit card details to a one-time token for charging later.  To store payment details for use later, use a customer object with store().">
		<cfargument name="account" type="any" required="true" />
		<cfargument name="money" type="any" required="false" />

		<cfset var post = addCreditCard(post = structNew(), account = arguments.account) />
		<cfreturn process(gatewayUrl = getGatewayURL("/tokens"), payload = post) />
	</cffunction>


	<cffunction name="store" output="false" access="public" returntype="any" hint="Convert a one-time token (from validate() or Stripe.js) into a Customer object for charging one or more times in the future">
		<cfargument name="account" type="any" required="true" /><!--- must be type of "token"? --->
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = {} />
		
		<cfif getService().getAccountType(account) EQ "creditcard">
			<cfset post = addCreditCard(post = post, account = account) />
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



	<!--- process wrapper with gateway/transaction error handling --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="gatewayUrl" type="string" required="true" />
		<cfargument name="payload" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="method" type="string" required="false" default="post" />

		<cfset var results = "" />
		<cfset var response = "" />
		<cfset var p = arguments.payload /><!--- shortcut (by reference) --->

		<!--- add authentication --->		
		<cfset headers["authorization"] = "Bearer #getConsumerKey()#" />

		<!--- process standard and common CFPAYMENT mappings into Braintree-specific values --->
		<cfif structKeyExists(arguments.options, "description")>
			<cfset p["description"] = arguments.options.description />
		</cfif>
		<cfif structKeyExists(arguments.options, "tokenId")>
			<cfset p["customer"] = arguments.options.tokenId />
		</cfif>


		<cfset response = createResponse(argumentCollection = super.process(url = arguments.gatewayUrl, payload = payload, headers = headers, method = arguments.method)) />


		<!--- dwolla responds 200 OK to everything but doesn't guarantee request succeeded --->
		<cfif response.getStatusCode() NEQ 200>
			<cfset response.setStatus(getService().getStatusFailure()) />
		</cfif>

		<!--- Dwolla returns errors with JSON object with a "success" true/false key --->		
		<cfif isJSON(response.getResult())>

			<cfset results = deserializeJSON(response.getResult()) />
			<cfset response.setParsedResult(results) />
			
			<!--- check for success/failure --->
			<cfif structKeyExists(results, "success") AND results.success EQ true>
				<cfset response.setStatus(getService().getStatusSuccessful()) />
			<cfelse>
				<cfset response.setMessage(results.message) />
				
				<cfif findNoCase("insufficient funds", results.message)>
					<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfelse>
					<cfset response.setStatus(getService().getStatusFailure()) />
				</cfif>
				
			</cfif>


			<!--- dwolla bundles everything in the Response key on a per-response basis, no commonality here unfortunately 
			<cfif structKeyExists(results, "response") AND isStruct(results.response)>
				
				<cfif structKeyExists(results.response, "id")>
					<cfset response.setTokenID(results.response.id) />
				</cfif>
				
			</cfif>--->

		</cfif>

		<cfreturn response />
	</cffunction>


	<!--- HELPER FUNCTIONS  --->
	<cffunction name="getGatewayURL" access="public" output="false" returntype="any" hint="Append to Gateway URL to return the appropriate url for the API endpoint">
		<cfargument name="endpoint" type="string" required="false" default="" />
		<cfargument name="oauth_token" type="string" required="false" />
		
		<cfif reFind("https?://", arguments.endpoint, 1, false)>
			<cfreturn arguments.endpoint />
		<cfelseif structKeyExists(arguments, "oauth_token")>
			<cfreturn variables.cfpayment.GATEWAY_URL & arguments.endpoint & "?oauth_token=#URLEncodedFormat(arguments.oauth_token)#" />
		<cfelse>
			<cfreturn variables.cfpayment.GATEWAY_URL & arguments.endpoint />
		</cfif>
	</cffunction>
 

</cfcomponent>
