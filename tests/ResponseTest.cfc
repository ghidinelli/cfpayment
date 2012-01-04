<cfcomponent name="ResponseTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">

		<cfscript>
			gw.path = "base";
			gw.GatewayID = 1;
			gw.MerchantAccount = 101010101;
			gw.Username = 'test';
			gw.Password = 'test';
			
			variables.svc = createObject("component", "cfpayment.api.core").init(gw);
			variables.gw = variables.svc.getGateway();
			variables.response = variables.gw.createResponse();
		</cfscript>
	</cffunction>


	<cffunction name="testAVSResult" access="public" returntype="void" output="false">

		<!--- test blank code --->
		<cfset variables.response.setAVSCode("")>
		<cfset assertTrue(variables.response.isValidAVS(), "isAVSValid failed for AVS Allow Blank Code is not passed in") />
		<cfset assertFalse(variables.response.isValidAVS(AllowBlankCode=false), "isAVSValid failed for AVS Allow Blank Code is false") />

		<!--- test "X" code: street + 9-digit zip match --->
		<cfset variables.response.setAVSCode("X")>
		<cfset assertTrue(variables.response.isValidAVS(), "isAVSValid failed for AVS street and 9-digit zip match") />

		<!--- test "Y" code: street + 5-digit zip match --->
		<cfset variables.response.setAVSCode("Y")>
		<cfset assertTrue(variables.response.isValidAVS(), "isAVSValid failed for AVS street and 5-digit zip match") />

		<!--- test "Z" code: 5-digit zip match --->
		<cfset variables.response.setAVSCode("Z")>
		<cfset assertFalse(variables.response.isValidAVS(), "isAVSValid failed for AVS 5-digit zip match and AllowPostalOnlyMatch not passed in") />
		<cfset assertTrue(variables.response.isValidAVS(AllowPostalOnlyMatch=true), "isAVSValid failed for AVS 5-digit zip match and AllowPostalOnlyMatch=true") />

		<!--- test "A" code: street match --->
		<cfset variables.response.setAVSCode("A")>
		<cfset assertFalse(variables.response.isValidAVS(), "isAVSValid failed for AVS street match and AllowStreetOnlyMatch not passed in") />
		<cfset assertTrue(variables.response.isValidAVS(AllowStreetOnlyMatch=true), "isAVSValid failed for AVS street match and AllowStreetOnlyMatch=true") />

	</cffunction>

	<cffunction name="testCVVResult" access="public" returntype="void" output="false">

		<!--- test blank code --->
		<cfset variables.response.setCVVCode("")>
		<cfset assertTrue(variables.response.isValidCVV(), "isCVVValid failed for CVV Allow Blank Code is not passed in") />
		<cfset assertFalse(variables.response.isValidCVV(AllowBlankCode=false), "isCVVValid failed for CVV Allow Blank Code is false") />

		<!--- test "N" code: No Match --->
		<cfset variables.response.setCVVCode("N")>
		<cfset assertFalse(variables.response.isValidCVV(), "isCVVValid failed for CVV No Match") />

		<!--- test "M" code: No Match --->
		<cfset variables.response.setCVVCode("M")>
		<cfset assertTrue(variables.response.isValidCVV(), "isCVVValid failed for CVV Match") />

	</cffunction>


</cfcomponent>
