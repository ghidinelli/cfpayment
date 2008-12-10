<html>
<body>
<h1>Refund Transaction</h1>

<cfform action="RefundReceipt.cfm" method="post">
<table>
	<tr>
		<td>Transaction ID: </td>
		<cfif IsDefined("trxID")>
			<td><cfinput type="text" name="trxID" message="Enter a transaction ID" required="Yes" value=#trxID#></td>
		<cfelse>
			<td><cfinput type="text" name="trxID" message="Enter a transaction ID" required="Yes"></td>
		</cfif>
		<td><font size=-1 color=red>Required</font></td>
	</tr>
	<tr>
		<td>Refund Type: </td>
		<td>
			<select name="refundType">
				<option>Full</option>
				<option>Partial</option>
			</select>
		</td>
		<td><font size=-1 color=red>Required</font></td>
	</tr>
	<tr>
		<td>Amount: </td>
		<cfif IsDefined("amount")>
			<td><cfinput type="text" name="amount" required="No" value=#amount#></td>
		<cfelse>
			<td><cfinput type="text" name="amount" required="No"></td>
		</cfif>
		
		<td>USD</td>
	</tr>
</table><br>
<input type="submit" value="Refund">
<input type="button" value="Cancel" onClick="javascript:history.back()">
</cfform>

</body>
</html>
