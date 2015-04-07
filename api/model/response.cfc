<!---
	$Id$

	Copyright 2007 Brian Ghidinelli (http://www.ghidinelli.com/)
                   Mark Mazelin (http://www.mkville.com)

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
<cfcomponent name="response" displayname="Gateway Response" output="false" hint="Normalized result for gateway response">

	<!--- CONSTANTS in psuedo-constructor --->
	<cfscript>
		variables.cfpayment = structNew();

		variables.cfpayment.Status = "";			// set in init() to be unprocessed
		variables.cfpayment.StatusCode = "";		// hold the HTTP/connection status code 
		variables.cfpayment.Result = "";			// hold the raw response from the other end
		variables.cfpayment.TestMode = false;
		variables.cfpayment.Message = "";
		variables.cfpayment.TransactionID = ""; 	// transaction id from remote system
		variables.cfpayment.Authorization = ""; 	// six-character alphanum approval/authorization code
		variables.cfpayment.AVSCode = "";
		variables.cfpayment.CVVCode = "";
		variables.cfpayment.ParsedResult = "";
		variables.cfpayment.RequestData = "";		// store the payload from the Request; dev use only; populated only when testmode = true
		variables.cfpayment.TokenID = "";			// normalize an ID for vault/remote lockbox services (store/unstore methods)

		// list the possible AVS responses
		variables.cfpayment.ResponseAVS = structNew();
		structInsert(variables.cfpayment.ResponseAVS, "A", "Street address matches, but 5-digit and 9-digit postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "B", "Street address matches, but postal code not verified.", true);
		structInsert(variables.cfpayment.ResponseAVS, "C", "Street address and postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "D", "Street address and postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "E", "AVS data is invalid or AVS is not allowed for this card type.", true);
		structInsert(variables.cfpayment.ResponseAVS, "F", "Card member's name does not match, but billing postal code matches.", true);
		structInsert(variables.cfpayment.ResponseAVS, "G", "Non-U.S. issuing bank does not support AVS.", true);
		structInsert(variables.cfpayment.ResponseAVS, "H", "Card member's name does not match. Street address and postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "I", "Address not verified.", true);
		structInsert(variables.cfpayment.ResponseAVS, "J", "Card member's name, billing address, and postal code match. Shipping information verified and chargeback protection guaranteed through the Fraud Protection Program.", true);
		structInsert(variables.cfpayment.ResponseAVS, "K", "Card member's name matches but billing address and billing postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "L", "Card member's name and billing postal code match, but billing address does not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "M", "Street address and postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "N", "Street address and postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "O", "Card member's name and billing address match, but billing postal code does not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "P", "Postal code matches, but street address not verified.", true);
		structInsert(variables.cfpayment.ResponseAVS, "Q", "Card member's name, billing address, and postal code match. Shipping information verified but chargeback protection not guaranteed.", true);
		structInsert(variables.cfpayment.ResponseAVS, "R", "System unavailable.", true);
		structInsert(variables.cfpayment.ResponseAVS, "S", "U.S.-issuing bank does not support AVS.", true);
		structInsert(variables.cfpayment.ResponseAVS, "T", "Card member's name does not match, but street address matches.", true);
		structInsert(variables.cfpayment.ResponseAVS, "U", "Address information unavailable.", true);
		structInsert(variables.cfpayment.ResponseAVS, "V", "Card member's name, billing address, and billing postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "W", "Street address does not match, but 9-digit postal code matches.", true);
		structInsert(variables.cfpayment.ResponseAVS, "X", "Street address and 9-digit postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "Y", "Street address and 5-digit postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "Z", "Street address does not match, but 5-digit postal code matches.", true);

		// list the CVC or CVV2 response options
		variables.cfpayment.ResponseCVV = structNew();
		structInsert(variables.cfpayment.ResponseCVV, "D", "Suspicious transaction", true);
		structInsert(variables.cfpayment.ResponseCVV, "I", "Failed data validation check", true);
		structInsert(variables.cfpayment.ResponseCVV, "M", "Match", true);
		structInsert(variables.cfpayment.ResponseCVV, "N", "No Match", true);
		structInsert(variables.cfpayment.ResponseCVV, "P", "Not Processed", true);
		structInsert(variables.cfpayment.ResponseCVV, "S", "Should have been present", true);
		structInsert(variables.cfpayment.ResponseCVV, "U", "Issuer unable to process request", true);
		structInsert(variables.cfpayment.ResponseCVV, "X", "Card does not support verification", true);

	</cfscript>


	<cffunction name="init" output="false" access="public" returntype="any" hint="Instantiate (and optionally populate) the response object">
		<cfargument name="service" type="any" required="true" />
		<cfargument name="Status" type="string" required="false" />
		<cfargument name="StatusCode" type="string" required="false" />
		<cfargument name="Message" type="string" required="false" />
		<cfargument name="Result" type="string" required="false" />
		<cfargument name="RequestData" type="struct" required="false" />
		<cfargument name="TestMode" type="boolean" required="false" />

		<cfset variables.cfpayment.service = arguments.service />

		<cfif NOT structKeyExists(arguments, "Status")>
			<cfset setStatus(getService().getStatusUnprocessed()) />
		</cfif>
		
		<cfset populate(argumentCollection = arguments) />
		
		<cfreturn this />
	</cffunction>


	<cffunction name="getService" output="false" access="private" returntype="any" hint="get access to the service for generating responses, errors, etc">
		<cfreturn variables.cfpayment.service />
	</cffunction>


	<cffunction name="getSuccess" access="public" output="false" returntype="string" hint="Success is determined by comparing status to success in the core API">
		<cfreturn getStatus() EQ getService().getStatusSuccessful()>
	</cffunction>

	<cffunction name="hasError" access="public" output="false" returntype="boolean" hint="An error is determined by the status code; the list of good/bad is in the core API">
		<cfreturn listFind(getService().getStatusErrors(), getStatus()) />
	</cffunction>


	<cffunction name="getStatus" access="public" output="false" returntype="numeric" hint="Status tracks transaction flow from unprocessed to attempted to success or exception">
		<cfreturn variables.cfpayment.Status />
	</cffunction>
	<cffunction name="setStatus" access="public" output="false" returntype="any">
		<cfargument name="Status" type="any" required="true" />
		<cfset variables.cfpayment.Status = arguments.Status />
		<cfreturn this />
	</cffunction>

	<cffunction name="getStatusCode" access="public" output="false" returntype="any" hint="StatusCode represents the original connection's result status.  For HTTP this would be like 200, 404, 500, etc.  For RESTful APIs which may use status codes to define results">
		<cfreturn variables.cfpayment.StatusCode />
	</cffunction>
	<cffunction name="setStatusCode" access="public" output="false" returntype="void">
		<cfargument name="StatusCode" type="any" required="true" />
		<cfset variables.cfpayment.StatusCode = arguments.StatusCode />
	</cffunction>

	<!---  Usage: getAVSCode / setAVSCode  methods for AVSCode value --->
	<cffunction name="getAVSCode" access="public" output="false" returntype="any">
		<cfreturn variables.cfpayment.AVSCode />
	</cffunction>
	<cffunction name="setAVSCode" access="public" output="false" returntype="any">
		<cfargument name="AVSCode" type="any" required="true" />

		<cfif len(arguments.AVSCode)>
			<cfif structKeyExists(variables.cfpayment.ResponseAVS, arguments.AVSCode)>
				<cfset variables.cfpayment.AVSCode = uCase(arguments.AVSCode) />
			<cfelse>
				<cfthrow message="Invalid AVS Response Code: #arguments.AVSCode#" type="cfpayment.InvalidResponse.AVS" />
			</cfif>
		</cfif>
		
		<cfreturn this />
	</cffunction>

	<!---  Usage: getCVVCode / setCVVCode  methods for CVVCode value --->
	<cffunction name="getCVVCode" access="public" output="false" returntype="any">
		<cfreturn variables.cfpayment.CVVCode />
	</cffunction>
	<cffunction name="setCVVCode" access="public" output="false" returntype="any">
		<cfargument name="CVVCode" type="any" required="true" />

		<cfif len(arguments.CVVCode)>
			<cfif structKeyExists(variables.cfpayment.ResponseCVV, arguments.CVVCode)>
				<cfset variables.cfpayment.CVVCode = uCase(arguments.CVVCode) />
			<cfelse>
				<cfthrow message="Invalid CVV Response Code: #arguments.CVVCode#" type="cfpayment.InvalidResponse.CVV" />
			</cfif>
		</cfif>
		
		<cfreturn this />
	</cffunction>


	<!---  Gateways typically return both an Authorization code (from Visa/Amex/MC/etc) and a Transaction ID (their reference number) --->
	<cffunction name="getAuthorization" access="public" output="false" returntype="string" hint="Authorization code is a bank-provided ID generated by Visa/Amex/MC/etc">
		<cfreturn variables.cfpayment.Authorization />
	</cffunction>
	<cffunction name="setAuthorization" access="public" output="false" returntype="any">
		<cfargument name="Authorization" type="string" required="true" />
		<cfset variables.cfpayment.Authorization = arguments.Authorization />
		<cfreturn this />
	</cffunction>

	<cffunction name="getTransactionID" access="public" output="false" returntype="any" hint="Transaction ID is an ID generated by the gateway to identify the transaction">
		<cfreturn variables.cfpayment.TransactionID />
	</cffunction>
	<cffunction name="setTransactionID" access="public" output="false" returntype="any">
		<cfargument name="TransactionID" type="any" required="true" />
		<cfset variables.cfpayment.TransactionID = arguments.TransactionID />
		<cfreturn this />
	</cffunction>

	<cffunction name="getTokenID" access="public" output="false" returntype="any" hint="Token ID is the reference to an account stored by the gateway">
		<cfreturn variables.cfpayment.TokenID />
	</cffunction>
	<cffunction name="setTokenID" access="public" output="false" returntype="any">
		<cfargument name="TokenID" type="any" required="true" />
		<cfset variables.cfpayment.TokenID = arguments.TokenID />
		<cfreturn this />
	</cffunction>


	<cffunction name="getResult" access="public" output="false" returntype="any" hint="Holds the raw response from the payment processor for the gateway to parse">
		<cfreturn variables.cfpayment.Result />
	</cffunction>
	<cffunction name="setResult" access="public" output="false" returntype="any">
		<cfargument name="Result" type="any" required="true" />
		<cfset variables.cfpayment.Result = arguments.Result />
		<cfreturn this />
	</cffunction>

	<!---  hold the parsed response from the payment processor for the gateway to access and leverage --->
	<cffunction name="getParsedResult" access="public" output="false" returntype="any">
		<cfreturn variables.cfpayment.ParsedResult />
	</cffunction>
	<cffunction name="setParsedResult" access="public" output="false" returntype="any">
		<cfargument name="ParsedResult" type="any" required="true" />
		<cfset variables.cfpayment.ParsedResult = arguments.ParsedResult />
		<cfreturn this />
	</cffunction>


	<cffunction name="getTestMode" access="public" output="false" returntype="boolean">
		<cfreturn variables.cfpayment.TestMode />
	</cffunction>
	<cffunction name="setTestMode" access="public" output="false" returntype="void">
		<cfargument name="TestMode" type="boolean" required="true" />
		<cfset variables.cfpayment.TestMode = arguments.TestMode />
	</cffunction>


	<cffunction name="getRequestData" output="false" access="public" returntype="any" hint="RequestData is only populated when TestMode = true">
		<cfreturn variables.cfpayment.RequestData />
	</cffunction>
	<cffunction name="setRequestData" output="false" access="public" returntype="any" hint="Be cautious when populating RequestData.  Card holder data must be protected in compliance with PCI DSS.">
		<cfset variables.cfpayment.RequestData = arguments[1] />
		<cfreturn this />
	</cffunction>


	<!---  Usage: getMessage / setMessage  methods for Message value --->
	<cffunction name="getMessage" access="public" output="false" returntype="string" hint="Human-readable transaction result">
		<cfreturn variables.cfpayment.Message />
	</cffunction>
	<cffunction name="setMessage" access="public" output="false" returntype="any">
		<cfargument name="Message" type="string" required="true" />
		<cfset variables.cfpayment.Message = arguments.Message />
		<cfreturn this />
	</cffunction>

	<cffunction name="getAVSPostalMatch" output="false" access="private" returntype="string" hint="Normalize the AVS postal match code">
		<cfset var res = uCase(getAVSCode()) />

		<!--- Y = yes, N = no, X = not relevant, U = unknown --->
		<cfif listFind("D,H,F,J,L,M,P,Q,V,W,X,Y,Z", res)>
			<cfreturn 'Y' />
		<cfelseif listFind("A,C,K,N,O", res)>
			<cfreturn 'N' />
		<cfelseif listFind("G,S", res)>
			<cfreturn 'X' />
		</cfif>

		<cfreturn 'U' />
	</cffunction>

	<cffunction name="getAVSStreetMatch" output="false" access="private" returntype="string" hint="Normalize the AVS street match code">
		<cfset var res = uCase(getAVSCode()) />

		<cfif listFind("A,B,D,H,J,M,O,Q,T,V,X,Y", res)><!--- it does match --->
			<cfreturn 'Y' />
		<cfelseif listFind("C,K,L,N,P,W,Z", res)><!--- it does not match --->
			<cfreturn 'N' />
		<cfelseif listFind("G,S", res)><!--- bank does not support/verify AVS --->
			<cfreturn 'X' />
		</cfif>

		<cfreturn 'U' /><!--- unknown - AVS invalid or could not be verified --->
	</cffunction>

	<cffunction name="getAVSMessage" output="false" access="public" returntype="string" hint="Get the human-readable AVS response">
		<cfset var ret = "" />
		<cfif structKeyExists(variables.cfpayment.ResponseAVS, getAVSCode())>
			<cfset ret = variables.cfpayment.ResponseAVS[getAVSCode()] />
		</cfif>
		<cfreturn ret />
	</cffunction>

	<cffunction name="getCVVMessage" output="false" access="public" returntype="string" hint="Get the human-readable CVV response">
		<cfset var ret = "" />
		<cfif structKeyExists(variables.cfpayment.ResponseCVV, getCVVCode())>
			<cfset ret = variables.cfpayment.ResponseCVV[getCVVCode()] />
		</cfif>
		<cfreturn ret />
	</cffunction>

	<cffunction name="isValidAVS" output="false" access="public" returntype="boolean" hint="Check if AVS passed fully?">
		<cfargument name="AllowBlankCode" type="boolean" default="true" hint="Set to true to allow blank AVS return code to pass validity" />
		<cfargument name="AllowPostalOnlyMatch" type="boolean" default="false" hint="Set to true to allow postal-only AVS match to pass validity"  />
		<cfargument name="AllowStreetOnlyMatch" type="boolean" default="false" hint="Set to true to allow prohibit street-only AVS match to pass validity"  />
		<cfset var ret = false />
		<cfif (arguments.AllowBlankCode AND (len(getAVSCode()) EQ 0))>
			<cfset ret = true />
		<cfelseif len(getAVSCode())>
			<cfif arguments.AllowStreetOnlyMatch AND (getAVSStreetMatch() EQ "Y")>
				<cfset ret = true />
			<cfelseif arguments.AllowPostalOnlyMatch AND (getAVSPostalMatch() EQ "Y")>
				<cfset ret = true />
			<cfelseif (getAVSPostalMatch() EQ "Y") AND (getAVSStreetMatch() EQ "Y")>
				<cfset ret = true />
			</cfif>
		</cfif>
		<cfreturn ret />
	</cffunction>

	<cffunction name="isValidCVV" output="false" access="public" returntype="boolean" hint="Check if the CVV response indicates a match">
		<cfargument name="AllowBlankCode" type="boolean" default="true" hint="Set to true to allow blank CVV return code to pass validity" />
		<cfset var ret = false />
		<cfif (arguments.AllowBlankCode AND (len(getCVVCode()) EQ 0)) OR (getCVVCode() EQ "M")>
			<cfset ret = true />
		</cfif>
		<cfreturn ret />
	</cffunction>

	<!---
	DUMP
	--->
	<cffunction name="dump" access="public" output="true" return="void">
		<cfargument name="abort" type="boolean" default="false" />
		<cfdump var="#variables.instance#" />
		<cfif arguments.abort>
			<cfabort />
		</cfif>
	</cffunction>

	<cffunction name="getMemento" output="false" access="public" returntype="any" hint="Return a copy of the internal values">
		<cfreturn duplicate(variables.cfpayment) />
	</cffunction>

	<cffunction name="populate" access="private" returntype="void" output="false" hint="Helper function to dynamically populate setters">
		<cfset var argName = "" />
		<cfloop collection="#arguments#" item="argName">
			<cfif structKeyExists(arguments, argName) AND structKeyExists(this, "set" & argName)>
				<cfinvoke component="#this#" method="set#argName#">
					<cfinvokeargument name="#argName#" value="#arguments[argName]#" />
				</cfinvoke>
			</cfif>
		</cfloop>
	</cffunction>

</cfcomponent>