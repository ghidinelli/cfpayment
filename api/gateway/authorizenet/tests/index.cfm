<cfsetting showDebugOutput="false">

    <cfparam name="url.runtests" default="false">
    <cfparam name="url.reporter" 		default="simple">
    <cfparam name="url.directory" 		default="tests.specs">
    <cfparam name="url.recurse" 		default="true" type="boolean">
    <cfparam name="url.bundles" 		default="">
    <cfparam name="url.labels" 			default="">
    <cfparam name="url.reportpath" 		default="#expandPath( "/tests/results" )#">
    <cfparam name="url.propertiesSummary" 	default="false" type="boolean">



<cfif url.runtests OR url.keyExists("testSuites") OR url.keyExists("testBundles") OR url.reporter EQ "text">


<!--- Executes all tests in the 'specs' folder with simple reporter by default --->
<!--- Include the TestBox HTML Runner --->
<cfinclude template="/libs/testbox/system/runners/HTMLRunner.cfm" >

<cfelse>

<html>
    <head>
        <title>Run tests</title>
    </head>
    <body>
        <h1>Run Tests</h1>
        <ul>
            <li><a href="index.cfm?runtests=true">Run All Tests</a></li>
            <li>Run Specific Tests:
                <cfset specDir = expandPath("/" & Replace(url.directory, ".", "/"))>
                <cfset Tests = DirectoryList(specDir,false, "query")>
                <ul>
                    <cfloop query="Tests">
                        <cfoutput>
                        <cfif type IS "Dir">
                            <li><a href="index.cfm?directory=#url.directory#.#Name#&runtests=true">#Name#</a></li>

                        <cfelse>
                            <cfset CFCName = "#url.directory#.#Replace(Name, ".cfc", "")#">
                            <li><a href="index.cfm?testSuites=#CFCName#&testBundles=#CFCName#">#Name#</a></li>
                        </cfif>

                        </cfoutput>
                    </cfloop>
                </ul>
            </li>
        </ul>
    </body>
</html>
</cfif>
