<html>
<body>
<h1>Get Transaction Details</h1>

<cfform action="TransactionDetails.cfm" method="post">
<table>
	<tr>
		<td>Transaction ID: </td>
		<td><cfinput type="text" name="trxID" message="Enter transaction ID" required="Yes" value="7J110007888511720"></td>
		<td><font size=-1 color=red>Required</font></td>
	</tr>
</table><br>
<input type="submit" value="Get">
<input type="button" value="Cancel" onClick="javascript:history.back()">
</cfform>

</body>
</html>
