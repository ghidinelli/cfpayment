<cfcomponent name="SymmetricEncryptionTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">	

		<cfset var gw = structNew() />

		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.encryption.symmetric");
			variables.svc.init(generateSecretKey("AES"));
		</cfscript>
	</cffunction>

	<cffunction name="testSymmetricEncryption" access="public" returntype="void" output="false">

		<cfset var txt = "this is some secret text that could contain credit card data" />	
		
		<cfset var data = variables.svc.encryptData(txt) />
		<cfset assertTrue(txt EQ variables.svc.decryptData(data), "Decrypted data did not match encrypted data") />

	</cffunction>


</cfcomponent>
