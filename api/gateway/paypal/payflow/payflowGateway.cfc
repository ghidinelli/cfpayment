<!---
	Copyright 2012 Andrew Penhorwood (http://www.coldbits.com/)

	Based on nvpgateway.cfc by Joseph Lamoree (http://www.lamoree.com/) & Brian Ghidinelli (http://www.ghidinelli.com/)

	Licensed under the Apache License, Version 2.0 (the "License"); you
	may not use this file except in compliance with the License. You may
	obtain a copy of the License at:

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

	Paypal Reference: https://cms.paypal.com/cms_content/US/en_US/files/developer/PayflowGateway_Guide.pdf

	Configuration
		Partner:            provided by PayPal ( partner )
		MerchantAccount:    provided by PayPal ( vendor )
		Username:           provided by PayPal ( username )
		Password:           provided by PayPal ( pwd )
		CheckAVS:           true (default) or false; enforce Address Verification Service checking
		CheckCVV:           true (default) or false; enforce Card Verification Value checking
		Masking:            true (default) or false; Masks account data to comply with PCI DSS
--->
<cfcomponent extends="cfpayment.api.gateway.base" hint="Name-Value Pair API for Payflow" output="false">

	<!--- cfpayment structure values override base class --->
	<cfset variables.cfpayment['GATEWAY_NAME'] = "Payflow Gateway via Name-Value Pairs">
	<cfset variables.cfpayment['GATEWAY_VERSION'] = "1.0">
	<cfset variables.cfpayment['GATEWAY_TEST_URL'] = "https://pilot-payflowpro.paypal.com">
	<cfset variables.cfpayment['GATEWAY_LIVE_URL'] = "https://payflowpro.paypal.com">
	<cfset variables.cfpayment['GATEWAY_REFERENCE'] = "Gateway Developer Guide and Reference - 31-July-2012">
	<cfset variables.cfpayment['GATEWAY_MASKING'] = true>
	<cfset variables.cfpayment['GATEWAY_CHECKAVS'] = true>
	<cfset variables.cfpayment['GATEWAY_CHECKCVV'] = true>

<!--- =======================================================================================================
	  purchase                                                                                              =
	  ================================================================================================== --->
	<cffunction name       = "purchase"
				access     = "public"
				returntype = "any"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="money" type="any" required="true">
		<cfargument name="account" type="any" required="true">
		<cfargument name="options" type="struct" required="false" default="#structNew()#">

		<cfset var payload = structNew()>

		<cfset addCustomer(payload=payload, account=arguments.account, options=arguments.options)>
		<cfset addCreditCard(payload=payload, account=arguments.account)>
		<cfset addOptions(payload, arguments.options)>

		<cfset payload['TRXTYPE'] = "S">   <!--- Sale Transaction --->
		<cfset payload['AMT'] = trim(arguments.money.getAmount())>
		<cfset payload['CURRENCY'] = arguments.money.getCurrency()>

		<cfreturn process(payload=payload, options=arguments.options)>
	</cffunction>

<!--- =======================================================================================================
	  authorize                                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "authorize"
				access     = "public"
				returntype = "any"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="money" type="any" required="true">
		<cfargument name="account" type="any" required="true">
		<cfargument name="options" type="struct" required="false" default="#structNew()#">

		<cfset var payload = structNew()>

		<cfset addCustomer(payload=payload, account=arguments.account, options=arguments.options)>
		<cfset addCreditCard(payload=payload, account=arguments.account)>
		<cfset addOptions(payload, arguments.options)>

		<cfset payload['TRXTYPE'] = "A">   <!--- Authorization Transaction --->
		<cfset payload['AMT'] = trim(arguments.money.getAmount())>
		<cfset payload['CURRENCY'] = arguments.money.getCurrency()>

		<cfreturn process(payload=payload, options=arguments.options)>
	</cffunction>

<!--- =======================================================================================================
	  capture                                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "capture"
				access     = "public"
				returntype = "any"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="money" type="any" required="true">
		<cfargument name="authorization" type="any" required="true">
		<cfargument name="options" type="struct" required="false" default="#structNew()#">

		<cfset var payload = structNew()>

		<cfset addOptions(payload, arguments.options)>

		<cfset payload['TRXTYPE'] = "D">   <!--- Delayed Capture Transaction --->
		<cfset payload['origID'] = arguments.authorization>
		<cfset payload['AMT'] = trim(arguments.money.getAmount())>
		<cfset payload['CURRENCY'] = arguments.money.getCurrency()>

		<cfreturn process(payload=payload, options=arguments.options)>
	</cffunction>

<!--- =======================================================================================================
	  credit                                                                                                =
	  ================================================================================================== --->
	<cffunction name       = "credit"
				access     = "public"
				returntype = "any"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="money" type="any" required="true">
		<cfargument name="transactionID" type="any" required="true">
		<cfargument name="options" type="struct" required="false" default="#structNew()#">

		<cfset var payload = structNew()>

		<cfset addOptions(payload, arguments.options)>

		<cfset payload['TRXTYPE'] = "C">   <!--- Credit Transaction --->
		<cfset payload['origID'] = arguments.transactionID>
		<cfset payload['AMT'] = trim(arguments.money.getAmount())>
		<cfset payload['CURRENCY'] = arguments.money.getCurrency()>

		<cfreturn process(payload=payload, options=arguments.options)>
	</cffunction>

<!--- =======================================================================================================
	  status                                                                                                =
	  ================================================================================================== --->
	<cffunction name       = "status"
				access     = "public"
				returntype = "any"
				output     = "false"
				purpose    = "Inquiry Transaction by TransactionID. Other types of inquiry transactions are not supported."
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="money" type="any" required="true">
		<cfargument name="transactionID" type="any" required="true">
		<cfargument name="options" type="struct" required="false" default="#structNew()#">

		<cfset var payload = structNew()>

		<cfset addOptions(payload, arguments.options)>

		<cfset payload['TRXTYPE'] = "I">   <!--- Inquiry Transaction --->
		<cfset payload['origID'] = arguments.transactionID>

		<cfreturn process(payload=payload, options=arguments.options)>
	</cffunction>

<!--- =======================================================================================================
	  void                                                                                                  =
	  ================================================================================================== --->
	<cffunction name       = "void"
				access     = "public"
				returntype = "any"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="transactionID" type="any" required="true">
		<cfargument name="options" type="struct" required="false" default="#structNew()#">

		<cfset var payload = structNew()>

		<cfset addOptions(payload, arguments.options)>

		<cfset payload['TRXTYPE'] = "V">   <!--- Void Transaction --->
		<cfset payload['origID'] = arguments.transactionID>

		<cfreturn process(payload=payload, options=arguments.options)>
	</cffunction>

<!--- =======================================================================================================
	  getIsCCEnabled                                                                                        =
	  ================================================================================================== --->
	<cffunction name       = "getIsCCEnabled"
				access     = "public"
				returntype = "boolean"
				output     = "false"
				purpose    = "determine whether or not this gateway can accept credit card transactions"
				author     = "Andrew Penhorwood"
				created    = "08/31/2012">

		<cfreturn true>
	</cffunction>


<!--- ------------------------------------------------------------------------------------------------------------------------------------------------
	  get/set methods                                                                                                                                -
	  ------------------------------------------------------------------------------------------------------------------------------------------- --->


<!--- =======================================================================================================
	  getCheckAVS                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "getCheckAVS"
				access     = "public"
				returntype = "boolean"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfreturn variables.cfpayment.GATEWAY_CHECKAVS>
	</cffunction>

<!--- =======================================================================================================
	  setCheckAVS                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "setCheckAVS"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="checkAVS" type="boolean" required="true">

		<cfset variables.cfpayment['GATEWAY_CHECKAVS'] = arguments.checkAVS>
	</cffunction>

<!--- =======================================================================================================
	  getCheckCVV                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "getCheckCVV"
				access     = "public"
				returntype = "boolean"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfreturn variables.cfpayment.GATEWAY_CHECKCVV>
	</cffunction>

<!--- =======================================================================================================
	  setCheckCVV                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "setCheckCVV"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="checkCVV" type="boolean" required="true">

		<cfset variables.cfpayment['GATEWAY_CHECKCVV'] = arguments.checkCVV>
	</cffunction>

<!--- =======================================================================================================
	  getMasking                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "getMasking"
				access     = "public"
				returntype = "boolean"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfreturn variables.cfpayment.GATEWAY_MASKING>
	</cffunction>

<!--- =======================================================================================================
	  setMasking                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "setMasking"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="masking" type="boolean" required="true">

		<cfset variables.cfpayment['GATEWAY_MASKING'] = arguments.masking>
	</cffunction>

<!--- =======================================================================================================
	  getPartner                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "getPartner"
				access     = "public"
				returntype = "string"
				output     = "false"
				purpose    = "returns the payflow gateway partner value"
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfreturn variables.cfpayment.GATEWAY_PARTNER>
	</cffunction>

<!--- =======================================================================================================
	  setPartner                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "setPartner"
				access     = "public"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="partner" type="string" required="true">

		<cfset variables.cfpayment.GATEWAY_PARTNER = arguments.partner>
	</cffunction>


<!--- ------------------------------------------------------------------------------------------------------------------------------------------------
	  private internal methods                                                                                                                       -
	  ------------------------------------------------------------------------------------------------------------------------------------------- --->


<!--- =======================================================================================================
	  addCustomer                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "addCustomer"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = "populate payload with customer billing information"
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="payload" type="struct" required="true">
		<cfargument name="account" type="any" required="true">
		<cfargument name="options" type="struct" required="true">

		<cfset var p = arguments.payload>
		<cfset var a = arguments.account>
		<cfset var o = arguments.options>

		<cfset p['BILLTOFIRSTNAME'] = a.getFirstName()>
		<cfset p['BILLTOLASTNAME'] = a.getLastName()>
		<cfset p['BILLTOSTREET'] = a.getAddress()>
		<cfset p['BILLTOCITY'] = a.getCity()>
		<cfset p['BILLTOSTATE'] = a.getRegion()>
		<cfset p['BILLTOCOUNTRY'] = a.getCountry()>
		<cfset p['BILLTOZIP'] = a.getPostalCode()>

		<cfif len(a.getPhoneNumber())>
			<cfset p['BILLTOPHONENUM'] = a.getPhoneNumber()>
		</cfif>

		<cfif structKeyExists(o, "email") and len(o.email)>
			<cfset p['BILLTOEMAIL'] = o.email>
		</cfif>

		<cfif structKeyExists(o, "company") and len(o.company)>
			<cfset p['COMPANYNAME'] = o.company>
		</cfif>

		<!--- enforce use of required AVS name/value pairs --->
		<cfif getCheckAVS() AND ( len(p.BILLTOSTREET) EQ 0  OR  len(p.BILLTOZIP) EQ 0 )>
			<cfthrow type="cfpayment.Gateway.Error" message="Missing Argument" detail="The of the following arguments are required: BillToStreet and BillToZip">
		</cfif>
	</cffunction>

<!--- =======================================================================================================
	  addCreditCard                                                                                         =
	  ================================================================================================== --->
	<cffunction name       = "addCreditCard"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = "populate payload with credit card information"
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="payload" type="struct" required="true">
		<cfargument name="account" type="any" required="true">

		<cfset var p = arguments.payload>
		<cfset var a = arguments.account>
		<cfset var expMonth = a.getMonth()>
		<cfset var expYear = right(a.getYear(),2)> <!--- paypal uses 2 digit dates --->

		<cfif len(expMonth) EQ 1>
			<cfset expMonth = "0" & expMonth>
		</cfif>

		<cfset p['ACCT'] = a.getAccount()>
		<cfset p['CVV2'] = a.getVerificationValue()>
		<cfset p['EXPDATE'] = expMonth & expYear>
		<cfset p['TENDER'] = "C">   <!--- CreditCard --->

		<!--- enforce use of required Card Verification Value name/value pair --->
		<cfif getCheckCVV() AND ( len(p.CVV2) EQ 0 )>
			<cfthrow type="cfpayment.Gateway.Error" message="Missing Argument" detail="The of the following argument is required: Card Verification Value (CVV)">
		</cfif>
	</cffunction>

<!--- =======================================================================================================
	  addOptions                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "addOptions"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = "populate payload with optional name/value pairs"
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="payload" type="struct" required="true">
		<cfargument name="options" type="struct" required="true">

		<cfset var p = arguments.payload>
		<cfset var o = arguments.options>

		<cfif structKeyExists(o, "orderID")>
			<cfset p['INVNUM'] = o.orderID>
			<cfset p['comment1'] = o.orderID>   <!--- copy orderID into comment1 so it appears on all reports in paypal manager --->
		</cfif>
	</cffunction>

<!--- =======================================================================================================
	  addCredentials                                                                                        =
	  ================================================================================================== --->
	<cffunction name       = "addCredentials"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = "populate payload with paypal manager logon credentials.  Normally this is an API only user"
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="payload" type="struct" required="true">

		<cfset var p = arguments.payload>

		<cfset p['PARTNER'] = getPartner()>
		<cfset p['VENDOR'] = getMerchantAccount()>
		<cfset p['USER'] = getUsername()>
		<cfset p['PWD'] = getPassword()>
	</cffunction>

<!--- =======================================================================================================
	  addHeaders                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "addHeaders"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = "supplies the CFHTTP header name/value pairs used by the gateway."
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="headers" type="struct" required="true">

		<cfset var h = arguments.headers>

		<cfset h['X-VPS-Request-ID'] = createUUID()>	<!--- X-VPS-Request-ID is a required http header.  Docs say 1-32 characters??  gateway request will not work without it --->
	</cffunction>

<!--- =======================================================================================================
	  addDetailReponses                                                                                     =
	  ================================================================================================== --->
	<cffunction name       = "addDetailReponses"
				access     = "private"
				returntype = "void"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="payload" type="struct" required="true">

		<cfset var p = arguments.payload>

		<cfset p['VERBOSITY'] = "HIGH">
	</cffunction>

<!--- =======================================================================================================
	  mask                                                                                                  =
	  ================================================================================================== --->
	<cffunction name       = "mask"
				access     = "private"
				returntype = "string"
				output     = "false"
				purpose    = "mask value part of name/value pairs according to industry standard rules"
				author     = "Brian Ghidinelli or Joseph Lamoree modified by Andrew Penhorwood"
				created    = "2008">

		<cfargument name="name" type="string" required="true">
		<cfargument name="value" type="string" required="true">

		<cfset var n = arguments.name>
		<cfset var v = arguments.value>
		<cfset var masked = "">

		<!--- Don't let any exceptions stop the transaction --->
		<cftry>
			<cfif (compareNoCase("ACCT", n) EQ 0) AND (len(v) GT 4)>
				<cfset masked = repeatString("X", len(v) - 4) & right(v, 4)>
			<cfelseif inList("CVV2,PWD", n)>
				<cfset masked = repeatString("X", len(v))>
			<cfelse>
				<cfset masked = v>
			</cfif>

			<cfcatch type="any">
				<!--- Fail without disclosing any data --->
				<cfset masked = "MaskingException on #n#">
			</cfcatch>
		</cftry>

		<cfreturn masked>
	</cffunction>

<!--- =======================================================================================================
	  inList                                                                                                =
	  ================================================================================================== --->
	<cffunction name       = "inList"
				access     = "private"
				returntype = "boolean"
				output     = "no"
				hint       = "looks for an item in a list and returns true if item is present"
				author     = "Andrew Penhorwood"
				created    = "01/14/2010">

		<cfargument name="list" type="string" required="yes">
		<cfargument name="item" type="string" required="yes">
		<cfargument name="delimiter" type="string" default=",">
		<cfargument name="noCase" type="boolean" default="true">

		<cfset var result = false>

		<cfif arguments.noCase>
			<cfset result = ListFindNoCase(arguments.list, arguments.item, arguments.delimiter) NEQ 0>
		<cfelse>
			<cfset result = ListFind(arguments.list, arguments.item, arguments.delimiter) NEQ 0>
		</cfif>

		<cfreturn result>
	</cffunction>

<!--- ------------------------------------------------------------------------------------------------------------------------------------------------
	  response methods                                                                                                                               -
	  ------------------------------------------------------------------------------------------------------------------------------------------- --->

<!--- =======================================================================================================
	  process                                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "process"
				access     = "private"
				returntype = "any"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="payload" type="struct" required="true">
		<cfargument name="options" type="struct" required="true">

		<cfset var response = "null">
		<cfset var results = structNew()>
		<cfset var headers = structNew()>
		<cfset var rd = "null">
		<cfset var n = "">
		<cfset var cSUCCESS = 0> <!--- pseudo constant --->

		<!---
			Minimum Requirements for Payflow Gateway:

			The following is the minimum set of NAME/VALUE pairs that must be submitted to the payment gateway for each credit card transaction.

		headers
			X-VPS-Request-ID - 36 alphanumeric character string - generated automatically

		formfields
			PARTNER ......... Partner - value provided by Paypal, normally in an email.
			VENDOR .......... Merchant's Login ID (set by user when signing up for account
			USER ............ Defined in Paypal Manager (https://manager.paypal.com) for API transactions
			PWD ............. Defined in Paypal Manager (https://manager.paypal.com) for API transactions

			TRXTYPE ......... Paypal Code - Type of Transaction to perform
			AMT ............. Amount of Transaction (xxxx.xx format)
			TENDER .......... Paypal Code - Method of Payment
			ACCT ............ Credit Card Number
			EXPDATE ......... Credit Card Expiration date (mmyy)
			CVVS ............ Credit Card Verification Value (needed for CVV to work, called Card Security Code by Paypal)

			BILLTOSTREET .... Customer Street (needed for AVS to work)
			BILLTOZIP ....... Customer Postal Code (needed for AVS to work)
		--->

		<cfset addCredentials(arguments.payload)>
		<cfset addHeaders(headers)>
		<cfset addDetailReponses(arguments.payload)>
		<cfset response = createResponse(argumentCollection = super.process(payload=arguments.payload, headers=headers, encoded="false"))>

		<cfif response.hasError()>
			<!--- Service did not receive an HTTP response --->
			<cfset response.setStatus(getService().getStatusUnknown())>
		<cfelse>
			<cfset results = parseResponse(response.getResult())>
			<cfset response.setParsedResult(results)>

			<!--- request declined --->
			<cfif results.result NEQ cSUCCESS>
				<cfset response.setStatus(getService().getStatusDeclined())>
				<cfif structKeyExists(results, "RESPMSG")>
					<cfset response.setMessage(results.RESPMSG)>
				</cfif>

			<!--- request successful --->
			<cfelseif results.result EQ cSUCCESS>
				<cfset response.setStatus(getService().getStatusSuccessful())>

				<cfif structKeyExists(arguments.payload, "TRXTYPE")>
					<!--- authorize (Authorization Transaction) & purchase (Sale Transaction) --->
					<cfif inList("A,S", arguments.payload.TRXTYPE)>
						<cfif structKeyExists(results, "PNREF")>
							<cfset response.setTransactionId(results.PNREF)>
							<cfset response.setAuthorization(results.PNREF)>
						</cfif>

					<!--- capture (Delayed Capture Transaction) --->
					<cfelseif inList("D,C,I,V", arguments.payload.TRXTYPE)>
						<cfif structKeyExists(results, "PNREF")>
							<cfset response.setTransactionId(results.PNREF)>
						</cfif>

					</cfif>
				</cfif>

				<!--- handle common response fields --->
				<cfif structKeyExists(results, "RESPMSG")>
					<cfset response.setMessage(results.RESPMSG)>
				</cfif>

				<!--- handle Address Verification Service field --->
				<cfif structKeyExists(results, "PROCAVS")>
					<cfset response.setAVSCode( normalizeAVSresponse(results.PROCAVS) )>
				</cfif>

				<!--- handle Card Verification Value field --->
				<cfif structKeyExists(results, "PROCCVV2")>
					<cfset response.setCVVCode( normalizeCVVresponse(results.PROCCVV2) )>
				</cfif>

			<cfelse>
				<cfset response.setStatus(getService().getStatusFailure())>
			</cfif>
		</cfif>

		<!--- Mask the request data --->
		<cfif getMasking()>
			<cfset rd = response.getRequestData()>
			<cfloop collection="#rd.PAYLOAD#" item="n">
				<cfset rd.PAYLOAD[n] = mask(n, rd.PAYLOAD[n])>
			</cfloop>
			<cfset response.setRequestData(rd)>
		</cfif>

		<cfreturn response>
	</cffunction>


<!--- ------------------------------------------------------------------------------------------------------------------------------------------------
	  response methods                                                                                                                               -
	  ------------------------------------------------------------------------------------------------------------------------------------------- --->


<!--- =======================================================================================================
	  normalizeAVSresponse                                                                                  =
	  ================================================================================================== --->
	<cffunction name       = "normalizeAVSresponse"
				access     = "private"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="paypalCode" type="string" required="true">

		<cfset var code = arguments.paypalCode>

		<!--- possible paypal code that match response.cfc codes A,B,C,D,E,G,N,P,R,S,U,W,X,Y,Z --->

		<!--- codes that don't match response.cfc --->
		<cfif code EQ "F"> <!--- UK match on address and postal --->
			<cfset code = "X">

		<cfelseif code EQ "I"> <!--- International Unavaliable --->
			<cfset code = "G">

		<cfelse> <!--- anything else (all others in paypal docs) --->
			<cfset code = "E">
		</cfif>

		<cfreturn code>
	</cffunction>

<!--- =======================================================================================================
	  normalizeCVVresponse                                                                                  =
	  ================================================================================================== --->
	<cffunction name       = "normalizeCVVresponse"
				access     = "private"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "08/30/2012">

		<cfargument name="paypalCode" type="string" required="true">

		<cfset var code = arguments.paypalCode>

		<!--- possible paypal code that match response.cfc codes M,N,P --->

		<!--- codes that don't match response.cfc --->
		<cfif code EQ "X"> <!--- No Response --->
			<cfset code = "U">

		<cfelse> <!--- anything else (S,U) Service Not Supported,Unavaliable --->
			<cfset code = "X">
		</cfif>

		<cfreturn code>
	</cffunction>

<!--- =======================================================================================================
	  parseResponse                                                                                         =
	  ================================================================================================== --->
	<cffunction name       = "parseResponse"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = "parse gateway response into name/value pairs"
				author     = "Joseph Lamoree or Brian Ghidinelli modified by Andrew Penhorwood"
				created    = "2008">

		<cfargument name="data" type="string" required="true">

		<cfset var parsed = structNew()>
		<cfset var pair = "">
		<cfset var name = "">
		<cfset var value = "">

		<cfloop index="pair" list="#arguments.data#" delimiters="&">
			<cfset name = listFirst(pair, "=")>

			<cfif listLen(pair, "=") GT 2>
				<cfset value = urlDecode(listRest(pair,"="))>
			<cfelseif listLen(pair, "=") EQ 2>
				<cfset value = urlDecode(listLast(pair,"="))>
			<cfelse>
				<cfset value = "">
			</cfif>

			<!--- determine if we need to mask value for display --->
			<cfif inList("CVV2,PWD,ACCT", name) and getMasking()>
				<cfset parsed[name] = mask(name, value)>
			<cfelse>
				<cfset parsed[name] = value>
			</cfif>
		</cfloop>

		<cfreturn parsed>
	</cffunction>

</cfcomponent>