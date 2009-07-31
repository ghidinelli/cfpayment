<!---
	$Id$
	
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
<cfcomponent displayname="Braintree Interface" extends="cfpayment.api.gateway.base" hint="Braintree Gateway" output="false">

	<cfset variables.cfpayment.GATEWAY_NAME = "Braintree" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<!--- braintree test mode uses different username/password instead of different urls --->
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://secure.braintreepaymentgateway.com/api/transact.php" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = variables.cfpayment.GATEWAY_LIVE_URL />
	<cfset variables.cfpayment.GATEWAY_REPORT_URL = "https://secure.braintreepaymentgateway.com/api/query.php" />

	<cfset variables.braintree = structNew() />
	<cfset variables.braintree["100"] = "Transaction was approved" />
	<cfset variables.braintree["200"] = "Transaction was declined by Processor" />
	<cfset variables.braintree["201"] = "Do Not Honor" />
	<cfset variables.braintree["202"] = "Insufficient Funds" />
	<cfset variables.braintree["203"] = "Over Limit" />
	<cfset variables.braintree["204"] = "Transaction not allowed" />
	<cfset variables.braintree["220"] = "Incorrect Payment Data" />
	<cfset variables.braintree["221"] = "No such card issuer" />
	<cfset variables.braintree["222"] = "No card number on file with Issuer" />
	<cfset variables.braintree["223"] = "Expired card" />
	<cfset variables.braintree["224"] = "Invalid expiration date" />
	<cfset variables.braintree["225"] = "Invalid card security code" />
	<cfset variables.braintree["240"] = "Call Issuer for further information" />
	<cfset variables.braintree["250"] = "Pick up card" />
	<cfset variables.braintree["251"] = "Lost card" />
	<cfset variables.braintree["252"] = "Stolen card" />
	<cfset variables.braintree["253"] = "Fraudulent card" />
	<cfset variables.braintree["260"] = "Declined with further instructions available (see response text)" />
	<cfset variables.braintree["261"] = "Declined - Stop all recurring payments" />
	<cfset variables.braintree["262"] = "Declined - Stop this recurring program" /> 
	<cfset variables.braintree["263"] = "Declined - Updated cardholder data available" /> 
	<cfset variables.braintree["264"] = "Declined - Retry in a few days" />
	<cfset variables.braintree["300"] = "Transaction was rejected by gateway" />
	<cfset variables.braintree["400"] = "Transaction error returned by processor" />
	<cfset variables.braintree["410"] = "Invalid merchant configuration" />
	<cfset variables.braintree["411"] = "Merchant account is inactive" />
	<cfset variables.braintree["420"] = "Communication error" />
	<cfset variables.braintree["421"] = "Communication error with issuer" />
	<cfset variables.braintree["430"] = "Duplicate transaction at processor" />
	<cfset variables.braintree["440"] = "Processor format error" />
	<cfset variables.braintree["441"] = "Invalid transaction information" />
	<cfset variables.braintree["460"] = "Processor feature not available" />
	<cfset variables.braintree["461"] = "Unsupported card type" />



	<!--- process wrapper with gateway/transaction error handling --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var response = "" />
		<cfset var results = structNew() />
		<cfset var pairs = "" />
		<cfset var ii = "" />
		<cfset p = arguments.payload /><!--- shortcut (by reference) --->


		<!--- create structure of URL parameters; swap in test parameters if necessary --->
		<cfif getTestMode()>
			<cfset p["username"] = "testapi" />
			<cfset p["password"] = "password1" />
		<cfelse>
			<cfset p["username"] = getUsername() />
			<cfset p["password"] = getPassword() />
		</cfif>

		<!--- provide optional data --->
		<cfset structAppend(p, arguments.options, true) />

		<!--- process standard and common CFPAYMENT mappings into Braintree-specific values --->
		<cfif structKeyExists(arguments.options, "orderId")>
			<cfset p["order_id"] = arguments.options.orderId />
		</cfif>
		<cfif structKeyExists(arguments.options, "tokenId")>
			<cfset p["customer_vault_id"] = arguments.options.tokenId />
		</cfif>


		<!---
		state (recommended) Format: CC, 2 Character abbrev.
		country (recommended) Format: CC (ISO-3166) 
		processor_id (optional) 
		product_sku_# (optional) Format: product_sku_1 
		orderdescription (optional) 
		company (optional) 
		address2 (optional) 
		fax (optional) 
		Billing fax number
		website (optional) 
		shipping_firstname (optional) 
		shipping_lastname (optional) 
		shipping_company (optional) 
		shipping_address1 (optional) 
		shipping_address2 (optional) 
		shipping_city (optional) 
		shipping_state (optional) 2 character abbreviation.
		shipping_zip (optional) 
		shipping_country (optional) Format: CC (ISO-3166, ie. US)
		tracking_number (optional) 
		shipping_carrier (optional) Format: ups / fedex / dhl / usps 
		orderid (optional) 
		sec_code (optional) Format: PPD / WEB / TEL / CCD 
		descriptor (optional) 
		descriptor_phone (optional) 
		--->

	
		<!--- braintree requires lower case parameters (per Katrina in support on 3/25/09), so force case --->
		<cfloop collection="#p#" item="ii">
			<cfset p[lcase(ii)] = p[ii] />
		</cfloop>


		<!--- send it over the wire using the base gateway --->
		<cfset response = super.process(payload = p) />

		
		<!--- we do some meta-checks for gateway-level errors (as opposed to auth/decline errors) --->
		<cfif NOT response.hasError()>
	
			<!--- we need to have a result; otherwise that's an error in itself --->	
			<cfif len(response.getResult())>
				
				<cfif isXML(response.getResult())>
				
					<!--- returned from query api, just shoehorn it in and return the result --->
					<cfset results = xmlParse(response.getResult()) />					
					
					<!--- store parsed result --->
					<cfset response.setParsedResult(results) />
					
					<!--- check returned XML for success/failure --->
					<cfif structKeyExists(results.xmlRoot, "error_response")>
						<cfset response.setStatus(getService().getStatusFailure()) />
					<cfelse>
						<cfset response.setStatus(getService().getStatusSuccessful()) />
					</cfif>
					
				<cfelse>
				
					<!--- From: http://developer.getbraintree.com/apis/1-payment-processing 
						  The transaction responses are returned in the body of the HTTP response 
						  in a query string name/value format delimited by ampersands. For example: 
						  variable1=value1&variable2=value2&variable3=value3				
					--->
					<cfset pairs = listToArray(response.getResult(), "&") />
					
					<!--- now split the variable=value --->
					<cfloop from="1" to="#arrayLen(pairs)#" index="ii">
						<cfif listLen(pairs[ii], "=") GT 1>
							<cfset results[listFirst(pairs[ii], "=")] = listLast(pairs[ii], "=") />
						<cfelse>
							<cfset results[listFirst(pairs[ii], "=")] = "" />
						</cfif>
					</cfloop>
					
					<!--- store parsed result --->
					<cfset response.setParsedResult(results) />
	
					<!--- handle common response fields --->
					<cfif structKeyExists(results, "response_code")>
						<cfset response.setMessage(variables.braintree[results.response_code]) />
					</cfif>
					<cfif structKeyExists(results, "response_text")>
						<cfset response.setMessage(response.getMessage() & ": " & variables.braintree[results.response_text]) />
					</cfif>
					<cfif structKeyExists(results, "transactionid")>
						<cfset response.setTransactionID(results.transactionid) />
					</cfif>
					<cfif structKeyExists(results, "authcode")>
						<cfset response.setAuthorization(results.authcode) />
					</cfif>
					<cfif structKeyExists(results, "customer_vault_id")>
						<cfset response.setTokenID(results.customer_vault_id) />
					</cfif>
					
					<!--- handle common "success" fields --->
					<cfif structKeyExists(results, "avsresponse")>
						<cfset response.setAVSCode(results.avsresponse) />					
					</cfif>
					<cfif structKeyExists(results, "cvvresponse")>
						<cfset response.setCVVCode(results.cvvresponse) />					
					</cfif>				
	
					<!--- see if the response was successful --->
					<cfif results.response EQ "1">
		
						<cfset response.setStatus(getService().getStatusSuccessful()) />
		
					<cfelseif results.response EQ "2">
		
						<cfset response.setStatus(getService().getStatusDeclined()) />
		
					<cfelse>
						
						<!--- only other known state is 3 meaning, "error in transaction data or system error" --->
						<cfset response.setStatus(getService().getStatusFailure()) />
						
					</cfif>
			
				</cfif>
		
			<cfelse>
			
				<!--- this is bad, because Braintree didn't return a response.  Uh oh! --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
			
			</cfif>
		
		</cfif>

		<cfreturn response />		

	</cffunction>


	<!--- implement primary methods --->
	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Authorize + Capture in one step">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		
		<!--- set general values --->
		<cfset post["amount"] = arguments.money.getAmount() />
		<cfset post["type"] = "sale" />

		<cfswitch expression="#lcase(listLast(getMetaData(arguments.account).fullname, "."))#">
			<cfcase value="creditcard">
				<!--- copy in name and customer details --->
				<cfset post = addCustomer(post = post, account = arguments.account) />
				<cfset post = addCreditCard(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfcase value="eft">
				<!--- copy in name and customer details --->
				<cfset post = addCustomer(post = post, account = arguments.account) />
				<cfset post = addEFT(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfcase value="token">
				<!--- tokens don't need customer info --->
				<cfset post = addToken(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfdefaultcase>
				<cfthrow type="cfpayment.InvalidAccount" message="The account type #lcase(listLast(getMetaData(arguments.account).fullname, "."))# is not supported by this gateway." />
			</cfdefaultcase>
		</cfswitch>

		<cfreturn process(payload = post, options = options) />
	</cffunction>

	
	<cffunction name="authorize" output="false" access="public" returntype="any" hint="Authorize (only) a credit card">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		
		<!--- set general values --->
		<cfset post["amount"] = arguments.money.getAmount() />
		<cfset post["type"] = "auth" />


		<cfswitch expression="#lcase(listLast(getMetaData(arguments.account).fullname, "."))#">
			<cfcase value="creditcard">
				<!--- copy in name and customer details --->
				<cfset post = addCustomer(post = post, account = arguments.account) />
				<cfset post = addCreditCard(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfcase value="eft">
				<cfthrow message="Authorize not implemented for E-checks; use purchase instead." type="cfpayment.MethodNotImplemented" />
			</cfcase>
			<cfcase value="token">
				<cfset post = addToken(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfdefaultcase>
				<cfthrow type="cfpayment.Invalid.AccountType" message="The account type #lcase(listLast(getMetaData(arguments.account).fullname, "."))# is not supported by this gateway." />
			</cfdefaultcase>
		</cfswitch>

		<cfreturn process(payload = post, options = options) />
	</cffunction>	
	

	<cffunction name="capture" output="false" access="public" returntype="any" hint="Add a previous authorization to be settled">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="authorization" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		
		<!--- set general values --->
		<cfset post["amount"] = arguments.money.getAmount() />
		<cfset post["type"] = "capture" />
		<cfset post["transactionid"] = arguments.authorization />

		<!--- capture can also take the following options values:
			descriptor (optional) 
			descriptor_phone (optional) 
			type (required) 
			amount (required) Format: x.xx 
			transactionid (required) 
			tracking_number (optional) 
			shipping_carrier (optional) Format: ups / fedex / dhl / usps 
			orderid (optional) 
		--->

		<cfreturn process(payload = post, options = options) />
	</cffunction>


	<!--- refund all or part of a previous settled transaction --->
	<cffunction name="credit" output="false" access="public" returntype="any" hint="Credit all or part of a previous transaction">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="transactionid" type="any" required="false" />
		<cfargument name="account" type="any" required="false" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		
		<!--- set general values --->
		<cfset post["amount"] = arguments.money.getAmount() />

		<cfif structKeyExists(arguments, "account") AND lcase(listLast(getMetaData(arguments.account).fullname, ".")) EQ "eft">
			<!--- in the direct deposit scenario, we need the account --->
			<cfset post["type"] = "credit" />
			<cfset post = addEFT(post = post, account = arguments.account, options = arguments.options) />
		<cfelseif structKeyExists(arguments.options, "tokenId")>
			<!--- direct deposit using the vault --->
			<cfset post["type"] = "credit" />
			<cfset post["customer_vault_id"] = arguments.options.tokenId /><!--- redundant due to normalized processing in process() --->
		<cfelseif structKeyExists(arguments, "transactionid")>
			<cfset post["type"] = "refund" />
			<cfset post["transactionid"] = arguments.transactionid />
		</cfif>

		<cfreturn process(payload = post, options = options) />
	</cffunction>


	<cffunction name="void" output="false" access="public" returntype="any" hint="">
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		
		<!--- set general values --->
		<cfset post["type"] = "void" />
		<cfset post["transactionid"] = arguments.transactionid />

		<cfreturn process(payload = post, options = options) />
	</cffunction>


	<!--- function to get a copy of the actual transaction response
	
		Only requests that have valid structure and therefore reach the processing modules are available for this.
	--->	
	<cffunction name="status" output="false" access="public">
		<cfargument name="transactionid" type="any" required="false" hint="If checking status of a transaction with unknown response, this may not be known and can be blank" />
		<cfargument name="options" type="any" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		<cfset post["type"] = "query" />		

		<cfif structKeyExists(arguments, "transactionid")>
			<cfset post["transaction_id"] = arguments.transactionid />
		</cfif>

		<!---
			email (recommended) 
			orderid (optional) 
			last_name (optional) 
			cc_number (optional, use either the full number or the last 4 digits of the number)
			start_date (optional) 
			end_date (optional) 
			condition (optional, [pending|pendingsettlement|failed|canceled|complete|unknown], you can send multiple values separated by commas) 
			transaction_type (optional, [cc|ck]) 
			action_type (optional, [sale|refund|credit|auth|capture|void], can send multiple separated by commas) 
			transaction_id (optional, Original Payment Gateway Transaction ID. This value was passed in the response of a previous Gateway Transaction. Please note that in the Payment Gateway, this value is called transaction (no underscore))
			report_type=customer_vault (optional) for running a query against the SecureVault
		--->

		<cfreturn process(payload = post, options = arguments.options) />
	</cffunction>


	<cffunction name="store" output="false" access="public" returntype="any" hint="Put payment information into the vault">
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		<cfset var res = "" />
		
		<cfswitch expression="#lcase(listLast(getMetaData(arguments.account).fullname, "."))#">
			<cfcase value="creditcard">
				<cfset post = addCreditCard(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfcase value="eft">
				<cfset post = addEFT(post = post, account = arguments.account, options = arguments.options) />
			</cfcase>
			<cfdefaultcase>
				<cfthrow type="cfpayment.InvalidAccount" message="Account type of token is not supported by this method." />
			</cfdefaultcase>
		</cfswitch>

		<cfset post["customer_vault"] = "add_customer" />
		<cfset post = addCustomer(post = post, account = arguments.account) />

		<!--- check if we have an optional vault id --->
		<cfif structKeyExists(arguments.options, "tokenId")>
			<cfset post["customer_vault_id"] = arguments.options.tokenId />
			<cfset post["customer_vault"] = "update_customer" /><!--- tell it to update --->
		</cfif>
		
		<!--- process transaction --->
		<cfreturn process(payload = post, options = arguments.options) />
	</cffunction>


	<cffunction name="unstore" output="false" access="public" returntype="any" hint="Delete information from the vault">
		<cfargument name="account" type="any" required="true" /><!--- must be type of "token"? --->
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />
		<cfset var res = "" />

		<cfif lcase(listLast(getMetaData(arguments.account).fullname, ".")) NEQ "token">
			<cfthrow type="cfpayment.InvalidAccount" message="Only an account type of token is supported by this method." />
		</cfif>
			
		<cfset post["customer_vault"] = "delete_customer" />
		<cfset post = addToken(post = post, account = arguments.account) />

		<!--- process transaction --->
		<cfreturn process(payload = post, options = arguments.options) />
		
	</cffunction>	
 

	<!--- override getGatewayURL to inject the extra URL method per gateway method  --->
	<cffunction name="getGatewayURL" access="public" output="false" returntype="any" hint="">
		<!--- argumentcollection will include method and payload --->
		<cfargument name="payload" type="struct" required="true" />
		
		<cfif structKeyExists(arguments.payload, "type") AND arguments.payload.type EQ "query">
			<cfreturn variables.cfpayment.GATEWAY_REPORT_URL />
		<cfelse>
			<cfreturn variables.cfpayment.GATEWAY_LIVE_URL />
		</cfif>
	</cffunction>

	<!--- ------------------------------------------------------------------------------

		  PRIVATE HELPER METHODS

		  ------------------------------------------------------------------------- --->
	<cffunction name="addCustomer" output="false" access="private" returntype="any" hint="Add customer contact details to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />
		
		<cfset arguments.post["firstname"] = arguments.account.getFirstName() />
		<cfset arguments.post["lastname"] = arguments.account.getLastName() />
		<cfset arguments.post["address1"] = arguments.account.getAddress() />
		<cfset arguments.post["city"] = arguments.account.getCity() />
		<cfset arguments.post["state"] = arguments.account.getRegion() />
		<cfset arguments.post["zip"] = arguments.account.getPostalCode() />
		<cfset arguments.post["country"] = arguments.account.getCountry() />
	
		<cfreturn arguments.post />
	</cffunction>


	<cffunction name="addCreditCard" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		
		<cfset post["payment"] = "creditcard" />
		<cfset post["ccnumber"] = arguments.account.getAccount() />
		<cfset post["ccexp"] = arguments.account.getMonth() & right(arguments.account.getYear(), 2) />
		<cfset post["cvv"] = arguments.account.getVerificationValue() />

		<!--- if we want to save the instrument to the vault; check if we have an optional vault id --->
		<cfif structKeyExists(arguments.options, "tokenize")>
			<cfset post["customer_vault"] = "add_customer" />
			<cfif structKeyExists(arguments.options, "tokenId")>
				<cfset post["customer_vault_id"] = arguments.options.tokenId />
			</cfif>
		</cfif>

		<cfreturn arguments.post />
	</cffunction>


	<cffunction name="addEFT" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		
		<cfset arguments.post["payment"] = "check" />
		<cfset arguments.post["checkname"] = arguments.account.getName() />
		<cfset arguments.post["checkaba"] = arguments.account.getRoutingNumber() />
		<cfset arguments.post["checkaccount"] = arguments.account.getAccount() />
		<cfset arguments.post["account_type"] = arguments.account.getAccountType() />
		<cfset arguments.post["phone"] = arguments.account.getPhoneNumber() />
		<cfset arguments.post["sec_code"] = arguments.account.getSEC() />

		<!--- convert SEC code to braintree values --->
		<cfif arguments.account.getSEC() EQ "PPD">
			<cfset arguments.post["account_holder_type"] = "personal" />
		<cfelseif arguments.account.getSEC() EQ "CCD">
			<cfset arguments.post["account_holder_type"] = "business" />
		</cfif>

		<!--- if we want to save the instrument to the vault; check if we have an optional vault id --->
		<cfif structKeyExists(arguments.options, "tokenize")>
			<cfset post["customer_vault"] = "add_customer" />
			<cfif structKeyExists(arguments.options, "tokenId")>
				<cfset post["customer_vault_id"] = arguments.options.tokenId />
			</cfif>
		</cfif>
	
		<cfreturn arguments.post />
	</cffunction>


	<cffunction name="addToken" output="false" access="private" returntype="any" hint="Add payment source fields to the request object">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />
		
		<!--- required when using as a payment source --->
		<cfset arguments.post["customer_vault_id"] = arguments.account.getID() />

		<cfreturn arguments.post />
	</cffunction>


</cfcomponent>
