<cfcomponent name="CreditCardTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">
		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.core");
		</cfscript>
	</cffunction>


	<cffunction name="testCreditCard" access="public" returntype="void" output="false">
		<cfset var cc = variables.svc.createCreditCard() />
			
		<cfset assertTrue(isObject(cc)) />
		
		<cfset cc.setAccount(5454545454545454) />
		<cfset cc.setMonth(12) />
		<cfset cc.setYear(year(now())+1) />
		<!--- also test the jquery-like return 'this' --->
		<cfset cc.setVerificationValue(123).setFirstName("John").setLastName("Doe") />

		<cfset assertTrue(cc.getLastName() EQ "Doe", "The stacked set* did not set the last name to Doe") />

		<cfset assertTrue(NOT cc.getIsVisa()) />
		<cfset assertTrue(NOT cc.getIsAmex()) />
		<cfset assertTrue(cc.getIsMastercard()) />

		<cfset assertTrue(arrayLen(cc.validate(requireAVS = false)) EQ 0, "If we aren't validating AVS, this should pass without an address") />
		<cfset assertTrue(arrayLen(cc.validate()) GT 0, "Without an address, this shouldn't validate") />
		
		<cfset cc.setAddress("236 N. Santa Cruz Ave") />
		<cfset cc.setPostalCode("95030") />
		<cfset debug(cc.validate()) />
		<cfset assertTrue(arrayLen(cc.validate()) EQ 0) />


		<!--- test cvv2 verification --->
		<cfset cc.setVerificationValue("") />
		<cfset assertTrue(arrayLen(cc.validate()) GT 0, "Without a verification code, this shouldn't validate") />
		<cfset assertTrue(arrayLen(cc.validate(requireVerificationValue = false)) EQ 0, "Ignoring security code, should validate") />

		<cfset cc.setVerificationValue("12") />
		<cfset assertTrue(arrayLen(cc.validate()) GT 0, "Verification code must be between 3 and 4 digits") />

		<cfset cc.setVerificationValue("12345") />
		<cfset assertTrue(arrayLen(cc.validate()) GT 0, "Verification code must be between 3 and 4 digits") />

		<cfset cc.setVerificationValue("ABC") />
		<cfset assertTrue(arrayLen(cc.validate()) GT 0, "Verification code must be numeric") />
		<cfset assertTrue(arrayLen(cc.validate(requireVerificationValue = false)) EQ 0, "If security code is completely non-numeric AND not required, it will pass since numbersOnly will make it an empty string") />

		<cfset cc.setVerificationValue("12A") />
		<cfset assertTrue(arrayLen(cc.validate(requireVerificationValue = false)) GT 0, "Even when security code is not required, we still break on an invalid value") />
		
	</cffunction>


	<cffunction name="testAccountWithDashes" access="public" returntype="void" output="false">
		<cfset var cc = variables.svc.createCreditCard() />
		<cfset var num = "5454-5454-5454-5454" />
			
		<cfset cc.setAccount(num) />
		<cfset assertTrue(cc.getAccount() NEQ num, "cc.setAccount() is not stripping non-numeric values") />
		<cfset assertTrue(cc.getAccount() EQ reReplace(num, "[^0-9]", "", "ALL"), "cc.setAccount() is not stripping non-numeric values") />
		
	</cffunction>


	<cffunction name="testExpirationDates" access="public" returntype="void" output="false">
		<cfset var cc = variables.svc.createCreditCard() />
		<cfset var ii = "" />
			
		<!--- should be 1/1/1969 --->
		<cfset assertTrue(cc.getExpirationDate() EQ createDate(1969, 1, 1), "Expiration date should fail before month/year are set and return 1/1/1969") />

		<!--- try some invalid dates --->
		<cfset cc.setMonth(13) />
		<cfset cc.setYear(year(now()) + 1) />
		<cfset assertTrue(cc.getExpirationDate() EQ createDate(1969, 1, 1), "Expiration date should fail with invalid date and return 1/1/1969") />
		<cfset assertTrue(NOT cc.getIsExpirationValid(), "Expiration date of 1/1/1969 should not be valid!") />
		
		<!--- try a valid leap year date --->
		<cfset cc.setMonth(2) />
		<cfset cc.setYear(2008) />
		<cfset assertTrue(cc.getExpirationDate() EQ createDate(2008, 2, 29), "Leap year expiration date should be 2/29/2008") />
		<cfset assertTrue(NOT cc.getIsExpirationValid(), "Expiration date of 2/29/2008 should not be valid since it is before #now()#!") />

		<!--- try every month of next year for failure --->
		<cfloop from="1" to="12" index="ii">
			<cfset cc.setMonth(ii) />
			<cfset cc.setYear(year(now())-1) />
			<cfset assertTrue(NOT cc.getIsExpirationValid(), "Expiration date of #cc.getExpirationDate()# should be not valid since it is before #now()#") />
		</cfloop>

		<!--- try every month of next year for success --->
		<cfloop from="1" to="12" index="ii">
			<cfset cc.setMonth(ii) />
			<cfset cc.setYear(year(now())+1) />
			<cfset assertTrue(cc.getIsExpirationValid(), "Expiration date of #cc.getExpirationDate()# should be valid since it is after #now()#") />
		</cfloop>
		
	</cffunction>



</cfcomponent>
