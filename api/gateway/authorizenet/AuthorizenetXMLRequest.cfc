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

	<cfset variables.validCustomerRequestTypes = "createCustomerProfileRequest,getCustomerProfileRequest,getCustomerProfileIdsRequest,updateCustomerProfileRequest,deleteCustomerProfileRequest,createCustomerPaymentProfileRequest,getCustomerPaymentProfileRequest,getCustomerPaymentProfileListRequest,validateCustomerPaymentProfileRequest,updateCustomerPaymentProfileRequest,deleteCustomerPaymentProfileRequest">


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
		<cfargument name="customer" hint="A stored customer">
		<cfargument name="paymentProfile" hint="The customer's payment profile">
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
			    

			    <cfif !isNull(customer)>
			    	<profile>
				      <customerProfileId>#customer.getCustomerProfileId()#</customerProfileId>

				      <cfif !isNull(paymentProfile)>
				      <paymentProfile>
				        <paymentProfileId>#paymentProfile.getCustomerPaymentProfileId()#</paymentProfileId>
				      </paymentProfile>
				      </cfif>
				    </profile>
				    
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
		<cfargument name="paymentProfile" required="false">
		<cfargument name="options" default="#StructNew()#">
		<cfargument name="search" default="#StructNew()#">

		<cfif !isValidCustomerRequestType(requestType)>
			<cfthrow type="cfpayment.UnknownCustomerRequestType" message="Request type, #requestType# is not a valid request type">
		</cfif>


		<cfif requestType EQ "createCustomerPaymentProfileRequest">

			

		</cfif>
		
		<cfxml variable="local.xml">
		<cfoutput>


			<#requestType# xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
				<merchantAuthentication>
					<name>#merchantAuthentication.name#</name>
					<transactionKey>#merchantAuthentication.transactionKey#</transactionKey>
				</merchantAuthentication>

				<cfif ListFindNoCase("getCustomerProfileRequest,deleteCustomerProfileRequest,createCustomerPaymentProfileRequest,getCustomerPaymentProfileRequest,validateCustomerPaymentProfileRequest,updateCustomerPaymentProfileRequest,deleteCustomerPaymentProfileRequest", requestType)>
				<!--- They require it so throw a message --->
					<cfif isEmpty(customer.getCustomerProfileId())>
						<cfthrow type="cfpayment.missingAttributeException" message="The customerProfileId is required for this transaction">
					</cfif>
					<customerProfileId>#customer.getCustomerProfileId()#</customerProfileId>
				</cfif> 

				<cfif ListFindNoCase("getCustomerPaymentProfileRequest,validateCustomerPaymentProfileRequest,deleteCustomerPaymentProfileRequest", requestType)>
					<cfif isEmpty(paymentProfile.getCustomerPaymentProfileID())>
						<cfthrow type="cfpayment.missingAttributeException" message="The customerPaymentProfileId is required for this transaction">
					</cfif>
					<customerPaymentProfileId>#paymentProfile.getCustomerPaymentProfileID()#</customerPaymentProfileId>
				</cfif>

				<cfif requestType EQ "validateCustomerPaymentProfileRequest">
					<cfset var mode = variables.testmode? "testMode" :  "liveMode">
						<validationMode>#mode#</validationMode>
				</cfif>
				
				
				<!--- This is for searches of payment profiles --->
				<cfif requestType EQ "getCustomerPaymentProfileListRequest">
					<cfif structIsEmpty(search)>
						<cfthrow type="cfpayment.missingAttributeException" message="Thhere are no properties in the search query">
					</cfif>
						<searchType>cardsExpiringInMonth</searchType>
					  	<month>#search.month#</month>
					  <sorting>
					  	<orderBy>#search.sorting.orderBy#</orderBy>
					    <orderDescending>#search.sorting.orderDescending#</orderDescending>
					  </sorting>
					  <paging>
					    <limit>#search.paging.limit#</limit>
					    <offset>#search.paging.offset#</offset>
					  </paging>
				</cfif>

				

				<cfif listFindNoCase("createCustomerPaymentProfileRequest,updateCustomerPaymentProfileRequest", requestType)>
					<cfif isEmpty(paymentProfile)>
						<cfthrow type="cfpayment.missingAttributeException" message="The paymentProfile is required for this transaction">
					</cfif>

					<cfset card = paymentProfile.getPaymentMethods()>
			
					<paymentProfile>


					
					

					<!--- If we have a billTo --->
					<cfif !isNull(paymentProfile.getBillTo())>
						<cfset billto =paymentProfile.getBillTo()>
						<billTo>
					      <firstName>#billto.getfirstName()#</firstName>
					      <lastName>#billto.getlastName()#</lastName>
					      <company>#billto.getCompany()#</company>
					      <address>#billto.getAddress()#</address>
					      <city>#billto.getCity()#</city>
					      <state>#billto.getstate()#</state>
					      <zip>#billto.getZip()#</zip>
					      <country>#billto.getCountry()#</country>
					      <phoneNumber>#billto.getphoneNumber()#</phoneNumber>
					      <faxNumber>#billto.getfaxNumber()#</faxNumber>
					    </billTo>
					<cfelseif !isNull(card)>
					
						 <billTo>
					      <firstName>#card.getfirstName()#</firstName>
					      <lastName>#card.getlastName()#</lastName>
					      <company>#card.getCompany()#</company>
					      <address>#card.getAddress()#</address>
					      <city>#card.getCity()#</city>
					      <state>#card.getRegion()#</state>
					      <zip>#card.getPostalCode()#</zip>
					      <country>#card.getCountry()#</country>
					      <phoneNumber>#card.getphoneNumber()#</phoneNumber>
					    </billTo>
					</cfif>
					    

					<cfif isObject(card) && !isNull(card)>
					    <payment>
					      <creditCard>
					        <cardNumber>#card.getAccount()#</cardNumber>
					        <expirationDate>#DateFormat(card.getExpirationDate(), "YYYY-MM")#</expirationDate>
					      </creditCard>
					    </payment>
					  <cfelseif isStruct(card)>
					  	 <payment>
					      <creditCard>
					        <cardNumber>#card.creditcard.cardNumber#</cardNumber>
					        <expirationDate>#card.creditcard.expirationDate#</expirationDate>
					      </creditCard>
					    </payment>

					  </cfif>


					  
						<cfif requestType EQ "updateCustomerPaymentProfileRequest">
								<cfif isEmpty(paymentProfile.getCustomerPaymentProfileId())>
							<cfthrow type="cfpayment.missingAttributeException" message="The customerPaymentProfileId is required for this transaction">
						</cfif>
							<customerPaymentProfileId>#paymentProfile.getCustomerPaymentProfileId()#</customerPaymentProfileId>
						</cfif>

					  </paymentProfile>

					<cfif variables.testmode>
						<validationMode>testMode</validationMode>
					</cfif>

				</cfif>


				<cfif ListFindNoCase("createCustomerProfileRequest,updateCustomerProfileRequest", requestType)>
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

					<cfif !isEmpty(customer.getCustomerProfileId())>
						<customerProfileId>#customer.getCustomerProfileId()#</customerProfileId>
					</cfif>
					 
						<cfset paymentProfiles = customer.getPaymentProfiles()>
						<cfif !isNull(paymentProfiles) && ArrayLen(paymentProfiles)>

							<cfloop array="#paymentProfiles#" item="paymentProfile">
							<paymentProfiles>
								<customerType>#paymentProfile.getCustomerType()#</customerType>

								<cfif !isNull(paymentProfile.getBillTo())>
									<cfset var billTo = paymentProfile.getBillTo()>
									 <billTo>
									      <firstName>#billTo.getfirstName()#</firstName>
									      <lastName>#billTo.getlastName()#</lastName>
									      <company>#billTo.getcompany()#</company>
									      <address>#billTo.getaddress()#</address>
									      <city>#billTo.getcity()#</city>
									      <state>#billTo.getstate()#</state>
									      <zip>#billTo.getzip()#</zip>
									      <country>#billTo.getcountry()#</country>
									      <phoneNumber>#billTo.getphoneNumber()#</phoneNumber>
									      <faxNumber>#billTo.getfaxNumber()#</faxNumber>
									    </billTo>
								</cfif>



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
							</cfloop>
						</cfif>
						
					</profile>
					<cfif variables.testmode && !isNull(paymentProfiles) && ArrayLen(paymentProfiles)>
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