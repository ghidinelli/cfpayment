README for PayPal Java SDK ColdFusion Sample
============================================

This sample code demonstrates how to call the PayPal Java SDK libraries from ColdFusion.

Steps to run the PayPal Java SDK ColdFusion Sample:

About directory names in the samples: the samples assume directory locations, as detailed
in the following set-up steps. 

You can use whatever directory locations you prefer, as long as you are consistent in specifying 
your preferred locations in the PayPal-provided samples.
   
1. Download and install the following required software.

   Software:                Version:       Download from:
   =========                ========       ==============
   ColdFusion MX7.0.1       MX7.0.1        http://www.macromedia.com/software/coldfusion/

2. Create a C:\paypal\lib\ directory.

3. From the <SDK ROOT>\lib directory, copy the following files to the C:\paypal\lib\ directory:
   (Note: <SDK ROOT> is the directory where you installed the PayPal SDK)
   
   bcmail-jdk14-128.jar
   bcprov-jdk14-128.jar
   paypal_base.jar
   paypal_stubs.jar 
   sax2.jar
   xerces.jar
   xpp3-1.1.3.4d_b4_min.jar
   xstream-1.1.3.jar

4. In the ColdFusion Administrator, add the C:\paypal\lib path to the ColdFusion Class Path (Java and JVM).

5. Restart the ColdFusion MX service.

6. Move all files from the <SDK_ROOT>\samples\ColdFusion directory to your ColdFusion project directory under wwwroot.

7. To access the samples type http://localhost:8500/ColdFusion/index.cfm in the address bar of your browser and hit enter.

DEFAULT LOGGING
===============
A "paypal.cf.log" file will be created under <CFMX7_ROOT>\runtime\bin. To change the logging configuration, update 
the log4j.xml file.

OPTIONAL SOAP LOGGING 
=====================
Logging SOAP requests and responses SOAP messages is useful for program debugging,
but is not recommended for production use.

To record SOAP requests and responses to the PayPal log, 
add the following lines to the "globalConfiguration" section of the
<CFusionMX7 ROOT>\wwwroot\WEB-INF\client-confid.wsdd file.

  <requestFlow>
    <handler type="java:com.paypal.sdk.logging.DefaultSOAPHandler" />
  </requestFlow>
  <responseFlow>
    <handler type="java:com.paypal.sdk.logging.DefaultSOAPHandler" />
  </responseFlow>

Known Issues with UTF-8 Encoded Characters:
The PayPal ColdFusion sample application uses the version of log4j bundled within CFMX7, log4j-1.1.3. In this log4j release, 
the FileAppender seems to always use the default encoding (even when an "encoding" parameter is specified), and therefore, UTF-8 
encoded characters contained in the SOAP envelopes are not logged properly.



