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
<cfcomponent displayname="iTransact XML Interface" extends="itransact" hint="Used for processing credit card payments via iTransact.com/PaymentClearing.com" output="false">

	<!--- wrap process with cardauth* processing --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<!--- pass up the chain, and do generic result processing --->
		<cfset var response = super.process(argumentCollection = arguments) />
		<cfset var xmlResponse = "" />
		
		<!--- see if the response is already an error --->
		<cfif NOT response.hasError() AND isXML(response.getResult())>

			<!--- the raw result is XML, load it --->
			<cfset xmlResponse = response.getParsedResult() />
	
			<!--- see if the response object has a successful root node: <CardAuthResponseOK> --->
			<cfif isCardAuthOK(xmlResponse)>

				<cfset response.setStatus(getService().getStatusSuccessful()) />

			<cfelseif isCardAuthError(xmlResponse)>

				<cfset response.setStatus(getService().getStatusDeclined()) />
				<cfset response.setMessage(getCardAuthError(xmlResponse)) />

			</cfif>

		</cfif>

		<cfreturn response />
	</cffunction>


	<!--- implement primary methods --->
	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Authorize + Capture in one step">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfset var xmlRequest = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<CardSaleRequest>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<CardAccountNumber>#arguments.account.getAccount()#</CardAccountNumber>
				<CardExpirationDate month="#arguments.account.getMonth()#" year="#arguments.account.getYear()#" />
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
				<cfif len(arguments.account.getPostalCode())><PostalCode>#xmlFormat(arguments.account.getPostalCode())#</PostalCode></cfif>
				<cfif len(arguments.account.getAddress())><StreetAddress>#xmlFormat(arguments.account.getAddress())#</StreetAddress></cfif>
				<cfif len(arguments.account.getVerificationValue())>
					<CardCVV2Data number="#arguments.account.getVerificationValue()#" indicator="1"/>
				<cfelse>
					<CardCVV2Data number="" indicator="0"/>
				</cfif>
			</CardSaleRequest>	
		</cfxml>
		</cfoutput>		
		
		<cfreturn process(toString(xmlRequest)) />
	</cffunction>

	
	<cffunction name="authorize" output="false" access="public" returntype="any" hint="Authorize (only) a credit card">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />
		
		<cfset var xmlRequest = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<CardPreAuthRequest>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<CardAccountNumber>#arguments.account.getAccount()#</CardAccountNumber>
				<CardExpirationDate month="#arguments.account.getMonth()#" year="#arguments.account.getYear()#" />
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
				<cfif len(arguments.account.getPostalCode())><PostalCode>#xmlFormat(arguments.account.getPostalCode())#</PostalCode></cfif>
				<cfif len(arguments.account.getAddress())><StreetAddress>#xmlFormat(arguments.account.getAddress())#</StreetAddress></cfif>
			</CardPreAuthRequest>
		</cfxml>
		</cfoutput>

		<cfreturn process(toString(xmlRequest)) />
	</cffunction>


	<cffunction name="capture" output="false" access="public" returntype="any" hint="Add a previous authorization to be settled">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="authorization" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />

		<cfset var xmlRequest = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<CardPostAuthRequest>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<InternalId>#arguments.options.InternalId#</InternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
			</CardPostAuthRequest>
		</cfxml>
		</cfoutput>
		
		<!--- run thru local process routine which normalizes the response --->
		<cfreturn process(toString(xmlRequest)) />
	</cffunction>

	
	<!--- additional gateway specific requests --->
	<cffunction name="checkAVS" output="false" access="public" returntype="any" hint="Verify (but not process) the AVS for the credit card">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" />
		<cfargument name="options" type="struct" required="true" />
		
		<cfset var xmlRequest = "" />
		
		<cfoutput>
		<cfxml variable="xmlRequest">
			<CardAVSOnlyRequest>
				<CentAmount>#arguments.money.getCents()#</CentAmount>
				<CardAccountNumber>#arguments.account.getAccount()#</CardAccountNumber>
				<CardExpirationDate month="#arguments.account.getMonth()#" year="#arguments.account.getYear()#" />
				<ExternalId>#arguments.options.ExternalId#</ExternalId>
				<MerchantAccountNumber>#getMerchantAccount()#</MerchantAccountNumber>
				<cfif len(arguments.account.getPostalCode())><PostalCode>#xmlFormat(arguments.account.getPostalCode())#</PostalCode></cfif>
				<cfif len(arguments.account.getAddress())><StreetAddress>#xmlFormat(arguments.account.getAddress())#</StreetAddress></cfif>
			</CardAVSOnlyRequest>				
		</cfxml>
		</cfoutput>

		<cfreturn process(toString(xmlRequest)) />
	</cffunction>
	
	
	<cffunction name="getIsCCEnabled" access="public" output="false" returntype="boolean">
		<cfreturn true />
	</cffunction>


	<!--- PRIVATE HELPER METHODS FOR PARSING XML ------------------------------
	
		Based upon iTransact Documentation as of 6/24/2006
		Used in production through 11/8/2008
	
	----------------------------------------------------------------------- --->

	<!--- boolean test to see if the transaction was successful --->
	<cffunction name="isCardAuthOK" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />
		<!--- format looks like:
			<CardAuthResponseOk>
				<ApprovalCode>text</ApprovalCode>
				<AVSCategory>text</AVSCategory>
				<AVSResponse>text</AVSResponse>
				<CVV2Response>text</CVV2Response>
				<InternalId>text</InternalId>
			</CardAuthResponseOk>	
		--->		

		<!--- see if the response object has a successful root node: <CardAuthResponseOK> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("CardAuthResponseOK")>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	

	<!--- boolean test to see if the transaction failed --->
	<cffunction name="isCardAuthError" output="false" access="private" returntype="boolean">
		<cfargument name="xmlObject" type="any" required="true" />

		<!--- see if the response object has an error root node: <CardAuthResponseError> --->
		<cfif lcase(xmlObject.xmlRoot.xmlName) EQ lcase("CardAuthResponseError")>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>


	<!--- return a string message for the cause of the error --->
	<cffunction name="getCardAuthError" output="false" access="private" returntype="string">
		<cfargument name="xmlObject" type="any" required="true" />
		
		<cfset var msg = "" />
		<!--- first format looks like:
			<CardAuthResponseError>
				<AVSCategory>text</AVSCategory>
				<AVSResponse>text</AVSResponse>
				<CVV2Response>text</CVV2Response>
				<ErrorMessage>text</ErrorMessage>
				<InternalId>text</InternalId>
			</CardAuthResponseError>	

			second:
			<TransactionResponseFail>
				...
			</TransactionResponseFail>
		--->
		<cfif IsDefined("xmlObject.xmlRoot.ErrorMessage.xmlText")>
			<cfswitch expression="#xmlObject.xmlRoot.ErrorMessage.xmlText#">
				<cfcase value="EXPIRED CARD">
					<cfset msg = "The transaction was declined because the credit card has expired.  Please try another credit card or e-check.">
				</cfcase>
				<cfcase value="NOT ON FILE">
					<cfset msg = "Your bank has declined the transaction indicating you are not on file.  You should call your bank to verify your account is working properly.">
				</cfcase>
				<cfcase value="INVALID CARD">
					<cfset msg = "The transaction was declined because the card number was invalid.  Please double-check the number matches the digits on your card.">
				</cfcase>
				<cfcase value="DECLINED">
					<!--- check the reason why --->
					<cfif listFindNoCase("C,N,R", ucase(xmlObject.xmlRoot.AVSResponse.xmlText))>
						<cfset msg = "The transaction was declined because the address or zip code provided does not match the information on file at your bank.  Are you sure the address supplied matches your billing address?">
					<cfelse>
						<cfset msg = "The transaction was declined by your bank.  Please try another credit card or e-check.">
					</cfif>
				</cfcase>
				<cfcase value="CALL AUTH CENTER">
					<cfset msg = "Your bank is asking me to call for a voice authorization but I am just a computer!  Would you please call them and ask why they declined your card?  Then you can return and I will happily accept your payment.">
				</cfcase>
				<cfcase value="CALL REF.; 999999,PICK UP CARD">
					<cfset msg = "Your bank has instructed us to decline your card at this time.  Please try another credit card or e-check.">
				</cfcase>
				<cfcase value="DECLINE CVV2,DECLINED CVV2,CVV2 MISMATCH">
					<cfset msg = "The transaction was declined because the security code on the back of your card does not match the code on file at your bank.  Please verify the 3-digit code is correct.">
				</cfcase>
				<cfcase value="PLEASE RETRY">
					<cfset msg = "There was a temporary error processing your card with the bank.  Please retry the transaction.">
				</cfcase>
				<cfcase value="MAX MONTHLY $VOL">
					<cfset msg = "There has been a temporary error with the bank that requires our attention.  Please try again later.">
				</cfcase>
				<cfcase value="REQ. EXCEEDS BALANCE">
					<cfset msg = "The transaction was declined because this charge would exceed the credit limit of the card.  Please try another credit card or e-check.">
				</cfcase>
				<cfdefaultcase>
					<cfset msg = "The transaction was declined by the bank because:  #xmlObject.xmlRoot.ErrorMessage.xmlText#" />
					<!--- should notify admins here so we can better message this in the future --->
				</cfdefaultcase>
			</cfswitch>
		<cfelse>
			<cfset msg = "No error description found.  Please contact the administrators for help.  The error object is:  #toString(xmlObject)#" />
		</cfif>
		
		<!--- return msg --->
		<cfreturn msg />
	</cffunction>


</cfcomponent>