<cfsetting enablecfoutputonly="true">
<!---
Copyright 2008 Brian Ghidelli and Mark Mazelin.

Licensed under the Apache License, Version 2.0 (the "License"); 
you may not use this file except in compliance with the License. 
You may obtain a copy of the License at 

http://www.apache.org/licenses/LICENSE-2.0 

Unless required by applicable law or agreed to in writing, software 
distributed under the License is distributed on an "AS IS" BASIS, 
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
See the License for the specific language governing permissions and 
limitations under the License. 

$Id$
--->
<!--- check for defaults --->
<cfif structKeyExists(request, "formdefaults")>
	<cfloop collection="#request.formdefaults#" item="currKey">
		<!--- don't override ones that are passed --->
		<cfif not StructKeyExists(attributes, currKey)>
			<cfset attributes[currKey]=request.formdefaults[currkey]>
		</cfif>
	</cfloop>
</cfif>
<!--- initialize parameters --->
<cfparam name="attributes.Title" type="string">
<cfparam name="attributes.Name" type="string" default="">
<cfparam name="attributes.FieldName" type="string" default=""><!--- used instead of name when called as a module --->
<cfif len(attributes.fieldname)>
	<cfset attributes.name=attributes.FieldName>
</cfif>
<cfif len(attributes.name) eq 0>
	<cfthrow message="The 'name' attribute is required.">
</cfif>
<cfparam name="attributes.Value" type="string" default="">
<cfparam name="attributes.Type" type="string" default="text"><!--- text, password --->
<cfparam name="attributes.Size" type="numeric" default="1">
<cfparam name="attributes.Required" type="boolean" default="false">
<cfparam name="attributes.DivClass" type="string" default="">
<cfparam name="attributes.LabelClass" type="string" default="">
<!--- additional items for select boxes --->
<cfparam name="attributes.ListType" type="string" default="custom"><!--- optional --->
<cfparam name="attributes.ValuesList" type="string" default=""><!--- optional --->
<cfparam name="attributes.DisplayList" type="string" default=""><!--- required if listtype=custom --->
<cfparam name="attributes.TitleFieldSeparator" type="string" default="">
<cfparam name="attributes.IncludeSelectLine" type="string" default="true"><!--- optional --->
<cfparam name="attributes.SelectLineText" type="string" default="Please Select..."><!--- optional --->
<cfparam name="attributes.Delimiter" type="string" default=","><!--- optional --->
<cfparam name="attributes.Multiple" type="string" default=""><!--- optional --->

<cfif attributes.ListType eq "state">
	<cfset attributes.ValuesList="AL,AK,AZ,AR,CA,CO,CT,DE,DC,FL,GA,HI,ID,IL,IN,IA,KS,KY,LA,ME,MD,MA,MI,MN,MS,MO,MT,NE,NV,NH,NJ,NM,NY,NC,ND,OH,OK,OR,PA,RI,SC,SD,TN,TX,UT,VT,VA,WA,WV,WI,WY">
	<cfset attributes.DisplayList="Alabama,Alaska,Arizona,Arkansas,California,Colorado,Connecticut,Delaware,District of Columbia,Florida,Georgia,Hawaii,Idaho,Illinois,Indiana,Iowa,Kansas,Kentucky,Louisiana,Maine,Maryland,Massachusetts,Michigan,Minnesota,Mississippi,Missouri,Montana,Nebraska,Nevada,New Hampshire,New Jersey,New Mexico,New York,North Carolina,North Dakota,Ohio,Oklahoma,Oregon,Pennsylvania,Rhode Island,South Carolina,South Dakota,Tennessee,Texas,Utah,Vermont,Virginia,Washington,West Virginia,Wisconsin,Wyoming">
</cfif>
<!--- If the DisplayList is given, but not the ValuesList, assume they are the same --->
<cfif (Trim(Attributes.DisplayList) NEQ "") and (Trim(Attributes.ValuesList EQ ""))>
	<cfset Attributes.ValuesList=Attributes.DisplayList>
</cfif>

<cfset ValueArray = ListToArray(Attributes.ValuesList,Attributes.Delimiter)>
<cfset DisplayArray = ListToArray(Attributes.DisplayList,Attributes.Delimiter)>
<cfset ValueLen = ArrayLen(ValueArray)>
<cfset DisplayLen = ArrayLen(DisplayArray)>
<cfif ValueLen NEQ DisplayLen>
	<cfoutput>Value lists are not the same length.
	 (valueLen=#ValueLen#, displayLen=#DisplayLen#, delimiter=ASC:#ASC(Attributes.Delimiter)#) --->
	 </cfoutput>
	<cfsetting enablecfoutputonly="No">
	<cfabort>
</cfif>

<cfoutput><div<cfif len(attributes.divClass)> class="#attributes.divClass#"</cfif>></cfoutput>
<cfoutput><label for="BillingFirstName"<cfif len(attributes.labelClass)> class="#attributes.labelClass#"</cfif>></cfoutput>
<cfoutput>#attributes.Title#</cfoutput>
<cfif attributes.required><cfoutput><span class="required">*</span></cfoutput></cfif>
<cfoutput>#attributes.TitleFieldSeparator#</cfoutput>
<cfoutput></label></cfoutput>
<cfoutput><select name="#attributes.name#" id="#attributes.name#"<cfif attributes.Size NEQ ""> size="#attributes.Size#"</cfif><cfif Attributes.Multiple NEQ ""> multiple="multiple"</cfif>>
</cfoutput>
	<cfif attributes.IncludeSelectLine>
	<cfoutput><option value="">#Attributes.SelectLineText#</option>
</cfoutput>
	</cfif>
	<cfset startedOptGroup=false>
	<cfloop index="IndexValue" from="1" to="#ValueLen#">
		<cfset CurrValue=Trim(ValueArray[IndexValue])>
		<!--- Acommodates multiple select boxes --->
		<cfif ListFindNoCase(Attributes.value, CurrValue, Attributes.Delimiter)>
			<cfset selectedAttrValue="selected">
		<cfelse>
			<cfset selectedAttrValue="">
		</cfif>
		<!--- see if this is an optgroup value --->
		<cfif currValue.startsWith("**") and currValue.endsWith("**")>
			<!--- remove the special characters --->
			<cfset currValue = Replace(currValue, "**", "", "ALL")>
			<cfif startedOptGroup>
				<!--- close the opt group tag if we started one --->
				<cfoutput></optgroup>
</cfoutput>
			</cfif>
			<cfset startedOptGroup=true>
			<cfoutput><optgroup label="#CurrValue#">
</cfoutput>
		<cfelse>
			<cfoutput><option value="#CurrValue#"<cfif Len(selectedAttrValue)> selected="#selectedAttrValue#"</cfif>>#DisplayArray[IndexValue]#</option>
</cfoutput>
		</cfif>
	</cfloop>
	<!--- close the opt group tag if we started one --->
	<cfif startedOptGroup>
		<cfoutput></optgroup>
</cfoutput>
	</cfif>
<cfoutput></select>
</cfoutput>
<cfoutput></div></cfoutput>

<cfsetting enablecfoutputonly="false">