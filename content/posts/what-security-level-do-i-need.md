+++
title = 'What Security Level Do I Need?'
date = 2024-06-08T09:30:29+01:00
categories = ['Software Development']
tags = ['Cryptography', 'Encryption' 'Software Development', 'Secure Coding']
+++

This system provides 128-bit security level.

Ever seen a statement like this, and wondered what it meant?

When we talk about security level, we're basically talking about the number of steps an attacker would need in order to break a cryptographic system. So taking the above statement, that means that any attack on that system would require at least 2<sup>128</sup> steps.

Let's take an example. Imagine an encryption system that uses a 128-bit key. Let's also assume that the only available attack on that system is through an exhaustive key search. That's 2<sup>128</sup> possible keys that the attacker would have to search through in order to find the right key. That's 2<sup>128</sup> steps, giving the system a 128-bit security level.

In reality of course, the attacker would expect to find the key in half as many steps, but that's still 2<sup>127</sup> steps. The concept of security level is only approximate so a 128-bit security level is still an appropriate measure of the strength of this system.

You might notice the rather vague use of the term 'step' here. In this example a step is an encryption and comparison operation. In another attack it might be a table lookup. It doesn't really matter; when we're talking about the huge number of steps required for a cryptographic attack, the relatively small differences in what we call a 'step' become insignificant.

So what security level should we be aiming for? A 128-bit security level is generally seen as a minimum for systems designed today. 2<sup>128</sup> is an enormous number; performing that many steps is computationally infeasible even with todays ultra fast GPUs and scalable cloud platforms and will remain so for the foreseeable future.

So our imaginary 128-bit key system is secure enough, right? Actually, no. There's another generic attack that means that our imaginary system fails to meet our desired security level of 128-bits.

## Birthday Attacks
Birthday attacks are named after the birthday paradox. If you have 23 people in a room, there is a greater than 50% chance that at least two of them will share the same birthday. Given that there are 365 possible birthdays, this is surprisingly likely.

The birthday attack, and the related meet-in-the-middle attack, uses the principles of the birthday paradox to attack cryptographic systems. These attacks rely on finding duplicate values - or collisions, which like the birthday paradox happen surprisingly quickly. The general rule is that if an element can take on *n* different values, then you can expect a collision after choosing about 2<sup>*n*/2</sup> values.

Let's take our 128-bit key encryption system again as an example to demonstrate a meet-in-the-middle attack. Imagine that Alice and Bob are using that system to communicate, selecting a fresh 128-bit key for each message. Let's also image that one block of that message is predictable and known to Eve - an email header for example. The birthday paradox means that if Eve pre-computes the ciphertext for that block for 2<sup>64</sup> random keys and then listens to Alice's messages, she can expect to find a collision for that block after listening to about 2<sup>64</sup> messages. That collision means that the pre-computed key for that block matches the one Alice is using, so Eve can decrypt that message.

So what does this mean? Our 128-bit key encryption system only has a security level of 64-bits; well below our desired security level. In general, to achieve an *n*-bit security level, all cryptographic values should be 2*n* long. In this case a 256-bit key would give us our desired security level.

Of course, things aren't quite that simple. For example most block ciphers today, including the venerable Advanced Encryption Standard (AES), only have a block size of 128-bits. This isn't the end of the world though; we can mitigate the risks associated with a smaller-than-ideal block size by selecting a [good mode of operation](https://en.wikipedia.org/wiki/Galois/Counter_Mode), and by rotating our encryption key before the volume of data encrypted under that key makes the risk of collisions unacceptable. As long as we do this then we can still say that an AES based encryption system with a 256-bit key has a 128-bit security level.

So, in summary, the security level of a system is basically the number of steps needed to break it. We should generally be aiming for a security level of 128-bits in systems built today. In order to achieve this security level we can follow a simple rule of thumb; all cryptographic values should be 256-bits long. That won't always be possible - as in the case with the 128-bit block size of modern block ciphers - but by understanding the implications of these limitations and mitigating them we can often still achieve our required 128-bit security level.
