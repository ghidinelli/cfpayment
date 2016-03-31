<!---

	Copyright 2016  Mark Drew (http://markdrew.io)
		
	Helper class to genrate all the XML that is required to send to the  of the authorize.net API.

	http://developer.authorize.net/api/reference/index.html
	
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

<cfcomponent>
	<cfset variables.validTransactions = "authCaptureTransaction,authOnlyTransaction,priorAuthCaptureTransaction,refundTransaction,voidTransaction">

	<cfset variables.validCustomerRequestTypes = "createCustomerProfileRequest,getCustomerProfileRequest">


	<cfset variables.testmode = true>

	<cffunction name="init">
		<cfargument name="testMode" required="true" type="boolean">
		<cfset variables.testmode = arguments.testmode>
		<cfreturn this>
	</cffunction>

	<cffunction name="createTransactionRequest" returntype="xml" hint="Main entry point for generating all the xml">
		<cfargument name="transactionType">
		<cfargument name="merchantAuthentication" hint="The merchant ids">
		<cfargument name="money" hint="The amount to that we want to debit">
		<cfargument name="account" hint="The account (i.e. card)">
		<cfargument name="options" hint="other details about the transaction such as refId">


		<cfif !isValidTransactionType(transactionType)>
			<cfthrow type="cfpayment.UnknownTransactionType" message="transactionType, #transactionType# is not known">
		</cfif>

		<cfif transactionType EQ "priorAuthCaptureTransaction" && NOT structKeyExists(options, "refTransId")>
			<cfthrow type="cfpayment.RequiredOptionMissing" message="transactionType, #transactionType# requires a refTransId in the options">
		</cfif>


		  
		<cfxml variable="local.xml">
			<cfoutput>
				
			<createTransactionRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
			  <merchantAuthentication>
			    <name>#merchantAuthentication.name#</name>
			    <transactionKey>#merchantAuthentication.transactionKey#</transactionKey>
			  </merchantAuthentication>
			  <cfif structKeyExists(options, "refId")>
			 	 <refId>#options.refId#</refId>
			  </cfif>
			  
			  <transactionRequest>
			    <transactionType>#transactionType#</transactionType>
			    <cfif structKeyExists(arguments, "money") && !isNull(money)>
			    	<amount>#money.getAmount()#</amount>
			    </cfif>
			    

			    <cfif structKeyExists(options, "refTransId")>
 					<refTransId>#options.refTransId#</refTransId>
			    </cfif>


			 

			   <cfif !IsNull(account) >
			   <payment>
			      <creditCard>
			        <cardNumber>#account.getAccount()#</cardNumber>
			        <expirationDate>#DateFormat(account.getExpirationDate(), "MM/YY")#</expirationDate>
			        <cardCode>#account.getVerificationValue()#</cardCode>
			      </creditCard>
			    </payment>
			    </cfif>



			    <cfif structKeyExists(options, "order")>
			    <order>
			    <cfif structKeyExists(options.order, "invoiceNumber")>
			    	<invoiceNumber>#options.order.invliceNumber#</invoiceNumber>
			    </cfif>
			     <cfif structKeyExists(options.order, "description")>
			     	<description>#options.order.description#</description>
			     </cfif>
			    </order>
			    </cfif>


				<cfif structKeyExists(options, "lineItems")>
				<lineItems>
					<cfloop array="#options.lineItems#" index="itn">
						<lineItem>
							<itemId>#options.lineItems[itm].itemId#</itemId>
							<name>#options.lineItems[itm].name#</name>
							<description>#options.lineItems[itm].description#</description>
							<quantity>#options.lineItems[itm].quantity#</quantity>
							<unitPrice>#options.lineItems[itm].unitPrice#</unitPrice>
						</lineItem>
					</cfloop>
					
				</lineItems>
				</cfif>

				<cfif structKeyExists(options, "tax")>
				<tax>
					<amount>#options.tax.amount#</amount>
					<name>#options.tax.name#</name>
					<description>#options.tax.description#</description>
				</tax>
				</cfif>

				<cfif structKeyExists(options, "shipping")>
				<shipping>
					<amount>#options.shipping.amount#</amount>
					<name>#options.shipping.name#</name>
					<description>#options.shipping.description#</description>
				</shipping>
				</cfif>
			
				<cfif structKeyExists(options, "poNumber")>
				<poNumber>#options.poNumber#</poNumber>
				</cfif>

				<cfif structKeyExists(options, "customer")>
				<customer>
					<id>#options.customer#</id>
				</customer>
				</cfif>
				
				<cfif !isNull(account)>
				<billTo>
					<firstName>#account.getfirstName()#</firstName>
					<lastName>#account.getlastName()#</lastName>
					<company>#account.getCompany()#</company>
					<address>#account.getaddress()#</address>
					<city>#account.getcity()#</city>
					<state>#account.getRegion()#</state>
					<zip>#account.getPostalCode()#</zip>
					<country>#account.getcountry()#</country>
				</billTo>
				</cfif>

				<cfif structKeyExists(options, "shipTo")>
				<cfset var shipTo = options.shipTo>
				<shipTo>
					<firstName>#shipTo.firstName#</firstName>
					<lastName>#shipTo.lastName#</lastName>
					<company>#shipTo.company#</company>
					<address>#shipTo.address#</address>
					<city>#shipTo.city#</city>
					<state>#shipTo.state#</state>
					<zip>#shipTo.zip#</zip>
					<country>#shipTo.country#</country>
				</shipTo>
				</cfif>

				<cfif structKeyExists(options, "customerIP")>
				<customerIP>#options.customerIP#</customerIP>
				</cfif>
				
				<!--- Uncomment this section for Card Present Sandbox Accounts --->
				<!--- <retail><marketType>2</marketType><deviceType>1</deviceType></retail> --->
				<cfif structKeyExists(options, "transactionSettings")>
				<transactionSettings>
					<setting>
						<settingName>testRequest</settingName>
						<settingValue>false</settingValue>
					</setting>
				</transactionSettings>
				</cfif>
		   

				<cfif structKeyExists(options, "userFields")>
					<userFields>
					<cfloop array="#option.userFields#" item="uf">
						<userField>
					        <name>#options.userfields[uf].name#</name>
					        <value>#options.userfields[uf].value#</value>
					    </userField>
					</cfloop>
				    </userFields>
				</cfif>
			  </transactionRequest>
			</createTransactionRequest>
			
			</cfoutput>
		</cfxml>

		<cfreturn local.xml>
	</cffunction>


	<cffunction name="createCustomerRequest" returntype="xml" hint="Creates the customer requests XML items">
		<cfargument name="requestType" hint="the type of transaction we need to carry out">
		<cfargument name="merchantAuthentication" hint="The merchant ids">
		<cfargument name="customer" required="false">
		<cfargument name="options" default="#StructNew()#">

		<cfif !isValidCustomerRequestType(requestType)>
			<cfthrow type="cfpayment.UnknownCustomerRequestType" message="Request type, #requestType# is not a valid request type">
		</cfif>


		<cfset paymentProfile = customer.getPaymentProfiles()>

		<cfxml variable="local.xml">
		<cfoutput>


			<#requestType# xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
				<merchantAuthentication>
					<name>#merchantAuthentication.name#</name>
					<transactionKey>#merchantAuthentication.transactionKey#</transactionKey>
				</merchantAuthentication>

				<cfif requestType EQ "getCustomerProfileRequest">
					<customerProfileId>#customer.getMerchantCustomerID()#</customerProfileId>
				</cfif> 
				

				<cfif requestType EQ "createCustomerProfileRequest">
					<profile>
					<cfif !isEmpty(customer.getMerchantCustomerID())>
						<merchantCustomerId>#customer.getMerchantCustomerID()#</merchantCustomerId>
					</cfif>
					<cfif !isEmpty(customer.getdescription())>
						<description>#customer.getdescription()#</description>
					</cfif>
					<cfif !isEmpty(customer.getemail())>
						<email>#customer.getemail()#</email>
					</cfif>

						<cfif !isNull(paymentProfile)>
							<paymentProfiles>
								<customerType>#paymentProfile.getCustomerType()#</customerType>
								<cfif !isNull(paymentProfile.getPaymentMethods())>
								<cfset creditcard = paymentProfile.getPaymentMethods()>
									<payment>
										<creditCard>
											<cardNumber>#creditcard.getAccount()#</cardNumber>
											<expirationDate>#DateFormat(creditcard.getExpirationDate(), "YYYY-MM")#</expirationDate>
										</creditCard>
									</payment>
								</cfif>
							</paymentProfiles>
						</cfif>
						
					</profile>
					<cfif variables.testmode>
						<validationMode>testMode</validationMode>
					</cfif>
				</cfif>

				
			</#requestType#>
		</cfoutput>
		</cfxml>


		<cfreturn local.xml>
	</cffunction>

	<cffunction name="isValidTransactionType" access="private" returntype="boolean" hint="Checks whether the transaction type is valid">
		<cfargument name="type" type="string">
		<cfreturn listFindNoCase(variables.validTransactions, arguments.type)>
	</cffunction>
	<cffunction name="isValidCustomerRequestType" access="private" returntype="boolean" hint="Checks whether the customer transaction type is valid">
		<cfargument name="type" type="string">
		<cfreturn listFindNoCase(variables.validCustomerRequestTypes, arguments.type)>
	</cffunction>

</cfcomponent>