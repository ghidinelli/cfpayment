<cfinclude template="paypal-util.cfm">

<html>
<body>
<h1>Direct Payment Receipt</h1>

<cfinvoke component="paypal" method="DoDirectPayment" returnvariable="doDirectPaymentResponse">
	<cfinvokeargument name="buyerLastName" value=#buyerLastName#>
	<cfinvokeargument name="buyerFirstName" value=#buyerFirstName#>
	<cfinvokeargument name="buyerAddress1" value=#buyerAddress1#>
	<cfinvokeargument name="buyerAddress2" value=#buyerAddress2#>
	<cfinvokeargument name="buyerCity" value=#buyerCity#>
	<cfinvokeargument name="buyerZipCode" value=#buyerZipCode#>
	<cfinvokeargument name="buyerState" value=#buyerState#>
	<cfinvokeargument name="creditCardType" value=#creditCardType#>
	<cfinvokeargument name="creditCardNumber" value=#creditCardNumber#>
	<cfinvokeargument name="CVV2" value=#CVV2#>
	<cfinvokeargument name="expMonth" value=#expMonth#>
	<cfinvokeargument name="expYear" value=#expYear#>
	<cfinvokeargument name="paymentAmount" value=#paymentAmount#>
</cfinvoke>


<!--- Check the Ack --->
<cfscript>
	If (Not IsTrxSuccessful(doDirectPaymentResponse)) {
		PrintErrorMessages(doDirectPaymentResponse);
	}
</cfscript>

<!--- Print the transaction results --->
<b>Thank you for your purchase!</b><br><br>
Transaction Details:<br>
<table border="1">
	<cfoutput>
		<tr>
			<td>Transaction ID: </td> 
			<td>#doDirectPaymentResponse.getTransactionID()#</td>
		</tr>
		<tr>
			<td>AVS Code: </td>
			<td>#doDirectPaymentResponse.getAVSCode()#</td>
		</tr>
		<tr>
			<td>CVV2 Code: </td>
			<td>#doDirectPaymentResponse.getCVV2Code()#</td>
		</tr>
		<tr>
			<td>Amount: </td>
			<td>#doDirectPaymentResponse.getAmount().getCurrencyID()# #doDirectPaymentResponse.getAmount().get_value()#</td>
		</tr>
	</cfoutput>
</table>
<a href="index.cfm">Home</a>

</body>
</html>
