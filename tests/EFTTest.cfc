<cfcomponent name="EFTTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">
		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.core");
		</cfscript>
	</cffunction>


	<cffunction name="testEFT" access="public" returntype="void" output="false">
		<cfset var account = variables.svc.createEFT() />
			
		<cfset assertTrue(isObject(account)) />
		
		<!--- test out some of the stacked set* commands --->
		<cfset account.setAccount("12345-12345").setRoutingNumber("121000358") />
		<cfset account.setFirstName("John").setLastName("Doe") />
		<cfset account.setAddress("236 N. Santa Cruz Ave").setPostalCode("95030").setPhoneNumber("415-555-1212") />

		<!--- test seemingly valid bank account --->
		<cfset assertTrue(arrayLen(account.validate()) EQ 0, "EFT should validate") />
		
		<!--- munge the aba --->
		<cfset account.setRoutingNumber("000") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 1, "Invalid ABA should throw an error") />

		<!--- try valid length but invalid ABA --->
		<cfset account.setRoutingNumber("000000111") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 1, "Non-blank but invalid routing number should throw an error") />

		<!--- try without address --->
		<cfset account.setRoutingNumber("121000358") />
		<cfset account.setAddress("") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 0, "Address is not required for EFT") />
		
		<!--- try without postal code --->
		<cfset account.setAddress("236 N. Santa Cruz Ave") />
		<cfset account.setPostalCode("") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 0, "Postal code is not required for EFT") />

		<!--- try without account number --->
		<cfset account.setPostalCode("95030") />
		<cfset account.setAccount("") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 1, "Blank account should throw an error") />
		
		<!--- try without first name --->
		<cfset account.setAccount("12345-12345") />
		<cfset account.setFirstName("") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 1, "Blank first name should throw an error") />
		
		<!--- try without last name --->
		<cfset account.setFirstName("John") />
		<cfset account.setLastName("") />
		<cfset assertTrue(arrayLen(account.validate()) EQ 1, "Blank last name should throw an error") />

	</cffunction>


	<cffunction name="testAccountWithDashes" access="public" returntype="void" output="false">
		<cfset var account = variables.svc.createEFT() />
		<cfset var num = "5454-54-54" />

		<cfset account.setAccount(num) />
		<cfset assertTrue(account.getAccount() NEQ num, "account.setAccount() is not stripping non-numeric values") />
		<cfset assertTrue(account.getAccount() EQ reReplace(num, "[^0-9]", "", "ALL"), "account.setAccount() is not stripping non-numeric values") />
		
	</cffunction>


</cfcomponent>
