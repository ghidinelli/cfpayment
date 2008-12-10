<cfinclude template="paypal-util.cfm">

<html>
<body>
<h1>Refund Transaction Receipt</h1>

<cfinvoke component="paypal" method="RefundTransaction" returnvariable="refundTransactionResponse">
	<cfinvokeargument name="trxID" value=#trxID#>
	<cfinvokeargument name="refundType" value=#refundType#>
	<cfinvokeargument name="partialAmount" value=#amount#>
</cfinvoke>

<!--- Check the Ack --->
<cfscript>
	If (Not IsTrxSuccessful(refundTransactionResponse)) {
		PrintErrorMessages(refundTransactionResponse);
	}
</cfscript>

<!--- Print the transaction result --->
<b>The transaction has been refunded!</b>
<br><a href="index.cfm">Home</a>

</body>
</html>
