<cfcomponent displayname="PayPal" hint="PayPal Gateway">
	<cfset environment = "sandbox">
	<cfscript>
		PPInitialize();
	</cfscript>

	<cffunction name="PPInitialize" returntype="void" output="no">
		<cfset logConfig = GetDirectoryFromPath(GetTemplatePath()) & "log4j.xml">
		<cfset p12Certificate = GetDirectoryFromPath(GetTemplatePath()) & "sdk-seller.p12">

		<cfscript>
			// Configure the logger w/ a properties file
			configurator = CreateObject("java", "org.apache.log4j.xml.DOMConfigurator");
			configurator.configure(logConfig);

			// Create CF caller object
			pp_caller = CreateObject("java", "com.paypal.sdk.services.CallerServices");
	
			// Set API profile
			/*
			 WARNING: Do not embed plaintext credentials in your application code.
			 Doing so is insecure and against best practices.
			 Your API credentials must be handled securely. Please consider 
			 encrypting them for use in any production environment, and ensure
			 that only authorized individuals may view or modify them.
			 */
			pp_profile = CreateObject("java", "com.paypal.sdk.profiles.CertificateAPIProfile");
			pp_profile.setAPIUsername("sdk-seller_api1.sdk.com");
			pp_profile.setAPIPassword("12345678");
			pp_profile.setCertificateFile(p12Certificate);
			pp_profile.setPrivateKeyPassword("password");
			pp_profile.setEnvironment(environment);	
			pp_caller.setAPIProfile(pp_profile);
		</cfscript>
	</cffunction>

	<cffunction name="TransactionSearch" returntype="any" output="no">
		<cfargument name="startDate" type="date" required="true">
		<cfargument name="endDate" type="date" required="true">
		<cfscript>
			// Create the request object
			pp_request = CreateObject("java", "com.paypal.soap.api.TransactionSearchRequestType");
	
			calendar =  CreateObject("java", "java.util.Calendar");

			calendarObj1 = calendar.getInstance();
			calendarObj1.setTime(startDate);
			pp_request.setStartDate(calendarObj1);
			
			calendarObj2 = calendar.getInstance();
			calendarObj2.setTime(endDate);
			pp_request.setEndDate(calendarObj2);
		</cfscript>
		<cfreturn #pp_caller.call("TransactionSearch", pp_request)#>
	</cffunction>

	<cffunction name="GetTransactionDetails" returntype="any" output="no">
		<cfargument name="trxID" type="string" required="true">
		<cfscript>
			// Create the request object
			pp_request = CreateObject("java", "com.paypal.soap.api.GetTransactionDetailsRequestType");
			pp_request.setTransactionID(trxID);
		</cfscript>
		<cfreturn #pp_caller.call("GetTransactionDetails", pp_request)#>
	</cffunction>

	<cffunction name="RefundTransaction" returntype="any" output="no">
		<cfargument name="trxID" type="string" required="true">
		<cfargument name="refundType" type="string" required="true">
		<cfargument name="partialAmount" type="string" required="false">
		<cfscript>
			// Utils class
			refundTypes = CreateObject("java", "com.paypal.soap.api.RefundPurposeTypeCodeType");
			currencies = CreateObject("java", "com.paypal.soap.api.CurrencyCodeType");

			// Create the request object
			pp_request = CreateObject("java", "com.paypal.soap.api.RefundTransactionRequestType");

			pp_request.setTransactionID(trxID);
			switch(refundType)
			{
				case "Full":
				{
					pp_request.setRefundType(refundTypes.Full);
					break;
				}
				case "Partial":
				{
					pp_request.setRefundType(refundTypes.Partial);
					
					amount = CreateObject("java", "com.paypal.soap.api.BasicAmountType");
					amount.setCurrencyID(currencies.USD);
					amount.set_value(partialAmount);

						pp_request.setAmount(amount);
					break;
				}
			} //end switch
		</cfscript>
		<cfreturn #pp_caller.call("RefundTransaction", pp_request)#>
	</cffunction>

	<cffunction name="DoDirectPayment" returntype="any" output="no">
		<cfargument name="buyerLastName" type="string" required="true">
		<cfargument name="buyerFirstName" type="string" required="true">
		<cfargument name="buyerAddress1" type="string" required="true">
		<cfargument name="buyerAddress2" type="string">
		<cfargument name="buyerCity" type="string" required="true">
		<cfargument name="buyerZipCode" type="string" required="true">
		<cfargument name="buyerState" type="string" required="true">
		<cfargument name="creditCardType" type="string" required="true">
		<cfargument name="creditCardNumber" type="string" required="true">
		<cfargument name="CVV2" type="string" required="true">
		<cfargument name="expMonth" type="string" required="true">
		<cfargument name="expYear" type="string" required="true">
		<cfargument name="paymentAmount" type="string" required="true">
		<cfscript>
			// Utils class
			creditCardTypes = CreateObject("java", "com.paypal.soap.api.CreditCardTypeType");
			countryCodes = CreateObject("java", "com.paypal.soap.api.CountryCodeType");
			paymentTypes = CreateObject("java", "com.paypal.soap.api.PaymentActionCodeType");
			currencies = CreateObject("java", "com.paypal.soap.api.CurrencyCodeType");
			userStatusCodes = CreateObject("java", "com.paypal.soap.api.PayPalUserStatusCodeType");

			// Create the request object
			pp_request = CreateObject("java", "com.paypal.soap.api.DoDirectPaymentRequestType");

			// Create the request details object
			details= CreateObject("java", "com.paypal.soap.api.DoDirectPaymentRequestDetailsType");

			details.setIPAddress("10.244.43.106");
			details.setMerchantSessionId("1X911810264059026");
			details.setPaymentAction(paymentTypes.Sale);
			
			// Credit card
			creditCard = CreateObject("java", "com.paypal.soap.api.CreditCardDetailsType");
			
			creditCard.setCreditCardNumber(creditCardNumber);	
			switch(creditCardType)
			{
				case "Visa":
				{
					creditCard.setCreditCardType(creditCardTypes.Visa);
					break;
				}
				case "MasterCard":
				{
					creditCard.setCreditCardType(creditCardTypes.MasterCard);
					break;
				}
				case "Discover":
				{
					creditCard.setCreditCardType(creditCardTypes.Discover);
					break;
				}
				case "Amex":
				{
					creditCard.setCreditCardType(creditCardTypes.Amex);
					break;
				}
			} //end switch
			creditCard.setCVV2(CVV2);
			creditCard.setExpMonth(expMonth);
			creditCard.setExpYear(expYear);
			
			// Payer info
			cardOwner = CreateObject("java", "com.paypal.soap.api.PayerInfoType");
		
			cardOwner.setPayerCountry(countryCodes.US);
			
			// Address
			address = CreateObject("java", "com.paypal.soap.api.AddressType");
			address.setStreet1(buyerAddress1);
			address.setStreet2(buyerAddress2);
			address.setCityName(buyerCity);			
			address.setStateOrProvince(buyerState);			
			address.setPostalCode(buyerZipCode);
			address.setCountryName("USA");
			address.setCountry(countryCodes.US);
			
			cardOwner.setAddress(address);
			
			// Name	
			payerName = CreateObject("java", "com.paypal.soap.api.PersonNameType");
			payerName.setFirstName(buyerFirstName);
			payerName.setLastName(buyerLastName);
			
			cardOwner.setPayerName(payerName);

			creditCard.setCardOwner(cardOwner);
			
			details.setCreditCard(creditCard);
			
			// Payment
			payment = CreateObject("java", "com.paypal.soap.api.PaymentDetailsType");

			// Order total			
			orderTotal = CreateObject("java", "com.paypal.soap.api.BasicAmountType");
			orderTotal.setCurrencyID(currencies.USD);
			orderTotal.set_value(paymentAmount);

			payment.setOrderTotal(orderTotal);
			
			details.setPaymentDetails(payment);

			pp_request.setDoDirectPaymentRequestDetails(details);
		</cfscript>
		<cfreturn #pp_caller.call("DODirectPayment", pp_request)#>
	</cffunction>
</cfcomponent>