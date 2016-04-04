<cfcomponent displayname="paymentservice" output="false" accessors="true">
	<cfproperty name="apikey" default="dv637Zh3r2sRdrXDzWjq97KCY2WY6aR5"/>

	<cffunction name="init">
		<cfargument name="apikey" default=""/>
		<cfif len(arguments.apikey)>
			<cfset variables.apikey = arguments.apikey>
		</cfif>
		
		<cfreturn this>
	</cffunction>

	<!----add customer to vault with sale---->
	<cffunction name="addCustomer" hint="This function is used to create the customer">
		<!---scope return variable--->
		<cfset var content = ''/>
		<!----compile xml packet --->
		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<sale>
						<add-customer></add-customer>
						<api-key>#getApiKey()#</api-key>
						<merchant-defined-field-1>#XmlFormat(arguments.attributecollection.transactionid,true)#</merchant-defined-field-1>
						<redirect-url>#XmlFormat(arguments.attributecollection.RedirectURL,true)#</redirect-url>
						<amount>#XmlFormat(arguments.attributecollection.amount,true)#</amount>
						<billing>
							<first-name>#XmlFormat(arguments.attributecollection.firstname,true)#</first-name>
							<last-name>#XmlFormat(arguments.attributecollection.lastname,true)#</last-name>
							<address1>#XmlFormat(arguments.attributecollection.ccaddress,true)#</address1>
							<email>#XmlFormat(arguments.attributecollection.ccemail,true)#</email>
							<city>#XmlFormat(arguments.attributecollection.cccity,true)#</city>
							<state>#XmlFormat(arguments.attributecollection.ccstate,true)#</state>
							<postal>#XmlFormat(arguments.attributecollection.postal,true)#</postal>
						</billing>
					</sale>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<cfreturn sendPacket(content)/>
	</cffunction>	

	<!----just add customer to vault---->
	<cffunction name="addCustomerVault" hint="This function is used to create the customer">
		<!---scope return variable--->
		<cfset var content = ''/>
		<!----compile xml packet --->
		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<validate>
						<cfif structKeyExists(arguments.attributecollection,'vaultid') and len(arguments.attributecollection.vaultid)>
							<update-customer>
								<customer-vault-id>#XmlFormat(arguments.attributecollection.vaultid,true)#</customer-vault-id>
							</update-customer>
						<cfelse>
							<add-customer></add-customer>
						</cfif>
						
						<api-key>#getApiKey()#</api-key>
						<merchant-defined-field-1>#XmlFormat(arguments.attributecollection.transactionid,true)#</merchant-defined-field-1>
						<redirect-url>#XmlFormat(arguments.attributecollection.RedirectURL,true)#</redirect-url>
						<billing>
							<first-name>#XmlFormat(arguments.attributecollection.firstname,true)#</first-name>
							<last-name>#XmlFormat(arguments.attributecollection.lastname,true)#</last-name>
							<address1>#XmlFormat(arguments.attributecollection.ccaddress,true)#</address1>
							<email>#XmlFormat(arguments.attributecollection.ccemail,true)#</email>
							<city>#XmlFormat(arguments.attributecollection.cccity,true)#</city>
							<state>#XmlFormat(arguments.attributecollection.ccstate,true)#</state>
							<postal>#XmlFormat(arguments.attributecollection.postal,true)#</postal>
						</billing>
					</validate>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<cfreturn sendPacket(content)/>
	</cffunction>
	
	<cffunction name="completeTransaction" output="false" hint="I complete a customer vault addition.">
		<cfargument name="tokenid" required="true"/>

		<cfset var content = ''>

		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<complete-action>
						<api-key>#getApiKey()#</api-key>
						<token-id>#XmlFormat(arguments.tokenid,true)#</token-id>
					</complete-action>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<cfreturn sendPacket(content)/>
	</cffunction>	

	<cffunction name="billCustomer" output="false" hint="I complete a customer vault addition.">
		<cfargument name="amount" required="true"/>
		<cfargument name="vaultid" required="true"/>
		
		<cfset var content = ''>

		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<sale>
						<api-key>#getApiKey()#</api-key>
						<amount>#trim(arguments.amount)#</amount>
						<customer-vault-id>#trim(arguments.vaultid)#</customer-vault-id>
					</sale>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<cfreturn sendPacket(content)/>
	</cffunction>

	<cffunction name="sendPacket" hint="This function sends a packet to the payment processor and returns the result">
		<cfargument name="packet" required="true"/>
		<cfset var result = ''>

		<cfhttp url="https://secure.paylinedatagateway.com/api/v2/three-step" 
				method="post"
				compression="none"
				port="443">
				<cfhttpparam type="XML" value="#arguments.packet#">
		</cfhttp>

		<cfif IsXml(cfhttp.filecontent)>
			<cfset result = xmlparse(cfhttp.filecontent)>
		<cfelse>
			<cfthrow errorcode="#cfhttp.statuscode#" message="#cfhttp.filecontent#" />
		</cfif>
		<cfreturn result/>
	</cffunction>
	
	<cffunction name="void" output="false" hint="Transaction voids will cancel an existing sale or captured authorization. In addition, non-captured authorizations can be voided to prevent any future capture. Voids can only occur if the transaction has not been settled.">
		<cfargument name="transactionid" required="true"/>
		
		<cfset var result = ''>

		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<refund>
						<api-key>##</api-key>
						<transaction-id>#XmlFormat(arguments.transactionid)#</transaction-id>
					</refund>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<<cfset result = sendPacket(content)>
		<cfreturn xmlparse(cfhttp.filecontent)/>
	</cffunction>
	
	<cffunction name="refund" output="false" hint="Transaction refunds will reverse a previously settled transaction. If the transaction has not been settled, it must be voided instead of refunded.">
		<cfargument name="transactionid" required="true"/>
		<cfargument name="amount" required="true"/>

		<cfset var result = ''>

		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<refund>
						<api-key>#getApiKey()#</api-key>
						<transaction-id>#XmlFormat(arguments.transactionid)#</transaction-id>
						<amount>#XmlFormat(arguments.amount)#</amount>
					</refund>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<<cfset result = sendPacket(content)>
		<cfreturn xmlparse(result)/>
	</cffunction>


	<cffunction name="vaultSale" output="false" hint="Transaction to process a sale.">
		<cfargument name="vaultid" required="true"/>
		<cfargument name="amount" required="true"/>
		<cfargument name="description" required="true"/>
		<cfargument name="orderid" required="true"/>
		<cfargument name="username" required="true"/>
		<cfargument name="password" required="true"/>

		<cfset var cfhttp = ''>

		<cfhttp url="https://secure.paylinedatagateway.com/api/transact.php" 
				method="post"
				compression="none" 
				port="443">
			    <cfhttpparam type="Formfield" value="#trim(arguments.vaultid)#" name="customer_vault_id"> 
			    <cfhttpparam type="Formfield" value="#trim(arguments.amount)#" name="amount"> 
			    <cfhttpparam type="Formfield" value="#trim(arguments.orderid)#" name="orderid"> 
			    <cfhttpparam type="Formfield" value="#trim(arguments.description)#" name="orderdescription"> 
			    <cfhttpparam type="Formfield" value="#trim(arguments.username)#" name="username"> 
			    <cfhttpparam type="Formfield" value="#trim(arguments.password)#" name="password"> 
			    <cfhttpparam type="Formfield" value="sale" name="type"> 
		</cfhttp>

		<!---return a struct if the charge goes through, return a string if it fails--->
		<cfif listlen(cfhttp.filecontent,'=') gt 3>
			<cfreturn  QueryStringToStruct(cfhttp.filecontent)>
		<cfelse>
			<cfif len(cfhttp.errordetail)>
				<cfreturn cfhttp.errordetail>
			<cfelse>
				<cfreturn cfhttp.filecontent>
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="saveTransactionLog">
		<cfargument name="practitioner" default="" required="true"/>
		<cfargument name="Amount" default="" required="true"/>
		<cfargument name="CardHolder" default="" required="true"/>
		<cfargument name="AuthCode" default="" required="true"/>
		<cfargument name="RefID" default="" required="true"/>
		<cfargument name="Status" default="" required="true"/>

		<cfset var saveTransaction = ""/>
		<cfset var result = ""/>
		<cfquery name="saveTransaction" result="Result" datasource="therapyappoint">
			INSERT INTO TransactionLog (Practitioner, Amount, CardHolder, AuthCode, RefID, Status)
			VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#val(arguments.Practitioner)#"/>,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#val(arguments.Amount)#"/>,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#val(arguments.CardHolder)#"/>,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#val(arguments.AuthCode)#"/>,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#val(arguments.RefID)#"/>,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#val(arguments.Status)#"/>
					)
		</cfquery>
		<cfreturn Result.GENERATED_KEY/>
	</cffunction>

	<!----helper functions------>
	<cffunction name="getAVSResponse" hint="I decode the AVS response into readable language">
		<cfargument name="avs" default="string"/>
		<cfset var result = 'AVS code not found'>

		<cfswitch expression="#trim(arguments.avs)#">
			<cfcase value="X">
				<cfset result = 'Exact match, 9-character numeric ZIP'>
			</cfcase>
			<cfcase value="Y,D,M">
				<cfset result = 'Exact match, 5-character numeric ZIP'>
			</cfcase>
			<cfcase value="A,B">
				<cfset result = 'Address match only'>
			</cfcase>
			<cfcase value="W">
				<cfset result = '9-character numeric ZIP match only'>
			</cfcase>
			<cfcase value="Z,P,L">
				<cfset result = '5-character ZIP match only'>
			</cfcase>
			<cfcase value="N,C">
				<cfset result = 'No address or ZIP match only'>
			</cfcase>
			<cfcase value="U">
				<cfset result = 'Address unavailable'>
			</cfcase>
			<cfcase value="G,I">
				<cfset result = 'Non-U.S. issuer does not participate'>
			</cfcase>
			<cfcase value="R">
				<cfset result = 'Issuer system unavailable'>
			</cfcase>
			<cfcase value="E">
				<cfset result = 'Not a mail/phone order'>
			</cfcase>
			<cfcase value="S">
				<cfset result = 'Service not supported'>
			</cfcase>
			<cfcase value="O">
				<cfset result = 'AVS not available'>
			</cfcase>
		</cfswitch>
		<cfreturn result>
	</cffunction>

	<cffunction name="getCVVResponse" hint="I decode the CVV response into readable language">
		<cfargument name="cvv" default="string"/>
		<cfset var result = 'CVV code not found'>

		<cfswitch expression="#trim(arguments.cvv)#">
			<cfcase value="M">
				<cfset result = 'CVV2/CVC2 match'>
			</cfcase>
			<cfcase value="N">
				<cfset result = 'CVV2/CVC2 no match'>
			</cfcase>
			<cfcase value="P">
				<cfset result = 'Not processed'>
			</cfcase>
			<cfcase value="S">
				<cfset result = 'Merchant has indicated that CVV2/CVC2 is not present on card'>
			</cfcase>
			<cfcase value="U">
				<cfset result = 'Issuer is not certified and/or has not provided Visa encryption keys'>
			</cfcase>
		</cfswitch>
		<cfreturn result>
	</cffunction>

	<cffunction name="decodeResponse" hint="I decode the API response code into readable language">
		<cfargument name="response" default="string"/>
		<cfset var result = 'Response code not found'>

		<cfswitch expression="#trim(arguments.response)#">
			<cfcase value="100">
				<cfset result = 'Transaction was approved.'>
			</cfcase>
			<cfcase value="200">
				<cfset result = 'Transaction was declined by processor.'>
			</cfcase>
			<cfcase value="201">
				<cfset result = 'Do not honor.'>
			</cfcase>
			<cfcase value="202">
				<cfset result = 'Insufficient funds.'>
			</cfcase>
			<cfcase value="203">
				<cfset result = 'Over limit.'>
			</cfcase>
			<cfcase value="204">
				<cfset result = 'Transaction not allowed.'>
			</cfcase>
			<cfcase value="220">
				<cfset result = 'Incorrect payment information.'>
			</cfcase>
			<cfcase value="221">
				<cfset result = "No such card issuer.">
			</cfcase>
			<cfcase value="222">
				<cfset result = 'No card number on file with issuer.'>
			</cfcase>
			<cfcase value="223">
				<cfset result = 'Expired card.'>
			</cfcase>
			<cfcase value="224">
				<cfset result = 'Invalid expiration date.'>
			</cfcase>
			<cfcase value="225">
				<cfset result = 'Invalid card security code.'>
			</cfcase>
			<cfcase value="240">
				<cfset result = 'Call issuer for further information.'>
			</cfcase>
			<cfcase value="250">
				<cfset result = 'Pick up card.'>
			</cfcase>
			<cfcase value="251">
				<cfset result = 'Lost card.'>
			</cfcase>
			<cfcase value="252">
				<cfset result = 'Stolen card.'>
			</cfcase>
			<cfcase value="253">
				<cfset result = 'Fraudulent card.'>
			</cfcase>
			<cfcase value="260">
				<cfset result = 'Declined with further instructions available. (See response text)'>
			</cfcase>
			<cfcase value="261">
				<cfset result = 'Declined-Stop all recurring payments.'>
			</cfcase>
			<cfcase value="262">
				<cfset result = 'Declined-Stop this recurring program.'>
			</cfcase>
			<cfcase value="263">
				<cfset result = 'Declined-Update cardholder data available.'>
			</cfcase>
			<cfcase value="264">
				<cfset result = 'Declined-Retry in a few days.'>
			</cfcase>
			<cfcase value="300">
				<cfset result = 'Transaction was rejected by gateway.'>
			</cfcase>
			<cfcase value="400">
				<cfset result = 'Transaction error returned by processor.'>
			</cfcase>
			<cfcase value="410">
				<cfset result = 'Invalid merchant configuration.'>
			</cfcase>
			<cfcase value="411">
				<cfset result = 'Merchant account is inactive.'>
			</cfcase>
			<cfcase value="420">
				<cfset result = 'Communication error.'>
			</cfcase>
			<cfcase value="421">
				<cfset result = 'Communication error with issuer.'>
			</cfcase>
			<cfcase value="430">
				<cfset result = 'Duplicate transaction at processor.'>
			</cfcase>
			<cfcase value="440">
				<cfset result = 'Processor format error.'>
			</cfcase>
			<cfcase value="441">
				<cfset result = 'Invalid transaction information.'>
			</cfcase>
			<cfcase value="460">
				<cfset result = 'Processor feature not available.'>
			</cfcase>
			<cfcase value="461">
				<cfset result = 'Unsupported card type.'>
			</cfcase>
		</cfswitch>
		<cfreturn result>
	</cffunction>


	<!----3 step processe for sales / obtain vaultid ----->
	<cffunction name="generateToken" hint="This function is used to create the first step in the payment process">
		<cfargument name="data" default="#structNew()#" type="struct" required="true"/>
		
		<!----set up default values--->
		<cfparam name="arguments.data.RedirectURL" type="string" default=""/>
		<cfparam name="arguments.data.amount" type="string" default=""/>
		<cfparam name="arguments.data.firstname" type="string" default=""/>
		<cfparam name="arguments.data.lastname" type="string" default=""/>
		<cfparam name="arguments.data.address1" type="string" default=""/>
		<cfparam name="arguments.data.city" type="string" default=""/>
		<cfparam name="arguments.data.state" type="string" default=""/>
		<cfparam name="arguments.data.postal" type="string" default=""/>

		<!---scope return variable--->
		<cfset var content = ''/>

		<!----compile xml packet --->
		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<sale>
						<api-key>#XmlFormat(variables.apikey)#</api-key>
						<redirect-url>#XmlFormat(arguments.data.RedirectURL)#</redirect-url>
						<amount>#XmlFormat(arguments.data.amount)#</amount>
						<billing>
							<first-name>#XmlFormat(arguments.data.firstname)#</first-name>
							<last-name>#XmlFormat(arguments.data.lastname)#</last-name>
							<address1>#XmlFormat(arguments.data.address1)#</address1>
							<address2>#XmlFormat(arguments.data.address2)#</address2>
							<city>#XmlFormat(arguments.data.city)#</city>
							<state>#XmlFormat(arguments.data.state)#</state>
							<postal>#XmlFormat(arguments.data.postal)#</postal>
						</billing>
					</sale>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>

		<!----return resulting xml--->
		<cfreturn tostring(content)/>
	</cffunction>

	<cffunction name="finalizePayment" hint="This function is used to create the packet to send the ~sensitive~ information">
		<cfargument name="token" required="true"/>

		<cfset var content = ''/>
		<cfprocessingdirective suppresswhitespace="Yes">
			<cfxml variable="content">
				<cfoutput>
					<complete-action>
						<api-key>#XmlFormat(variables.apikey)#</api-key>
						<token-id>#XMLformat(arguments.token)#</token-id>
					</complete-action>
				</cfoutput>
			</cfxml>
		</cfprocessingdirective>
		<cfreturn tostring(content)/>
	</cffunction>
	<cffunction name="QueryStringToStruct" output="false">
		<cfargument name="QueryString" required="yes" type="string">
		<cfset myStruct = StructNew()>
		<cfloop list="#QueryString#" delimiters="&" index="i">
			<cfset QueryStringParts = ListToArray(i, "=")>
			<cfif arrayLen(QueryStringParts) LT 2>
				<cfset QueryStringParts[2] = ''>
			</cfif>

			<cfset structInsert(myStruct, Trim(QueryStringParts[1]),Trim(QueryStringParts[2]))>
		</cfloop>
		<cfreturn myStruct />
	</cffunction>
</cfcomponent>