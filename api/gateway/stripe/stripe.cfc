<!---
	$Id$
	
	Copyright 2011 Phil Cruz (http://www.philcruz.com/)
	
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
<cfcomponent displayname="Stripe Gateway" extends="cfpayment.api.gateway.stripe.base" hint="Stripe Gateway" output="false">

	<cfset variables.cfpayment.GATEWAY_NAME = "Stripe" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<!--- braintree test mode uses different username/password instead of different urls --->
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://api.stripe.com/v1/" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = variables.cfpayment.GATEWAY_LIVE_URL />
	<cfset variables.cfpayment.GATEWAY_REPORT_URL = "" />
	
	<cffunction name="getSecretKey" access="public" output="false" returntype="string">		
			<cfreturn variables.SecretKey />		
	</cffunction>
	<cffunction name="setSecretKey" access="public" output="false" returntype="void">
		<cfargument name="SecretKey" type="string" required="true" />
		<cfset variables.SecretKey = arguments.SecretKey />
	</cffunction>
	
	<cffunction name="getPublishableKey" access="public" output="false" returntype="string">		
			<cfreturn variables.PublishableKey />		
	</cffunction>
	<cffunction name="setPublishableKey" access="public" output="false" returntype="void">
		<cfargument name="PublishableKey" type="string" required="true" />
		<cfset variables.PublishableKey = arguments.PublishableKey />
	</cffunction>
	
	<!--- process wrapper with gateway/transaction error handling --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="gatewayUrl" type="string" required="true" />
		<cfargument name="payload" type="struct" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="method" type="string" required="false" default="post" />
		<cfscript>
			
		var response = "";
		headers.authorization = "Basic #toBase64(variables.SecretKey & ":")#";

		//Stripe returns errors with http status like 400,402 or 404 (https://stripe.com/docs/api#errors)
		response = createResponse(argumentCollection = super.process(gatewayUrl=arguments.gatewayUrl, payload = payload, headers = headers, method=arguments.method));
		// now add custom handling of status codes for Stripe
		handleHttpStatus(response = response, status = response.getStatusCode());
		
		//we do some meta-checks for gateway-level errors (as opposed to auth/decline errors) 
		if (NOT response.hasError())
		{				
			//handleHttpStatus() can set the status for card declined so check if already declined
			if (NOT response.getStatus() EQ getService().getStatusDeclined())
			{
				//if we get here, all is good
				var stripeResponse = deserializeJSON(response.getResult());
				response.setParsedResult(stripeResponse);																					
				response.setStatus(getService().getStatusSuccessful());
			}			
		}
		return response;
		</cfscript>
	</cffunction>
	
	<!--- 
	//Stripe returns errors with http status like 400,402 or 404 (https://stripe.com/docs/api#errors)
	//so we need to override handleHttpStatus() in base.cfc
	 --->
	<cffunction name="handleHttpStatus" output="false">
		<cfargument name="status" required="true" />
		<cfargument name="response" required="true" />		
		<cfscript>
		var stripeResponse = "";
		arguments.response.setMessage("Gateway returned status #arguments.status#: ");
		switch(arguments.status)
		{
			case "400": //invalid request, params not lowercase
			case "402": //invalid card
			case "404": //item not found, i.e. no charge for that id
				stripeResponse = deserializeJSON(arguments.response.getResult());
				if (structKeyExists(stripeResponse.error,'type') and stripeResponse.error.type EQ "card_error")
					arguments.response.setStatus(getService().getStatusDeclined());
				else
					arguments.response.setStatus(getService().getStatusFailure());
				break;					
			default:	
				arguments.response.setStatus(getService().getStatusUnknown());
		}
		if (isDefined('stripeResponse.error.type'))
			arguments.response.setMessage(arguments.response.getMessage() & stripeResponse.error.type & ",");
		if (isDefined('stripeResponse.error.code'))
			arguments.response.setMessage(arguments.response.getMessage() & stripeResponse.error.code & ",");
		if (isDefined('stripeResponse.error.message'))
			arguments.response.setMessage(arguments.response.getMessage() & stripeResponse.error.message);
		return arguments.response;
		</cfscript>
	</cffunction>

	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Authorize + Capture in one step">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="false" />		
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />				
		<cfscript>
		var payload = structNew();		
		var accountType = "";
		var gatewayUrl = getGatewayUrl() & "charges";			
		
		payload["amount"]= arguments.money.getCents();
		payload["currency"] = arguments.money.getCurrency();
		
		if (isDefined('arguments.options') and structKeyExists(arguments.options,"customer"))
		{
				payload["customer"] = arguments.options.customer;	
		}else if (structKeyExists(arguments,"account"))
		{
			if (isObject(arguments.account))
				accountType = lcase(listLast(getMetaData(arguments.account).fullname, "."));
			else
				accountType = getMetaData(arguments.account).getName();
			switch(accountType)
			{
				case "creditcard":
					payload["card[number]"] = arguments.account.getAccount();
					payload["card[exp_month]"] = arguments.account.getMonth();
					payload["card[exp_year]"] = arguments.account.getYear();
					payload["card[cvc]"] = arguments.account.getVerificationValue();
					payload["card[name]"] = arguments.account.getName();
					payload["card[address_line1]"] = arguments.account.getAddress();
					payload["card[address_line2]"] = arguments.account.getAddress2();
					payload["card[address_zip]"] = arguments.account.getPostalCode();
					payload["card[address_state]"] = arguments.account.getRegion();
					payload["card[address_country]"] = arguments.account.getCountry();
					break;
				case "token":
					payload["card"] = arguments.account.getId();
					break;
				default:
					 Throw(type="cfpayment.InvalidAccount",message="The account type #accountType# is not supported by this gateway");
			}	
		}
												
		if (isDefined('arguments.options') and structKeyExists(arguments.options,"description"))
			payload["description"]= arguments.options["description"];		
			
		var response = process(gatewayUrl=gatewayUrl, payload = payload);
		if (isStruct(response.getParsedResult()) and structKeyExists(response.getParsedResult(),"id"))
			response.setTransactionID(response.getParsedResult().id);
		return response;
		</cfscript>	
	</cffunction>

	<!--- refund all or part of a previous settled transaction --->
	<cffunction name="refund" output="false" access="public" returntype="any" hint="Refund all or part of a previous transaction">
		<cfargument name="money" type="any" required="false" />
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" default="#structNew()#" />
		<cfscript>
		var payload = structNew();
		var gatewayUrl = getGatewayUrl() & "charges/" & trim(arguments.transactionid) & "/refund";
		
		if (isDefined('arguments.money'))
			payload["amount"]= arguments.money.getCents();				

		var response = process(gatewayUrl=gatewayUrl, payload = payload);
		if (isStruct(response.getParsedResult()) and structKeyExists(response.getParsedResult(),"id"))
			response.setTransactionID(response.getParsedResult().id);
		return response;
		</cfscript>
	</cffunction>
		
	<cffunction name="listCharges" output="false" access="public" >
		<cfscript>			
		var post = structNew();
		var gatewayUrl = getGatewayUrl() & "charges";
		return process(gatewayUrl=gatewayUrl, method="get",payload = post);		
		</cfscript>		
	</cffunction>
	
	<!--- override getGatewayURL to return the appropriate url for the api call --->
	<cffunction name="getGatewayURL" access="public" output="false" returntype="any" hint="">		
		<cfargument name="gatewayUrl" type="string" required="false" />		
		<cfif isDefined('arguments.gatewayUrl') >
			<cfreturn arguments.gatewayUrl />
		<cfelse>
			<cfreturn variables.cfpayment.GATEWAY_LIVE_URL />
		</cfif>			
	</cffunction>
 
	<!--- HELPER FUNCTIONS  --->
	
	<cffunction name="UTCToDate" output="false" access="public" returntype="date" hint="Take a UTC timestamp and convert it to a ColdFusion date object">
		<cfargument name="utcdate" required="true" />
		<cfreturn DateAdd("s",arguments.utcDate,DateConvert("utc2Local", "January 1 1970 00:00")) />
	</cffunction>

</cfcomponent>
