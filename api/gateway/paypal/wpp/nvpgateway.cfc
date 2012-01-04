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


	TODO: Add support for API Certificate Security, as well as API Signature Security

	Configuration
		Username:						provided by PayPal in syntax of e-mail address
		Password:						provided by PayPal as 16 alphanumeric char string
		APIVersion:						56.0 (default)
		CredentialType:					signature (default) or certificate
		Signature:						required for signature credential authentication type
		Certificate:					required for certificate credential authentication type
		FraudManagement:				off (default) or on; Enables robust fraud management, which is an optional PayPal service
		Masking:						on (default) or off; Masks account data to comply with PCI DSS
		ReturnURL						The URL that PayPal will use to return the customer
		CancelURL						The URL that PayPal will use if a customer cancels the order

--->
<cfcomponent extends="cfpayment.api.gateway.base" hint="Name-Value Pair API Gateway for PayPal Website Payments Pro" output="false">

	<!--- cfpayment structure values override base class --->
	<cfset variables.cfpayment.GATEWAY_NAME = "Name-Value Pair API Gateway for PayPal Website Payments Pro" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "https://api-3t.sandbox.paypal.com/nvp" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://api-3t.paypal.com/nvp" />
	<cfset variables.cfpayment.GATEWAY_TEST_CLIENT_URL = "https://www.sandbox.paypal.com/cgi-bin/webscr" />
	<cfset variables.cfpayment.GATEWAY_LIVE_CLIENT_URL = "https://www.paypal.com/cgi-bin/webscr" />
	<cfset variables.cfpayment.GATEWAY_API_VERSION = "56.0" />
	<cfset variables.cfpayment.GATEWAY_CREDENTIAL_TYPE = "signature" />
	<cfset variables.cfpayment.GATEWAY_SIGNATURE = "" />
	<cfset variables.cfpayment.GATEWAY_CERTIFICATE = "" />
	<cfset variables.cfpayment.GATEWAY_MASKING = "on" />
	<cfset variables.cfpayment.GATEWAY_FRAUD_MANAGEMENT = "off" />
	<cfset variables.cfpayment.GATEWAY_RETURN_URL = "http://localhost/index.cfm?event=confirmPayPalOrder" />
	<cfset variables.cfpayment.GATEWAY_CANCEL_URL = "http://localhost/index.cfm?event=cancelPayPalOrder" />


	<cffunction name="purchase" returntype="any" access="public" output="false">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />

		<cfset post.AMT = arguments.money.getAmount() />
		<cfset post.CURRENCYCODE = arguments.money.getCurrency() />
		<cfset post.METHOD = "DoDirectPayment" />
		<cfset addCustomer(post=post, account=arguments.account, options=arguments.options) />
		<cfset addCreditCard(post=post, account=arguments.account) />
		<cfset addClient(post, arguments.options) />

		<!--- TODO: Support Sale, Authorization, and Order? --->
		<cfset post.PAYMENTACTION = "Sale" />

		<cfreturn process(payload=post, options=arguments.options) />
	</cffunction>

	<cffunction name="setExpressCheckout" returntype="any" access="public" output="false">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />

		<cfset post.METHOD = "SetExpressCheckout" />
		<cfset post.AMT = arguments.money.getAmount() />
		<cfset post.CURRENCYCODE = arguments.money.getCurrency() />
		<cfset post.RETURNURL = getReturnURL() />
		<cfset post.CANCELURL = getCancelURL() />

		<!--- TODO: Support Sale, Authorization, and Order? --->
		<cfset post.PAYMENTACTION = "Sale" />

		<cfreturn process(payload=post, options=arguments.options) />
	</cffunction>

	<cffunction name="getExpressCheckoutDetails" returntype="any" access="public" output="false">
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />

		<cfset post.METHOD = "GetExpressCheckoutDetails" />
		<cfset post.TOKEN = arguments.options.tokenId />
		<cfreturn process(payload=post, options=arguments.options) />
	</cffunction>

	<cffunction name="doExpressCheckoutPayment" returntype="any" access="public" output="false">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />

		<cfset post.METHOD = "DoExpressCheckoutPayment" />
		<cfset post.AMT = arguments.money.getAmount() />
		<cfset post.CURRENCYCODE = arguments.money.getCurrency() />
		<cfset post.TOKEN = arguments.options.tokenId />
		<cfset post.PAYERID = arguments.options.payerId />

		<!--- TODO: Support Sale, Authorization, and Order? --->
		<cfset post.PAYMENTACTION = "Sale" />

		<cfreturn process(payload=post, options=arguments.options) />
	</cffunction>

	<cffunction name="cancelExpressCheckout" returntype="any" access="public" output="false">
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var result = structNew() />

		<cfreturn result />
	</cffunction>


	<cffunction name="getExpressCheckoutForward" returntype="string" access="public" output="false">
		<cfargument name="tokenId" type="string" required="true" />

		<cfset var u = "" />

		<cfif getTestMode()>
			<cfset u = variables.cfpayment.GATEWAY_TEST_CLIENT_URL />
		<cfelse>
			<cfset u = variables.cfpayment.GATEWAY_LIVE_CLIENT_URL />
		</cfif>
		<cfset u = u & "?cmd=_express-checkout&token=" & urlEncodedFormat(arguments.tokenId) />
		<cfreturn u />
	</cffunction>


	<cffunction name="process" returntype="any" access="private" output="false">
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfset var response = "null" />
		<cfset var results = structNew() />
		<cfset var rd = "null" />
		<cfset var n = "" />

		<cfset arguments.payload.VERSION = getAPIVersion() />
		<cfset addCredentials(arguments.payload) />
		<cfset response = createResponse(argumentCollection = super.process(payload=arguments.payload)) />

		<cfif response.hasError()>
			<!--- Service did not receive an HTTP response --->
			<cfset response.setStatus(getService().getStatusUnknown()) />
		<cfelse>
			<cfset results = parseResponse(response.getResult()) />
			<cfset response.setParsedResult(results) />

			<cfif arguments.payload.METHOD eq "DoDirectPayment">
				<cfif structKeyExists(results, "AVSCODE")>
					<cfset response.setAVSCode(results.AVSCODE) />
				</cfif>
				<cfif structKeyExists(results, "CVV2MATCH")>
					<cfset response.setCVVCode(results.CVV2MATCH) />
				</cfif>
			</cfif>

			<cfif results.ACK eq "Failure">
				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfif structKeyExists(results, "L_LONGMESSAGE0")>
					<cfset response.setMessage(results.L_LONGMESSAGE0) />
				</cfif>
			<cfelseif results.ACK eq "Success">
				<cfset response.setStatus(getService().getStatusSuccessful()) />



				<!--- Credit Cards --->
				<cfif structKeyExists(arguments.payload, "PAYMENTACTION")>
					<cfif arguments.payload.PAYMENTACTION eq "Authorization">
						<cfif structKeyExists(results, "TRANSACTIONID")>
							<cfset response.setAuthorization(results.TRANSACTIONID) />
						</cfif>
					<cfelseif arguments.payload.PAYMENTACTION eq "Sale">
						<cfif structKeyExists(results, "TRANSACTIONID")>
							<cfset response.setTransactionId(results.TRANSACTIONID) />
						</cfif>
						<cfif structKeyExists(results, "TOKEN")>
							<cfset response.setTokenId(results.TOKEN) />
						</cfif>
					</cfif>
				</cfif>
			<cfelse>
				<cfset response.setStatus(getService().getStatusFailure()) />
			</cfif>
		</cfif>

		<!--- Mask the request data --->
		<cfif getMasking() eq "on">
			<cfset rd = response.getRequestData() />
			<cfloop collection="#rd.PAYLOAD#" item="n">
				<cfset rd.PAYLOAD[n] = mask(n, rd.PAYLOAD[n]) />
			</cfloop>
			<cfset response.setRequestData(rd) />
		</cfif>

		<cfreturn response />
	</cffunction>


	<cffunction name="parseResponse" returntype="struct" access="private" output="false">
		<cfargument name="data" type="string" required="true" />

		<cfset var parsed = structNew() />
		<cfset var pair = "" />
		<cfset var name = "" />
		<cfset var value = "" />

		<cfloop list="#arguments.data#" index="pair" delimiters="&">
			<cfset name = listFirst(pair, "=") />
			<cfif listLen(pair, "=") gt 1>
				<cfset value = urlDecode(listLast(pair, "=")) />
			<cfelse>
				<cfset value = "" />
			</cfif>
			<cfif getMasking() eq "on">
				<cfset parsed[name] = mask(name, value) />
			<cfelse>
				<cfset parsed[name] = value />
			</cfif>
		</cfloop>
		<cfreturn parsed />
	</cffunction>



	<cffunction name="addCredentials" returntype="void" access="private" output="false">
		<cfargument name="payload" type="struct" required="true" />

		<cfset arguments.payload.USER = getUsername() />
		<cfset arguments.payload.PWD = getPassword() />

		<cfif getCredentialType() eq "signature">
			<cfset arguments.payload.SIGNATURE = getSignature() />
		<cfelseif getCredentialType() eq "certificate">
			<cfset arguments.payload.CERTIFICATE = getCertificate() />
		<cfelse>
			<cfset createObject("component", "GatewayException").init(type="UnsupportedCredentialTypeException", message="An unsupported credential type was specified.").doThrow() />
		</cfif>
	</cffunction>

	<cffunction name="addClient" returntype="void" access="private" output="false">
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfif not structKeyExists(arguments.options, "ipAddress")>
			<cfset createObject("component", "GatewayException").init(type="RequiredParameterMissingException", message="The ipAddress is a required parameter.").doThrow() />
		</cfif>
		<cfset arguments.payload.IPADDRESS = arguments.options.ipAddress />
	</cffunction>

	<cffunction name="addCustomer" returntype="void" access="private" output="false">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfset var p = arguments.post />
		<cfset var a = arguments.account />

		<cfset p.FIRSTNAME = a.getFirstName() />
		<cfset p.LASTNAME = a.getLastName() />
		<cfset p.STREET = a.getAddress() />
		<cfset p.STREET2 = a.getAddress2() />
		<cfset p.CITY = a.getCity() />
		<cfset p.STATE = a.getRegion() />
		<cfset p.COUNTRYCODE = a.getCountry() />
		<cfset p.ZIP = a.getPostalCode() />
		<cfset p.PHONENUM = a.getPhoneNumber() />
		<cfif structKeyExists(arguments.options, "email") and arguments.options.email neq "">
			<cfset p.EMAIL = arguments.options.email />
		</cfif>
		<cfif structKeyExists(arguments.options, "company") and arguments.options.company neq "">
			<cfset p.BUSINESS = arguments.options.company />
		</cfif>
	</cffunction>

	<cffunction name="addCreditCard" returntype="void" access="private" output="false">
		<cfargument name="post" type="struct" required="true" />
		<cfargument name="account" type="any" required="true" />

		<cfset var p = arguments.post />
		<cfset var a = arguments.account />

		<cfif a.getIsVisa()>
			<cfset p.CREDITCARDTYPE = "Visa" />
		<cfelseif a.getIsMasterCard()>
			<cfset p.CREDITCARDTYPE = "MasterCard" />
		<cfelseif a.getIsAmex()>
			<cfset p.CREDITCARDTYPE = "Amex" />
		<cfelseif a.getIsDiscover()>
			<cfset p.CREDITCARDTYPE = "Discover" />
		<cfelse>
			<cfset createObject("component", "GatewayException").init(type="UnsupportedCardTypeException", message="An unsupported credit card type was specified.").doThrow() />
		</cfif>

		<cfset p.ACCT = a.getAccount() />
		<cfset p.EXPDATE = a.getMonth() & a.getYear() />
		<cfset p.CVV2 = a.getVerificationValue() />
	</cffunction>

	<cffunction name="mask" returntype="string" access="private" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="value" type="string" required="true" />

		<cfscript>
			var r = "";
			var n = arguments.name;
			var v = arguments.value;

			// Don't let any exceptions stop the transaction
			try {
				if (compareNoCase("ACCT", n) eq 0) {
					r = repeatString("X", len(v) - 4) + right(v, 4);
				} else if (listContainsNoCase("CVV2,PWD,SIGNATURE", n) gt 0) {
					r = repeatString("X", len(v));
				} else {
					r = v;
				}
			}
			catch(Any e) {
				// Fail without disclosing any data
				r = "MaskingException on #n#";
			}
			return r;
		</cfscript>
	</cffunction>


	<cffunction name="getCredentialType" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_CREDENTIAL_TYPE />
	</cffunction>
	<cffunction name="setCredentialType" returntype="void" access="public" output="false">
		<cfargument name="credentialType" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_CREDENTIAL_TYPE = arguments.credentialType />
	</cffunction>

	<cffunction name="getAPIVersion" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_API_VERSION />
	</cffunction>
	<cffunction name="setAPIVersion" returntype="void" access="public" output="false">
		<cfargument name="apiVersion" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_API_VERSION = arguments.apiVersion />
	</cffunction>

	<cffunction name="getSignature" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_SIGNATURE />
	</cffunction>
	<cffunction name="setSignature" returntype="void" access="public" output="false">
		<cfargument name="signature" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_SIGNATURE = arguments.signature />
	</cffunction>

	<cffunction name="getCertificate" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_CERTIFICATE />
	</cffunction>
	<cffunction name="setCertificate" returntype="void" access="public" output="false">
		<cfargument name="certificate" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_CERTIFICATE = arguments.certificate />
	</cffunction>

	<cffunction name="getFraudManagement" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_FRAUD_MANAGEMENT />
	</cffunction>
	<cffunction name="setFraudManagement" returntype="void" access="public" output="false">
		<cfargument name="fraudManagement" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_FRAUD_MANAGEMENT = arguments.fraudManagement />
	</cffunction>

	<cffunction name="getMasking" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_MASKING />
	</cffunction>
	<cffunction name="setMasking" returntype="void" access="public" output="false">
		<cfargument name="masking" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_MASKING = arguments.masking />
	</cffunction>

	<cffunction name="getReturnURL" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_RETURN_URL />
	</cffunction>
	<cffunction name="setReturnURL" returntype="void" access="public" output="false">
		<cfargument name="returnURL" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_RETURN_URL = arguments.returnURL />
	</cffunction>

	<cffunction name="getCancelURL" returntype="string" access="public" output="false">
		<cfreturn variables.cfpayment.GATEWAY_CANCEL_URL />
	</cffunction>
	<cffunction name="setCancelURL" returntype="void" access="public" output="false">
		<cfargument name="cancelURL" type="string" required="true" />
		<cfset variables.cfpayment.GATEWAY_CANCEL_URL = arguments.cancelURL />
	</cffunction>

</cfcomponent>