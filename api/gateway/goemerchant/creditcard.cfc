<!---
	$Id: creditcard.cfc 152 2011-01-18 00:23:34Z briang $

	Copyright 2007 Brian Ghidinelli (http://www.ghidinelli.com/)
	Copyright 2011 Shawn Mckee (http://www.clinicapps.com)

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
<cfcomponent name="creditcard" extends="cfpayment.api.model.creditcard" output="false">

	<!---
		// CardTypes              Prefix          Width
		// American Express       34, 37            15
		// Diners Club            300 to 305, 36    14
		// Carte Blanche          38                14
		// Discover               6011              16
		// EnRoute                2014, 2149        15
		// JCB                    3                 16
		// JCB                    2131, 1800        15
		// Master Card            51 to 55          16
		// Visa                   4                 13, 16
		// http://www.beachnet.com/~hstiles/cardtype.html
		// http://www.ros-soft.net/otros/cakephp_blog/creditcard.php.txt
		// http://www.rgagnon.com/javadetails/java-0034.html

		// Most comprehensive seems to be Wikipedia: http://en.wikipedia.org/wiki/Credit_card_number
	--->
	<cffunction name="getCardType" access="public" returntype="struct" output="false" hint="Card Type short/long name required by GoEmerchant gateway">
		<cfscript>
			var local = structNew(); 
			local.ccNum = getAccount();
			switch(len(local.ccNum))
			{
				case 16:
					if(left(local.ccNum, 1) == 4)
					{
						local.returnStruct.shortName = "Visa";
						local.returnStruct.longName = "Visa";
					}
					else if(listFind("51,52,53,54,55", left(local.ccNum, 2)))
					{
						local.returnStruct.shortName = "MasterCard";
						local.returnStruct.longName = "Master Card";
					}
					else if(left(local.ccNum, 4) == 6011)
					{
						local.returnStruct.shortName = "JCB";
						local.returnStruct.longName = "JCB";
					}
					else if(left(local.ccNum, 1) == 3)
					{
						local.returnStruct.shortName = "JCB";
						local.returnStruct.longName = "JCB";
					}
				break;

				case 15:
					if(listFind("34,37", left(local.ccNum, 2)))
					{
						local.returnStruct.shortName = "Amex";
						local.returnStruct.longName = "American Express";
					}
					else if(listFind("2131,1800", left(local.ccNum, 4)))
					{
						local.returnStruct.shortName = "JCB";
						local.returnStruct.longName = "JCB";
					}
					else if(listFind("2014,2149", left(local.ccNum, 4)))
					{
						local.returnStruct.shortName = "EnRoute";
						local.returnStruct.longName = "EnRoute";
					}
				break;

				case 14:
					if(left(local.ccNum, 2) == 36 OR listFind("301,302,303,304,305", left(local.ccNum, 3)))
					{
						local.returnStruct.shortName = "DinersClub";
						local.returnStruct.longName = "Diners Club";
					}
					else if(left(local.ccNum, 2) == 38)
					{
						local.returnStruct.shortName = "CarteBlanche";
						local.returnStruct.longName = "Carte Blanche";
					}
				break;

				case 13:
					if(left(local.ccNum, 1) == 4)
					{
						local.returnStruct.shortName = "Visa";
						local.returnStruct.longName = "Visa";
					}
				break;
			}

			return local.returnStruct;

		</cfscript>

	</cffunction>

</cfcomponent>