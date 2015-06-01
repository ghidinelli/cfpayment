<!---
	Original code from Phil Cruz's Stripe.cfc from https://github.com/philcruz/Stripe.cfc/blob/master/stripe/Stripe.cfc
	Added Stripe Connect/Marketplace support in 2015 by Chris Mayes & Brian Ghidinelli (http://www.ghidinelli.com)
	
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
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0.7" />
	<cfset variables.cfpayment.API_VERSION = "2015-04-07" />
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


	<cffunction name="authorize" output="false" access="public" returntype="any" hint="Authorize but don't capture a credit card">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="false" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset arguments.options["capture"] = false />
		<cfreturn purchase(argumentCollection = arguments) />
	</cffunction>


	<cffunction name="capture" output="false" access="public" returntype="any" hint="Capture a previously authorized charge">
		<cfargument name="transactionId" type="string" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfreturn process(gatewayUrl = getGatewayUrl("/charges/#arguments.transactionId#/capture"), payload = post, options = options) />
	</cffunction>
			

	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Authorize + Capture in one step">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="false" hint="source to be charged - a credit card, bank account or a tokenized source" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" hint="Key options are customer, ConnectedAccount, destination and application_fee" />
		
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
		<cfargument name="money" type="any" required="false" hint="The amount to refund, if omitted, defaults to the full amount" />
		<cfargument name="transactionId" type="any" required="true" />
		<cfargument name="refund_application_fee" type="boolean" required="false" hint="For a destination or Connect charge, whether to refund the application_fee; defaults to false" />
		<cfargument name="reverse_transfer" type="boolean" required="false" hint="For destination charges, whether to pull back funds from the connected account; defaults to false" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset local.post = structNew() />
		
		<!--- default is to refund full amount --->
		<cfif structKeyExists(arguments, "money")>
			<cfset post["amount"] = abs(arguments.money.getCents()) />
		</cfif>

		<!--- self-documenting --->
		<cfif structKeyExists(arguments, "refund_application_fee")>
			<cfset post["refund_application_fee"] = arguments.refund_application_fee />
		</cfif>

		<cfif structKeyExists(arguments, "reverse_transfer")>
			<cfset post["reverse_transfer"] = arguments.reverse_transfer />
		</cfif>

		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.transactionId#/refunds"), payload = post, options = options) />
	</cffunction>


	<cffunction name="search" access="public" output="false" returntype="any" hint="Find transactions using gateway-supported criteria">
		<cfargument name="options" type="struct" required="true" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>


	<cffunction name="status" access="public" output="false" returntype="any" hint="Reconstruct a response object for a previously executed transaction">
		<cfargument name="transactionId" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.transactionId#"), options = options, method = "GET") />
	</cffunction>

	
	<cffunction name="validate" output="false" access="public" returntype="any" hint="Convert payment details to a one-time token for charging once.  To store payment details for repeat use, convert to a customer object with store().">
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
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = {} />
		
		<cfif getService().getAccountType(account) EQ "creditcard">
			<cfset post = addCreditCard(post = post, account = account) />
		<cfelseif getService().getAccountType(account) EQ "eft">
			<cfset post = addBankAccount(post = post, account = account) />
		<cfelse>
			<cfset post["source"] = arguments.account.getID() />
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
		<cfreturn process(gatewayUrl = getGatewayURL("/customers/#arguments.tokenId#"), method = "DELETE") />
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
	
		<cfreturn process(gatewayUrl = getGatewayUrl("/charges"), method = "GET", payload = payload) />
	</cffunction>


	<cffunction name="getApplicationFee" output="false" access="public" returntype="any" hint="Retrieve details about an application fee">
		<cfargument name="id" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		<cfreturn process(gatewayUrl = getGatewayURL("/application_fees/#arguments.id#"), payload = {}, options = arguments.options, method = "GET") />
	</cffunction>


	<cffunction name="getBalance" output="false" access="public" returntype="any" hint="Retrieve current Stripe account balance when automatic transfers are disabled">
		<cfreturn process(gatewayUrl = getGatewayURL("/balance"), payload = {}, method = "GET") />
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


	<cffunction name="createTokenInConnectedAccount" output="false" access="public" returntype="any" hint="Get a token for an existing customer)">
		<cfargument name="customer" type="any" required="true" />
		<cfargument name="ConnectedAccount" type="any" required="true" />

		<cfreturn process(gatewayUrl = getGatewayURL("/tokens"), payload = {}, options = {"ConnectedAccount": arguments.ConnectedAccount, "customer": arguments.customer}) />
	</cffunction>


	<cffunction name="getAccountToken" output="false" access="public" returntype="any" hint="Retrieve details about a one-time use token">
		<cfargument name="id" type="any" required="true" />
		<cfreturn process(gatewayUrl = getGatewayURL("/tokens/#arguments.id#"), payload = {}, options = {}, method = "GET") />
	</cffunction>


	<cffunction name="listConnectedAccounts" output="false" access="public" returntype="any" hint="List Connect accounts for a platform">
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts"), payload = structNew(), method = "GET") />
	</cffunction>


	<cffunction name="createConnectedAccount" output="false" access="public" returntype="any" hint="Provisions a marketplace account">
		<cfargument name="country" type="string" required="true" />
		<cfargument name="managed" type="boolean" required="true" />
		<cfargument name="email" type="string" required="false" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<!--- two set-only and important fields: country, managed --->
		<cfset local.post = {} />
		<cfset post["country"] = arguments.country />
		<cfset post["managed"] = arguments.managed />

		<cfif NOT arguments.managed AND NOT structKeyExists(arguments, "email")>
			<cfthrow type="cfpayment.InvalidArguments" message="Stripe requires an email address when creating an unmanaged account" />
		<cfelseif structKeyExists(arguments, "email")>
			<cfset post["email"] = arguments.email />
		</cfif>
		
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts"), payload = post, options = options) />
	</cffunction>


	<cffunction name="updateConnectedAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="ConnectedAccount" type="any" required="true" />		
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.ConnectedAccount.getID()#"), payload = structNew(), options = options) />
	</cffunction>
	

	<cffunction name="listBankAccounts" output="false" access="public" returntype="any" hint="">
		<cfargument name="ConnectedAccount" type="any" required="true" />		
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.ConnectedAccount.getID()#/bank_accounts"), payload = structNew(), method = "GET") />
	</cffunction>


	<cffunction name="deleteBankAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="ConnectedAccount" type="any" required="false" />		
		<cfargument name="bankAccountId" type="any" required="false" />		

		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.ConnectedAccount.getID()#/bank_accounts/#arguments.bankAccountId#"), payload = {}, method = "DELETE") />
	</cffunction>


	<cffunction name="createBankAccount" output="false" access="public" returntype="any" hint="">
		<cfargument name="ConnectedAccount" type="any" required="false" />
		<cfargument name="account" type="any" required="false" hint="Either a token or EFT" />
		<cfargument name="currency" type="string" required="true" hint="A 3-letter ISO currency code" />

		<cfset local.post = structNew() />
		
		<cfif getService().getAccountType(account) EQ "token">
			<cfset post["bank_account"] = arguments.account.getID() />
		<cfelseif getService().getAccountType(account) EQ "eft">
			<cfset post = addBankAccount(post = post, account = account) />
			<cfset post["bank_account[currency]"] = lcase(arguments.currency) />
		<cfelse>
			<cfthrow type="cfpayment.InvalidAccount" message="The account type #getService().getAccountType(arguments.account)# is not supported by this gateway." />
		</cfif>

		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.ConnectedAccount.getID()#/bank_accounts"), payload = local.post) />
	</cffunction>


	<cffunction name="setDefaultBankAccountForCurrency" output="false" access="public" returntype="any" hint="">
		<cfargument name="ConnectedAccount" type="any" required="false" />		
		<cfargument name="bankAccountId" type="any" required="false" />		

		<cfset local.post = {"default_for_currency": true} />
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.ConnectedAccount.getID()#/bank_accounts/#arguments.bankAccountId#"), payload = local.post) />
	</cffunction>


	<cffunction name="uploadFile" output="false" access="public" returntype="any" hint="Stripe allows file uploads for identity verification and chargeback dispute evidence - first upload and then assign the file id to its intended object">
		<cfargument name="file" type="any" required="false" hint="An absolute path to a file" />
		<cfargument name="purpose" type="string" required="true" hint="Allowed values - from https://stripe.com/docs/api##create_file_upload" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" hint="Pass a ConnectedAccount if attaching to a Connect account" />

		<cfif NOT listFind("identity_document,dispute_evidence", arguments.purpose)>
			<cfthrow type="cfpayment.InvalidArguments" message="Purpose must be one of: identity_document, dispute_evidence" />
		</cfif>

		<cfset local.files = {"file": arguments.file} />
		<cfset local.post = {"purpose": arguments.purpose} />
		
		<cfreturn process(gatewayUrl = "https://uploads.stripe.com/v1/files", payload = local.post, files = local.files, options = arguments.options) />
	</cffunction>


	<cffunction name="attachIdentityFile" output="false" access="public" returntype="any" hint="For attaching Connect account identity documents">
		<cfargument name="ConnectedAccount" type="any" required="true" />
		<cfargument name="fileId" type="any" required="true" />		
		<cfargument name="options" type="struct" required="false" default="#structNew()#" hint="Pass a ConnectedAccount if attaching to a Connect account" />

		<cfset local.post = {"legal_entity[verification][document]": arguments.fileId} />
		
		<cfreturn process(gatewayUrl = getGatewayURL("/accounts/#arguments.ConnectedAccount.getID()#"), payload = local.post, options = arguments.options) />
	</cffunction>


	<cffunction name="updateDispute" output="false" access="public" returntype="any" hint="">
		<cfargument name="transactionId" type="any" required="false" />		
		<cfargument name="options" type="struct" required="false" default="#structNew()#" hint="Disputes can include file references generated from uploadFile() for evidence" />

		<cfreturn process(gatewayUrl = getGatewayURL("/charges/#arguments.transactionId#/disputes"), payload = structNew(), options = arguments.options) />
	</cffunction>


	<cffunction name="listTransfers" output="false" access="public" returntype="any" hint="">
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		<cfreturn process(gatewayUrl = getGatewayURL("/transfers"), payload = {}, options = arguments.options, method = "GET") />
	</cffunction>


	<cffunction name="transfer" output="false" access="public" returntype="any" hint="">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="destination" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset local.post = structNew() />
		<cfset local.post["amount"] = arguments.money.getCents() />
		<cfset local.post["currency"] = lCase(arguments.money.getCurrency()) />
		<cfset local.post["destination"] = arguments.destination.getID() />

		<cfreturn process(gatewayUrl = getGatewayURL("/transfers"), payload = local.post, options = arguments.options) />
	</cffunction>


	<cffunction name="transferReverse" output="false" access="public" returntype="any">
		<cfargument name="transferId" type="string" required="true" hint="The transfer to reverse" />
		<cfargument name="money" type="any" required="false" hint="Amount to refund, if omitted, the default is the entire amount" />
		<cfargument name="refund_application_fee" type="boolean" required="false" hint="For a destination or Connect charge, whether to refund the application_fee; defaults to false" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset local.post = structNew() />
		
		<cfif structKeyExists(arguments, "money")>
			<cfset post["amount"] = abs(arguments.money.getCents()) />
		</cfif>

		<!--- self-documenting --->
		<cfif structKeyExists(arguments, "refund_application_fee")>
			<cfset post["refund_application_fee"] = arguments.refund_application_fee />
		</cfif>

		<cfreturn process(gatewayUrl = getGatewayURL("/transfers/#arguments.transferId#/reversals"), payload = post, options = arguments.options) />
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

		<!--- process standard and common CFPAYMENT mappings into gateway-specific values --->
		<cfif structKeyExists(arguments.options, "description")>
			<cfset p["description"] = arguments.options.description />
		</cfif>
		<cfif structKeyExists(arguments.options, "tokenId")>
			<cfset p["customer"] = arguments.options.tokenId />
		</cfif>

		<!--- add baseline authentication --->
		<cfset headers["authorization"] = "Bearer #getSecretKey()#" />

		<!--- add connect authentication on behalf of a Connect/Marketplace customer --->
		<cfif structKeyExists(arguments.options, "ConnectedAccount")>
			<cfif NOT isObject(arguments.options.ConnectedAccount)>
				<cfthrow type="cfpayment.InvalidArguments" message="ConnectedAccount must be a cfpayment token object" />
			</cfif>
			<cfset headers["Stripe-Account"] = arguments.options.ConnectedAccount.getID() />
			<cfset structDelete(arguments.options, "ConnectedAccount") />
		</cfif>

		<!--- if we want to override the stripe API version, we can set it in the config with "ApiVersion".  Using 'latest' overrides to current version --->
		<cfif len(getApiVersion())>
			<!--- https://groups.google.com/a/lists.stripe.com/forum/#!topic/api-discuss/V4sYRlHwalc --->
			<cfset headers["Stripe-Version"] = getApiVersion() />
		</cfif>

		<!--- help track where this request was made from --->
		<cfset headers["User-Agent"] = "Stripe/v1 cfpayment/#variables.cfpayment.GATEWAY_VERSION#" />

		<!--- add dynamic statement descriptors which show up on CC statement alongside merchant name: https://stripe.com/docs/api#create_charge --->
		<cfif structKeyExists(arguments.options, "statement_descriptor")>
			<cfset p["statement_descriptor"] = reReplace(arguments.options.statement_descriptor, "[<>""']", "", "ALL") />
			<cfset structDelete(arguments.options, "statement_descriptor") />
		</cfif>

		<!--- application_fee is a money object, just like the amount to be charged --->
		<cfif structKeyExists(arguments.options, "application_fee")>
			<cfif NOT isObject(arguments.options.application_fee)>
				<cfthrow type="cfpayment.InvalidArguments" message="application_fee must be a cfpayment money object" />
			</cfif>
			<cfset p["application_fee"] = arguments.options.application_fee.getCents() />
			<cfset structDelete(arguments.options, "application_fee") />
		</cfif>

		<!--- if a card is converted to a customer, you can optionally pass a customer to many requests to charge their default account instead --->
		<cfif structKeyExists(arguments.options, "customer")>
			<cfif NOT isObject(arguments.options.customer)>
				<cfthrow type="cfpayment.InvalidArguments" message="Customer must be a cfpayment token object" />
			</cfif>
			<cfset p = addCustomer(post = p, customer = arguments.options.customer) />
			<cfset structDelete(arguments.options, "customer") />
		</cfif>

		<cfif structKeyExists(arguments.options, "destination")>
			<cfif NOT isObject(arguments.options.destination)>
				<cfthrow type="cfpayment.InvalidArguments" message="Destination must be a cfpayment token object" />
			</cfif>
			<cfset p["destination"] = arguments.options.destination.getID() />
			<cfset structDelete(arguments.options, "destination") />
		</cfif>



		<!--- finally, copy in any additional keys like customer, destination, etc, stripe always wants lower-case --->
		<cfloop collection="#arguments.options#" item="local.key">
			<cfset p[lcase(key)] = arguments.options[key] />
		</cfloop>
	

		<!--- Stripe returns errors with http status like 400,402 or 404 (https://stripe.com/docs/api#errors) --->		
		<cfset response = createResponse(argumentCollection = super.process(url = arguments.gatewayUrl, payload = payload, headers = headers, method = arguments.method, files = files)) />


		<cfif isJSON(response.getResult())>

			<cfset results = deserializeJSON(response.getResult()) />
			<cfset response.setParsedResult(results) />

			<!--- take object-specific IDs like tok_*, ch_*, re_*, etc and always put it as the transaction id --->
			<cfif structKeyExists(results, "id")>
				<cfset response.setTransactionID(results.id) />
			</cfif>
			
			<!--- the available 'types': list, customer, charge, token, card, bank_account, refund, application_fee, transfer, transfer_reversal, account, file_upload --->
			<cfif structKeyExists(results, "object")>
			
				<cfswitch expression="#results.object#">
					<cfcase value="account">
					
						<cfset response.setTokenID(results.id) />
						
					</cfcase>	
					<cfcase value="bank_account">
					
						<cfset response.setTokenID(results.id) />
						
					</cfcase>					
					<cfcase value="charge">
						
						<cfset response.setCVVCode(normalizeCVV(results.source)) />
						<cfset response.setAVSCode(normalizeAVS(results.source)) />
						
						<!--- if you authorize without capture, you use the charge id to capture it later, which is the same as the transaction id, but for normality, put it here --->
						<cfif structKeyExists(results, "captured") AND NOT results.captured AND structKeyExists(results, "id")>
							<cfset response.setAuthorization(results.id) />
						</cfif>

					</cfcase>
					<cfcase value="customer">
					
						<!--- customers have a "sources" key with, by default, one card on file 
							  you can add more cards to a customer using the card api, but otherwise
							  adding a new one actually replaces the previous one on file.
							  we make the assumption today that we only have one until someone needs more
						--->
						<cfset response.setCVVCode(normalizeCVV(results.sources.data[1])) />
						<cfset response.setAVSCode(normalizeAVS(results.sources.data[1])) />
			
						<cfset response.setTokenID(results.id) />
						
					</cfcase>
					<cfcase value="token">
					
						<!--- stripe does not check AVS/CVV at the token stage - only once converted to a customer or in a charge --->
						<!--- could be results.source.object EQ card or bank_account --->
						<cfset response.setTokenID(results.id) />
					
					</cfcase>				
				</cfswitch>
			
			</cfif>

		</cfif>
		
		<!--- now add custom handling of status codes for Stripe which overrides base.cfc --->
		<cfset handleHttpStatus(response = response) />

		<cfreturn response />
	</cffunction>

	
	<cffunction name="normalizeCVV" output="false" access="private" returntype="string">
		<cfargument name="source" type="any" required="true" hint="A structure that contains a cvc_check key" />
	
		<!--- translate to normalized cfpayment CVV codes --->			
		<cfif structKeyExists(arguments.source, "cvc_check") AND arguments.source.cvc_check EQ "pass">
			<cfreturn "M" />
		<cfelseif structKeyExists(arguments.source, "cvc_check") AND arguments.source.cvc_check EQ "fail">
			<cfreturn "N" />
		<cfelseif structKeyExists(arguments.source, "cvc_check") AND arguments.source.cvc_check EQ "unchecked">
			<cfreturn "U" />
		<cfelseif NOT structKeyExists(arguments.source, "cvc_check")>
			<!--- indicates it wasn't checked --->
			<cfreturn "" />
		<cfelse>
			<cfreturn "P" />
		</cfif>
	</cffunction>


	<cffunction name="normalizeAVS" output="false" access="private" returntype="string">
		<cfargument name="source" type="any" required="true" hint="A structure that contains address_line1_check and address_zip_check keys" />
	
		<!--- translate to normalized cfpayment AVS codes.  Options are pass, fail, unavailable and unchecked.  Watch out that either address_line1_check or address_zip_check can be null OR "unchecked"; null throws error trying to access --->
		<cfif structKeyExists(arguments.source, "address_zip_check") AND arguments.source.address_zip_check EQ "pass" 
			  AND structKeyExists(arguments.source, "address_line1_check") AND arguments.source.address_line1_check EQ "pass">
			<cfreturn "M" />
		<cfelseif structKeyExists(arguments.source, "address_zip_check") AND arguments.source.address_zip_check EQ "pass">
			<cfreturn "P" />
		<cfelseif structKeyExists(arguments.source, "address_line1_check") AND arguments.source.address_line1_check EQ "pass">
			<cfreturn "B" />
		<cfelseif (structKeyExists(arguments.source, "address_zip_check") AND arguments.source.address_zip_check EQ "unchecked")
				  OR (structKeyExists(arguments.source, "address_line1_check") AND arguments.source.address_line1_check EQ "unchecked")>
			<cfif arguments.source.country EQ "US">
				<cfreturn "S" />
			<cfelse>
				<cfreturn "G" />
			</cfif>
		<cfelseif NOT structKeyExists(arguments.source, "address_zip_check") AND NOT structKeyExists(arguments.source, "address_line1_check")>
			<!--- indicates it wasn't checked --->
			<cfreturn "" />
		<cfelse>
			<cfreturn "N" />
		</cfif>
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
					response.setMessage("There is a configuration error preventing the transaction from completing successfully. (Original issue: Invalid API key)");
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
		
		<cfset arguments.post["source"] = arguments.account.getID() />

		<cfreturn arguments.post />
	</cffunction>


	<cffunction name="addCustomer" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="customer" type="any" required="true" />
		
		<cfset arguments.post["customer"] = arguments.customer.getID() />

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
	<cffunction name="createResponse" access="public" output="false" returntype="any" hint="Create a Stripe response object with status set to unprocessed">
		<cfreturn createObject("component", "response").init(argumentCollection = arguments, service = getService()) />
	</cffunction>

</cfcomponent>
