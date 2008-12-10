<!---
	$Id$

	Copyright 2008 Mark Mazelin (http://www.mkville.com/)

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
<cfparam name="url.output" default="extjs">
<cfparam name="url.debug" default="false">
<cfparam name="url.quiet" default="false">
<cfparam name="url.includeGW" default="false">
<cfparam name="url.gatewayFilter" default=""><!--- specify a specific gateway folder name to only run a single gateway's tests --->

<cfset folders=ArrayNew(1)>

<!--- Add main tests folder --->
<cfset folder=StructNew()>
<cfset folder.dir=expandPath(".")>
<cfset folder.componentPath="cfpayment.tests">
<cfset ArrayAppend(folders, folder)>

<cfif url.includeGW or len(url.gatewayFilter)>
	<!--- find all gateway tests --->
	<cfset gatewayFolder="../api/gateway">
	<cfdirectory action="list" directory="#ExpandPath(gatewayFolder)#" name="gatewaydirs" recurse="true" listInfo="name" type="dir" filter="tests">
	<cfloop query="gatewayDirs">
		<cfif (len(url.gatewayFilter) EQ 0) OR (ListFirst(name, "/") eq url.gatewayFilter)>
			<cfset folder=StructNew()>
			<cfset folder.dir=ExpandPath(gatewayFolder & "/" & name)>
			<cfset folder.componentPath="cfpayment.api.gateway." & replace(name, "/", ".", "ALL")>
			<cfset ArrayAppend(folders, folder)>
		</cfif>
	</cfloop>
</cfif>

<!--- run 'em! --->
<cfset numFolders=ArrayLen(folders)>
<cfloop from="1" to="#numFolders#" index="ctr">
	<cfset folder=folders[ctr]>
	<cfset dir=folder.dir>
	<cfoutput><h1>Processing #folder.componentPath#</h1></cfoutput>

	<cftry>
		<cfset DTS = createObject("component","mxunit.runner.DirectoryTestSuite")>
	<cfcatch>
		<cfoutput><p>Could not invoke the mxunit DirectoryTestSuite runner. Is mxunit installed? Do you have access to CreateObject()?</p></cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>

	<cfinvoke component="#DTS#"
		method="run"
		directory="#dir#"
		componentpath="#folder.componentPath#"
		recurse="false"
		returnvariable="Results">

	<cfif not url.quiet>

		<cfif NOT StructIsEmpty(DTS.getCatastrophicErrors())>
			<cfdump var="#DTS.getCatastrophicErrors()#" expand="false" label="#StructCount(DTS.getCatastrophicErrors())# Catastrophic Errors">
		</cfif>

		<cfsetting showdebugoutput="true">
		<cfoutput>#results.getResultsOutput(url.output)#</cfoutput>

		<cfif isBoolean(url.debug) AND url.debug>
			<div class="bodypad">
				<cfdump var="#results.getResults()#" label="Debug">
			</div>
		</cfif>

	</cfif>

	<!---
	<cfdump var="#results.getDebug()#"> --->
	<cfif ctr LT numFolders>
		<cfoutput><hr /></cfoutput>
	</cfif>
</cfloop>