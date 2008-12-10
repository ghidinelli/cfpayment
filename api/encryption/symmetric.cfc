<cfcomponent displayname="Symmetric Encryption Provider" output="false" hint="Provides encryption and decryption services for CFPAYMENT transactions">

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="key" type="string" required="true" />
		
		<cfset variables.instance = structNew() />
		<cfset variables.instance.key = arguments.key />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="encryptData" access="public" output="false" returntype="any">
		<cfargument name="data" type="any" required="true" />

		<cfreturn encrypt(arguments.data, variables.instance.key, "AES") />
	</cffunction>

	<cffunction name="decryptData" access="public" output="false" returntype="any">
		<cfargument name="data" type="any" required="true" />
		
		<cfreturn decrypt(arguments.data, variables.instance.key, "AES") />
	</cffunction>

</cfcomponent>