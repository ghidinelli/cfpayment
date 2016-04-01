/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a a response object that is returned from the authorize.net system whenever
	we have interactions with the customer based actions. 
	
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

component 
	accessors="true"
	extends="cfpayment.api.model.response"
{
	property name="resultCode" 										getter="true" setter="true";
	property name="messageCode" 									getter="true" setter="true";
	property name="messageText" 									getter="true" setter="true";
	property name="responseType"					type="string"	getter="true" setter="true";
	property name="customerProfileId"								getter="true" setter="true";
	property name="customerPaymentProfileId"						getter="true" setter="true";
	property name="customer"						type="customer"	getter="true" setter="true";
	property name="customerPaymentProfileIdList" 	type="array" 	getter="true" setter="true";
	property name="customerShippingAddressIdList" 	type="array" 	getter="true" setter="true";
	property name="validationDirectResponseList" 	type="array"	getter="true" setter="true";
	property name="directResponse" 					type="string"	getter="true" setter="true";
	property name="ids"								type="array"	getter="true" setter="true";
	property name="paymentProfiles"					type="array"	getter="true" setter="true";
	property name="totalNumInResultSet"				type="numeric"	getter="true" setter="true";

	
	function init(){
		super.init(argumentCollection=arguments);




		if(!hasError()){
			var xmlResponse = XMLParse(getResult());
				setParsedResult(xmlResponse);
			var messages = XMLSearch(xmlResponse, "//:messages")[1]; //Should work, always you get a message
			
			//If this errors is because the service didn't actually respond which means hasError() should be true;
			setResultCode(messages.resultCode.xmlText);
			setMessageCode(messages.message.code.xmlText);
			setMessageText(messages.message.text.xmlText);
			setMessage(getMessageCode() & ": " & getMessageText());
	
			//there might be other meta processing. 

			

			//Both HTTP call and actual call were ok
			if(getResultCode() EQ "OK"){
				setStatus(getService().getStatusSuccessful());
				setResponseType(xmlResponse.XmlRoot.xmlName);

				//If anything is in the response set it 
				setCustomerProfileId(getXMLElementText(xmlResponse, "customerProfileId"));
				setCustomerPaymentProfileId(getXMLElementText(xmlResponse, "customerPaymentProfileId"));
				addValidationDirectResponse(getXMLElementText(xmlResponse, "validationDirectResponse"));
				setDirectResponse(getXMLElementText(xmlResponse, "directResponse"));


				



				//Handle specific data types
				if(getResponseType() EQ "getCustomerProfileIdsResponse"){
					var ids = XMlSearch(xmlResponse, "//:ids");
					if(ArrayLen(ids)){
						var iditems = ids[1].xmlChildren;
						var items = [];
						for(var id  in iditems){
							items.append(id.xmltext);
						}
						setIds(items);
					}
				}

				if(getResponseType() EQ "getCustomerPaymentProfileListResponse"){
					setTotalNumInResultSet(getXMLElementText(xmlResponse, "totalNumInResultSet", nullValue()));

					var paymentProfiles = XMlSearch(xmlResponse, "//:paymentProfile");

					var profiles = [];

					for(var profile in paymentProfiles){
						var paymentProfile = new paymentProfile();
							paymentProfile.setCustomerPaymentProfileId(getXMLElementText(profile, "customerPaymentProfileId"));
							paymentProfile.setCustomerProfileId(getXMLElementText(profile, "customerProfileId"));

							var paymentMethod = {
								"creditCard":{
									"cardNumber": getXMLElementText(profile, "cardNumber"),
									"expirationDate": getXMLElementText(profile, "expirationDate")
								}
							};	
							paymentProfile.setPaymentMethods(paymentMethod);

							profiles.append(paymentProfile);
					}

					setPaymentProfiles(profiles);
				}

			}
			else{
				setStatus(getService().getStatusFailure());
			}

		}
		return this;
	}


	//Add items to arrays
	public void function addCustomerPaymentProfileId(String id){

		var paymentProfileList = getCustomerPaymentProfileIdList();
			paymentProfileList = isNull(paymentProfileList) ? [] : paymentProfileList;

			paymentProfileList.append(id);
			setCustomerPaymentProfileIdList(paymentProfileList);
	}
	public void function addCustomerShippingAddressId(Any id){
		var shipIDList = getCustomerPaymentProfileIdList();
				shipIDList = isNull(shipIDList) ? [] : shipIDList;

				shipIDList.append(id);
				setCustomerShippingAddressIdList(shipIDList);
	}

	public void function addvalidationDirectResponse(String  directResponse){
		var directResponseList = getValidationDirectResponseList();
			directResponseList = isNull(directResponseList) ? [] : directResponseList;
			
			directResponseList.append(directResponse);
			setValidationDirectResponseList(directResponseList);
	}

	private function getXMLElementText(XML responseXML, String elementName, default=""){
		var searchItem = XMLSearch(responseXML, "//:#elementName#");

		
		return ArrayLen(searchItem) ? searchItem[1].xmlText : default;
	}
}