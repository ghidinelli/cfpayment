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
	From ActiveMerchant's gateway lib:

    # == Description
    # The Gateway class is the base class for all ActiveMerchant gateway implementations.
    #
    # The standard list of gateway functions that most concrete gateway subclasses implement is:
    #
    # * <tt>purchase(money, creditcard, options = {})</tt>
    # * <tt>authorize(money, creditcard, options = {})</tt>
    # * <tt>capture(money, authorization, options = {})</tt>
    # * <tt>void(identification, options = {})</tt>
    # * <tt>credit(money, identification, options = {})</tt>
    #
    # Some gateways include features for recurring billing
    #
    # * <tt>recurring(money, creditcard, options = {})</tt>
    #
    # Some gateways also support features for storing credit cards:
    #
    # * <tt>store(creditcard, options = {})</tt>
    # * <tt>unstore(identification, options = {})</tt>
    #
    # === Gateway Options
    # The options hash consists of the following options:
    #
    # * <tt>:order_id</tt> - The order number
    # * <tt>:ip</tt> - The IP address of the customer making the purchase
    # * <tt>:customer</tt> - The name, customer number, or other information that identifies the customer
    # * <tt>:invoice</tt> - The invoice number
    # * <tt>:merchant</tt> - The name or description of the merchant offering the product
    # * <tt>:description</tt> - A description of the transaction
    # * <tt>:email</tt> - The email address of the customer
    # * <tt>:currency</tt> - The currency of the transaction.  Only important when you are using a currency that is not the default with a gateway that supports multiple currencies.
    # * <tt>:billing_address</tt> - A hash containing the billing address of the customer.
    # * <tt>:shipping_address</tt> - A hash containing the shipping address of the customer.
    #
    # The <tt>:billing_address</tt>, and <tt>:shipping_address</tt> hashes can have the following keys:
    #
    # * <tt>:name</tt> - The full name of the customer.
    # * <tt>:company</tt> - The company name of the customer.
    # * <tt>:address1</tt> - The primary street address of the customer.
    # * <tt>:address2</tt> - Additional line of address information.
    # * <tt>:city</tt> - The city of the customer.
    # * <tt>:state</tt> - The state of the customer.  The 2 digit code for US and Canadian addresses. The full name of the state or province for foreign addresses.
    # * <tt>:country</tt> - The [ISO 3166-1-alpha-2 code](http://www.iso.org/iso/country_codes/iso_3166_code_lists/english_country_names_and_code_elements.htm) for the customer.
    # * <tt>:zip</tt> - The zip or postal code of the customer.
    # * <tt>:phone</tt> - The phone number of the customer.
    #

	Valid Periodicity Values: bimonthly,monthly,biweekly,weekly,yearly,daily,semimonthly,quadweekly,quarterly,semiyearly
	Each gatway should create a PERIODICITY_MAP to map these normalized values to gateway-specific values

		<cfset variables.cfpayment.PERIODICITY_MAP["weekly"] = "1" />
		<cfset variables.cfpayment.PERIODICITY_MAP["monthly"] = "2" />

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
	<cfset variables.cfpayment.TestMode = true />


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



	<!--- manage transport and network/connection error handling; all gateways should send HTTP requests through this method --->
	<cffunction name="process" output="false" access="package" returntype="any" hint="Robust HTTP get/post mechanism with error handling">
		<cfargument name="method" type="any" required="false" default="post" />
		<cfargument name="payload" type="struct" required="true" />

		<!--- prepare response before attempting to send over wire --->
		<cfset var response = getService().createResponse() />
		<cfset var CFHTTP = "" />
		<cfset var key = "" />
		<cfset var timeout = 300 />
		<cfset var status = "" />
		<cfset var paramType = "" />
		<cfset var RequestData = "" />

		<!--- TODO: NOTE: THIS INTERNAL DATA REFERENCE MAY GO AWAY, DO NOT RELY UPON IT!!! --->
		<!--- store payload for reference --->
		<cfset RequestData = duplicate(arguments.payload) />

		<cfset response.setRequestData(RequestData) /><!--- TODO: should this be another duplicate? --->

		<!--- tell response if this a test transaction? --->
		<cfset response.setTest(getTestMode()) />

		<!--- enable a little extra time past the CFHTTP timeout so error handlers can run --->
		<cfsetting requesttimeout="#timeout + 15#" />

		<cfif ucase(arguments.method) EQ "GET">
			<cfset paramType = "url" />
		<cfelseif ucase(arguments.method) EQ "POST">
			<cfset paramType = "formfield" />
		<cfelse>
			<cfthrow message="Invalid Method" type="cfpyament.InvalidParameter.Method">
		</cfif>

		<cftry>
			<!--- change status to pending --->
			<cfset response.setStatus(getService().getStatusPending()) />

			<!--- send request --->
			<cfhttp url="#getGatewayURL(argumentCollection = arguments)#" method="#arguments.method#" timeout="#timeout#" throwonerror="no">
				<cfloop collection="#arguments.payload#" item="key">
					<!--- TODO: how do we support raw XML post (type=xml, supported back to CF 6.1) here?  Do any gateways use this? --->
					<cfhttpparam name="#key#" value="#arguments.payload[key]#" type="#paramType#" />
				</cfloop>
			</cfhttp>

			<!--- begin result handling --->
			<cfif isDefined("CFHTTP") AND isStruct(CFHTTP) AND structKeyExists(CFHTTP, "fileContent")>
				<!--- duplicate the non-struct data from CFHTTP for our response --->
				<cfset response.setResult(CFHTTP.fileContent) />
			<cfelse>
				<!--- an unknown failure here where the response doesn't exist somehow or is malformed --->
				<cfset response.setStatus(getStatusUnknown()) />
			</cfif>


			<!--- make decisions based on the HTTP status code --->
			<cfset status = reReplace(cfhttp.statusCode, "[^0-9]", "", "ALL") />

			<cfif status NEQ "200">

				<cfswitch expression="#status#">
					<cfcase value="404">
						<!--- 404 error, obviously transaction wasn't processed unless response was faked --->
						<cfset response.setMessage("Gateway returned #cfhttp.statusCode#: #cfhttp.errorDetail#") />
						<cfset response.setStatus(getService().getStatusFailure()) />
					</cfcase>
					<cfdefaultcase>
						<cfset response.setMessage("Gateway returned unknown response: #cfhttp.statusCode#: #cfhttp.errorDetail#") />
						<cfset response.setStatus(getService().getStatusUnknown()) />
						<cfreturn response />
					</cfdefaultcase>
				</cfswitch>

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

			<cfcatch type="COM.Allaire.ColdFusion.HTTPFailure">
				<!--- ColdFusion wasn't able to connect successfully.  This can be an expired, not legit or self-signed SSL cert. --->
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="coldfusion.runtime.RequestTimedOutException">
				<cfset response.setStatus(getService().getStatusTimeout()) />
				<cfreturn response />
			</cfcatch>
			<!---
			Since changing from throwonerror=true, these are no longer needed?
			<cfcatch type="COM.Allaire.ColdFusion.HTTPNotFound">
				<!--- 404 error, obviously transaction wasn't processed unless response was faked --->
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPMovedTemporarily">
				<!--- 302 response, CF doesn't follow so this is like a 404 --->
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPServiceUnavailable">
				<!--- 503 response, "503 Service Unavailable"; highly unlikely the other end processes --->
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfreturn response />
			</cfcatch>
			<cfcatch type="COM.Allaire.ColdFusion.HTTPServerError">
				<!--- 500 response, this is an unknown answer since the other end might have processed --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
				<cfreturn response />
			</cfcatch>
			--->

			<cfcatch type="any">
				<!--- something we don't yet have an exception for --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
				<cfset response.setMessage(cfcatch.Message) />
				<cfreturn response />
			</cfcatch>

		</cftry>

		<!--- return raw collection to be handled by gateway-specific code --->
		<cfreturn response />

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