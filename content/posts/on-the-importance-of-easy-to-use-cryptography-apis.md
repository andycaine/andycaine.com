+++
title = 'On the Importance of Easy to Use Cryptography APIs'
date = 2024-04-23T18:04:08+01:00
summary = 'I recently came across some code very similar to the below, a Lambda event handler implementing an encryption service:'
categories = ['Software Development']
tags = ['Cryptography', 'Encryption', 'jstink', 'Tink', 'Software Development', 'Secure Coding']
+++

I recently came across some code very similar to the below, a Lambda event handler implementing
an encryption service:

```typescript
export const handler = async (event: any) => {

  const keyHexString = getRequiredEnvVariable('KEY_HEX_STRING');
  const ivHexString = getRequiredEnvVariable('IV_HEX_STRING');

  const key = Buffer.from(keyHexString, 'hex');
  const iv = Buffer.from(ivHexString, 'hex');

  const inputData = event.queryStringParameters.data;

  // Encryption
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  let aesEncryptedData = cipher.update(inputData, 'utf8', 'base64');
  aesEncryptedData += cipher.final('base64');
  const authTag = cipher.getAuthTag();

  const response = {
    statusCode: 200,
    body: {
      aesEncryptedData,
      authTag
    }
  };
  return response;
};
```

Spot the problem here?

Well for a start, that encryption key probably shouldn't be stored in
an environment variable. But there's a much more serious issue here. That API
is being misused, leading to a very exploitable vulnerability.

## The Importance of the Initialization Vector

The initialization vector (IV) is critical to the security and integrity of the
encryption scheme. It should be random and unique for each encryption
operation. For the GCM mode of operation used here, a 12-byte IV is recommended
for efficiency and security.

The problem is, none of these requirements are clear from the API. And this is
this is the issue with APIs like Node's `crypto` API, where details like the
initialization vector are exposed to developers. Using these APIs can feel like
"juggling chainsaws in the dark", where mistakes can easily be made that
subvert the security of the system.

This is why I often recommend [Tink](https://developers.google.com/tink) for
situations like this. Tink provides APIs that are "easy to use correctly and
hard(er) to misuse". For example, the API for AES-GCM encryption in Tink does
not require the developer to provide an IV. Tink also has an excellent utility
tool for managing encryption keys in a keyset, including support for using Key
Management Systems such as AWS KMS to envelope encrypt data encryption keys.
Unfortunately Tink does not have a production-grade JavaScript version, which
is why I wrote a Tink compatible library for JavaScript for this basic
[Authenticated Encryption with Associated Data (AEAD) use case](https://github.com/andycaine/jstink).

## The Known-Plaintext Attack

Back to our example, you might be wondering how serious an issue reusing the IV
really is. Well, it can lead to a number of exploitable vulnerabilities but perhaps
the most damaging is one where the attacker has access to the encrypted version
of some known plaintext - often called a known-plaintext attack. Recovering the
plaintext for any ciphertext encrypted with the same IV is as simple as
performing an exclusive-or (XOR) operation on the ciphertext, the known
ciphertext, and the known plaintext. In other words, an attacker can decipher
your data without access to the encryption key - all they need is a plaintext
and the corresponding ciphertext.

Let's go through an example. Imagine the encryption handler above is
responsible for encrypting credit card numbers for an e-commerce website. An
attacker has managed to access the database and is confronted with some user IDs
and some encrypted data:
```
----------------------------------------------------
| user_id | encrypted_cc                           |
----------------------------------------------------
| 1       | 10e2fae3ea522c74a1b2e4841fea57d1752cbf |
| 2       | 13e0f9e1ea532d71a3b2e5831eed57d4742bb8 |
| 3       | 15e4fee4ea532c70a5b2e3811cee57d3702cbf |
| 4       | 16e6fee5ea552a76a3b2e3821def57d57626b4 |
----------------------------------------------------

```
Now suppose that the attacker has been using this system, and that he has
identified from inspecting URLs in the app that their user ID is `4`.

Just before exfiltrating this data, the attacker updated their credit card
number to be `1122-3344-5566-7788`. This means that the attacker now knows the
ciphertext for that plaintext. They can execute a known-plaintext attack and
discover the plaintexts for all of the encrypted data:

```javascript
function xor(buf1, buf2) {
    const result = Buffer.alloc(buf1.length);
    for (let i = 0; i < buf1.length; i++) {
        result[i] = buf1[i] ^ buf2[i];  // Apply XOR on each byte
    }
    return result;
}

function decrypt(ciphertext) {
    return xor(xor(ciphertext, knownCiphertext), knownPlaintext);
}

const knownCiphertext = Buffer.from(
    '16e6fee5ea552a76a3b2e3821def57d57626b4', 'hex'
);
const knownPlaintext = Buffer.from(
    '1122-3344-5566-7788', 'utf-8'
);

ciphertexts.forEach(ciphertext => {
    const plaintext = decrypt(Buffer.from(ciphertext, 'hex'));
    console.log(plaintext.toString('utf-8'));
});
```

Running this prints out the decrypted credit card numbers:
```
7564-4566-2343-3423
4756-5434-3454-6554
2323-5522-5677-1123
1122-3344-5566-7788
```

## Summary
Some basic cryptography knowledge is crucial for developers to write secure
code. Developers should have a broad understanding of how to apply
cryptography, which algorithms to use and which to avoid in a given scenario,
and how to use them securely.

However, most developers will not be cryptography experts. Using simple
cryptography APIs that are easier to use securely will improve your chances of
implementing secure systems.
