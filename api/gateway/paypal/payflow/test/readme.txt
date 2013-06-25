You must configure your paypal credentials in payflowLibrary.cfc init method.  This is the only place you will need to change any of the values.

Log into Paypal manager - > Account Administration - > Manager Users

This page will allow you to see all of the users on that account.  The role for the API user but we API_FULL_TRANSACTION.  If you don't have
a user with that role then you will need to create one back clicking on the "Add User" link.

Paypal requires you to setup a API user for the gateway.