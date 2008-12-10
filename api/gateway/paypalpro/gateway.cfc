<cfcomponent displayname="Gateway" extends="org.cfpayment.gateway" output="false">

<cffunction name="init" access="public" output="false" returntype="any">
	<cfset super.init()>
	<!--- setup static variables --->
	<cfset variables.instance[variables.instance.GATEWAY_NAME_KEY]="PayPalPro">
	<cfset variables.instance[variables.instance.GATEWAY_VERSION_KEY]="alpha 20071111">
	<cfset variables.instance[variables.instance.TEST_URL]="https://api.sandbox.paypal.com/2.0/">
	<cfset variables.instance[variables.instance.LIVE_URL]="https://api-3t.paypal.com/2.0/">
	<!---
	____https://www.paypal.com/IntegrationCenter/ic_api-reference.html____ 
	Live  	API Certificate  	Name-Value Pair  	https://api.paypal.com/nvp
	Live 	API Signature 	Name-Value Pair 	https://api-3t.paypal.com/nvp
	Live 	API Certificate 	SOAP 	https://api.paypal.com/2.0/
	Live 	API Signature 	SOAP 	https://api-3t.paypal.com/2.0/
	Sandbox 	API Certificate 	Name-Value Pair 	https://api.sandbox.paypal.com/nvp
	Sandbox 	API Signature 	Name-Value Pair 	https://api.sandbox.paypal.com/nvp
	Sandbox 	API Certificate 	SOAP 	https://api.sandbox.paypal.com/2.0/
	Sandbox 	API Signature 	SOAP 	https://api.sandbox.paypal.com/2.0/
	--->
	<cfreturn this />
</cffunction>

<!--- implemented functions --->
<cffunction name="authorize" output="false" access="public" returntype="any" hint="">
	<cfargument name="amount" type="any" required="true"/>
	<cfargument name="creditcard" type="any" required="true"/>
	<cfargument name="params" type="any" required="true"/>
	<cfset var response=CreateObject("component", "org.cfpayment.response").init()>
	<cfset response.setMessage("Testing. Testing. Testing.")>
	<cfset response.setSuccess(true)>
	<cfreturn response>
</cffunction>

</cfcomponent>