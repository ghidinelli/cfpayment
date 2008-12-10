<html>
<body>
<h1>Transaction Search Results</h1>

<cfinvoke component="paypal" method="TransactionSearch" returnvariable="transactionSearchResponse">
	<cfinvokeargument name="startDate" value=#ParseDateTime(startDateStr)#/>
	<cfinvokeargument name="endDate" value=#DateAdd("d", 1, ParseDateTime(endDateStr))#/>  
</cfinvoke>

<cfscript>
	// Get response objects
	results = transactionSearchResponse.getPaymentTransactions();
</cfscript>

<!--- Make sure results is defined --->
<cfif Not IsDefined("results")>
	<h1>Your search did not match any transactions!</h1>
	<cfabort>
</cfif>
	
<!--- Print the transaction results --->
<cfoutput>Results 1 - #ArrayLen(results)#</cfoutput><br>
<table border="1">
	<tr>
		<th></th>
		<th>ID</th>
		<th>Time</th>
		<th>Status</th>
		<th>Payer Name</th>
		<th>Gross Amount</th>
	</tr>
	<cfloop index = "count" from = "1" to = #ArrayLen(results)#>
		<cfoutput>
			<tr>
				<td>#count#</td>
				<td><a href="TransactionDetails.cfm?trxID=#results[count].getTransactionID()#">#results[count].getTransactionID()#</a></td>
				<td>#DateFormat(results[count].getTimestamp(), "mm/dd/yyyy")#</td>
				<td>#results[count].getStatus()#</td>
				<td>#results[count].getPayerDisplayName()#</td>
				<td>#results[count].getGrossAmount().getCurrencyID()# #results[count].getGrossAmount().get_value()#</td>
			</tr>
 		</cfoutput>
	</cfloop>
</table>
<a href="index.cfm">Home</a>

</body>
</html>
