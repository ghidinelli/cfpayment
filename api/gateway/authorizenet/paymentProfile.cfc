/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a customer that can be loaded and saved to the authorize.net system
	
	
	Licensed under the Apache License, Version 2.0 (the "License"); you 
	may not use this file except in compliance with the License. You may 
	obtain a copy of the License at:
	 
		http://www.apache.org/licenses/LICENSE-2.0
		 
	Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/
component accessors="true"
{

	property name="customerType" 				type="string"	getter="true" setter="true";
	property name="billTo" 						type="struct"	getter="true" setter="true";
	property name="service" 					getter="true" setter="true";
	property name="customerProfileId" 			type="string"	getter="true" setter="true";
	property name="customerPaymentProfileId" 	type="string"	getter="true" setter="true";
	property name="paymentMethods"				type="struct" 	getter="true" setter="true" hint="Card that we can use with this profile";

	variables.custTypes = "individual,business";


	public function setCustomerType(String type){

		if(!listFindNoCase(variables.custTypes, type)){
			throw(type="cfpayment.authorizenet.illegalArgumentException", message="CustomerType can only be individual or business");
		}
		variables.customerType = type;
		return this;
	}



	public paymentProfile function populate(XML responseXML){


			getXMLElementText(responseXML, "customerType", "", setCustomerType);
			setCustomerPaymentProfileId(getXMLElementText(responseXML, "customerPaymentProfileId"));
		
			var billToXML = XMLSearch(responseXML, "//:billTo");
			

			if(ArrayLen(billToXML)){
				 var billTo = {
					"firstName": getXMLElementText( billToXML[1], "firstName"),
					"lastName": getXMLElementText( billToXML[1], "lastName"),
					"company": getXMLElementText( billToXML[1], "company"),
					"address": getXMLElementText( billToXML[1], "address"),
					"city": getXMLElementText( billToXML[1], "city"),
					"state": getXMLElementText( billToXML[1], "state"),
					"zip": getXMLElementText( billToXML[1], "zip"),
					"country": getXMLElementText( billToXML[1], "country"),
					"phoneNumber": getXMLElementText( billToXML[1], "phoneNumber"),
					"faxNumber": getXMLElementText( billToXML[1], "faxNumber"),
				};

				setBillTo(new address(argumentCollection=billTo));
			}
				
			
			
			var creditCard = XMLSearch(responseXML, "//:creditCard");
			if(ArrayLen(creditCard)){
				//This should be a card object no?
				//No. The api doesn't return actual cards it seems. So this clashes with this api
				
				// var card  = getService().createCreditCard();
				// 	card.setAccount(creditCard[1].cardNumber.xmltext);
				// 	card.setMonth(Left(creditCard[1].expirationDate.xmltext, 2));
				// 	card.setYear(Right(creditCard[1].expirationDate.xmltext, 2));
				
				
			
				var paymentMethod = {
					"creditCard":{
						"cardNumber": creditCard[1].cardNumber.xmltext,
						"expirationDate": creditCard[1].expirationDate.xmltext
					}
				};	
				setPaymentMethods(paymentMethod);
			}
			
		


			
		return this;
	}


	

	private function getXMLElementText(XML responseXML, String elementName, default="",Function callback ){
		var searchItem = XMLSearch(responseXML, "//:#elementName#");

		//Deal with callbacks.
		if(	structKeyExists(arguments, "callback") 
			&& !isNull(arguments.callback) 
			&& isValid("Function", callback)
			&& ArrayLen(searchItem)
			){

			callback(searchItem[1].xmlText);
			
		}
		
		return ArrayLen(searchItem)?searchItem[1].xmlText : default;
	}
}