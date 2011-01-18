<cfcomponent name="MoneyTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">
		<cfscript>
			variables.svc = createObject("component", "cfpayment.api.core");
		</cfscript>
	</cffunction>


	<cffunction name="testMoneyInCentsViaInit" access="public" returntype="void" output="false">

		<cfset var money = variables.svc.createMoney(cents = 1000, currency = "USD") />

		<!--- verify some values --->
		<cfset assertTrue(isNumeric(money.getCents()), "Cents should be numeric data") />
		<cfset assertTrue(money.getCents() EQ "1000", "Cents should be an integer and 1000") />
		<cfset assertTrue(money.getAmount() EQ "10.00", "Amount should divide by fraction of 100") />
		<cfset assertTrue(money.getCurrency() EQ "USD", "Currency should be USD") />

	</cffunction>


	<cffunction name="testMoneyInCentsWithUnnamedParameters" access="public" returntype="void" output="false">
		<!--- trying to test scenario reported by Joe Zack of unnamed parameters causing money not to be set --->
		<cfset var money = variables.svc.createMoney(1000, "USD") />

		<!--- verify some values --->
		<cfset assertTrue(isNumeric(money.getCents()), "Cents should be numeric data") />
		<cfset assertTrue(money.getCents() EQ "1000", "Cents should be an integer and 1000") />
		<cfset assertTrue(money.getAmount() EQ "10.00", "Amount should divide by fraction of 100") />
		<cfset assertTrue(money.getCurrency() EQ "USD", "Currency should be USD") />


		<!--- try with only one param --->
		<cfset money = variables.svc.createMoney(1000) />

		<cfset assertTrue(isNumeric(money.getCents()), "Cents should be numeric data") />
		<cfset assertTrue(money.getCents() EQ "1000", "Cents should be an integer and 1000") />
		<cfset assertTrue(money.getAmount() EQ "10.00", "Amount should divide by fraction of 100") />
		<cfset assertTrue(money.getCurrency() EQ "USD", "Currency should be USD") />

	</cffunction>


	<cffunction name="testMoneyInCentsViaSetters" access="public" returntype="void" output="false">

		<cfset var money = variables.svc.createMoney() />

		<cfset money.setCents(1250) />

		<!--- verify some values --->
		<cfset assertTrue(isNumeric(money.getCents()), "Cents should be numeric data") />
		<cfset assertTrue(money.getCents() EQ "1250", "Cents should be an integer and 1250") />
		<cfset debug(money.getAmount()) />
		<cfset assertTrue(money.getAmount() EQ "12.50", "Amount should divide by fraction of 100") />
		<cfset assertTrue(money.getCurrency() EQ "USD", "Currency should be USD (default)") />

	</cffunction>


	<cffunction name="testMoneyInCAD" access="public" returntype="void" output="false">

		<cfset var money = variables.svc.createMoney(500, "CAD") />

		<!--- verify some values --->
		<cfset assertTrue(money.getCents() EQ "500", "Cents should be an integer and 500") />
		<cfset assertTrue(money.getAmount() EQ "5.00", "Amount should divide by fraction of 100") />
		<cfset assertTrue(money.getCurrency() EQ "CAD", "Currency should be CAD") />

		<!--- test stacked setters --->
		<cfset money.setCents(1000).setCurrency("USD") />

		<cfset assertTrue(money.getCents() EQ "1000", "Cents should be an integer and 1000") />
		<cfset assertTrue(money.getCurrency() EQ "USD", "Currency should be USD") />

	</cffunction>


	<cffunction name="testZeroAndNegative" access="public" returntype="void" output="false">

		<cfset var money = variables.svc.createMoney(0) />

		<!--- verify formatting --->
		<cfset assertTrue(money.getCents() EQ "0", "0 cents should be '0'") />
		<cfset assertTrue(money.getAmount() EQ "0.00", "Zero should be formatted like 0.00") />

		<!--- try negative --->
		<cfset money.setCents(-500) />
		<cfset assertTrue(money.getCents() EQ "-500", "-500 cents should be '-500'") />
		<cfset assertTrue(money.getAmount() EQ "-5.00", "Negative $5 should be formatted like -5.00") />

	</cffunction>

</cfcomponent>
