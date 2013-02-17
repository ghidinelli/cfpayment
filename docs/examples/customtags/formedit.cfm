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
<cfparam name="attributes.Size" type="numeric" default="20">
<cfparam name="attributes.Required" type="boolean" default="false">
<cfparam name="attributes.DivClass" type="string" default="">
<cfparam name="attributes.LabelClass" type="string" default="">
<cfparam name="attributes.TitleFieldSeparator" type="string" default="">

<cfoutput><div<cfif len(attributes.divClass)> class="#attributes.divClass#"</cfif>></cfoutput>
<cfoutput><label for="BillingFirstName"<cfif len(attributes.labelClass)> class="#attributes.labelClass#"</cfif>></cfoutput>
<cfoutput>#attributes.Title#</cfoutput>
<cfif attributes.required><cfoutput><span class="required">*</span></cfoutput></cfif>
<cfoutput>#attributes.TitleFieldSeparator#</cfoutput>
<cfoutput></label></cfoutput>
<cfoutput><input type="#attributes.Type#" name="#attributes.name#" id="#attributes.name#" size="#attributes.size#" value="#attributes.value#" /></cfoutput>
<cfoutput></div></cfoutput>

<cfsetting enablecfoutputonly="false">