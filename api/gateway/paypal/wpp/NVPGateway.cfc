<!---

	Copyright 2009 Joseph Lamoree (http://www.lamoree.com/)

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
		FraudManagement:				off (default) or on

--->

<cfcomponent extends="cfpayment.api.gateway.base" hint="Name-Value Pair API Gateway for PayPal Website Payments Pro" output="false">

	<!--- cfpayment structure values override base class --->
	<cfset variables.cfpayment.GATEWAY_NAME = "Name-Value Pair API Gateway for PayPal Website Payments Pro" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "https://api-3t.sandbox.paypal.com/nvp" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://api-3t.paypal.com/nvp" />
	<cfset variables.cfpayment.GATEWAY_API_VERSION = "56.0" />
	<cfset variables.cfpayment.GATEWAY_CREDENTIAL_TYPE = "signature" />
	<cfset variables.cfpayment.GATEWAY_SIGNATURE = "" />
	<cfset variables.cfpayment.GATEWAY_CERTIFICATE = "" />
	<cfset variables.cfpayment.GATEWAY_FRAUD_MANAGEMENT = "off" />


	<cffunction name="purchase" output="false" access="public" returntype="any">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />

		<cfset var post = structNew() />

		<cfset post.AMT = arguments.money.getAmount() />
		<cfset post.CURRENCYCODE = arguments.money.getCurrency() />
		<cfset post.METHOD = "DoDirectPayment" />
		<cfset post.PAYMENTACTION = "Sale" />
		<cfset addCustomer(post=post, account=arguments.account, options=arguments.options) />
		<cfset addCreditCard(post=post, account=arguments.account) />

		<cfreturn process(payload=post, options=arguments.options) />
	</cffunction>


	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfset var response = "null" />			<!--- An instance of cfpayment.api.model.Response --->
		<cfset var results = structNew() />		<!--- The parsed and decoded fields from PayPal --->
		<cfset var _payload = arguments.payload />

		<cfset _payload.VERSION = getAPIVersion() />
		<cfset addClient(_payload, arguments.options) />
		<cfset addCredentials(_payload) />

		<cfset response = super.process(payload=_payload) />

		<cfif response.hasError()>
			<cfset response.setStatus(getService().getStatusUnknown()) />
		<cfelse>
			<cfset results = parseResponse(response.getResult()) />
			<cfset response.setParsedResult(results) />

			<cfif structKeyExists(results, "AVSCODE")>
				<cfset response.setAVSCode(results.AVSCODE) />
			</cfif>
			<cfif structKeyExists(results, "CVV2MATCH")>
				<cfset response.setCVVCode(results.CVV2MATCH) />
			</cfif>

			<cfif results.ACK eq "Failure">
				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfif structKeyExists(results, "L_LONGMESSAGE0")>
					<cfset response.setMessage(results.L_LONGMESSAGE0) />
				</cfif>
			<cfelseif results.ACK eq "Success">
				<cfset response.setStatus(getService().getStatusSuccessful()) />
				<cfif _payload.PAYMENTACTION eq "Authorization">
					<cfif structKeyExists(results, "TRANSACTIONID")>
						<cfset response.setAuthorization(results.TRANSACTIONID) />
					</cfif>
				<cfelseif _payload.PAYMENTACTION eq "Sale">
					<cfif structKeyExists(results, "TRANSACTIONID")>
						<cfset response.setTransactionId(results.TRANSACTIONID) />
					</cfif>
				</cfif>
			<cfelse>
				<cfset response.setStatus(getService().getStatusFailure()) />
			</cfif>
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
			<cfset parsed[name] = value />
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
			<cfset createObject("component", "GatewayException").init(type="UnsupportedCredentialTypeException").doThrow() />
		</cfif>
	</cffunction>

	<cffunction name="addClient" returntype="void" access="private" output="false">
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfif not structKeyExists(arguments.options, "ipAddress")>
			<cfset createObject("component", "GatewayException").init(type="RequiredParameterMissingException").doThrow() />
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
		<cfif structKeyExists(arguments.options, "email")>
			<cfset p.EMAIL = arguments.options.email />
		</cfif>
		<cfif structKeyExists(arguments.options, "company")>
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
			<cfset createObject("component", "GatewayException").init(type="InvalidCardTypeException").doThrow() />
		</cfif>

		<cfset p.ACCT = a.getAccount() />
		<cfset p.EXPDATE = a.getMonth() & a.getYear() />
		<cfset p.CVV2 = a.getVerificationValue() />
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


</cfcomponent>