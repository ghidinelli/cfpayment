<cfcomponent name="BaseStripeTest" extends="mxunit.framework.TestCase" output="false">


	<cffunction name="setUp" returntype="void" access="public">	
		
		<cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "credentials.cfm")>
			<cfinclude template="credentials.cfm" />
		<cfelse>
			<cfset variables.credentials = { "CAD": {"TestSecretKey": "sk_test_Zx4885WE43JGqPjqGzaWap8a", "TestPublishableKey": ""}
											,"USD": {"TestSecretKey": "tGN0bIwXnHdwOa85VABjPdSn8nWY7G7I", "TestPublishableKey": ""}
											} />
		</cfif>
	
		<cfscript>  
			// $CAD credentials (provided by support@stripe.com)
			local.gw = {"path": "stripe.stripe", "GatewayID": 2, "TestMode": true};
			local.gw.TestSecretKey = credentials.cad.TestSecretKey;
			local.gw.TestPublishableKey = credentials.cad.TestPublishableKey;

			variables.svc = createObject("component", "cfpayment.api.core").init(local.gw);
			variables.cad = variables.svc.getGateway();
			variables.cad.currency = "cad"; // ONLY FOR UNIT TEST
			variables.cad.country = "CA"; // ONLY FOR UNIT TEST


			// $USD credentials - from PHP unit tests on github
			local.gw = {"path": "stripe.stripe", "GatewayID": 2, "TestMode": true};
			local.gw.TestSecretKey = credentials.usd.TestSecretKey;
			local.gw.TestPublishableKey = credentials.usd.TestPublishableKey;

			variables.svc = createObject("component", "cfpayment.api.core").init(local.gw);
			variables.usd = variables.svc.getGateway();
			variables.usd.currency = "usd"; // ONLY FOR UNIT TEST
			variables.usd.country = "US"; // ONLY FOR UNIT TEST

			// create default
			variables.gw = variables.usd;
			
			// for dataprovider testing
			variables.gateways = [cad, usd];
		</cfscript>

		<!--- if set to false, will try to connect to remote service to check these all out --->
		<cfset variables.localMode = true />
		<cfset variables.debugMode = true />
	</cffunction>


	<cffunction name="offlineInjector" access="private">
		<cfif variables.localMode>
			<cfset injectMethod(argumentCollection = arguments) />
		</cfif>
		<!--- if not local mode, don't do any mock substitution so the service connects to the remote service! --->
	</cffunction>


	<cffunction name="standardResponseTests" access="private">
		<cfargument name="response" type="any" required="true" />
		<cfargument name="expectedObjectName" type="any" required="true" />
		<cfargument name="expectedIdPrefix" type="any" required="true" />

		<cfif variables.debugMode>
			<cfset debug(arguments.expectedObjectName)>
			<cfset debug(arguments.response.getParsedResult())>
			<cfset debug(arguments.response.getResult())>
		</cfif>

		<cfif isSimpleValue(arguments.response)>
			<cfset assertTrue(false, "Response returned a simple value: '#arguments.response#'") />
		</cfif>
		<cfif NOT isObject(arguments.response)>
			<cfset assertTrue(false, "Invalid: response is not an object") />
		<cfelseif isStruct(arguments.response.getParsedResult()) AND structIsEmpty(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response structure returned is empty") />
		<cfelseif isSimpleValue(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response is a string, expected a structure. Returned string = '#arguments.response.getParsedResult()#'") />
		<cfelseif arguments.response.getStatusCode() neq 200>
			<!--- Test status code and remote error messages --->
			<cfif structKeyExists(arguments.response.getParsedResult(), "error")>
				<cfset assertTrue(false, "Error From Stripe: (Type=#arguments.response.getParsedResult().error.type#) #arguments.response.getParsedResult().error.message#") />
			</cfif>
			<cfset assertTrue(false, "Status code should be 200, was: #arguments.response.getStatusCode()#") />
		<cfelse>
			<!--- Test returned data (for object and valid id) --->
			<cfset assertTrue(arguments.response.getSuccess(), "Response not successful") />
			<cfif arguments.expectedObjectName neq "">
				<cfset assertTrue(structKeyExists(arguments.response.getParsedResult(), "object") AND arguments.response.getParsedResult().object eq arguments.expectedObjectName, "Invalid #expectedObjectName# object returned") />
			</cfif>
			<cfif arguments.expectedIdPrefix neq "">
				<cfset assertTrue(len(arguments.response.getParsedResult().id) gt len(arguments.expectedIdPrefix) AND left(arguments.response.getParsedResult().id, len(arguments.expectedIdPrefix)) eq arguments.expectedIdPrefix, "Invalid account ID prefix returned, expected: '#arguments.expectedIdPrefix#...', received: '#response.getParsedResult().id#'") />
			</cfif>
		</cfif>
	</cffunction>


	<cffunction name="standardErrorResponseTests" access="private">
		<cfargument name="response" type="any" required="true" />
		<cfargument name="expectedErrorType" type="any" required="true" />
		<cfargument name="expectedStatusCode" type="any" required="true" />

		<cfif variables.debugMode>
			<cfset debug(arguments.expectedErrorType)>
			<cfset debug(arguments.expectedStatusCode)>
			<cfset debug(arguments.response.getParsedResult())>
			<cfset debug(arguments.response.getResult())>
		</cfif>

		<cfif isSimpleValue(arguments.response)>
			<cfset assertTrue(false, "Response returned a simple value: '#arguments.response#'") />
		</cfif>
		<cfif NOT isObject(arguments.response)>
			<cfset assertTrue(false, "Invalid: response is not an object") />
		<cfelseif isStruct(arguments.response.getParsedResult()) AND structIsEmpty(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response structure returned is empty") />
		<cfelseif isSimpleValue(arguments.response.getParsedResult())>
			<cfset assertTrue(false, "Response is a string, expected a structure. Returned string = '#arguments.response.getParsedResult()#'") />
		<cfelseif arguments.response.getStatusCode() neq arguments.expectedStatusCode>
			<cfset assertTrue(false, "Status code should be #arguments.expectedStatusCode#, was: #arguments.response.getStatusCode()#") />
		<cfelse>
			<cfif structKeyExists(arguments.response.getParsedResult(), "error")>
				<cfif structKeyExists(arguments.response.getParsedResult().error, "message") AND structKeyExists(arguments.response.getParsedResult().error, "type")>
					<cfset assertTrue(arguments.response.getParsedResult().error.type eq arguments.expectedErrorType, "Received error type (#arguments.response.getParsedResult().error.type#), expected error type (#arguments.expectedErrorType#) from API") />
				<cfelse>
					<cfset assertTrue(false, "Error message from API missing details") />
				</cfif>
			<cfelse>
				<cfset assertTrue(false, "Object returned did not have an error") />
			</cfif>
		</cfif>
	</cffunction>


</cfcomponent>