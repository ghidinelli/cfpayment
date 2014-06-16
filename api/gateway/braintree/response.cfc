<!---
	$Id$

	Copyright 2007 Brian Ghidinelli (http://www.ghidinelli.com/)

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
<cfcomponent name="response" displayname="Braintree Gateway Response" output="false" hint="Normalized result for gateway response" extends="cfpayment.api.model.response">

	<!--- CONSTANTS in psuedo-constructor --->
	<cfscript>
		// list the possible AVS responses
		variables.cfpayment.ResponseAVS = structNew();
		structInsert(variables.cfpayment.ResponseAVS, "0", "AVS Not Available", true);							// seen in wild
		structInsert(variables.cfpayment.ResponseAVS, "A", "Billing street address matches, but 5-digit or 9-digit postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "B", "Billing street address matches, but postal code not verified.", true);
		structInsert(variables.cfpayment.ResponseAVS, "C", "Billing street address and postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "D", "Billing street address and postal code match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "E", "Not a mail/phone order.", true);
		structInsert(variables.cfpayment.ResponseAVS, "F", "Address and Postal Code match (UK only).", true);
		structInsert(variables.cfpayment.ResponseAVS, "G", "Non-U.S. issuing bank does not support AVS.", true);
		structInsert(variables.cfpayment.ResponseAVS, "I", "Non-U.S. issuing bank does not support AVS.", true);
		structInsert(variables.cfpayment.ResponseAVS, "L", "Card member's name and 5-digit billing postal code match, but billing address does not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "M", "Card member's name and 5-digit billing postal code match, but billing address does not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "N", "Street address and postal code do not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "O", "Address Verification System (AVS) not available.", true);
		structInsert(variables.cfpayment.ResponseAVS, "P", "Card member's name and 5-digit billing postal code match, but billing address does not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "R", "Issuing bank Address Verificaiton System (AVS) unavailable.", true);
		structInsert(variables.cfpayment.ResponseAVS, "S", "U.S.-issuing bank does not support AVS.", true);
		structInsert(variables.cfpayment.ResponseAVS, "U", "Address information unavailable.", true);
		structInsert(variables.cfpayment.ResponseAVS, "W", "Card member's name and 9-digit billing postal code match, but billing address does not match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "X", "Cardholder's 9-digit billing postal code and billing address match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "Y", "Cardholder's 5-digit billing postal code and billing address match.", true);
		structInsert(variables.cfpayment.ResponseAVS, "Z", "Card member's name and 5-digit billing postal code match, but billing address does not match.", true);

		// list the CVC or CVV2 response options per Braintree docs
		variables.cfpayment.ResponseCVV = structNew();
		structInsert(variables.cfpayment.ResponseCVV, "M", "Match", true);																// seen in wild
		structInsert(variables.cfpayment.ResponseCVV, "N", "No Match", true);															// seen in wild
		structInsert(variables.cfpayment.ResponseCVV, "P", "Not Processed", true);														// seen in wild
		structInsert(variables.cfpayment.ResponseCVV, "S", "Merchant has indicated that CVV2/CVC2 is not present on card", true);
		structInsert(variables.cfpayment.ResponseCVV, "U", "Credit card issuing bank unable to process request, is not certified and/or has not provided Visa encryption keys", true);// seen in wild
		structInsert(variables.cfpayment.ResponseCVV, "X", "Card does not support verification", true); // seen in wild, it actually says "No such issuer" but it's a decline

	</cfscript>


	<cffunction name="getAVSPostalMatch" output="false" access="private" returntype="string" hint="Normalize the AVS postal match code">
		<cfset var res = uCase(getAVSCode()) />

		<!--- Y = yes, N = no, X = not relevant, U = unknown --->
		<cfif listFind("D,F,L,M,P,W,X,Y,Z", res)><!--- it does match --->
			<cfreturn 'Y' />
		<cfelseif listFind("A,B,C,N", res)><!--- it does not match --->
			<cfreturn 'N' />
		<cfelseif listFind("0,E,G,I,O,R,S,U", res)><!--- bank does not support/verify AVS --->
			<cfreturn 'X' />
		</cfif>

		<cfreturn 'U' />
	</cffunction>


	<cffunction name="getAVSStreetMatch" output="false" access="private" returntype="string" hint="Normalize the AVS street match code">
		<cfset var res = uCase(getAVSCode()) />

		<cfif listFind("A,B,D,F,X,Y", res)><!--- it does match --->
			<cfreturn 'Y' />
		<cfelseif listFind("C,L,M,N,P,W,Z", res)><!--- it does not match --->
			<cfreturn 'N' />
		<cfelseif listFind("0,E,G,I,O,R,S,U", res)><!--- bank does not support/verify AVS --->
			<cfreturn 'X' />
		</cfif>

		<cfreturn 'U' /><!--- unknown - AVS invalid or could not be verified --->
	</cffunction>

</cfcomponent>