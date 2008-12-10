<html>
<body>
<h1>Transaction Search</h1>

<cfform action="TransactionSearchResults.cfm" method="post">
<table>
	<tr>
		<td>Start Date (mm/dd/yyyy): </td>
		<td><cfinput type="text" name="startDateStr" message="Enter search start date, formatted mm/dd/yyyy (e.g. 12/31/2005)" 
			validate="date" required="Yes" value="#DateFormat(DateAdd("m", -1, Now()), "mm/dd/yyyy")#"></td>
		<td><font size=-1 color=red>Required</font></td>
	</tr>
	<tr>
		<td>End Date (mm/dd/yyyy): </td>
		<td><cfinput type="text" name="endDateStr" message="Enter search end date, formatted mm/dd/yyyy (e.g. 12/31/2005)" 
			validate="date" required="Yes" value=#DateFormat(Now(), "mm/dd/yyyy")#></td>
		<td><font size=-1 color=red>Required</font></td>
	</tr>
</table><br>
<input type="submit" value="Search">
<input type="button" value="Cancel" onClick="javascript:history.back()">
</cfform>

</body>
</html>
