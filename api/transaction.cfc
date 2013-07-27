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
<cfcomponent dislayname="transaction" output="false" hint="The core API for CFPAYMENT">
		
	<!--- 
	NOTES:
	* This is the transaction API that wraps the core to provide persistence
	* Expects tables to have been created by install script	
	--->
	<cfset variables.instance = structNew() />
	<cfset variables.core = createObject("component", "core") />
	
	<!--- init --->
	<cffunction name="init" output="false" access="public" returntype="any" hint="">
		<cfargument name="config" type="struct" required="true" />
		<cfargument name="encryptionService" type="any" required="false" />

		<!--- the core service expects a structure of configuration information to be passed to it
			  telling it what gateway to use and so forth --->
		<cfset getCore().init(config = arguments.config) />	

		<cfif structKeyExists(arguments, "encryptionService") AND isObject(arguments.encryptionService)>
			<cfset variables.instance.encryptionService = arguments.encryptionService />
			<cfset variables.instance.hasEncryptionService = true />
		<cfelse>
			<cfset variables.instance.hasEncryptionService = false />
		</cfif>
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getCore" output="false" access="private" returntype="any" hint="return the core cfpayment service">
		<cfreturn variables.instance.core />
	</cffunction>
	

	<!--- GATEWAY WRAPPERS FOR PERSISTENCE (only necessary for credits/debits, not lookups/etc) --->
	<cffunction name="authorize" output="false" access="public" returntype="any" hint="Verifies payment details with merchant bank">
		<cfargument name="amount" type="numeric" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="params" type="struct" required="true" />

		<!--- 1. collect data, 
					if encryption service, 
						getEncryptedMemento()
					else
						leave the encrypted field blank and don't store CHD
					/if
			     write to database with a pending status --->
			  
		<!--- 2. getCore().getGateway().charge(argumentCollection = arguments) --->
		
		<!--- 3. take normalized results and update database, return result --->
	</cffunction>


	<!--- capture, charge, void, etc; all credit/debit routines 
	
			...
			...
			...
			...
			...
	
	--->





	<!--- PRIVATE ENCRYPTION WRAPPERS --->
	<cffunction name="hasEncryptionService" access="private" returntype="any" output="false"><cfreturn variables.instance.hasEncryptionService /></cffunction>
	<cffunction name="getEncryptionService" access="private" returntype="any" output="false"><cfreturn variables.instance.encryptionService /></cffunction>
	
	<cffunction name="getEncryptedMemento" access="private" output="false" returntype="any">
		<cfargument name="account" type="any" required="true" />
		
		<!--- WARNING: PCI DSS MANDATES WHAT CARDHOLDER DATA
			  		   MAY BE STORED.  CVC OR CVV2 IS NOT PERMITTED
			  		   TO BE RETAINED POST-AUTHORIZATION UNDER ANY
			  		   CIRCUMSTANCES.  DO NOT ADD IT TO THE ENCRYPTED
			  		   MEMENTO LIST!!!! 
			  		   
			  		   The CVC/CVV2 number is an anti-fraud tool but does
			  		   *NOT* change your processing rate so there is no reason
			  		   to retain it after attempting to charge a card.  There
			  		   are giant penalties for being out of compliance here
			  		   so if you feel that you need it, contact your acquiring
			  		   bank FIRST.
		--->
		<cfset var data = "" />
		<cfset var key = "" />
		
		<cfif hasEncryptionService()>

			<cfset data = listAppend(data, arguments.account.getFirstName(), "|") />
			<cfset data = listAppend(data, arguments.account.getLastName(), "|") />
			<cfset data = listAppend(data, arguments.account.getAddress(), "|") />
			<cfset data = listAppend(data, arguments.account.getPostalCode(), "|") />
			
			<cfif arguments.account.getIsCreditCard()>

				<cfset data = listAppend(data, arguments.account.getAccount(), "|") />
				<cfset data = listAppend(data, arguments.account.getMonth(), "|") />
				<cfset data = listAppend(data, arguments.account.getYear(), "|") />

			<cfelseif arguments.account.getIsEFT()>
			
				<cfset data = listAppend(data, arguments.account.getPhoneNumber(), "|") />
				<cfset data = listAppend(data, arguments.account.getAccount(), "|") />
				<cfset data = listAppend(data, arguments.account.getRoutingNumber(), "|") />
				<cfset data = listAppend(data, arguments.account.getCheckNumber(), "|") />			
			
			</cfif>
			
			<!--- add random salt into encrypted data --->
			<cfset data = listAppend(data, generateSecretKey("AES"), "|") />
		
			<cfreturn getEncryptionService().encryptData(data) />
		
		</cfif>
	
		<cfreturn "" />
		
	</cffunction>
	<cffunction name="setEncryptedMemento" access="private" output="false" returntype="void">
		<cfargument name="account" type="any" required="true" />
		<cfargument name="data" type="any" required="true" />
		
		<cfset var acct = "" />
		
		<cfif hasEncryptionService()>
		
			<cfset acct = getEncryptionService().decryptData(arguments.data) />

			<!--- use settings to return object to decrypted status --->
			<cfset arguments.account.setFirstName(listGetAt(acct, 1, "|")) />
			<cfset arguments.account.setLastName(listGetAt(acct, 2, "|")) />
			<cfset arguments.account.setAddress(listGetAt(acct, 3, "|")) />
			<cfset arguments.account.setPostalCode(listGetAt(acct, 4, "|")) />
			
			<cfif arguments.account.getIsCreditCard()>

				<cfset arguments.account.setAccount(listGetAt(acct, 5, "|")) />
				<cfset arguments.account.setMonth(listGetAt(acct, 6, "|")) />
				<cfset arguments.account.setYear(listGetAt(acct, 7, "|")) />

			<cfelseif arguments.account.getIsEFT()>
			
				<cfset arguments.account.setPhoneNumber(listGetAt(acct, 5, "|")) />
				<cfset arguments.account.setAccount(listGetAt(acct, 6, "|")) />
				<cfset arguments.account.setRoutingNumber(listGetAt(acct, 7, "|")) />
				<cfset arguments.account.setCheckNumber(listGetAt(acct, 8, "|")) />

			</cfif>
			
		</cfif>
	
	</cffunction>


</cfcomponent>