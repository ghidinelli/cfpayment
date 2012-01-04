<cfcomponent displayname="Gateway" extends="cfpayment.api.gateway.base" output="false" hint="Bogus gateway demonstrates an implementation">

	<!--- THIS GATEWAY IS ONLY FOR UNIT TEST PURPOSES --->

	<!--- gateway specific variables --->
	<cfset variables.cfpayment.GATEWAYID = "2" />
	<cfset variables.cfpayment.GATEWAY_NAME = "Bogus Gateway" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.1" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "http://localhost/" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "http://localhost/" />
	<cfset variables.cfpayment.Authorization = "51515" />
	<cfset variables.cfpayment.SuccessMessage = "Bogus Gateway: Forced success; use CC number 1 for success, 2 for decline, anything else for error" />
	<cfset variables.cfpayment.DeclineMessage = "Bogus Gateway: Forced failure; use CC number 1 for success, 2 for decline, anything else for error" />
	<cfset variables.cfpayment.ErrorMessage = "Bogus Gateway: Forced Error; use CC number 1 for success, 2 for decline, anything else for error" />


	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset super.init(argumentCollection = arguments) />
		<cfreturn this />
	</cffunction>


	<cffunction name="process" output="false" access="public" returntype="any">
		<cfargument name="method" type="string" required="false" default="post" />
		<cfargument name="payload" type="any" required="true" /><!--- can be xml (simplevalue) or a struct of key-value pairs --->
		<cfargument name="headers" type="struct" required="false" />

		<cfreturn createResponse(argumentCollection = super.process(argumentCollection = arguments)) />
									
	</cffunction>


	<cffunction name="getIsCCEnabled" output="false" access="public" returntype="boolean" hint="determine whether or not this gateway can accept credit card transactions">
		<cfreturn true />
	</cffunction>

</cfcomponent>