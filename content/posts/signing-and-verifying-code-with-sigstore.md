+++
title = 'Signing and Verifying Code with Sigstore'
date = 2025-09-08T09:13:35+01:00
categories = ['Software Development']
tags = ['PyPi', 'Secure Coding', 'Code signing']
+++

## Sigstore Basics

Let's start with a really simple example of keyless signing using `sigstore`:

First, install [sigstore](https://github.com/sigstore/sigstore-python) if you
don't already have it.  E.g. with `brew:

```bash
brew install sigstore
```

Then, sign a file:

```bash
sigstore sign README.md
```

This should ask you to authenticate with an IdP to obtain an OIDC identity
token. Behind the scenes, Sigstore creates a new local ephemeral keypair, then
uses the OIDC identity token to create a Certificate Signing Request for the
keypair which it sends to Fulcio. Sigstore receives the Signed Certificate
Timestamp (SCT), Certificate and intermediate chain from Fulcio. Sigtore then
signs the input using the ephemeral private key, publishes the signature, the
inputs hash, and the signing certificate to the certificate transparency log -
Rekor.  Finally Sigstore saves the verifications materials locally, in a
Sigstore bundle at README.md.sigstore.json.

We can extract the certificate from the bundle and inspect it with `openssl`:

```bash
jq -r .verificationMaterial.certificate.rawBytes README.md.sigstore.json \
  | base64 -d > README.crt
openssl x509 -in README.md.crt -inform DER -text -noout
```

The certificate's extensions show the Sigstore entries for our signing
identity:

```X509v3
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage: 
                Code Signing
            X509v3 Subject Key Identifier: 
                FF:42:28:64:01:92:38:30:5C:3A:2B:1F:02:0D:9E:7E:74:F3:77:F5
            X509v3 Authority Key Identifier: 
                DF:D3:E9:CF:56:24:11:96:F9:A8:D8:E9:28:55:A2:C6:2E:18:64:3F
            X509v3 Subject Alternative Name: critical
                email:andy@hyperscale.consulting
            1.3.6.1.4.1.57264.1.1: 
                https://accounts.google.com
            1.3.6.1.4.1.57264.1.8: 
                ..https://accounts.google.com
            CT Precertificate SCTs: 
                Signed Certificate Timestamp:
                    Version   : v1 (0x0)
                    Log ID    : DD:3D:30:6A:C6:C7:11:32:63:19:1E:1C:99:67:37:02:
                                A2:4A:5E:B8:DE:3C:AD:FF:87:8A:72:80:2F:29:EE:8E
                    Timestamp : Sep  7 12:58:27.052 2025 GMT
                    Extensions: none
                    Signature : ecdsa-with-SHA256
                                30:45:02:21:00:E4:9B:E8:34:65:30:70:C6:E8:C7:5C:
                                4E:79:09:D2:7A:43:9E:48:9E:EA:AD:C6:21:06:A3:5B:
                                2D:17:26:57:65:02:20:34:C5:F0:B8:98:02:F4:67:58:
                                D4:7B:69:19:BF:C9:A1:56:18:94:7C:AA:CB:2A:9A:B1:
                                D1:80:54:C2:52:98:DD
```

We can get Sigstore to verify the certificate and signature for us:

```bash
sigstore verify identity \
  --bundle README.md.sigstore.json \
  --cert-identity andy@hyperscale.consulting \
  --cert-oidc-issuer https://accounts.google.com README.md
OK: README.md
```

This confirms that the certificate and signature checks out as expected, and
that the Rekor transparency log contains the expected entries.  We can also
check the Rekor log manually. Install `rekor-cli`:

```bash
brew install rekor-cli
```

Get the log index from the Sigstore bundle:

```bash
jq -r ".verificationMaterial.tlogEntries[].logIndex" README.md.sigstore.json
481896712
```

Find the signing certificate in the Rekor log:

```bash
rekor-cli get \
  --log-index 481896712 \
  --format json \
    | jq -r .Body.HashedRekordObj.signature.publicKey.content 
    | base64 -d > README.md.pem
openssl x509 -in README.md.pem -text -noout
```

This should show that the same signing certificate included in the Sigstore
bundle was indeed included in the Rekor log.

## Verifying Python Packages

Since version 1.11.0 of `pypa/gh-action-pypi-publish`, packages published to
pypi have had packages built with attestations and signed using the Sigstore
ecosystem, allowing for packages to be easily verified using
`pypi-attestations`:

```bash
pip install pypi-attestations
pypi-attestations verify pypi --repository https://github.com/andycaine/nsst pypi:nsst-0.3.3.tar.gz
```

And we can verify packages locally:

```bash
pip download nsst==0.3.3 --no-deps
curl https://pypi.org/integrity/nsst/0.3.3/nsst-0.3.3-py3-none-any.whl/provenance \
  | jq '.attestation_bundles[0].attestations[0]' \
  > nsst-0.3.3-py3-none-any.whl.publish.attestation
pypi-attestations verify attestation \
  --identity https://github.com/andycaine/nsst/.github/workflows/python-publish.yml@refs/tags/v0.3.3 \
  nsst-0.3.3-py3-none-any.whl
```

## Signing and Verifying Other Packages

Non-python projects can use
[slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)
to generate provenance. There are generators for various different languages,
plus language agnostic options.

Provenance generated by `slsa-github-generator` can be verified using [slsa-verifier](https://github.com/slsa-framework/slsa-verifier):

```bash
wget https://github.com/hyperscale-consulting/awseal/releases/download/v0.3.0/awseal-v0.3.0.tar.gz
wget https://github.com/hyperscale-consulting/awseal/releases/download/v0.3.0/awseal-v0.3.0.tar.gz.intoto.jsonl
slsa-verifier verify-artifact awseal-v0.3.0.tar.gz \
  --provenance-path awseal-v0.3.0.tar.gz.intoto.jsonl \
  --source-uri github.com/hyperscale-consulting/awseal \
  --source-tag v0.3.0
```

Just like before, we can extract and view the certificate:

```bash
jq -r .verificationMaterial.certificate.rawBytes awseal-v0.3.0.tar.gz.intoto.jsonl \
  | base64 -d > awseal.crt
openssl x509 -in awseal.crt -inform DER -text -noout
```

And we can also view the provenance claims:

```bash
jq -r .dsseEnvelope.payload awseal-v0.3.0.tar.gz.intoto.jsonl | base64 -d | jq
```
