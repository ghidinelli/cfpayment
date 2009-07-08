<!-----------------------------------------------------------------------------
	
	Component Name:	Cryptography.		
	Description:	This component handles all the functionalities 
					related to cryptography.	
									
	Author:			Mindfire Solutions (contracted by Brian Ghidinelli)
	Create Date:	25th June 2007
	Copyright: 		Copyright (c) 2007 Brian Ghidinelli (http://www.ghidinelli.com)

------------------------------------------------------------------------------>
<cfcomponent name="cryptoService"
			displayname="Cryptography Component"
			hint="I contain all functionalities related to cryptography">

	<!---------------------------------------------------------------------------
			
		Name: init
				
		Arguments:
			1.	keyStoreFile [ Type:String Required:Yes	]
				- The keystore filename with physical path which is to be initialized					

		Returns:
			Nothing.

		Description:			
			Initializes a specified keystore file. Creates a new one, if specified 
			keystore file is not present and initializes to the new keystore.
				
	---------------------------------------------------------------------------->
	<cffunction name="init"
				access="public"
				displayname="Init Key Store"
				returntype="void"
				output="false">
		<cfargument name="keyStoreFile"
					displayname="Key Store File "
					type="string"
					required="yes">	
		<cfargument name="passPhrase"
					displayname="Pass Phrase "
					type="string"
					required="no">
		
			
			<!--- Initialization of local variables. --->
			<cfset var objCrypto = 0>
			
			<!--- Create the java object and initialize by calling its constructor. --->
			<cfset objCrypto = CreateObject("java", "java.Cryptography")>
			<cfset objCrypto.Init()>
						
			<cftry>
				
				<cfif not FileExists(keyStoreFile) and Len(passPhrase) eq 0>
					
					<cfset displayError("Invalid Arguments","Password is not provided and KeyStore doesn't exist")>							
									
				<cfelseif not FileExists(keyStoreFile) and Len(passPhrase) gt 0>
					
					<cfset objCrypto.keyStoreGenerator(keyStoreFile,passPhrase )>
					<cfset objCrypto.Init(keyStoreFile)>
					
				<cfelse>
				
					<cfset objCrypto.Init(keyStoreFile)>	
					
				</cfif>
				
				<cfcatch type="any">
					<cfset displayError(cfcatch.Type,cfcatch.Message)>		
				</cfcatch>
				
			</cftry>				
			
			<cfset variables.objCrypto = objCrypto>
			
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: encryptData

		Arguments:
			1.	data [ Type:String Required:Yes	]
				- Data to be encrypted. 

			2.	publicKey [ Type:Struct Required:Yes	]
				- Structure containing public key data to be used for encryption. 


		Returns:
			The encrypted Data.
			[ Type:String ]

		Description:			
			Encrypts the specified data using the specified public key.
				
	---------------------------------------------------------------------------->	
	<cffunction name="encryptData"
				access="public"
				displayname="Encrypt Data"
				returntype="string"
				output="false">
		<cfargument name="data"
					displayname="Data"
					type="string"
					required="yes">
		<cfargument name="publicKey"
					displayname="Public Key"
					type="struct"
					required="yes">			

			
			<!--- Initialization of local variables. --->
			<cfset var encString = "">
			
			<cftry>
				
				<cfset encString =  variables.objCrypto.encryption(data, publicKey.modulus, publicKey.exponent)>
				<cfcatch type="any" >	
					<cfset displayError(cfcatch.Type,cfcatch.Message)>				
				</cfcatch>
				
			</cftry>
			
			<cfreturn encString>
											
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: decryptData

		Arguments:
			1.	data [ Type:String Required:Yes	]
				- Data to be decrypted. 

			2.	privateKey [ Type:Struct Required:Yes	]
				- Structure containing private key data	to be used for decryption.

		Returns:
			The decrypted Data.
			[ Type:String ]

		Description:			
			Decrypts the specified data using the specified private key.
				
	---------------------------------------------------------------------------->	
	<cffunction name="decryptData"
				access="public"
				displayname="Decrypt Data"
				returntype="String"
				output="false">
		<cfargument name="data"
					displayname="Data"
					type="string"
					required="yes">
		<cfargument name="privateKey"
					displayname="Private Key"
					type="struct"
					required="yes">		
		
			
			<!--- Initialization of local variables. --->
			<cfset var decString = "">
			
			<cftry>
				
				<cfset decString = variables.objCrypto.decryption(data, privateKey.modulus, 
								privateKey.privExponent, privateKey.pubExponent, privateKey.primeP,	
								privateKey.primeQ, privateKey.primeexponentP, 
								privateKey.primeExponentQ, privateKey.crtCoefficient)>
								
				<cfcatch type="any" >	
					<cfset displayError(cfcatch.Type,cfcatch.Message)>				
				</cfcatch>
				
			</cftry>
			
			<cfreturn decString>
												
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: importKey

		Arguments:
			1.	key [ Type:Structure Required:Yes	]
				- key which will be added in the KeyStore.It can be Public Key or Private Key	.					 

			2.	passPhrase [ Type:String Required:Yes	]
				- Password of the keystore where key is to be imported.	

			3.	alias [ Type:String Required:Yes	]
				- Alias name for the key to be imported.					

		Returns:
			Noting
			[ Type:Void ]

		Description:			
			Add  a key from specified keyfile to the  keystore with the specified
			alias and password.
				
	---------------------------------------------------------------------------->	
	<cffunction name="importKey"
				access="public"
				displayname="Import Key"
				returntype="Void"
				output="false">			
		<cfargument name="key"
					displayname="Key"
					type="struct"
					required="yes">
		<cfargument name="alias"
					displayname="Alias"
					type="string"
					required="yes">
		<cfargument name="passPhrase"
					displayname="Pass Phrase"
					type="string"
					required="yes">			
		

		<cftry>	
		
			<cfif StructCount(key) GT 2>
				<cfset variables.objCrypto.importKey(alias, passPhrase, key.modulus, 
						key.privExponent, key.pubExponent, key.primeP,	key.primeQ, 
						key.primeExponentP, key.primeExponentQ, key.crtCoefficient)>
	
			<cfelse>
				
				<cfset variables.objCrypto.importKey
						(alias, passPhrase, key.modulus, key.exponent)>
						
			</cfif>

			<cfcatch type="any" >	
				<cfset displayError(cfcatch.Type,cfcatch.Message)>				
			</cfcatch>

		</cftry>						
		
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: deleteKey

		Arguments:
			1.	alias [ Type:String Required:Yes	]
				- Alias name of the key to be deleted. 

			2.	passPhrase [ Type:String Required:Yes	]
				- Password of the keystore from which key is to be deleted.

		Returns:
			Noting
			[ Type:Void ]

		Description:			
			Deletes a key with the specified alias name.
				
	---------------------------------------------------------------------------->	
	<cffunction name="deleteKey"
				access="public"
				displayname="Delete Key"
				returntype="Void"
				output="false">
		<cfargument name="alias"
					displayname="Alias"
					type="string"
					required="yes">
		<cfargument name="passPhrase"
					displayname="Pass Phrase"
					type="string"
					required="yes">
												
		<cftry>
		
			<cfset variables.objCrypto.deleteKey(alias,passPhrase)>	
			
			<cfcatch type="any">
				<cfset displayError(cfcatch.Type,cfcatch.Message)>
			</cfcatch>
		
		</cftry>		
		
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: listKeys

		Arguments:
			1.	passPhrase [ Type:String Required:Yes	]
				- Password of the keystore from which key aliases are to be listed.

		Returns:
			A an array containing a list of key aliases. 
			[ Type:Array ]

		Description:			
			Lists all key aliases from the keystore.
				
	---------------------------------------------------------------------------->	
	<cffunction name="listKeys"
				access="public"
				displayname="Init Key Store"
				returntype="array"
				output="false">
		
		<cfargument name="passPhrase"
					displayname="Pass Phrase"
					type="string"
					required="yes">								
		
			
			<!--- Initialization of local variables. --->
			<cfset var keyArray = ArrayNew(1)>
			
			<cftry>
			
				<cfset keyArray = variables.objCrypto.listKeys(passPhrase)>
				<cfcatch>
					<cfset displayError(cfcatch.Type,cfcatch.Message)>
				</cfcatch>
				
			</cftry>
			
			<cfreturn keyArray>		
		
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: getKey

		Arguments:
			1.	alias [ Type:String Required:Yes	]
				- Alias name of the key to be retrieved. 

			2.	passPhrase [ Type:String Required:Yes	]
				- Password of the keystore from which key will be retrieved.

		Returns:
			The key related to the specified alias name.
			[ Type:Structure ]

		Description:			
			Gets the key of the specified alias name.

	---------------------------------------------------------------------------->	
	<cffunction name="getKey"
				access="public"
				displayname="Get Key"
				returntype="struct"
				output="false">
		<cfargument name="alias"
					displayname="Alias"
					type="string"
					required="yes">
		<cfargument name="passPhrase"
					displayname="Pass Phrase"
					type="string"
					required="yes">								
		
			
		<!--- Initialization of local variables. --->
		<cfset var retKey = "" />
		<cfset var isPublicKey = 0 />
		<cfset var Key = StructNew() />
		
		<cftry>	
			
			<cfset retKey = variables.objCrypto.retrieveKey(alias,passPhrase)>			
			<cfset isPublicKey = Find("RSAPublicKey",retKey.getClass().toString())>
			
			<cfif isPublicKey EQ "0">
				<!--- Create a Private Key Structure --->					
				<cfset Key.modulus = retKey.getModulus().toString()>
				<cfset Key.privExponent = retKey.getPrivateExponent().toString()>
				<cfset Key.pubExponent = retKey.getPublicExponent().toString()>
				<cfset Key.primeP = retKey.getPrimeP().toString()>
				<cfset Key.primeQ = retKey.getPrimeQ().toString()>
				<cfset Key.primeExponentP = retKey.getPrimeExponentP().toString()>
				<cfset Key.primeExponentQ = retKey.getPrimeExponentQ().toString()>			
				<cfset Key.crtCoefficient = retKey.getCrtCoefficient().toString()>
				
			<cfelse>
				<!--- Create a Public Key Structure --->
				<cfset Key = StructNew()>
				<cfset Key.modulus = retKey.getModulus().toString()>
				<cfset Key.exponent = retKey.getPublicExponent().toString()>
				
			</cfif>
			
			<cfcatch type="any" >
				<cfset displayError(cfcatch.Type,cfcatch.Message)>
			</cfcatch>
			
		</cftry>		
			
		<cfreturn Key>		
		
	</cffunction>

	<!---------------------------------------------------------------------------
			
		Name: generateKeyPair

		Arguments:
			1.	keySize [ Type:Integer Required:Yes	]
				- Size of the keyPair to be generated. 

		Returns:
			A structure containing a key pair of private key and public key.
			[ Type:Struct ]

		Description:			
			Generate a keypair having public key and private key.
				
	---------------------------------------------------------------------------->	
	<cffunction name="generateKeyPair"
				access="public"
				displayname="Generate Key Pair"
				returntype="struct"
				output="false">
		<cfargument name="keySize"
					displayname="Key Size"
					type="numeric"
					required="yes">								
		
			
			<!--- Initialization of local variables. --->
			<cfset var keyPair = StructNew()>
			<cfset var key = 0>
			
			<cfif arguments.keySize gt 2048>
				<cfset displayError("KeySize Exception","KeySize exceeded than 2048 bits")>
			<cfelseif arguments.keySize lt 0>
				<cfset displayError("KeySize Exception","KeySize cannot be negative.")>
			<cfelse>
						
				<cftry>

					<cfset key = variables.objCrypto.keyPairGeneration(arguments.keySize)>
					<cfset keyPair.publicKey = StructNew()>
					<cfset keyPair.publicKey.modulus = key.getPublic().getModulus().toString()>
					<cfset keyPair.publicKey.exponent = key.getPublic().getExponent().toString()>

					<cfset keyPair.privateKey = StructNew()>
					<cfset keyPair.privateKey.modulus = key.getPrivate().getModulus().toString()>
					<cfset keyPair.privateKey.privExponent = key.getPrivate().getExponent().toString()>
					<cfset keyPair.privateKey.pubExponent = key.getPrivate().getPublicExponent().toString()>
					<cfset keyPair.privateKey.primeExponentP = key.getPrivate().getDP().toString()>
					<cfset keyPair.privateKey.primeExponentQ = key.getPrivate().getDQ().toString()>
					<cfset keyPair.privateKey.primeP = key.getPrivate().getP().toString()>
					<cfset keyPair.privateKey.primeQ = key.getPrivate().getQ().toString()>
					<cfset keyPair.privateKey.crtCoefficient = key.getPrivate().getQInv().toString()>	

					<cfcatch type="any">
						<cfset displayError(cfcatch.Type,cfcatch.Message)>
					</cfcatch>

				</cftry>
				
			</cfif>
			
			<cfreturn keyPair>			
		
	</cffunction>
	
	<!---------------------------------------------------------------------------
				
		Name: displayError

		Arguments:
			1.	errorType [ Type:String Required:Yes	]
				- Type of exception to be generated. 
			2.	errorMessage [Type:String Required:Yes]	
				- Message for the exception

		Returns:
			A string containing a type of exception and details about the exception.
			[ Type:String ]

		Description:			
			Display exception of particular type and corresponding message.
					
	---------------------------------------------------------------------------->	
	<cffunction name="displayError"
				access="public"
				displayname="Display Error"
				returntype="struct"
				output="true">
		<cfargument name="errorType"
					displayname="Error Type"
					type="string"
					required="yes">
		<cfargument name="errorMessage"
					displayname="Error Message"
					type="string"
					required="yes">

		<cfoutput>
			 
			<table cellpadding="2" style="font-family:Verdana;width:80%;color:##666666;
											border-top:##CCCCCC solid 1px; 
											border-bottom:##999999 solid 1px;
											border-right:##CCCCCC solid 1px;
											border-left:##999999 solid 1px;">
				<tr style="background-color:##cccccc;font-size:16px;">
					<td colspan="2"><b>Error</b>
					</td>
				</tr>
				<tr>
					<td style="font-size:14px;">Type:</td>
					<td style="font-size:12px;">#errorType#</td>
				</tr>
				<tr>
					<td style="font-size:14px;">Message:</td>
					<td style="font-size:12px;">#errorMessage#</td>
				</tr>
			</table>			
		</cfoutput>	
		<cfabort>
		
	</cffunction>
	
</cfcomponent>
