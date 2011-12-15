<!---
	$Id: base.cfc 152 2011-01-18 00:23:34Z briang $

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
<cfcomponent name="base" extends="cfpayment.api.gateway.base" output="false" hint="Base gateway to be extended by real implementations">

	<!--- manage transport and network/connection error handling; all gateways should send HTTP requests through this method --->
	<cffunction name="process" output="false" access="package" returntype="any" hint="Robust HTTP get/post mechanism with error handling">
		<cfargument name="method" type="string" required="false" default="post" />
		<cfargument name="payload" type="any" required="true" /><!--- can be xml or a struct of key-value pairs --->
		<cfargument name="headers" type="struct" required="false" />

		<!--- prepare response before attempting to send over wire --->
		<cfset var response = getService().createResponse() />
		<cfset var CFHTTP = "" />
		<cfset var status = "" />
		<cfset var paramType = "" />
		<cfset var RequestData = "" />

		<!--- TODO: NOTE: THIS INTERNAL DATA REFERENCE MAY GO AWAY, DO NOT RELY UPON IT!!! --->
		<!--- store payload for reference --->
		<cfset RequestData = duplicate(arguments.payload) />
		<cfset RequestData.GATEWAY_URL = getGatewayURL(argumentCollection = arguments) />
		<cfset RequestData.HTTP_METHOD = arguments.method />

		<cfset response.setRequestData(RequestData) /><!--- TODO: should this be another duplicate? --->

		<!--- tell response if this a test transaction? --->
		<cfset response.setTest(getTestMode()) />

		<!--- enable a little extra time past the CFHTTP timeout so error handlers can run --->
		<cfsetting requesttimeout="#max(getCurrentRequestTimeout(), getTimeout() + 10)#" />

		<cftry>
			<!--- change status to pending --->
			<cfset response.setStatus(getService().getStatusPending()) />

			<cfset CFHTTP = doHttpCall(url = getGatewayURL(argumentCollection = arguments)
										,timeout = getTimeout()
										,argumentCollection = arguments) />

			<!--- begin result handling --->
			<cfif isDefined("CFHTTP") AND isStruct(CFHTTP) AND structKeyExists(CFHTTP, "fileContent")>
				<!--- duplicate the non-struct data from CFHTTP for our response --->
				<cfset response.setResult(CFHTTP.fileContent) />
			<cfelse>
				<!--- an unknown failure here where the response doesn't exist somehow or is malformed --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
			</cfif>


			<!--- make decisions based on the HTTP status code --->
			<cfset status = reReplace(cfhttp.statusCode, "[^0-9]", "", "ALL") />

			<cfif status NEQ "200">				
				<cfset response = handleHttpStatus(status=status,response=response,errorDetail=cfhttp.errorDetail) />								
			</cfif>

			<!---
				catch (COM.Allaire.ColdFusion.HTTPFailure postError) - invalid ssl / self-signed ssl / expired ssl
				catch (coldfusion.runtime.RequestTimedOutException postError) - tag timeout like cfhttp timeout or page timeout
				COM.Allaire.ColdFusion.HTTPAuthFailure: Thrown by CFHTTP when the Web page specified in the URL attribute requires different username/passwords to be provided.
				COM.Allaire.ColdFusion.HTTPFailure: Thrown by CFHTTP when the Web server specified in the URL attribute cannot be reached
				COM.Allaire.ColdFusion.HTTPMovedTemporarily: Thrown by CFHTTP when the Web server specified in the URL attribute is reporting the request page as having been moved
				COM.Allaire.ColdFusion.HTTPNotFound: Thrown by CFHTTP when the Web server specified in the URL cannot be found  (404)
				COM.Allaire.ColdFusion.HTTPServerError - error 500 from the server

				are these the same?
				COM.Allaire.ColdFusion.Request.Timeout - untested
				coldfusion.runtime.RequestTimedOutException - i know this works, tested against itransact
			--->

			<!--- implementation exceptions, we rethrow here to break the call as this may happen during development --->
			<cfcatch type="cfpayment">
				<cfrethrow />
			</cfcatch>

			<!--- runtime exceptions; we set status and return --->
			<cfcatch type="COM.Allaire.ColdFusion.HTTPFailure">
				<!--- "Connection Failure" - ColdFusion wasn't able to connect successfully.  This can be an expired, not legit or self-signed SSL cert. --->
				<cfset response.setMessage("Gateway was not successfully reached and the transaction was not processed (100)") />
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="coldfusion.runtime.RequestTimedOutException">
				<cfset response.setMessage("The bank did not respond to our request.  Please wait a few moments and try again. (101)") />
				<cfset response.setStatus(getService().getStatusTimeout()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPNotFound">
				<!--- 404 error, obviously transaction wasn't processed unless response was faked --->
				<cfset response.setMessage("Gateway was not successfully reached and the transaction was not processed (404)") />
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPMovedTemporarily">
				<!--- 302 response, CF doesn't follow so this is like a 404 --->
				<cfset response.setMessage("Gateway was not successfully reached and the transaction was not processed (302)") />
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPServiceUnavailable">
				<!--- 503 response, "503 Service Unavailable"; highly unlikely the other end processes --->
				<cfset response.setMessage("Gateway was not successfully reached and the transaction was not processed (503)") />
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPServerError">
				<!--- 500 response, this is an unknown answer since the other end might have processed --->
				<cfset response.setMessage("Gateway did not respond as expected and the transaction may have been processed (500)") />
				<cfset response.setStatus(getService().getStatusUnknown()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="any">
				<!--- something we don't yet have an exception for --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
				<cfset response.setMessage(cfcatch.Message & "   (" & cfcatch.Type & ")") />
				<cfreturn response />
			</cfcatch>

		</cftry>

		<!--- return raw collection to be handled by gateway-specific code --->
		<cfreturn response />

	</cffunction>
	
	<cffunction name="handleHttpStatus" output="false">
		<cfargument name="status" required="true" />
		<cfargument name="response" required="true" />
		<cfargument name="errorDetail" required="true" />
		<cfswitch expression="#arguments.status#">
			<cfcase value="404">
				<!--- 404 error, obviously transaction wasn't processed unless response was faked --->
				<cfset arguments.response.setMessage("Gateway returned #arguments.status#: #arguments.errorDetail#") />
				<cfset arguments.response.setStatus(getService().getStatusFailure()) />
			</cfcase>
			<cfdefaultcase>
				<cfset arguments.response.setMessage("Gateway returned unknown response: #arguments.status#: #arguments.errorDetail#") />
				<cfset arguments.response.setStatus(getService().getStatusUnknown()) />				
			</cfdefaultcase>
		</cfswitch>
		<cfreturn arguments.response />
	</cffunction>

	<!--- ------------------------------------------------------------------------------

		  PRIVATE HELPER METHODS FOR DEVELOPERS

		  ------------------------------------------------------------------------- --->
	<cffunction name="doHttpCall" access="private" hint="wrapper around the http call - improves testing" returntype="struct" output="false">
		<cfargument name="url" type="string" required="true" hint="URL to get/post" />
		<cfargument name="method" type="string" required="false" hint="the http request method. use 'get' or 'post'" default="get" />
		<cfargument name="timeout" type="numeric" required="true" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="payload" type="struct" required="false" default="#structNew()#" />
		<cfargument name="throwonerror" required="false" default="yes" />

		<cfset var CFHTTP = "" />
		<cfset var key = "" />
		<cfset var keylist = "" />
		<cfset var skey = "" />
		<cfset var paramType = "" />

		<cfif ucase(arguments.method) EQ "GET">
			<cfset paramType = "url" />
		<cfelseif ucase(arguments.method) EQ "POST">
			<cfset paramType = "formfield" />
		<cfelse>
			<cfthrow message="Invalid Method" type="cfpayment.InvalidParameter.Method" />
		</cfif>

		<!--- send request --->
		<cfhttp url="#arguments.url#" method="#arguments.method#" timeout="#arguments.timeout#" throwonerror="#arguments.throwonerror#">
			<!--- pass along any extra headers, like Accept or Authorization or Content-Type --->
			<cfloop collection="#arguments.headers#" item="key">
				<cfhttpparam name="#key#" value="#arguments.headers[key]#" type="header" />
			</cfloop>
			
			<!--- accept nested structures including ordered structs (required for skipjack) --->
			<cfif isStruct(arguments.payload)>
			
				<cfloop collection="#arguments.payload#" item="key">
					<cfif isSimpleValue(arguments.payload[key])>
						<!--- most common param is simple value --->
						<cfhttpparam name="#key#" value="#arguments.payload[key]#" type="#paramType#" />
					<cfelseif isStruct(arguments.payload[key])>
						<!--- loop over structure (check for _keylist to use a pre-determined output order) --->
						<cfif structKeyExists(arguments.payload[key], "_keylist")>
							<cfset keylist = arguments.payload[key]._keylist />
						<cfelse>
							<cfset keylist = structKeyList(arguments.payload[key]) />
						</cfif>
						<cfloop list="#keylist#" index="skey">
							<cfif ucase(skey) NEQ "_KEYLIST">
								<cfhttpparam name="#skey#" value="#arguments.payload[key][skey]#" type="#paramType#" />
							</cfif>
						</cfloop>
					<cfelse>
						<cflog file="application" text="throwing error 1" />
						<cfthrow message="Invalid data type for #key#" detail="The payload must be either XML/JSON/string or a struct" type="cfpayment.InvalidParameter.Payload" />
					</cfif>
				</cfloop>
				
			<cfelseif isSimpleValue(arguments.payload)>

				<!--- some services may need a Content-Type header of application/xml, pass it in as part of the headers array instead --->
				<cfhttpparam value="#arguments.payload#" type="body" />

			<cfelse>

				<cflog file="application" text="throwing error 2" />
				<cfthrow message="The payload must be either XML/JSON/string or a struct" type="cfpayment.InvalidParameter.Payload" />

			</cfif>
		</cfhttp>

		<cfreturn CFHTTP />
	</cffunction>

</cfcomponent>