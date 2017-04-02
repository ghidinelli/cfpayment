<!---starting the process over, let's clear the session--->
<cfloop collection="#session#" item="i">
	<cfset session[i] = ''>
</cfloop>

<!DOCTYPE html>
<!--[if lt IE 7 ]><html class="ie ie6" lang="en"> <![endif]-->
<!--[if IE 7 ]><html class="ie ie7" lang="en"> <![endif]-->
<!--[if IE 8 ]><html class="ie ie8" lang="en"> <![endif]-->
<!--[if (gte IE 9)|!(IE)]><!--><html lang="en-US"> <!--<![endif]-->

<!-- head -->
<head>

<!-- meta -->
<meta charset="UTF-8" />
<meta http-equiv="X-UA-Compatible" content="IE=9" />
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<title>TherapyAppointment</title>

<!-- stylesheet -->
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol-child/style.css" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/js/fancybox/jquery.fancybox-1.3.4.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/ui/jquery.ui.all.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/responsive.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/skins/blue/images.css?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/style-colors.php?ver=1.2.2" media="all" />
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/style.php?ver=1.2.2" media="all" />
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Raleway:300,400,400italic,700" >
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Raleway:300,400,400italic,700" >
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Raleway:300,400,400italic,700" >
<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Patua+One" >

<!-- wp_head() -->

<link rel="icon" href="https://www.psychselect.com/wp-stuff/favicon.ico" type="image/x-icon" />
<link rel="shortcut icon" href="https://www.psychselect.com/wp-stuff/favicon.ico" type="image/x-icon" />

<meta name="description" content="a practice management system designed to simplify routine office tasks for mental health professionals" />

<script type='text/javascript' src='https://www.psychselect.com/wp-stuff/wp-includes/js/jquery/jquery.js?ver=1.8.3'></script>

<link rel='canonical' href='http://therapyappointment.com' />

<!--[if lt IE 9]>
<script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
<!--[if lte IE 8]>
<link rel="stylesheet" href="https://www.psychselect.com/wp-stuff/wp-content/themes/pindol/css/ie8.css" />
<![endif]-->


<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-42664327-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>

</head>


<!-- body -->
<body class="page page-id-5804 page-template-default  layout-full-width">
	
	<div id="Wrapper">

		<!-- #Header -->
		<header id="Header">
			
			<div id="top_bar">
				<div class="container">
					<div class="sixteen columns">
						<!-- #logo -->
						<a id="logo" href="http://therapyappointment.com" title="TherapyAppointment">
							<img src="https://www.psychselect.com/wp-stuff/wp-content/uploads/2013/07/logo.png" alt="TherapyAppointment" />
						</a>
					</div>		
				</div>
			</div>
			
			<div id="Subheader"><div class="container"><div class="sixteen columns"><h1 style="font-family:arial;text-align:center;color:#B8B8B8;">Sign up for an account</h1></div></div></div>			<!---display error message if it exists--->
			<cfif structKeyExists(url,'result')>
				<cfoutput><p align="center"><font color="red"><strong>#htmleditformat(urlDecode(url.result))#</strong></font></p></cfoutput>
			</cfif>
		</header>	
<!-- Content -->
<div id="Content">
	<div class="container">
	<div style="min-height:400px;" class="the_content the_content_wrapper"> 
		<!-- CONTENT GOES HERE. TO HIGHLIGHT A PAGE IN MENU, ADD current-menu-item CLASS TO THE PAGE'S LI YOU WISH TO BE THE CURRENT PAGE -->
		<Table cellpadding=8 style="border-width:0;">
  <tr><td align="center" style="border-width:0;">
	<table style="border-width:0;">
	<tr style="border-width:0;"><td style="border-width:0;" align=center colspan=2>
	<font face="arial" color="darkblue">
	
	Discounts are available if you share an office with other<br /> therapists who currently use TherapyAppointment, or if you<br /> schedule very few appointments. Indicate this below:<p>

	</font></td></tr>

	<CFForm Name="SoloOrMulti" ACTION="NewPaymentPortal2.cfm" target="_top" METHOD="POST" style="margin-bottom:0;">
	
	<tr style="border-width:0;"><td style="border-width:0;text-align:right;font-family:arial;color:darkblue;vertical-align:middle;">
	How many appointments do you<br />usually schedule each month?</font></td>
	<td style="text-align:left;font-family:arial;color:darkblue;border-width:0;">
		<CFInput type="radio" Name="Appointments" Value="500" checked> 40 or more per MONTH<br>
		<CFInput type="radio" Name="Appointments" Value="40"> Between 10 and 39 per MONTH<br>
		<CFInput type="radio" Name="Appointments" Value="10"> Fewer than 10 per MONTH<br>
	</td></tr> 

	<tr style="border-width:0;"><td style="text-align:right;font-family:arial;color:darkblue;vertical-align:middle;border-width:0;">
	Are other therapists in your office<br />currently using TherapyAppointment?</font></td>
	<td style="text-align:left;font-family:arial;color:darkblue;border-width:0;">
		<CFInput type="radio" Name="Others" Value=0 checked onClick="document.getElementById('Secondary').style.display='none';"> No<br>
		<CFInput type="radio" Name="Others" Value=1 onClick="document.getElementById('Secondary').style.display='inline';"> Yes<br>	
	</td></tr></table>
	
	<span id="Secondary" style="display:none;">
		<Table border=0>
		<tr><td style="text-align:right;font-family:arial;color:darkblue;border-width:0;vertical-align:top;">What is the SECONDARY password<br />used by the other therapists?</td>
		<td style="text-align:left;font-family:arial;color:darkblue;border-width:0;vertical-align:top;"><CFInput type="password" name="secondary" style="width:200px;height:11px;"></td></tr>
		
		<tr style="border-width:0;">
		<td style="text-align:right;font-family:arial;color:darkblue;border-width:0;vertical-align:top;">What is the ZIP CODE<br />of your office address?</td>
		<td style="text-align:left;font-family:arial;color:darkblue;border-width:0;vertical-align:top;"><CFInput type="text" name="zipcode" style="width:200px;height:11px;"></td></tr>
		</table>
	</span>
  </td></tr>
  
	<tr><td align="center" colspan=10 style="border-width:0;"><CFInput type="submit" name="SubmitThis" Value="Sign me up!" style="margin-top:15px;color:white;"></td></tr>
</cfform>
   </table>     
        
        
	</div>
	<div class="clearfix"></div>	
		
		<!-- Sidebar -->
		
	</div>
</div>
		
	</div>
	
	
<!-- wp_footer() -->
	

</body>
</html>