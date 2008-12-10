<cffunction name="IsTrxSuccessful" returntype="boolean" output="no">
	<cfargument name="responseObj" required="true">
	<cfscript>
		switch(responseObj.getAck()) {
			case "Success":
				return true;
			case "SuccessWithWarning":
				return true;
			case "Failure":
				return false;
			case "FailureWithWarning":
				return false;
			default:
				return false;
		}
	</cfscript>		
</cffunction>

<cffunction name="PrintErrorMessages" returntype="void" output="yes">
	<cfargument name="responseObj" required="true">
	<cfscript>
		ppErrors = responseObj.getErrors();
	</cfscript>
	<cfloop index = "count" from = "1" to = #ArrayLen(ppErrors)#>
		<cfoutput>
			#ppErrors[count].getErrorCode()# - 
			#ppErrors[count].getLongMessage()#<br>
		</cfoutput>
	</cfloop>
	<cfabort>
</cffunction>
