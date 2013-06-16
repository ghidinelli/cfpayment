CFPAYMENT
=========

ColdFusion payment processing library makes plumbing e-commerce apps easy.  

Rather than roll your own credit card, ACH or alternative payment gateway with error, currency and money handling, leverage one of our production-tested gateways or extend our base gateway and write only the code necessary to create requests and parse responses for your gateway. Eliminates writing boilerplate code and handling esoteric CFHTTP errors that only seem to happen in production.

Tens of millions of dollars have been processed successfully.  Inspired by Ruby's ActiveMerchant.

Charge an Account in 6 Lines of Code
====================================
```js
// initialize gateway
cfg = { path = "stripe.stripe", TestSecretKey = "tGN0bIwXnHdwOa85VABjPdSn8nWY7G7I" };
svc = createObject("component", "cfpayment.api.core").init(cfg);
gw = svc.getGateway();


// create the account
account = svc.createCreditCard().setAccount(4242424242424242).setMonth(10).setYear(year(now())+1))
             .setFirstName("John").setLastName("Doe");

// in cents = $50.00, defaults to USD but can take any ISO currency code
money = svc.createMoney(5000); 

// charge the card
response = gw.purchase(money = money, account = account);

// did we succeed?
if (response.getSuccess())
  // yay!  look at response.getResult() or response.getParsedResult()
  // verify response.isValidAVS() or response.isValidCVV()
else
  // check response.getStatus(), output response.getMessage()
```

