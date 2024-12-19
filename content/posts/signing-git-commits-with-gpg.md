+++
title = 'Signing git commits with GPG'
date = 2024-12-14T09:13:35+01:00
categories = ['Software Development']
tags = ['GPG', 'Secure Coding']
+++

Signing commits with GPG is a useful technique for verifying the authenticity and integrity of code changes - here's how you can set it up.

## Creating keys

First you'll need to create a key-pair to start signing commits. Run the following command and follow the prompts (if in doubt accept the default settings).

```bash
gpg --full-generate-key
```

This should give you a primary key for signing and for certifying other keys, and a subkey for encryption:

```bash
gpg --list-secret-keys
------------------------
sec   ed25519 2024-12-19 [SC]
      10BAF1A94875F83112640CC9EC6D27F7601EFFDC
uid           [ultimate] Joe Bloggs <joe@example.com>
ssb   cv25519 2024-12-19 [E]
```

It's often recommended to create subkeys for day-to-day work, and then store your primary key offline. That way, you reduce the risk of compromise for your primary key, and you can easily revoke a compromised subkey and certify it with your primary key.  To do that, first create a subkey for signing:

```bash
gpg --edit-key 10BAF1A94875F83112640CC9EC6D27F7601EFFDC
gpg> addkey
```

Select a "sign only" (e.g. an ECC key), follow the rest of the prompts and save:

```bash
gpg> save
```

You'll now have two subkeys, one of which you can use for signing:

```bash
gpg --list-secret-keys
------------------------
sec   ed25519 2024-12-19 [SC]
      10BAF1A94875F83112640CC9EC6D27F7601EFFDC
uid           [ultimate] Joe Bloggs <joe@example.com>
ssb   cv25519 2024-12-19 [E]
ssb   ed25519 2024-12-19 [S] [expires: 2025-12-19]
```

## Exporting keys

To store your primary key safely offline, you'll need to export it:

```bash
gpg --export-secret-keys 10BAF1A94875F83112640CC9EC6D27F7601EFFDC > primary.key
```

You can also separately export the subkeys, to make it easier to import just your subkeys in the future:

```bash
gpg --export-secret-subkeys 10BAF1A94875F83112640CC9EC6D27F7601EFFDC > subkeys.key
```

You can also export your public key and share with anyone you want to be able to verify your commits, including uploading to services like github and gitlab:

```bash
gpg -a --export 10BAF1A94875F83112640CC9EC6D27F7601EFFDC > public.asc
```

Now another user can import that public key to use for verifying commits (more on that later...):

Once you've safely backed up your keys, you can delete your primary key:

```bash
gpg --delete-secret-key 10BAF1A94875F83112640CC9EC6D27F7601EFFDC
```

Answer 'n' when asked if you want to delete your subkeys, or just delete everything and re-import just the subkeys.

## Importing keys

To import just the subkeys:

```bash
gpg --import subkeys.key
```

To double check that you no longer have the primary key in your keyring, look for the little '#' symbol next to your primary key:

```bash
gpg --list-secret-keys
------------------------
sec#  ed25519 2024-12-19 [SC]
      10BAF1A94875F83112640CC9EC6D27F7601EFFDC
uid           [ultimate] Joe Bloggs <joe@example.com>
ssb   cv25519 2024-12-19 [E]
ssb   ed25519 2024-12-19 [S] [expires: 2025-12-19]
```


## Configuring git to sign commits

To configure git to sign commits, first get the key ID of the key you want to use for signing:

```bash
gpg --list-keys --with-subkey-fingerprint
------------------------
pub   ed25519 2024-12-19 [SC]
      10BAF1A94875F83112640CC9EC6D27F7601EFFDC
uid           [ultimate] Joe Bloggs <joe@example.com>
sub   cv25519 2024-12-19 [E]
      326FD13C60A54DC334304F96D3947C1D2BD8C48A
sub   ed25519 2024-12-19 [S] [expires: 2025-12-19]
      55DF9F370F923B743D995E6A4413D16EF0639625
```

Now we can tell git to use that key for signing in your git config file (e.g. ~/.gitconfig):

```
[user]
  name = Joe Bloggs
  email = joe@example.com
  signingkey = 55DF9F370F923B743D995E6A4413D16EF0639625
[commit]
  gpgSign = true
```

Now git will sign your commits (you might need to `export GPG_TTY=$(tty)` in your shell config to make sure gpg is using the correct terminal for passphrase entry).

## Verifying commits

To verify the authenticity and integrity of a commit, another user will have to install your public key:

```bash
gpg --import public.asc
```

They'll also need to sign your public key to indicate that they trust it, once they've confirmed it really is your key...

```bash
gpg --sign-key 10BAF1A94875F83112640CC9EC6D27F7601EFFDC
```

Now they can verify the signature on a commit:

```bash
git log -1 --show-signature
commit 8565412d99a679757f9ded4147d174383e40a584 (HEAD -> main)
gpg: Signature made Thu Dec 19 15:57:17 2024 GMT
gpg:                using EDDSA key 55DF9F370F923B743D995E6A4413D16EF0639625
gpg: Good signature from "Joe Bloggs <joe@example.com>" [full]
Author: Joe Bloggs <joe@example.com>
Date:   Thu Dec 19 15:57:17 2024 +0000
```

Here we can see that the signature is good, so we can trust the commit as much as we trust that public key.
