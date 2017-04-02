<cfparam name="error" default="">
<cfif StructKeyExists(url,'token-id')>
	<cfset result = application.paymentService.completeTransaction(url['token-id'])/>
	<cfif IsXML(result)>
		<cfset resultApproved = XmlSearch(result.response, 'result')[1]/>
		<cfif resultApproved.xmltext eq 1>
			<cfset vaultid = XmlSearch(result.response, 'customer-vault-id')[1].xmltext>
			<cfset amount = XmlSearch(result.response, 'amount')[1].xmltext>
			<cfset transactionid = XmlSearch(result.response, 'merchant-defined-field-1')[1].xmltext>
			<cfset authcode = XmlSearch(result.response, 'authorization-code')[1].xmltext>
			<cfset cardnumber = XmlSearch(result.response.billing, 'cc-number')[1].xmltext>
			<cfset cardtype = left(cardnumber,1) eq 4 ? 'Visa' : 'Mastercard'>
			<!---payment complete clear session--->
			<cfloop collection="#session#" item="i">
				<cfset session[i] = ''>
			</cfloop>
			<cflocation addtoken="false" url="https://www.psychselect.com/cgi-bin/paylinedatanew/newpaymentportal3.cfm?status=Approved&transactionid=#transactionid#&refid=#vaultid#&authcode=#authcode#&cardtype=#cardtype#&cardnumber=#cardnumber#&avs=&cvv="> 
		<cfelse>
			<cfset error = XmlSearch(result.response, 'result-text')[1].xmltext>

			<cfif ucase(error) contains 'AVS'>
				<cfset error = 'The billing address provided does not match the credit card billing address.'/>
				<cflocation addtoken="false" url="https://www.psychselect.com/cgi-bin/paylinedatanew/newpaymentportal2.cfm?result=#urlencodedformat(error)#&reset=1"> 
			<cfelse>
				<cflocation addtoken="false" url="https://www.psychselect.com/cgi-bin/paylinedatanew/newpaymentportal2.cfm?result=#urlencodedformat(error)#"> 
			</cfif>
		</cfif>
	<cfelse>
		<cfset error = "Sorry, but your credit card transaction could not be completed. Please try again later. Reason: response was not XML">
		<cflocation addtoken="false" url="https://www.psychselect.com/cgi-bin/paylinedatanew/newpaymentportal2.cfm?result=#urlencodedformat(error)#"> 
	</cfif>
<cfelse>
	<!---got here without token--->
	<cfset error = "Sorry, but this credit card transaction cound not be completed. Please start the sign up process over. Reason: token was not located.">
	<cflocation addtoken="false" url="https://www.psychselect.com/cgi-bin/paylinedatanew/newpaymentportal.cfm?result=#urlencodedformat(error)#"> 
</cfif>
