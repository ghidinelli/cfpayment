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
<cfcomponent name="base" output="false" hint="Base gateway to be extended by real implementations">

	<!---
	Building a new gateway is straightforward.  Extend this base.cfc and then map your gateway-specific parameters to normalized cfpayment parameters.
	
	For example, we call our internal tracking ID "orderId".  However, Braintree expects "order_id" and Skipjack expects "ordernumber".
	
	To write a new gateway, you would pass in orderId to a method like purchase() and map it to whatever name your gateway requires.  When you parse the response from your gateway,
	you would map it back to orderId in the common response object.  Make sense?
	
	Check the docs for a complete list of normalized cfpayment parameter names.
	--->

	<cfset variables.cfpayment = structNew() />
	<cfset variables.cfpayment.GATEWAYID = "1" />
	<cfset variables.cfpayment.GATEWAY_NAME = "Base Gateway" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "http://localhost/" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "http://localhost/" />
	<cfset variables.cfpayment.PERIODICITY_MAP = StructNew() />
	<cfset variables.cfpayment.MerchantAccount = "" />
	<cfset variables.cfpayment.Username = "" />
	<cfset variables.cfpayment.Password = "" />
	<cfset variables.cfpayment.Timeout = 300 />
	<cfset variables.cfpayment.TestMode = true />
	
	
	<!--- it's possible access to internal java objects is disabled, so we account for that --->
	<cftry>
		<!--- use this java object to get at the current RequestTimeout value for a given request --->
		<cfset variables.rcMonitor = createObject("java", "coldfusion.runtime.RequestMonitor") />
		<cfset variables.rcMonitorEnabled = true />
		<cfcatch type="any">
			<cfset variables.rcMonitorEnabled = false />
		</cfcatch>
	</cftry>


	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="service" type="any" required="true" />
		<cfargument name="config" type="struct" required="false" />

		<cfset var argName = "" />

		<cfset variables.cfpayment.service = arguments.service />

		<!--- loop over any configuration and set parameters --->
		<cfif structKeyExists(arguments, "config")>
			<cfloop collection="#arguments.config#" item="argName">
				<cfif structKeyExists(arguments.config, argName) AND structKeyExists(this, "set" & argName)>
					<cfinvoke component="#this#" method="set#argName#">
						<cfinvokeargument name="#argName#" value="#arguments.config[argName]#" />
					</cfinvoke>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn this />
	</cffunction>

	<!--- implemented base functions --->
	<cffunction name="getGatewayName" access="public" output="false" returntype="any" hint="">
		<cfif structKeyExists(variables.cfpayment, "GATEWAY_NAME")>
			<cfreturn variables.cfpayment.GATEWAY_NAME />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>

	<cffunction name="getGatewayVersion" access="public" output="false" returntype="any" hint="">
		<cfif structKeyExists(variables.cfpayment, "GATEWAY_VERSION")>
			<cfreturn variables.cfpayment.GATEWAY_VERSION />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>

	<cffunction name="getTimeout" access="public" output="false" returntype="numeric">
		<cfreturn variables.cfpayment.Timeout />
	</cffunction>
	<cffunction name="setTimeout" access="public" output="false" returntype="void">
		<cfargument name="Timeout" type="numeric" required="true" />
		<cfset variables.cfpayment.Timeout = arguments.Timeout />
	</cffunction>

	<cffunction name="getTestMode" access="public" output="false" returntype="any" hint="">
		<cfreturn variables.cfpayment.TestMode />
	</cffunction>
	<cffunction name="setTestMode" access="public" output="false" returntype="any">
		<cfset variables.cfpayment.TestMode = arguments[1] />
	</cffunction>

	<cffunction name="getGatewayURL" access="public" output="false" returntype="any" hint="">
		<cfif getTestMode()>
			<cfreturn variables.cfpayment.GATEWAY_TEST_URL />
		<cfelse>
			<cfreturn variables.cfpayment.GATEWAY_LIVE_URL />
		</cfif>
	</cffunction>


	<!--- 	Date: 7/6/2008  Usage: get access to the service for generating responses, errors, etc --->
	<cffunction name="getService" output="false" access="private" returntype="any" hint="get access to the service for generating responses, errors, etc">
		<cfreturn variables.cfpayment.service />
	</cffunction>


	<!--- getter/setters for common configuration parameters like MID, Username, Password --->
	<cffunction name="getMerchantAccount" access="package" output="false" returntype="any">
		<cfreturn variables.cfpayment.MerchantAccount />
	</cffunction>
	<cffunction name="setMerchantAccount" access="package" output="false" returntype="void">
		<cfargument name="MerchantAccount" type="any" required="true" />
		<cfset variables.cfpayment.MerchantAccount = arguments.MerchantAccount />
	</cffunction>

	<cffunction name="getUsername" access="package" output="false" returntype="any">
		<cfreturn variables.cfpayment.Username />
	</cffunction>
	<cffunction name="setUsername" access="package" output="false" returntype="void">
		<cfargument name="Username" type="any" required="true" />
		<cfset variables.cfpayment.Username = arguments.Username />
	</cffunction>

	<cffunction name="getPassword" access="package" output="false" returntype="any">
		<cfreturn variables.cfpayment.Password />
	</cffunction>
	<cffunction name="setPassword" access="package" output="false" returntype="void">
		<cfargument name="Password" type="any" required="true" />
		<cfset variables.cfpayment.Password = arguments.Password />
	</cffunction>

	<!--- the gatewayid is a value used by the transaction/HA apis to differentiate
		  the gateway used for a given payment.  The value is arbitrary and unique to
		  a particular system. --->
	<cffunction name="getGatewayID" access="public" output="false" returntype="any">
		<cfreturn variables.cfpayment.GATEWAYID />
	</cffunction>
	<cffunction name="setGatewayID" access="public" output="false" returntype="void">
		<cfargument name="GatewayID" required="true" type="any" />
		<cfset variables.cfpayment.GatewayID = arguments.GatewayID />
	</cffunction>

	<!--- the current request timeout allows us to intelligently modify the overall page timeout based 
		  upon whatever the current page context or configured timeout dictate.  It's possible to have
		  acces to internal Java components disabled so we take that into account here. --->
	<cffunction name="getCurrentRequestTimeout" output="false" access="private" returntype="numeric">
		<cfif variables.rcMonitorEnabled>
			<cfreturn variables.rcMonitor.getRequestTimeout() />
		<cfelse>
			<cfreturn 0 />
		</cfif>
	</cffunction>

	<!--- manage transport and network/connection error handling; all gateways should send HTTP requests through this method --->
	<cffunction name="process" output="false" access="package" returntype="struct" hint="Robust HTTP get/post mechanism with error handling">
		<cfargument name="url" type="string" required="false" hint="URL to get/post" default="#getGatewayURL(argumentCollection = arguments)#" />
		<cfargument name="method" type="string" required="false" default="post" />
		<cfargument name="payload" type="any" required="true" /><!--- can be xml (simplevalue) or a struct of key-value pairs --->
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="encoded" type="boolean" required="false" default="true" hint="Some gateways (e.g. PayPal Payflow Pro) require unencoded parameters" />
		<cfargument name="files" type="struct" required="false" default="#structNew()#" />

		<!--- prepare response before attempting to send over wire --->
		<cfset var CFHTTP = "" />
		<cfset var status = "" />
		<cfset var paramType = "" />
		<cfset var ResponseData = { Status = getService().getStatusPending()
									,StatusCode = ""
									,Result = ""
									,Message = ""
									,RequestData = {}
									,TestMode = getTestMode()
									} />
									
									
		<!--- TODO: NOTE: THIS INTERNAL DATA REFERENCE MAY GO AWAY, DO NOT RELY UPON IT!!!  DEVELOPMENT PURPOSES ONLY!!! --->
		<!--- store payload for reference during development (can be simplevalue OR structure) --->
		<cfif getTestMode()>
			<cfset ResponseData.RequestData = { PAYLOAD = duplicate(arguments.payload)
												,GATEWAY_URL = arguments.url
												,HTTP_METHOD = arguments.method
												,HEADERS = arguments.headers
												} />
		</cfif>									

		<!--- enable a little extra time past the CFHTTP timeout so error handlers can run --->
		<cfsetting requesttimeout="#max(getCurrentRequestTimeout(), getTimeout() + 10)#" />

		<cftry>
			<cfset CFHTTP = doHttpCall(url = arguments.url
										,timeout = getTimeout()
										,argumentCollection = arguments) />

			<!--- begin result handling --->
			<cfif isDefined("CFHTTP") AND isStruct(CFHTTP) AND structKeyExists(CFHTTP, "fileContent")>
				<!--- duplicate the non-struct data from CFHTTP for our response --->
				<cfset ResponseData.Result = CFHTTP.fileContent />
			<cfelse>
				<!--- an unknown failure here where the response doesn't exist somehow or is malformed --->
				<cfset ResponseData.Status = getService().getStatusUnknown() />
			</cfif>


			<!--- make decisions based on the HTTP status code --->
			<cfset ResponseData.StatusCode = reReplace(CFHTTP.statusCode, "[^0-9]", "", "ALL") />

			<!--- Errors that are thrown even when CFHTTP throwonerror = no:
				catch (COM.Allaire.ColdFusion.HTTPFailure postError) - invalid ssl / self-signed ssl / expired ssl
				catch (coldfusion.runtime.RequestTimedOutException postError) - tag timeout like cfhttp timeout or page timeout
				See http://www.ghidinelli.com/2012/01/03/cfhttp-error-handling-http-status-codes for all others (handled by HTTP status code below)
			--->

			<!--- implementation and runtime exceptions --->
			<cfcatch type="cfpayment">
				<!--- we rethrow here to break the call as this may happen during development --->
				<cfrethrow />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPFailure">
				<!--- "Connection Failure" - ColdFusion wasn't able to connect successfully.  This can be an expired, not legit, wildcard or self-signed SSL cert. --->
				<cfset ResponseData.Message = "Gateway was not successfully reached and the transaction was not processed (100)" />
				<cfset ResponseData.Status = getService().getStatusFailure() />
				<cfreturn ResponseData />
			</cfcatch>
			<cfcatch type="coldfusion.runtime.RequestTimedOutException">
				<cfset ResponseData.Message = "The bank did not respond to our request.  Please wait a few moments and try again. (101)" />
				<cfset ResponseData.Status = getService().getStatusTimeout() />
				<cfreturn ResponseData />
			</cfcatch>
			<cfcatch type="any">
				<!--- convert the CFCATCH.message into the HTTP Status Code --->
				<cfset ResponseData.StatusCode = reReplace(CFCATCH.message, "[^0-9]", "", "ALL") />
				<cfset ResponseData.Status = getService().getStatusUnknown() />
				<cfset ResponseData.Message = CFCATCH.Message & " (" & cfcatch.Type & ")" />
				<!--- let it fall through so we can attempt to handle the status code --->
			</cfcatch>
		</cftry>

		<cfif len(ResponseData.StatusCode) AND ResponseData.StatusCode NEQ "200">
			<cfswitch expression="#ResponseData.StatusCode#">
				<cfcase value="404,302,503"><!--- coldfusion doesn't follow 302s, so acts like a 404 --->
					<cfset ResponseData.Message = "Gateway was not successfully reached and the transaction was not processed" />
					<cfset ResponseData.Status = getService().getStatusFailure() />
					<cfif structKeyExists(CFHTTP, "ErrorDetail") AND len(CFHTTP.ErrorDetail)>
						<cfset ResponseData.Message = ResponseData.Message & " (Original message: #CFHTTP.ErrorDetail#)" />
					</cfif>
				</cfcase>
				<cfcase value="500">
					<cfset ResponseData.Message = "Gateway did not respond as expected and the transaction may have been processed" />
					<cfset ResponseData.Status = getService().getStatusUnknown() />
					<cfif structKeyExists(CFHTTP, "ErrorDetail") AND len(CFHTTP.ErrorDetail)>
						<cfset ResponseData.Message = ResponseData.Message & " (Original message: #CFHTTP.ErrorDetail#)" />
					</cfif>
				</cfcase>
			</cfswitch>
		<cfelseif NOT len(ResponseData.StatusCode)>
			<cfset ResponseData.Status = getService().getStatusUnknown() />
		</cfif>

		<!--- return raw collection to be handled by gateway-specific code --->
		<cfreturn ResponseData />

	</cffunction>


	<!--- ------------------------------------------------------------------------------

		  PRIVATE HELPER METHODS FOR DEVELOPERS

		  ------------------------------------------------------------------------- --->
	<cffunction name="doHttpCall" access="private" hint="wrapper around the http call - improves testing" returntype="struct" output="false">
		<cfargument name="url" type="string" required="true" hint="URL to get/post" />
		<cfargument name="method" type="string" required="false" hint="the http request method: GET, POST, PUT or DELETE" default="get" />
		<cfargument name="timeout" type="numeric" required="true" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="payload" type="any" required="false" default="#structNew()#" />
		<cfargument name="encoded" type="boolean" required="false" default="true" />
		<cfargument name="files" type="struct" required="false" default="#structNew()#" />

		<cfset var CFHTTP = "" />
		<cfset var key = "" />
		<cfset var keylist = "" />
		<cfset var skey = "" />
		<cfset var paramType = "" />

		<cfif uCase(arguments.method) EQ "GET">
			<cfset paramType = "url" />
		<cfelseif uCase(arguments.method) EQ "POST">
			<cfset paramType = "formfield" />
		<cfelseif uCase(arguments.method) EQ "PUT">
			<cfset paramType = "body" />
		<cfelseif uCase(arguments.method) EQ "DELETE">
			<cfset paramType = "body" />
		<cfelse>
			<cfthrow message="Invalid Method" type="cfpayment.InvalidParameter.Method" />
		</cfif>

		<!--- send request --->
		<cfhttp url="#arguments.url#" method="#arguments.method#" timeout="#arguments.timeout#" throwonerror="no">
			<!--- pass along any extra headers, like Accept or Authorization or Content-Type --->
			<cfloop collection="#arguments.headers#" item="key">
				<cfhttpparam name="#key#" value="#arguments.headers[key]#" type="header" />
			</cfloop>
			
			<!--- accept nested structures including ordered structs (required for skipjack) --->
			<cfif isStruct(arguments.payload)>
			
				<cfloop collection="#arguments.payload#" item="key">
					<cfif isSimpleValue(arguments.payload[key])>
						<!--- most common param is simple value --->
						<cfhttpparam name="#key#" value="#arguments.payload[key]#" type="#paramType#" encoded="#arguments.encoded#" />
					<cfelseif isStruct(arguments.payload[key])>
						<!--- loop over structure (check for _keylist to use a pre-determined output order) --->
						<cfif structKeyExists(arguments.payload[key], "_keylist")>
							<cfset keylist = arguments.payload[key]._keylist />
						<cfelse>
							<cfset keylist = structKeyList(arguments.payload[key]) />
						</cfif>
						<cfloop list="#keylist#" index="skey">
							<cfif ucase(skey) NEQ "_KEYLIST">
								<cfhttpparam name="#skey#" value="#arguments.payload[key][skey]#" type="#paramType#" encoded="#arguments.encoded#" />
							</cfif>
						</cfloop>
					<cfelse>
						<cfthrow message="Invalid data type for #key#" detail="The payload must be either XML/JSON/string or a struct" type="cfpayment.InvalidParameter.Payload" />
					</cfif>
				</cfloop>
				
			<cfelseif isSimpleValue(arguments.payload) AND len(arguments.payload)>

				<!--- some services may need a Content-Type header of application/xml, pass it in as part of the headers array instead --->
				<cfhttpparam value="#arguments.payload#" type="body" />

			<cfelse>

				<cfthrow message="The payload must be either XML/JSON/string or a struct" type="cfpayment.InvalidParameter.Payload" />

			</cfif>

			<!--- Handle file uploads with files that already exist on local drive/network. Note, this must be after the cfhttparam type formfield lines --->
			<cfloop collection="#arguments.files#" item="key">
				<cfhttpparam name="#key#" file="#arguments.files[key]#" type="file" />
			</cfloop>
		</cfhttp>

		<cfreturn CFHTTP />
	</cffunction>

	<cffunction name="getOption" output="false" access="private" returntype="any" hint="">
		<cfargument name="Options" type="any" required="true" />
		<cfargument name="Key" type="any" required="true" />
		<cfargument name="ErrorIfNotFound" type="boolean" default="false" />
		<cfif isStruct(arguments.Options) and structKeyExists(arguments.Options, arguments.Key)>
			<cfreturn arguments.Options[arguments.Key] />
		<cfelse>
			<cfif arguments.ErrorIfNotFound>
				<cfthrow message="Missing Option: #HTMLEditFormat(arguments.key)#" type="cfpayment.MissingParameter.Option" />
			<cfelse>
				<cfreturn "" />
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="verifyRequiredOptions" output="false" access="private" returntype="void" hint="I verify that the passed in Options structure exists for each item in the RequiredOptionList argument.">
		<cfargument name="options" type="struct" required="true"/>
		<cfargument name="requiredOptionList" type="string" required="true"/>
		<cfset var option="" />
		<cfloop list="#arguments.requiredOptionList#" index="option">
			<cfif not StructKeyExists(arguments.options, option)>
				<cfthrow message="Missing Required Option - #option#" type="cfpayment.MissingParameter.Option" />
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="isValidPeriodicity" output="false" access="private" returntype="any" hint="I validate the the given periodicity is valid for the current gateway.">
		<cfargument name="periodicity" type="string" required="true"/>
		<cfif len(getPeriodicityValue(arguments.periodicity))>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>

	<cffunction name="getPeriodicityValue" output="false" access="private" returntype="any" hint="I return the gateway-specific value for the given normalized periodicity.">
		<cfargument name="periodicity" type="string" required="true"/>
		<cfif structKeyExists(variables.cfpayment.PERIODICITY_MAP, arguments.periodicity)>
			<cfreturn variables.cfpayment.PERIODICITY_MAP[arguments.periodicity] />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>

	<!--- gateways may on RARE occasion need to override the response object; being generated by the base gateway allows an implementation to override this --->
	<cffunction name="createResponse" access="public" output="false" returntype="any" hint="Create a response object with status set to unprocessed">
		<cfreturn createObject("component", "cfpayment.api.model.response").init(argumentCollection = arguments, service = getService(), testMode = getTestMode()) />
	</cffunction>


	<!--- ------------------------------------------------------------------------------

		  PUBLIC API FOR USERS TO CALL AND FOR DEVELOPERS TO EXTEND


		  ------------------------------------------------------------------------- --->
	<!--- Stub out the public functions (these must be implemented in the gateway folders) --->
	<cffunction name="purchase" access="public" output="false" returntype="any" hint="Perform an authorization immediately followed by a capture">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="authorize" access="public" output="false" returntype="any" hint="Verifies payment details with merchant bank">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="capture" access="public" output="false" returntype="any" hint="Confirms an authorization with direction to charge the account">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="authorization" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="credit" access="public" output="false" returntype="any" hint="Returns an amount back to the previously charged account.  Only for use with captured transactions.">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="void" access="public" output="false" returntype="any" hint="Cancels a previously captured transaction that has not yet settled">
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="search" access="public" output="false" returntype="any" hint="Find transactions using gateway-supported criteria">
		<cfargument name="options" type="struct" required="true" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="status" access="public" output="false" returntype="any" hint="Reconstruct a response object for a previously executed transaction">
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="recurring" access="public" output="false" returntype="any" hint="">
		<cfargument name="mode" type="string" required="true" /><!--- must be one of: add, edit, delete, get --->
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="settle" access="public" output="false" returntype="any" hint="Directs the merchant account to close the open batch of transactions (typically run once per day either automatically or manually with this method)">
		<cfargument name="options" type="struct" required="false" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<cffunction name="supports" access="public" output="false" returntype="boolean" hint="Determine if gateway supports a specific card or account type">
		<cfargument name="type" type="any" required="true" />

		<cfthrow message="Method not implemented." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	<!--- determine capability of this gateway --->
	<cffunction name="getIsCCEnabled" access="public" output="false" returntype="boolean" hint="determine whether or not this gateway can accept credit card transactions">
		<cfreturn false />
	</cffunction>

	<cffunction name="getIsEFTEnabled" access="public" output="false" returntype="boolean" hint="determine whether or not this gateway can accept ACH/EFT transactions">
		<cfreturn false />
	</cffunction>

</cfcomponent>