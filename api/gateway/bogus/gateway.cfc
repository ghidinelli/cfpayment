<cfcomponent displayname="Gateway" extends="cfpayment.api.gateway.base" output="false" hint="Bogus gateway demonstrates an implementation">

	<!--- gateway specific variables --->
	<cfset variables.cfpayment.GATEWAYID = "2" />
	<cfset variables.cfpayment.GATEWAY_NAME = "Bogus Gateway" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.1" />
	<cfset variables.cfpayment.Authorization = "51515" />
	<cfset variables.cfpayment.SuccessMessage = "Bogus Gateway: Forced success; use CC number 1 for success, 2 for decline, anything else for error" />
	<cfset variables.cfpayment.DeclineMessage = "Bogus Gateway: Forced failure; use CC number 1 for success, 2 for decline, anything else for error" />
	<cfset variables.cfpayment.ErrorMessage = "Bogus Gateway: Forced Error; use CC number 1 for success, 2 for decline, anything else for error" />


	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset super.init(argumentCollection = arguments) />
		<!--- setup static variables --->
		<cfreturn this />
	</cffunction>


	<!--- implemented functions --->
	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Perform an authorization immediately followed by a capture">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<!--- first try the authorize --->
		<cfset var res = authorize(argumentCollection = arguments) />

		<!--- For demonstration purposes, we just roll from Authorization to Capture but most
			  gateways have a separate routine that does both actions at once.  This is often called
			  "Sale" or something similar.  In that case, your purchase() would be different than authorize()+capture() --->
		<cfif res.getSuccess()>
			<cfreturn capture(money = arguments.money, authorization = res.getAuthorization(), options = arguments.options) />
		<cfelse>
			<cfreturn res />
		</cfif>
	</cffunction>


	<cffunction name="authorize" output="false" access="public" returntype="any" hint="Verifies payment details with merchant bank">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfset var response = createResponse() />

		<!--- Just for demonstration purposes; pass CC# 1 for sucecss, CC# 2 for failure, anything else for exception --->
		<cfswitch expression="#arguments.account.getAccount()#">
			<cfcase value="1">
				<cfset response.setMessage(variables.cfpayment.SuccessMessage) />
				<cfset response.setAuthorization(123456) />
				<cfset response.setStatus(getService().getStatusSuccessful()) />
			</cfcase>
			<cfcase value="2">
				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfset response.setMessage(variables.cfpayment.DeclineMessage) />
			</cfcase>
			<cfdefaultcase>
				<cfset response.setMessage(variables.cfpayment.ErrorMessage) />
				<cfset response.setStatus(getService().getStatusFailure()) />
			</cfdefaultcase>
		</cfswitch>

		<cfreturn response />
	</cffunction>


	<cffunction name="capture" output="false" access="public" returntype="any" hint="Confirms an authorization with direction to charge the account">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="authorization" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfset var response = createResponse() />

		<cfswitch expression="#arguments.authorization#">
			<cfcase value="123456">
				<cfset response.setMessage(variables.cfpayment.SuccessMessage) />
				<cfset response.setAuthorization(123456) />
				<cfset response.setStatus(getService().getStatusSuccessful()) />
			</cfcase>
			<cfdefaultcase>
				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfset response.setMessage(variables.cfpayment.DeclineMessage) />
			</cfdefaultcase>
		</cfswitch>

		<cfreturn response />

	</cffunction>


	<cffunction name="process" output="false" access="public" returntype="any">
		<cfargument name="method" type="string" required="false" default="post" />
		<cfargument name="payload" type="any" required="true" /><!--- can be xml (simplevalue) or a struct of key-value pairs --->
		<cfargument name="headers" type="struct" required="false" />

		<cfreturn createResponse() />
									
	</cffunction>

	<!--- this is a credit card gateway --->
	<cffunction name="getIsCCEnabled" output="false" access="public" returntype="boolean" hint="determine whether or not this gateway can accept credit card transactions">
		<cfreturn true />
	</cffunction>

</cfcomponent>