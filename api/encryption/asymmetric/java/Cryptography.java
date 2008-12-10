/***************************************************************************************************

	File Name:		Cryptography.java.
 	Author:			Mindfire Solutions.
 	Create Date:	25th June 2007.
 	CopyRight: 		Copyright (c) 2007 Mindfire Solutions, Inc.

***************************************************************************************************/

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.math.BigInteger;
import java .util.Enumeration;
import java.util.Date;
import java.security.*;
import java.security.SecureRandom;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.Key;
import java.security.spec.RSAPublicKeySpec;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.RSAPrivateCrtKeySpec;
import java.security.interfaces.RSAPrivateCrtKey;
import java.security.cert.X509Certificate;
import javax.security.auth.x500.X500Principal;
import java.security.cert.CertificateFactory;
import java.security.cert.Certificate;
import org.bouncycastle.x509.X509V1CertificateGenerator;
import org.bouncycastle.crypto.generators.RSAKeyPairGenerator;
import org.bouncycastle.crypto.AsymmetricCipherKeyPair;
import org.bouncycastle.crypto.AsymmetricCipherKeyPairGenerator;
import org.bouncycastle.crypto.params.RSAKeyGenerationParameters;
import org.bouncycastle.crypto.params.RSAKeyParameters;
import org.bouncycastle.crypto.params.RSAPrivateCrtKeyParameters;
import org.bouncycastle.crypto.AsymmetricBlockCipher;
import org.bouncycastle.crypto.engines.RSAEngine;
import org.bouncycastle.crypto.encodings.PKCS1Encoding;
import org.bouncycastle.util.encoders.Hex;


/***************************************************************************************************

 	Class Name:Cryptography

 	Description:
 		This class use  constructor to initialze KeyStoreName.It handles methods to create a new
 		KeyStore and add or delete Key into KeyStore.It handles methods for generating
 		AsymmetricCipherKeyPair(Public Key and Private Key)	using RSA algorithm and use those keys
 		for encrypting given data and deccrypting encrypted	data.

***************************************************************************************************/

public class Cryptography
{
	private AsymmetricBlockCipher cipher = null;
	private String keyStoreFileName = null;

	public Cryptography()
	{
		/*Empty*/
	}

    public Cryptography(String keyStoreName)throws Exception
	{
		 keyStoreFileName = keyStoreName;
	}

   	/******************************************************************************************

		Method Name:keyPairGeneration

		Arguments:
			1.	strength [Type: Integer]
				- The size, in bits, of the keys we want to produce.

		Return:
			A KeyPair containing PublicKey and Private Key.
			[Type: AsymmetricCipherKeyPair Object]

		Description:
			Gernerate KeyPair of specified size.

	*******************************************************************************************/

	public AsymmetricCipherKeyPair keyPairGeneration(int strength)throws Exception
	{
		SecureRandom securerandom = new SecureRandom();
		BigInteger pubExp = new BigInteger("10001", 16);

		RSAKeyGenerationParameters RSAKeyGenParams = new RSAKeyGenerationParameters
												(pubExp,securerandom, strength, 80);
		RSAKeyPairGenerator rsakeygen = new RSAKeyPairGenerator();
		rsakeygen.init(RSAKeyGenParams);
		AsymmetricCipherKeyPair keypair = rsakeygen.generateKeyPair();

		return keypair;
	}

   	/******************************************************************************************

		Method Name:encryption

	  	Arguments:
	  		1.	input	[Type: String]
				- String to be encrypted.
			2.	modulus	[Type: String]
				- Used to generate RSA Public Key.
			3.	exponent	[Type: String]
				- Used to generate RSA Public Key.

	  	Return:
	  		Encrypted String.
	  		[Type: String]

	  	Description:
			This method is used to encrypt bytes from a given string and convert the bytes into
			string.This method uses AsymmetricBlockCipher to perform the encryption.

	*******************************************************************************************/
	public String encryption(String input, String modulus, String exponent)throws Exception
	{
		String encString = null;

		BigInteger intModulus = new BigInteger(modulus);
		BigInteger intExponent = new BigInteger(exponent);
		RSAKeyParameters RSApubKey = new RSAKeyParameters(false, intModulus, intExponent);
		byte[] toEncrypt = input.getBytes();
		cipher = new PKCS1Encoding(new RSAEngine());
		cipher.init(true, RSApubKey);
		byte[] encByte = cipher.processBlock(toEncrypt, 0, toEncrypt.length);
		byte[] encValue = Hex.encode(encByte);
		encString = new String(encValue);

		return encString;
	}

   	/******************************************************************************************

		Method Name:decryption

		Arguments:
			1.	input [Type: String]
				-String to be decrypted.
			2.	modulus [Type: String]
				- Used to generate RSA Private Key.
			3.	privExponent [Type: String]
				- Used to generate RSA Private Key.
			4.	pubExponent [Type: String]
				- Used to generate RSA Private Key.
			5.	primeP [Type: String]
				- Used to generate RSA Private Key.
			6.	primeQ [Type: String]
				- Used to generate RSA Private Key.
			7.	primeExponentP [Type: String]
				- Used to generate RSA Private Key.
			8.	primeExponentQ [Type: String]
				- Used to generate RSA Private Key.
			9.	crtCoefficient [Type: String]
				- Used to generate RSA Private Key.

		Return:
			A Plain Text.
			[Type: String]

		Description:
			Method For Decrypting Encrypted String.

	*******************************************************************************************/

	public String decryption(String input,String modulus,String privExponent,String pubExponent,
							String primeP,String primeQ,String primeExponentP,String primeExponentQ,
							String crtCoefficient)throws Exception
	{
		BigInteger intModulus = new BigInteger(modulus);
		BigInteger intPrivExponent = new BigInteger(privExponent);
		BigInteger intPubExponent = new BigInteger(pubExponent);
		BigInteger intPrimeP = new BigInteger(primeP);
		BigInteger intPrimeQ = new BigInteger(primeQ);
		BigInteger intPrimeExponentP = new BigInteger(primeExponentP);
		BigInteger intPrimeExponentQ = new BigInteger(primeExponentQ);
		BigInteger intCrtCoefficient = new BigInteger(crtCoefficient);

		RSAPrivateCrtKeyParameters RSAprivKey =	new RSAPrivateCrtKeyParameters
						(intModulus, intPubExponent, intPrivExponent, intPrimeP,
						intPrimeQ, intPrimeExponentP, intPrimeExponentQ, intCrtCoefficient);
		byte[] toDecrypt = Hex.decode(input);
		cipher = new PKCS1Encoding(new RSAEngine());
		cipher.init(false, RSAprivKey);
		byte[] decByte = cipher.processBlock(toDecrypt, 0, toDecrypt.length);
		String decString = new String(decByte);
		return decString;
	}

   	/******************************************************************************************

		Method Name:keyStoreGenerator

		Arguments :
			1.	keyStorePassword	[Type: String]
				- Password to generate the keystore integrity check.

		Return:
			Nothing.
			[Type: Void]

		Description:
			This method generates an empty KeyStore with specified password using JCEKS.

	*******************************************************************************************/
	public void keyStoreGenerator(String keyStoreName, String keyStorePassword)throws Exception
	{
		  FileOutputStream stream = null;

		  try
		  {
			  stream= new FileOutputStream(keyStoreName);
			  KeyStore keystore = KeyStore.getInstance( "JCEKS", "SunJCE" );

			  //Create empty KeyStore
			  keystore.load(null,null);

			  //Save KeyStore
			  keystore.store(stream, keyStorePassword.toCharArray());
		  }
		  catch (Exception e)
		  {
			  e.printStackTrace();
		  }
		  finally
		  {
			  try
			  {
				  stream.close();
			  }	catch (Exception e){}
		  }
	}

   	/******************************************************************************************

		Method Name:importKey

		Arguments:
			1.	keyAlias  	[Type: String]
				- Alias for adding key in the KeyStore.
			2.	keyStorePassword	[type: String]
				- Password of the KeyStore to which key is to be imported.
			3.	modulus 	[Type: String]
				- Used to generate a RSAPublicKeySpec.
			4.	publicExponent 	[Type: String]
				- Used to generate a RSAPublicKeySpec.

		Return:
			Nothing.
			[Type: Void]

		Description :
			Add a new Public key in the Keystore with spcified key alias.Can not add key if the
			specified key alias already present in the KeyStore.

	*******************************************************************************************/

	public void importKey(String keyAlias, String keyStorePassword,
							String modulus, String publicExponent)throws Exception
	{

		// read keystore file
		FileInputStream keyStoreFile = new FileInputStream(keyStoreFileName);
		KeyStore keyStore = KeyStore.getInstance( "JCEKS", "SunJCE" );
		keyStore.load(keyStoreFile, keyStorePassword.toCharArray());

		//check whether specified alias present or not
		if(keyStore.isKeyEntry(keyAlias))
		{
				throw new KeyStoreException("Alias already exist in KeyStore.");
		}
		else
		{
			BigInteger RSAmod = new BigInteger(modulus);
			BigInteger RSApubExp = new BigInteger(publicExponent);

			// create RSAPublicKeySpec key spec
			RSAPublicKeySpec RSAPubSpec =
							new RSAPublicKeySpec(RSAmod, RSApubExp);

			KeyFactory keyfactory = KeyFactory.getInstance("RSA");
			RSAPublicKey publicKey = (RSAPublicKey)keyfactory.generatePublic(RSAPubSpec);

			// add the key to the keystore
			keyStore.setKeyEntry(keyAlias, publicKey, keyStorePassword.toCharArray(), null);

			//save keystore
			FileOutputStream keyStoreName = new FileOutputStream(keyStoreFileName);
			keyStore.store(keyStoreName, keyStorePassword.toCharArray());
		}
	}

	/******************************************************************************************

		Method Name:importKey

		Arguments:
			1.	keyAlias	[Type: String]
				- Alias for adding key in the KeyStore.
			2.	keyStorePassword	[type: String]
				- Password of the KeyStore to which key is to be imported.
			3.	modulus [Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.
			4.	privExponent	[Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.
			5.	pubExponent	[Type: String]
				- Used to generate RSA Private Key.
			6.	primeP [Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.
			7.	primeQ	[Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.
			8.	primeExponentP 	[Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.
			9.	primeExponentQ	[Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.
			10.	crtCoefficient [Type: String]
				- Used to generate new RSAPrivateCrtKeySpec.

		Return:
			Nothing.
			[Type: Void]

		Description :
			Add a new Private key in the Keystore with spcified key alias.Can not add key if the
			specified key alias already present in the KeyStore.

	*******************************************************************************************/
	public void importKey(String keyAlias, String keyStorePassword, String modulus,
							String privExponent, String pubExponent,String primeP,
							String primeQ, String primeExponentP,String primeExponentQ,
							String crtCoefficient)throws Exception
	{

		// read keystore file
		FileInputStream keyStoreFile = new FileInputStream(keyStoreFileName);
		KeyStore keyStore = KeyStore.getInstance( "JCEKS", "SunJCE" );
		keyStore.load(keyStoreFile, keyStorePassword.toCharArray());

		//check whether specified alias present or not
		if(keyStore.isKeyEntry(keyAlias))
		{
				throw new KeyStoreException("Alias already exist in KeyStore.");
		}
		else
		{
			BigInteger RSAmod = new BigInteger(modulus);
			BigInteger RSApubExp = new BigInteger(pubExponent);
			BigInteger RSAPrivExp = new BigInteger(privExponent);
			BigInteger RSAp = new BigInteger(primeP);
			BigInteger RSAq = new BigInteger(primeQ);
			BigInteger RSADp = new BigInteger(primeExponentP);
			BigInteger RSADq = new BigInteger(primeExponentQ);
			BigInteger RSAqInv = new BigInteger(crtCoefficient);

			// create RSAPublicKeySpec key spec using key file
			RSAPrivateCrtKeySpec RSAPrivSpec =
			new RSAPrivateCrtKeySpec(RSAmod, RSApubExp,RSAPrivExp,RSAp,RSAq,RSADp,RSADq,RSAqInv);

			KeyFactory keyfactory = KeyFactory.getInstance("RSA");
			RSAPrivateCrtKey privateKey = (RSAPrivateCrtKey)keyfactory.generatePrivate(RSAPrivSpec);

			Provider newProvider = (java.security.Provider)Class.forName
							("org.bouncycastle.jce.provider.BouncyCastleProvider").newInstance();
			Security.addProvider(newProvider);

			BigInteger intmod = new BigInteger(modulus);
			BigInteger intpubExp = new BigInteger(pubExponent);

			// create RSAPublicKeySpec key spec using key file
			RSAPublicKeySpec RSAPubSpec =
							new RSAPublicKeySpec(intmod, intpubExp);

			keyfactory = KeyFactory.getInstance("RSA");
			RSAPublicKey publicKey = (RSAPublicKey)keyfactory.generatePublic(RSAPubSpec);

			// generate the certificate
			X509V1CertificateGenerator  certGen = new X509V1CertificateGenerator();

			certGen.setSerialNumber(BigInteger.valueOf(System.currentTimeMillis()));
			certGen.setIssuerDN(new X500Principal("CN=Certificate"));
			certGen.setNotBefore(new Date(System.currentTimeMillis() - 50000));
			certGen.setNotAfter(new Date(System.currentTimeMillis() + 50000));
			certGen.setSubjectDN(new X500Principal("CN=Certificate"));
			certGen.setPublicKey(publicKey);
			certGen.setSignatureAlgorithm("SHA256WithRSAEncryption");

			Certificate[] chain = new Certificate[1];
			chain[0] = certGen.generate(privateKey,"BC");


			// add the key to the keystore
			keyStore.setKeyEntry(keyAlias, privateKey, keyStorePassword.toCharArray(), chain);

			//save keystore
			FileOutputStream keyStoreName = new FileOutputStream(keyStoreFileName);
			keyStore.store(keyStoreName, keyStorePassword.toCharArray());
		}

	}

   /******************************************************************************************

		Method Name:retrieveKey

		Arguments:
			1.	keyAlias	[Type: String]
				- Alias for retrieving key from the KeyStore.
			2.	keyStorePassword	[Type: String]
				- Password of the KeyStore from which key is to be retrieved.

		Return:
			The key related to the specified alias name.
			[Type: Key]

		Description:
			This method is used to retrieve Key from KeyStore using alias for that key.

	*******************************************************************************************/
	public Key retrieveKey(String keyAlias,String keyStorePassword)throws Exception
	{
		String retKeyVal = null;
		Key key = null;

		// read keystore file
		KeyStore keyStore = KeyStore.getInstance( "JCEKS", "SunJCE" );
		FileInputStream keyStoreFile = new FileInputStream(keyStoreFileName);
		keyStore.load(keyStoreFile, keyStorePassword.toCharArray());


		//check whether specified alias present or not
		if(keyStore.isKeyEntry(keyAlias))
		{
			//get key from keystore
			key = keyStore.getKey(keyAlias, keyStorePassword.toCharArray());
		}
		else
		{
			throw new KeyStoreException ("Alias doesn't exist in KeyStore for retrieval.");
		}

		return key;
	}

   /******************************************************************************************

		Method Name:deleteKey

		Arguments:
			1.	keyAlias	[Type: String]
				- Alias for deleting key from the KeyStore.
			2.	keyStorePassword  [Type: String]
				- Password of the KeyStore from which key is to be deleted.

		Return:
			Nothing.
			[Type: Void]

		Description:
			Delete a specified key from KeyStore.

	*******************************************************************************************/
	public void deleteKey(String keyAlias,String keyStorePassword) throws Exception
	{

		// read KeyStore file
		KeyStore keyStore = KeyStore.getInstance( "JCEKS", "SunJCE" );
		FileInputStream keyStoreFile = new FileInputStream(keyStoreFileName);
		keyStore.load(keyStoreFile, keyStorePassword.toCharArray());

		//check whether specified alias present or not
		if(keyStore.isKeyEntry(keyAlias))
		{
			//Delete key from KeyStore
			keyStore.deleteEntry(keyAlias);

			//save KeyStore
			FileOutputStream keyStoreName = new FileOutputStream(keyStoreFileName);
			keyStore.store(keyStoreName, keyStorePassword.toCharArray());

		}
		else
		{
			throw new KeyStoreException("Alias doesn't exist in KeyStore for deletion.");
		}
	}

   /******************************************************************************************

		Method Name:listKeys

		Argument:
			1.	keyStorePassword	[Type: String]
				- Password of the KeyStore from which all the aliases will be retrieve.

		Return:
			An array containing all the keyaliases of the KeyStore.
			[Type: Array]

		Description:
			Generate an array containg  all the alias.

	*******************************************************************************************/
	public String[] listKeys(String keyStorePassword)throws Exception
	{
		String[] aliasArray = null;

		// read KeyStore file
		KeyStore keyStore = KeyStore.getInstance( "JCEKS", "SunJCE" );
		FileInputStream keyStoreFile = new FileInputStream(keyStoreFileName);
		keyStore.load(keyStoreFile, keyStorePassword.toCharArray());

		//Get total no. of alias in a KeyStore
		int totalAlias = keyStore.size();

		if(totalAlias > 0)
		{

			aliasArray = new String[totalAlias];

			Enumeration enum = keyStore.aliases();
			while(enum.hasMoreElements())
			{
				String alias = enum.nextElement().toString();
				aliasArray[totalAlias -1] = alias;
				totalAlias = totalAlias -1;
			}
		}
		else
		{
			throw new KeyStoreException ("KeyStore is empty. No Alias present.");
		}

		return aliasArray;
	}
}

/***************************************************************************************************

	End of File.

***************************************************************************************************/