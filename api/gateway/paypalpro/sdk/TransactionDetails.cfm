<cfinclude template="paypal-util.cfm">

<html>
<body>
<h1>Transaction Details</h1>

<cfinvoke component="paypal" method="GetTransactionDetails" returnvariable="getTransactionDetailsResponse">
	<cfinvokeargument name="trxID" value=#trxID#/>
</cfinvoke>


<!--- Make sure results is defined --->
<cfscript>
	If (Not IsTrxSuccessful(getTransactionDetailsResponse)) {
		PrintErrorMessages(getTransactionDetailsResponse);
	}
</cfscript>

<!--- Print the transaction details --->
Payer Info:<br>
<table border="1">
	<cfoutput>
		<tr>
			<td>Payer: </td>
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPayerInfo().getPayer()#</td>
		</tr>
		<tr>
			<td>Payer ID: </td>
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPayerInfo().getPayerID()#</td>
		</tr>
		<tr>
			<td>First Name: </td>
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPayerInfo().getPayerName().getFirstName()#</td>
		</tr>
		<tr>
			<td>Last Name: </td>
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPayerInfo().getPayerName().getLastName()#</td>
		</tr>
	</cfoutput>
</table>

Payment Info:<br>
<table border="1">
	<cfoutput>
		<tr>
			<td>Transaction ID: </td> 
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getTransactionID()#</td>
		</tr>
		<tr>
			<td>Parent Transaction ID (if any): </td> 
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getParentTransactionID()#</td>
		</tr>
		<tr>
			<td>Gross Amount: </td>
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getGrossAmount().getCurrencyID()# 
			#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getGrossAmount().get_value()#</td>
		</tr>
		<tr>
			<td>Payment Status: </td> 
			<td>#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getPaymentStatus()#</td>
		</tr>
	</cfoutput>
</table><br>

<cfoutput>
	<a href="RefundTransaction.cfm?trxID=#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getTransactionID()#
	&amount=#getTransactionDetailsResponse.getPaymentTransactionDetails().getPaymentInfo().getGrossAmount().get_value()#">Refund</a>
</cfoutput>
<a href="javascript:history.back()">Back</a>

</body>
</html>
