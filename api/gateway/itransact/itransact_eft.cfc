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
<cfcomponent displayname="iTransact XML Interface" extends="itransact" hint="Used for processing e-checks payments via iTransact.com/PaymentClearing.com" output="false">

	<!--- wrap process with checkauth* processing --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<!--- pass up the chain, and do generic result processing --->
		<cfset var response = super.process(argumentCollection = arguments) />
		<cfset var xmlResponse = "" />
		
		<!--- see if the response is already an error --->
		<cfif NOT response.hasError() AND isXML(response.getResult())>

			<!--- the raw result is XML, load it --->
			<cfset xmlResponse = response.getParsedResult() />
	
			<!--- see if the response object has a successful root node: <CheckAuthResponseOK> --->
			<cfif isCheckAuthOK(xmlResponse)>

				<cfset response.setStatus(getService().getStatusSuccessful()) />

			<cfelseif isCheckAuthError(xmlResponse)>

				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfset response.setMessage(getCheckAuthError(xmlResponse)) />

			</cfif>

		</cfif>

		<cfreturn response />
	</cffunction>


	<!--- override the primary methods --->
	<cffunction name="authorize" output="false" access="public" returntype="any" hint="">
		<cfthrow message="Authorize not implemented for E-checks; use purchase instead." type="cfpayment.MethodNotImplemented" />
	</cffunction>

	
	<!--- e-check doesn't have separate auth vs. purchase --->
	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Debit a checking account">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfset var xmlRequest = "" />
		<cfset var xmlResponse = "" />
		<cfset var response = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<CheckAuthRequest>
				<FirstName>#arguments.account.getFirstName()#</FirstName>
				<LastName>#arguments.account.getLastName()#</LastName>				
				<PhoneNumber>#xmlFormat(arguments.account.getPhoneNumber())#</PhoneNumber>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<BankRouteNumber>#arguments.account.getRoutingNumber()#</BankRouteNumber>
				<BankAccountNumber>#arguments.account.getAccount()#</BankAccountNumber>
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
				<cfif len(arguments.account.getAddress())><Address1>#xmlFormat(arguments.account.getAddress())#</Address1></cfif>
				<cfif len(arguments.account.getAddress2())><Address2>#xmlFormat(arguments.account.getAddress2())#</Address2></cfif>
				<cfif len(arguments.account.getPostalCode())><PostalCode>#xmlFormat(arguments.account.getPostalCode())#</PostalCode></cfif>
				<cfif len(arguments.account.getCheckNumber())><CheckNumber>#arguments.account.getCheckNumber()#</CheckNumber></cfif>
			</CheckAuthRequest>
		</cfxml>
		</cfoutput>		
		
		<cfreturn process(toString(xmlRequest)) />
	</cffunction>


	<!--- can idbasedcredit work? 
	<cffunction name="credit" output="false" access="public" returntype="any" hint="Credit all or part of a previous transaction">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="transactionid" type="any" required="true" />
		<cfargument name="options" type="struct" required="false" />

		<cfset var xmlRequest = "" />
		<cfset var xmlResponse = "" />
		<cfset var response = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<CheckCreditRequest>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<BankAccountNumber>number</BankAccountNumber>
				<BankRouteNumber>number</BankRouteNumber>
				<ExternalId>number</ExternalId>
				<FirstName>string</FirstName>
				<LastName>string</LastName>
				<MerchantAccountNumber>number</MerchantAccountNumber>
			</CheckCreditRequest>	
					
			<IdBasedCreditRequest>
				<CentsAmount>#arguments.money.getCents()#</CentsAmount>
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

			<!--- the raw result is XML, load it --->
			<cfset xmlResponse = response.getParsedResult() />
	
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
	--->

	<cffunction name="getIsEFTEnabled" access="public" output="false" returntype="boolean">
		<cfreturn true />
	</cffunction>


	<!--- PRIVATE HELPER METHODS FOR PARSING XML ------------------------------
	
		Based upon iTransact Documentation as of 6/24/2006
		Used in production through 11/8/2008
	
	----------------------------------------------------------------------- --->

	<!--- boolean test to see if the transaction was successful --->
	<cffunction name="isCheckAuthOK" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- format looks like:
			<CheckAuthResponseOk>
				<InternalId>number</InternalId>
				<ProcessorTransactionId>string</ProcessorTransactionId>
			</CheckAuthResponseOk>
		--->		

		<!--- see if the response object has a successful root node: <CardAuthResponseOK> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("CheckAuthResponseOK")>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
		

	<!--- boolean test to see if the check transaction failed --->
	<cffunction name="isCheckAuthError" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- first format looks like:
			<CheckAuthResponseError>
				<AVSResponse>string</AVSResponse>
				<ErrorMessage>string</ErrorMessage>
				<EquifaxResponse>string</EquifaxResponse>
				<InternalId>number</InternalId>
				<PreviousPayment>string</PreviousPayment>
				<ProcessorTransactionId>string</ProcessorTransactionId>
				<RequiredText>string</RequiredText>
				<Score>number</Score>
			</CheckAuthResponseError>
			
			or 
			
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
			<cftry value="REQ. EXCEEDS BALANCE">
			Request exceeds available balance o ncard
			</cftry>
			<cfdefaultcase>

			</cfdefaultcase>
		</cfswitch>
		--->		

		<!--- see if the response object has an error root node: <CardAuthResponseError> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("CheckAuthResponseError")>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>


	<!--- return a string message for the cause of the error --->
	<cffunction name="getCheckAuthError" output="false" access="private" returntype="string">
		<cfargument name="xmlObject" type="any" required="true" />
		
		<cfset var msg = "" />
		<!--- first format looks like:
			<CheckAuthResponseError>
				<AVSResponse>string</AVSResponse>
				<ErrorMessage>string</ErrorMessage>
				<EquifaxResponse>string</EquifaxResponse>
				<InternalId>number</InternalId>
				<PreviousPayment>string</PreviousPayment>
				<ProcessorTransactionId>string</ProcessorTransactionId>
				<RequiredText>string</RequiredText>
				<Score>number</Score>
			</CheckAuthResponseError>
		--->
		<cfif IsDefined("xmlObject.xmlRoot.ErrorMessage.xmlText")>
			<cfswitch expression="#xmlObject.xmlRoot.ErrorMessage.xmlText#">
				<cfcase value="PLEASE RETRY">
					<!--- if this occurs, we should retry the transaction ourselves and not harass the user --->
					<cfset msg = "There was a temporary error processing your card with the bank.  Please retry the transaction." />
				</cfcase>
				<cfdefaultcase>
					<cfset msg = "Your check was declined by the bank because:  #xmlObject.xmlRoot.ErrorMessage.xmlText#.  Please try again or try using a credit card." />
				</cfdefaultcase>
			</cfswitch>
		<cfelse>
			<cfset msg = "No error description found.  Please contact the administrators for help.  The error object is:  #toString(xmlObject)#" />
		</cfif>
		
		<!--- return msg --->
		<cfreturn msg />
	</cffunction>

</cfcomponent>