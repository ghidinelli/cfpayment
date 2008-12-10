<!---
	$Id$

	Copyright 2008 	Ben Nadel / Kinky Solutions (http://)www.bennadel.com)
					Mark Mazelin (http://www.mkville.com/)

	Licensed under the Apache License, Version 2.0 (the "License"); you
	may not use this file except in compliance with the License. You may
	obtain a copy of the License at:

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--->
<cfcomponent output="false">
<--- --------------------------------------------------------------------------------------- ----

	Blog Entry:
	Parsing CSV Values In To A ColdFusion Query

	Code Snippet:
	1

	Author:
	Ben Nadel / Kinky Solutions

	Link:
	http://www.bennadel.com/index.cfm?dax=blog:501.view

	Date Posted:
	Jan 30, 2007 at 3:42 PM

	Modified 18-NOV-2008-MBM: to include CSVToArray() function to perform conversion to array

---- --------------------------------------------------------------------------------------- --->


<cffunction
	name="CSVToQuery"
	access="public"
	returntype="query"
	output="false"
	hint="Converts the given CSV string to a query.">

	<!--- Define arguments. --->
	<cfargument
		name="CSV"
		type="string"
		required="true"
		hint="This is the CSV string that will be manipulated."
		/>

	<cfargument
		name="Delimiter"
		type="string"
		required="false"
		default=","
		hint="This is the delimiter that will separate the fields within the CSV value."
		/>

	<cfargument
		name="Qualifier"
		type="string"
		required="false"
		default=""""
		hint="This is the qualifier that will wrap around fields that have special characters embeded."
		/>

	<cfargument
		name="Trim"
		type="boolean"
		required="false"
		default="false"
		hint=""
		/>

	<!--- 12-JUL-2007-MBM: ADDED 1 ARGUMENT --->
	<cfargument
		name="FirstRowColumnNames"
		type="boolean"
		required="false"
		default="false"
		hint=""
		/>

	<!--- 12-JUL-2007-MBM: ADDED 1 ARGUMENT --->
	<cfargument
		name="TrimData"
		type="boolean"
		required="false"
		default="false"
		hint=""
		/>

	<!--- Define the local scope. --->
	<cfset var LOCAL = StructNew() />

	<cfset LOCAL.Rows=CSVToArray(argumentCollection=arguments)>

	<!---
		ASSERT: At this point, we have parsed the CSV into an
		array of arrays (LOCAL.Rows). Now, we can take that
		array of arrays and convert it into a query.
	--->


	<!---
		To create a query that fits this array of arrays, we
		need to figure out the max length for each row as
		well as the number of records.

		The number of records is easy - it's the length of the
		array. The max field count per row is not that easy. We
		will have to iterate over each row to find the max.

		However, this works to our advantage as we can use that
		array iteration as an opportunity to build up a single
		array of empty string that we will use to pre-populate
		the query.
	--->

	<!--- Set the initial max field count. --->
	<cfset LOCAL.MaxFieldCount = 0 />

	<!---
		Set up the array of empty values. As we iterate over
		the rows, we are going to add an empty value to this
		for each record (not field) that we find.
	--->
	<cfset LOCAL.EmptyArray = ArrayNew( 1 ) />

	<!--- Loop over the records array. --->
	<cfloop
		index="LOCAL.RowIndex"
		from="1"
		to="#ArrayLen( LOCAL.Rows )#"
		step="1">

		<!--- Get the max rows encountered so far. --->
		<cfset LOCAL.MaxFieldCount = Max(
			LOCAL.MaxFieldCount,
			ArrayLen(
				LOCAL.Rows[ LOCAL.RowIndex ]
				)
			) />

		<!--- Add an empty value to the empty array. --->
		<cfset ArrayAppend(
			LOCAL.EmptyArray,
			""
			) />

	</cfloop>


	<!---
		ASSERT: At this point, LOCAL.MaxFieldCount should hold
		the number of fields in the widest row. Additionally,
		the LOCAL.EmptyArray should have the same number of
		indexes as the row array - each index containing an
		empty string.
	--->


	<!---
		Now, let's pre-populate the query with empty strings. We
		are going to create the query as all VARCHAR data
		fields, starting off with blank. Then we will override
		these values shortly.
	--->
	<cfset LOCAL.Query = QueryNew( "" ) />

	<!---
		Loop over the max number of fields and create a column
		for each records.
	--->

	<!--- 12-JUL-2007-MBM: ADDED 2 LINES --->
	<cfset LOCAL.ColumnArray=ArrayNew(1)>
	<cfset LOCAL.CurrColumnName="">

<!--- <cfdump var="#local.rows#"><cfabort> --->

	<cfloop
		index="LOCAL.FieldIndex"
		from="1"
		to="#LOCAL.MaxFieldCount#"
		step="1">

		<!---
			Add a new query column. By using QueryAddColumn()
			rather than QueryAddRow() we are able to leverage
			ColdFusion's ability to add row values in bulk
			based on an array of values. Since we are going to
			pre-populate the query with empty values, we can
			just send in the EmptyArray we built previously.
		--->
		<!--- 12-JUL-2007-MBM: ADDED 10 LINES --->
		<cfif arguments.FirstRowColumnNames>
			<!--- get column name --->
			<cfset LOCAL.CurrColumnName=trim(LOCAL.Rows[1][LOCAL.FieldIndex])>
			<!--- replace spaces --->
			<cfset LOCAL.CurrColumnName=Replace(LOCAL.CurrColumnName, " ", "_", "ALL")>
			<!--- replace pound signs --->
			<cfset LOCAL.CurrColumnName=Replace(LOCAL.CurrColumnName, "##", "NUM", "ALL")>
		<cfelse>
			<cfset LOCAL.CurrColumnName="COLUMN_#LOCAL.FieldIndex#">
		</cfif>

		<cfset ArrayAppend(LOCAL.ColumnArray, LOCAL.CurrColumnName)>


		<!--- 12-JUL-2007-MBM: MODIFIED 1 LINE --->
		<cfset QueryAddColumn(
			LOCAL.Query,
			LOCAL.CurrColumnName,
			"CF_SQL_VARCHAR",
			LOCAL.EmptyArray
			) />

	</cfloop>


	<!---
		ASSERT: At this point, our return query LOCAL.Query
		contains enough columns and rows to handle all the
		data that we have stored in our array of arrays.
	--->


	<!---
		Loop over the array to populate the query with
		actual data. We are going to have to loop over
		each row and then each field.
	--->
	<cfloop
		index="LOCAL.RowIndex"
		from="1"
		to="#ArrayLen( LOCAL.Rows )#"
		step="1">

		<!--- Loop over the fields in this record. --->
		<cfloop
			index="LOCAL.FieldIndex"
			from="1"
			to="#ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] )#"
			step="1">

			<!---
				Update the query cell. Remember to cast string
				to make sure that the underlying Java data
				works properly.
			--->
			<!--- 12-JUL-2007-MBM: MODIFIED 1 LINE --->
			<cfif arguments.trimData>
				<cfset LOCAL.Query[ LOCAL.ColumnArray[LOCAL.FieldIndex] ][ LOCAL.RowIndex ] = JavaCast(
					"string",
					trim(LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ])
					) />
			<cfelse>
				<cfset LOCAL.Query[ LOCAL.ColumnArray[LOCAL.FieldIndex] ][ LOCAL.RowIndex ] = JavaCast(
					"string",
					LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ]
					) />
			</cfif>

		</cfloop>

	</cfloop>

	<!--- 12-JUL-2007-MBM: ADDED 5 LINES --->
	<!---  remove the first row if it contains our column names --->
	<cfif arguments.FirstRowColumnNames>
		<!--- NOTE: This is undocumented ColdFusion and may break in future versions --->
		<cfset LOCAL.Query.RemoveRows(0,1)>
	</cfif>

	<!---
		Our query has been successfully populated.
		Now, return it.
	--->
	<cfreturn LOCAL.Query />

</cffunction>

<--- --------------------------------------------------------------------------------------- ----

	Blog Entry:
	CSVToArray() ColdFusion UDF For Parsing CSV Data / Files

	Author:
	Ben Nadel / Kinky Solutions

	Link:
	http://www.bennadel.com/index.cfm?dax=blog:991.view

	Date Posted:
	Oct 12, 2007 at 8:59 AM

---- --------------------------------------------------------------------------------------- --->


<cffunction
	name="CSVToArray"
	access="public"
	returntype="array"
	output="false"
	hint="Takes a CSV file or CSV data value and converts it to an array of arrays based on the given field delimiter. Line delimiter is assumed to be new line / carriage return related.">

	<!--- Define arguments. --->
	<cfargument
		name="File"
		type="string"
		required="false"
		default=""
		hint="The optional file containing the CSV data."
		/>

	<cfargument
		name="CSV"
		type="string"
		required="false"
		default=""
		hint="The CSV text data (if the file was not used)."
		/>

	<cfargument
		name="Delimiter"
		type="string"
		required="false"
		default=","
		hint="The data field delimiter."
		/>

	<cfargument
		name="Trim"
		type="boolean"
		required="false"
		default="true"
		hint="Flags whether or not to trim the END of the file for line breaks and carriage returns."
		/>


	<!--- Define the local scope. --->
	<cfset var LOCAL = StructNew() />


	<!---
		Check to see if we are using a CSV File. If so,
		then all we want to do is move the file data into
		the CSV variable. That way, the rest of the algorithm
		can be uniform.
	--->
	<cfif Len( ARGUMENTS.File )>

		<!--- Read the file into Data. --->
		<cffile
			action="read"
			file="#ARGUMENTS.File#"
			variable="ARGUMENTS.CSV"
			/>

	</cfif>


	<!---
		ASSERT: At this point, no matter how the data was
		passed in, we now have it in the CSV variable.
	--->


	<!---
		Check to see if we need to trim the data. Be default,
		we are going to pull off any new line and carraige
		returns that are at the end of the file (we do NOT want
		to strip spaces or tabs).
	--->
	<cfif ARGUMENTS.Trim>

		<!--- Remove trailing returns. --->
		<cfset ARGUMENTS.CSV = REReplace(
			ARGUMENTS.CSV,
			"[\r\n]+$",
			"",
			"ALL"
			) />

	</cfif>


	<!--- Make sure the delimiter is just one character. --->
	<cfif (Len( ARGUMENTS.Delimiter ) NEQ 1)>

		<!--- Set the default delimiter value. --->
		<cfset ARGUMENTS.Delimiter = "," />

	</cfif>


	<!---
		Create a compiled Java regular expression pattern object
		for the experssion that will be needed to parse the
		CSV tokens including the field values as well as any
		delimiters along the way.
	--->
	<cfset LOCAL.Pattern = CreateObject(
		"java",
		"java.util.regex.Pattern"
		).Compile(
			JavaCast(
				"string",

				<!--- Delimiter. --->
				"\G(\#ARGUMENTS.Delimiter#|\r?\n|\r|^)" &

				<!--- Quoted field value. --->
				"(?:""([^""]*+(?>""""[^""]*+)*)""|" &

				<!--- Standard field value --->
				"([^""\#ARGUMENTS.Delimiter#\r\n]*+))"
				)
			)
		/>

	<!---
		Get the pattern matcher for our target text (the
		CSV data). This will allows us to iterate over all the
		tokens in the CSV data for individual evaluation.
	--->
	<cfset LOCAL.Matcher = LOCAL.Pattern.Matcher(
		JavaCast( "string", ARGUMENTS.CSV )
		) />


	<!---
		Create an array to hold the CSV data. We are going
		to create an array of arrays in which each nested
		array represents a row in the CSV data file.
	--->
	<cfset LOCAL.Data = ArrayNew( 1 ) />

	<!--- Start off with a new array for the new data. --->
	<cfset ArrayAppend( LOCAL.Data, ArrayNew( 1 ) ) />


	<!---
		Here's where the magic is taking place; we are going
		to use the Java pattern matcher to iterate over each
		of the CSV data fields using the regular expression
		we defined above.

		Each match will have at least the field value and
		possibly an optional trailing delimiter.
	--->
	<cfloop condition="LOCAL.Matcher.Find()">

		<!---
			Get the delimiter. We know that the delimiter will
			always be matched, but in the case that it matched
			the START expression, it will not have a length.
		--->
		<cfset LOCAL.Delimiter = LOCAL.Matcher.Group(
			JavaCast( "int", 1 )
			) />


		<!---
			Check for delimiter length and is not the field
			delimiter. This is the only time we ever need to
			perform an action (adding a new line array). We
			need to check the length because it might be the
			START STRING match which is empty.
		--->
		<cfif (
			Len( LOCAL.Delimiter ) AND
			(LOCAL.Delimiter NEQ ARGUMENTS.Delimiter)
			)>

			<!--- Start new row data array. --->
			<cfset ArrayAppend(
				LOCAL.Data,
				ArrayNew( 1 )
				) />

		</cfif>


		<!---
			Get the field token value in group 2 (which may
			not exist if the field value was not qualified.
		--->
		<cfset LOCAL.Value = LOCAL.Matcher.Group(
			JavaCast( "int", 2 )
			) />

		<!---
			Check to see if the value exists. If it doesn't
			exist, then we want the non-qualified field. If
			it does exist, then we want to replace any escaped
			embedded quotes.
		--->
		<cfif StructKeyExists( LOCAL, "Value" )>

			<!---
				Replace escpaed quotes with an unescaped double
				quote. No need to perform regex for this.
			--->
			<cfset LOCAL.Value = Replace(
				LOCAL.Value,
				"""""",
				"""",
				"all"
				) />

		<cfelse>

			<!---
				No qualified field value was found, so use group
				3 - the non-qualified alternative.
			--->
			<cfset LOCAL.Value = LOCAL.Matcher.Group(
				JavaCast( "int", 3 )
				) />

		</cfif>


		<!--- Add the field value to the row array. --->
		<cfset ArrayAppend(
			LOCAL.Data[ ArrayLen( LOCAL.Data ) ],
			LOCAL.Value
			) />

	</cfloop>


	<!---
		At this point, our array should contain the parsed
		contents of the CSV value. Return the array.
	--->
	<cfreturn LOCAL.Data />
</cffunction>
</cfcomponent>