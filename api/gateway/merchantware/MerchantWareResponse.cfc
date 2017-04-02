/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is an implementation of Cayan MerchantWare API. 
	See:
https://ps1.merchantware.net/Merchantware/ws/RetailTransaction/v4/Credit.asmx

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
component accessors=true extends="cfpayment.api.model.response"
{

		property name="creditresponse4" 		setter="true" getter="true";
		property name="VaultBoardingResponse" 	setter="true" getter="true";
		property name="responseType" 			setter="true" getter="true";
		property name="requestType" 			setter="true" getter="true";
		property name="account" 				setter="true" getter="true";

		function init(){
			super.init(argumentCollection=arguments);



			var res = getParsedResult();
			var responseType = ListLast(res.getClass().getName(), ".");
			setResponseType(responseType);
		
			if(responseType EQ "CreditResponse4"){


					setCreditresponse4(res); //Set the main object we get back for any other info.
					setTokenId(res.getToken());
					setAuthorization(res.getAuthorizationCode());
					setAVSCode(res.getAvsResponse());
					setCVVCode(res.getCvResponse());
					setMessage(res.getApprovalStatus());
					setTokenId(res.getToken());
					setTransactionID(res.getToken());

					if(res.getApprovalStatus() EQ "APPROVED"){
						setStatus(getService().getStatusSuccessful());
					}
					else {
						setStatus(getService().getStatusFailure());
					}

					return this;
			}



			if(responseType EQ "VaultBoardingResponse"){
				setVaultBoardingResponse(res);
				setTokenId(res.getVaultToken());
				setMessage(res.getErrorMessage());


				if(Len(res.getErrorCode())){
						setStatus(getService().getStatusFailure());
				}
				else {
						setStatus(getService().getStatusSuccessful());
						
				}

				return this;
				
			}

			if(responseType EQ "VaultPaymentInfoResponse"){
				//create an account if it is correct. 

				setMessage(res.getErrorMessage());

				if(Len(res.getErrorCode())){
						setStatus(getService().getStatusFailure());
				}
				else {

						var card = super.getService().createCreditCard();


						card.setMonth(Left(res.getExpirationDate(), 2));
						card.setYear(Right(res.getExpirationDate(), 2));
						card.setAddress(res.getAvsStreetAddress());
						card.setPostalCode(res.getAvsZipCode());
						card.setAccount( res.getCardNumber());
					
						card.setLastName(ListLast(res.getCardHolder(), " "));
						var nameLen = ListLen(res.getCardHolder(), " ");
						var fname = ListDeleteAt(res.getCardHolder(), nameLen, " ");
						card.setFirstName(fname);
						setAccount(card)
						setStatus(getService().getStatusSuccessful());
						
				}
				return this;

				
			}

			throw("ResponseType #responseType# doens't have a handler");
			abort;

			return this;
		}

		function asString(){

			var resp = getcreditresponse4();
			var ret = "";
				ret &= "Token: #resp.getToken()# #Chr(10) & Chr(13)#";
				ret &= "ErrorMessage: #resp.getErrorMessage()# #Chr(10) & Chr(13)#";
				ret &= "AvsResponse: #resp.getAvsResponse()# #Chr(10) & Chr(13)#";
				ret &= "CvResponse: #resp.getCvResponse()# #Chr(10) & Chr(13)#";
				ret &= "EntryMode: #resp.getEntryMode()# #Chr(10) & Chr(13)#";
				ret &= "Amount: #resp.getAmount()# #Chr(10) & Chr(13)#";
				//ret &= "string: #resp.getstring()# #Chr(10) & Chr(13)#";
				ret &= "TransactionDate: #resp.getTransactionDate()# #Chr(10) & Chr(13)#";
				ret &= "AuthorizationCode: #resp.getAuthorizationCode()# #Chr(10) & Chr(13)#";
				ret &= "TransactionType: #resp.getTransactionType()# #Chr(10) & Chr(13)#";
				ret &= "ExtraData: #resp.getExtraData()# #Chr(10) & Chr(13)#";
				ret &= "InvoiceNumber: #resp.getInvoiceNumber()# #Chr(10) & Chr(13)#";
				ret &= "Cardholder: #resp.getCardholder()# #Chr(10) & Chr(13)#";
				ret &= "CardNumber: #resp.getCardNumber()# #Chr(10) & Chr(13)#";
				ret &= "CardType: #resp.getCardType()# #Chr(10) & Chr(13)#";
				
			return ret;
		}
}