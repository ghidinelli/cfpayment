<!---
	$Id$
	
	Copyright 2008 Brian Ghidinelli (http://www.ghidinelli.com/)
	
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
<cfcomponent displayname="Base iTransact XML Interface" extends="cfpayment.api.gateway.base" hint="Common functionality for iTransact/PaymentClearing.com Gateways" output="false">

	<cfset variables.cfpayment.GATEWAY_NAME = "iTransact" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://secure.paymentclearing.com:8180/registered/GatewayServlet" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "https://secure.test.itransact.com/gateway/registered/GatewayServlet" />

	<!--- shared process wrapper with gateway/transaction error handling --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="payload" type="string" required="true" />

		<cfset var p = structNew() />
		<cfset var response = "" />
		<cfset var xmlResponse = "" />
		
		<!--- create options array; iTransact expects XML as a string under FORM variable "xml"; not sure if case-sensitive --->
		<cfset p["xml"] = arguments.payload />
		<cfset p["username"] = getUsername() />
		<cfset p["password"] = getPassword() />
		
		<!--- send it over the wire using the base gateway --->
		<cfset response = createResponse(argumentCollection = super.process(payload = p)) />
		
		<!--- we do some meta-checks for gateway-level errors (as opposed to auth/decline errors) --->
		<cfif NOT response.hasError()>
	
			<!--- we need to have a result we can parse; otherwise that's an error in itself --->	
			<cfif len(response.getResult()) AND isXML(response.getResult())>
				
				<cfset xmlResponse = xmlParse(response.getResult()) />
				
				<!--- store parsed result --->
				<cfset response.setParsedResult(xmlResponse) />

				<!--- handle common response fields --->
				<cfif structKeyExists(xmlResponse.xmlRoot, "InternalId")>
					<cfset response.setTransactionID(xmlResponse.xmlRoot.InternalId.XmlText) />
				</cfif>
				<cfif structKeyExists(xmlResponse.xmlRoot, "ErrorMessage")>
					<cfset response.setMessage(xmlResponse.xmlRoot.ErrorMessage.XmlText) />					
				</cfif>
				<cfif structKeyExists(xmlResponse.xmlRoot, "ApprovalCode")>
					<cfset response.setAuthorization(xmlResponse.xmlRoot.ApprovalCode.XmlText) />
				</cfif>

				<cfif isTransactionResponseError(xmlResponse)>
					
					<!--- transaction error means somethign bad happened *before* the transaction could be run but that request structure is OK (so an iTransact problem?) --->
					<cfset response.setStatus(getService().getStatusFailure()) />
					<cfset response.setMessage(getTransactionResponseError(xmlResponse)) />
					
				<cfelseif isGatewayFailure(xmlResponse)>

					<!--- gateway failure means something happened *before* transaction was run: doesn't contain authentication fields, can't be mapped to a valid request structure, or has some other fatal initialization issues.  --->
					<cfset response.setStatus(getService().getStatusFailure()) />
					<cfset response.setMessage(getGatewayFailure(xmlResponse)) />
				
				<cfelse>
				
					<!--- handle common "success" fields --->
					<cfif structKeyExists(xmlResponse.xmlRoot, "AVSResponse")>
						<cfset response.setAVSCode(xmlResponse.xmlRoot.AVSResponse.XmlText) />					
					</cfif>
					<cfif structKeyExists(xmlResponse.xmlRoot, "CVV2Response")>
						<cfset response.setCVVCode(xmlResponse.xmlRoot.CVV2Response.XmlText) />					
					</cfif>

				</cfif>
		
			<cfelse>
			
				<!--- this is bad, because iTransact didn't return XML.  Uh oh! --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
			
			</cfif>
		
		</cfif>

		<cfreturn response />		

	</cffunction>


	<!--- shared methods between credit card and e-checks --->
	<cffunction name="credit" output="false" access="public" returntype="any" hint="Credit all or part of a previous transaction">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfset var xmlRequest = "" />
		<cfset var xmlResponse = "" />
		<cfset var response = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<IdBasedCreditRequest>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<InternalId>#arguments.transactionid#</InternalId>
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
			</IdBasedCreditRequest>
		</cfxml>
		</cfoutput>		
		
		<!--- run thru local process routine which normalizes the response --->
		<cfset response = process(toString(xmlRequest)) />
		
		<!--- see if the response is already an error --->
		<cfif NOT response.hasError() AND isXML(response.getResult())>

			<!--- the raw result is XML, parse it --->
			<cfset xmlResponse = xmlParse(response.getResult()) />
	
			<!--- normalize status and responses --->
			<!--- see if the response object has a successful root node: <CardAuthResponseOK> --->
			<cfif isCardAuthOK(xmlResponse)>

				<cfset response.setStatus(getService().getStatusSuccessful()) />
				<cfset response.setAuthorization(xmlResponse.xmlRoot.ApprovalCode.XmlText) />
				<cfset response.setTransactionID(xmlResponse.xmlRoot.InternalId.XmlText) />

			<cfelseif isCardAuthError(xmlResponse)>

				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfset response.setTransactionID(xmlResponse.xmlRoot.InternalId.XmlText) />
				<cfset response.setMessage(getCardAuthError(xmlResponse)) />

			</cfif>

		</cfif>

		<cfreturn response />
	</cffunction>


	<cffunction name="void" output="false" access="public" returntype="any" hint="">
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfset var xmlRequest = "" />
		<cfset var response = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<IdBasedVoidRequest>
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<InternalId>#arguments.transactionid#</InternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
			</IdBasedVoidRequest>
		</cfxml>
		</cfoutput>

		<!--- run thru local process routine which normalizes the response --->
		<cfset response = process(toString(xmlRequest)) />
		
		<!--- see if the response is already an error --->
		<cfif NOT response.hasError() AND isXML(response.getResult())>

			<!--- the raw result is XML, parse it --->
			<cfset xmlResponse = xmlParse(response.getResult()) />
	
			<!--- normalize status and responses --->
			<!--- see if the response object has a successful root node: <CardAuthResponseOK> --->
			<cfif isVoid(xmlResponse) OR isCardAuthOK(xmlResponse)>
	
				<cfset response.setStatus(getService().getStatusSuccessful()) />
				<cfset response.setAuthorization(xmlResponse.xmlRoot.ApprovalCode.XmlText) />
				<cfset response.setTransactionID(xmlResponse.xmlRoot.InternalId.XmlText) />

			<cfelseif isCardAuthError(xmlResponse)>
			
				<!--- the void failed for some reason; i'm not sure if we'll ever make it here
					  documentation says a CardAuthResponseError can come back but I think we only
					  get Gateway Failures for "transaction not found" --->
				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfset response.setTransactionID(xmlResponse.xmlRoot.InternalId.XmlText) />
				<cfset response.setMessage(getCardAuthError(xmlResponse)) />

			</cfif>

		</cfif>

		<cfreturn response />
	</cffunction>


	<cffunction name="settle" output="false" access="public" returntype="any" hint="">
		<cfargument name="options" type="struct" required="true" />

		<cfset var xmlRequest = "" />
		<cfset var response = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<SettlementRequest>
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
			</SettlementRequest>		
		</cfxml>
		</cfoutput>

		<!--- return the response which will need to be parsed via response.getResult() --->
		<cfset response = process(toString(xmlRequest)) />
		
		<!--- see if the response is already an error --->
		<cfif NOT response.hasError() AND isXML(response.getResult())>

			<!--- the raw result is XML, parse it --->
			<cfset xmlResponse = xmlParse(response.getResult()) />
	
			<!--- if we have a SettlementResponseOk node, it came back ok --->
			<cfif lcase(xmlResponse.xmlRoot.xmlName) EQ lcase("SettlementResponseOk")>

				<cfset response.setStatus(getService().getStatusSuccessful()) />
				<cfset response.setTransactionID(xmlResponse.xmlRoot.InternalId.XmlText) />

			</cfif>

		</cfif>

		<cfreturn response />		
	</cffunction>



	<!--- function to get a copy of the actual transaction response
	
		Only requests that have valid structure and therefore reach the processing modules are available for this.
		This means that any request that would return <GatewayResponseFail> will not be loadable.
		If a ReportResponseFail is returned from this request, it is most likely that the original request resulted
		in a GatewayResponseFail response.
	--->	
	<cffunction name="status" output="false" access="public">
		<cfargument name="transactionid" type="any" required="false" default="" hint="If checking status of a transaction with unknown response, this may not be known and can be blank" />
		<cfargument name="options" type="any" required="false" default="#structNew()#" />

		<cfset var xmlRequest = "" />
		<cfset var xmlResponse = "" />
		<cfset var response = "" />
		
		<cfif NOT (len(arguments.transactionid) OR (structKeyExists(arguments.options, "ExternalID") AND len(arguments.options.ExternalID)))>
			<cfthrow type="cfpayment.MissingParameter.Argument" detail="Requires either tranactionid or ExternalID to determine status" />
		</cfif>
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<TransactionResponseReportRequest>
				<cfif structKeyExists(arguments.options, "ExternalId")>
					<ExternalId>#arguments.options.ExternalID#</ExternalId>
					<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
				<cfelse>
					<InternalId>#arguments.transactionid#</InternalId>
				</cfif>
			</TransactionResponseReportRequest>
		</cfxml>
		</cfoutput>		
		
		<!--- run thru local process routine which normalizes the response --->
		<cfset response = process(toString(xmlRequest)) />
		
		<!--- see if the response is already an error --->
		<cfif NOT response.hasError() AND isXML(response.getResult())>

			<!--- the raw result is XML, parse it --->
			<cfset xmlResponse = xmlParse(response.getResult()) />
	
			<!--- normalize status and responses --->
			<!--- see if the response object has a successful root node --->
			<cfif listFindNoCase("CheckAuthResponseOK,CardAuthResponseOK", xmlResponse.xmlRoot.xmlName)>

				<cfset response.setStatus(getService().getStatusSuccessful()) />

			<cfelseif listFindNoCase("CheckAuthResponseError,CardAuthResponseError", xmlResponse.xmlRoot.xmlName)>

				<cfset response.setStatus(getService().getStatusDeclined()) />

			<cfelse>

				<!--- usually means original transaction resulted in GatewayResponseFail --->
				<cfset response.setStatus(getService().getStatusFailure()) />
				<cfset response.setMessage(xmlResponse.xmlRoot.ErrorMessage.XmlText) />

			</cfif>

		</cfif>

		<cfreturn response />
	</cffunction>



	<!--- PRIVATE HELPER METHODS FOR PARSING XML ------------------------------
	
		Based upon iTransact Documentation as of 6/24/2006
		Used in production through 11/8/2008
	
	----------------------------------------------------------------------- --->

	<!--- boolean test to see if the check transaction failed --->
	<cffunction name="isTransactionResponseError" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- first format looks like:

				<TransactionResponseFail>
					<ErrorCategory>text</ErrorCategory>
					<ErrorCode>text</ErrorCode>
					<ErrorMessage>text</ErrorMessage>
					<InternalId>text</InternalId>
				</TransactionResponseFail>			

		<cfswitch expression="#xmlObject.xmlNode.ErrorMessage#">
			<cftry value="EXPIRED CARD">
			Expired Card
			</cftry>
			...
			<cfcase value="PROCESSOR_CONNECTION,PROCESSOR_ERROR">
				<cfset msg = "The transaction was temporarily declined because we could not obtain an answer from your bank.  Please resubmit your payment in a few minutes or try an e-check.">
			</cfcase>
			<cftry value="REQ. EXCEEDS BALANCE">
			Request exceeds available balance o ncard
			</cftry>
			<cfdefaultcase>

			</cfdefaultcase>
		</cfswitch>
		
		--->

		<!--- see if the response object has an error root node: <CardAuthResponseError>  or <TransactionResponseFail> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("TransactionResponseFail")>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>


	<!--- return a string message for the cause of the error --->
	<cffunction name="getTransactionResponseError" output="false" access="private" returntype="string">
		<cfargument name="xmlObject" type="any" required="true" />
		
		<cfset var msg = "" />
		<!--- first format looks like:
			<TransactionResponseFail>
			<ErrorCategory>text</ErrorCategory>
			<ErrorCode>text</ErrorCode>
			<ErrorMessage>text</ErrorMessage>
			<InternalId>text</InternalId>
			</TransactionResponseFail>
		--->
		
		<cfif IsDefined("xmlObject.xmlRoot.ErrorMessage.xmlText")>

			<cfswitch expression="#xmlObject.xmlRoot.ErrorMessage#">
				<cfcase value="PROCESSOR_CONNECTION,PROCESSOR_ERROR">
					<cfset msg = "The transaction was temporarily declined because we could not obtain an answer from the bank.  Please resubmit your payment in a few minutes." />
				</cfcase>
				<cfcase value="SYSTEM_ERROR">
					<cfset msg = "The transaction was temporarily unable to be processed by the bank due to a system error.  Please resubmit your payment in a few minutes." />
				</cfcase>
				<cfdefaultcase>
					<cfset msg = "There was a transaction error connecting with the bank caused by: " & xmlObject.xmlRoot.ErrorMessage.xmlText />
				</cfdefaultcase>
			</cfswitch>

		<cfelse>
			<cfset msg = "No error description found.  Please contact the administrators for help.  The error object is:  #htmlEditFormat(toString(xmlObject))#" />
		</cfif>

		<!--- return msg --->
		<cfreturn msg />
	</cffunction>


	<!--- boolean test to see if the gateway had a failure --->
	<cffunction name="isGatewayFailure" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- format looks like:
		<GatewayResponseFail>
			<ErrorCategory>DATA_VALIDATION</ErrorCategory>
			<ErrorCode>castor.Unmarshal.unmarshal.2</ErrorCode>
			<ErrorMessage>unable to add text content to CardAccountNumber due to the following error: java.lang.IllegalStateException: Field access error: account(java.lang.String) access resulted in exception: null</ErrorMessage>
		</GatewayResponseFail> 
		--->		

		<!--- see if the response object has an error root node: <CardAuthResponseError> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("GatewayResponseFail")>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>


	<!--- method to return the gateway failure error --->
	<cffunction name="getGatewayFailure" output="false" access="private" returntype="string">
		<cfargument name="xmlObject" type="any" required="true" />
		
		<cfset var msg = "" />
		<!--- format looks like:
		<GatewayResponseFail>
			<ErrorCategory>DATA_VALIDATION</ErrorCategory>
			<ErrorCode>castor.Unmarshal.unmarshal.2</ErrorCode>
			<ErrorMessage>unable to add text content to CardAccountNumber due to the following error: java.lang.IllegalStateException: Field access error: account(java.lang.String) access resulted in exception: null</ErrorMessage>
		</GatewayResponseFail> 

		ErrorCategory:
		DATABASE - Database Error
		� DATA_VALIDATION - Error validating data within code. Not request specific.
		� PROCESSOR_CONNECTION - There was an error while connecting to the processing network.
		� PROCESSOR_DENIED - The processor denied the authorization.
		� PROCESSOR_ERROR - The processing network reported an internal problem.
		� REQUEST_VALIDATION - The request could not be processed because of a problem with the
		request. This could be becouse of formatting, missing data, invalid data, etc.
		� SECURITY - The request could not be processed because it would violate system security constraints.
		� SYSTEM_CONFIG - The iTransact Gateway is not configured correctly, please report.
		� SYSTEM_ERROR - There was a general system error while processing the request, please report.
		� UNSPECIFIED - There was an unexpected error processing the transaction.
		--->		

		<cfif IsDefined("xmlObject.xmlRoot.ErrorMessage.xmlText")>
			<cfswitch expression="#xmlObject.xmlRoot.ErrorMessage.xmlText#">
				<!--- cfcase value="DATABASE">
					<cfset msg = "">
				</cfcase>
				<cfcase value="DATA_VALIDATION">
					<cfset msg = "">
				</cfcase>
				<cfcase value="PROCESSOR_CONNECTION">
					<cfset msg = "">
				</cfcase --->
				<cfdefaultcase>
					<cfset msg = "The transaction was declined by the bank because:  #xmlObject.xmlRoot.ErrorMessage.xmlText#" />
				</cfdefaultcase>
			</cfswitch>
		<cfelse>
			<cfset msg = "No error description found.  Please contact the administrators for help.  The error object is:  #toString(xmlObject)#" />
		</cfif>

		<!--- see if the response object has an error root node: <CardAuthResponseError> --->
		<cfreturn msg />
	</cffunction>


	<cffunction name="isTransaction" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- 
			If a transaction does not exist in the DB, this is the error we'll get:
			<?xml version="1.0"?> 
			<ReportResponseFail>
				<ErrorCategory>DATABASE</ErrorCategory>
				<ErrorCode>trans.RequestResponseMap.DBLoadByExternalTransactionId.1</ErrorCode>
				<ErrorMessage>No record for externalId 18317065 and merchantAccountNumber 13588</ErrorMessage>
				<InternalId>21794289</InternalId>
			</ReportResponseFail>
		--->

		<!--- see if the response object has an error root node: <ReportResponseFail> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("ReportResponseFail")>
			<cfreturn false />
		<cfelse>
			<cfreturn true />
		</cfif>
	</cffunction>


	<cffunction name="isVoid" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- 
			If a transaction has been voided, its previously successful response will come back as a VOID:

			<CardAuthResponseOk>
				<ApprovalCode> SALE</ApprovalCode>
				<BatchNumber>877</BatchNumber>
				<CVV2Response></CVV2Response>
				<InternalId>21795510</InternalId>
				<ProcessorTransactionId>010</ProcessorTransactionId>
			</CardAuthResponseOk>
		--->

		<!--- see if the response object has root node: <CardAuthResponseOk> --->
		<!--- The first character or two in " SALE" is NOT a space, it's some  other character --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("CardAuthResponseOk") AND lcase(trim(right(xmlObject.xmlRoot.ApprovalCode.XmlText, 4))) EQ "sale">
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>


</cfcomponent>