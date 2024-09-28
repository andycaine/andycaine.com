+++
title = 'We Need to Talk About ReDoS'
date = 2024-09-28T09:13:35+01:00
categories = ['Software Development']
tags = ['Secure Coding', 'Injection', 'ReDoS']
+++

ReDoS - the security threat that no-one knows about. At least that how it seems, every time I talk to developers about ReDoS and get blank looks. Or when the results of a code audit highlight a bunch of evil regular expressions.

We need to talk about ReDoS. In this post, I'll explain what ReDoS actually is, and what developers can do about it.

## What is ReDoS?
So, what is a ReDoS attack? ReDoS stands for Regular Expression Denial of Service. It's an attack where an attacker sends a specially crafted string designed to get a regular expression (regex) engine to consume excessive resources trying to find a match, leading to a denial of service.

ReDoS attacks exploit a feature of most regex engines called 'backtracking'. A backtracking regex engine essentially tries to find a match by trying to match the longest possible string, before 'backtracking' if it fails to find a match to try a different way of matching the pattern. In the worst case scenario, the time taken to find a match grows exponentially with the the length of the input string.

Let's take an example.  Consider the following regex:

> ^(a+)+$

This is what we call an 'evil' regex, because it is susceptible to 'catastrophic' backtracking. Let's work through what happens when we try to match this pattern against the string 'aaaaX'.

The first thing the regex engine will try to do is to match the entire string against the pattern. The match fails when it hits the 'X':

> (aaaa<span style='color: red;'>X</span>)

So, the engine 'backtracks'. It gives up one character in the match (the 'X') and tries to match it in a different way:

>(aaaa)(<span style='color: red;'>X</span>)

This fails, so again it 'backtracks', giving up another character to try a different way of matching the pattern:

>(aaa)(a<span style='color: red;'>X</span>)

And again it fails, and the backtracking continues:

>(aaa)(a)(<span style='color: red;'>X</span>)<br>
(aa)(aa<span style='color: red;'>X</span>)<br>
(aa)(aa)(<span style='color: red;'>X</span>)<br>
(aa)(a)(a<span style='color: red;'>X</span>)<br>
(aa)(a)(a)(<span style='color: red;'>X</span>)<br>
(a)(aaa<span style='color: red;'>X</span>)<br>
(a)(aaa)(<span style='color: red;'>X</span>)<br>
(a)(aa)(a<span style='color: red;'>X</span>)<br>
(a)(aa)(a)(<span style='color: red;'>X</span>)<br>
(a)(a)(aa<span style='color: red;'>X</span>)<br>
(a)(a)(aa)(<span style='color: red;'>X</span>)<br>
(a)(a)(a)(a<span style='color: red;'>X</span>)<br>
(a)(a)(a)(a)(<span style='color: red;'>X</span>)<br>

Finally, after 16 attempts, the backtracking engine has exhausted all possibilities and gives up. Now 16 match attempts isn't a lot, but consider the fact that the number of matches *doubles* for each addition character in the input. This means that if an attacker entered the following input string:

> aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaX

then the backtracking regex engine would have to try 549,755,813,888 matches. That's a lot of match attempts, and would likely chew up any process trying to handle it for a considerable amount of time (give it a go in your favourite language!).

## Defending against ReDoS
So what can developers do about ReDoS?  The first thing is to recognise problematic patterns. There are 3 types of problematic pattern:

1. Nested quantifiers, e.g. ^(a+)+$
2. Quantified overlapping disjunctions, e.g. ^(a|a)+$
3. Quantified overlapping adjacencies, e.g. \d+\d+

The second thing you can do is to use tried and tested regex patterns, such as those available at the [OWASP validation regex repository](https://owasp.org/www-community/OWASP_Validation_Regex_Repository).

The third thing you can do is to use tools to check your patterns. For example, this [ReDoS checker](https://devina.io/redos-checker) does a good job at identifying evil regexes. [CodeQL](https://codeql.github.com) is also pretty good at spotting evil patterns if you want something in you CI pipeline.

A final option is to use a regex engine that doesn't use backtracking. Rust's regex library, for example, uses an engine that avoids backtracking and guarantees linear-time matching.

So far I've assumed that we're matching user input against regex patterns defined in code. However, I've often seen code that treats input from the *user* as a regex, for example in a search function. Such code is particularly vulnerable to ReDoS because now the pattern itself is under the attackers control, making the attack much easier. Input validation and sanitisation is the best defence in these situations; be restrictive in what you allow in the user input (ideally don't allow any regexp meta characters) and sanitise the validated input before passing to a regex engine.

## Summary
ReDoS is an attack against vulnerable (AKA evil) regex patterns used with backtracking regex engines. A successful ReDoS attack causes the regex engine to get stuck, consuming large amounts of resources as it tries to find a match, resulting in a denial of service.

As a developer, there are a number of things you can do to protect against these attacks. These include learning to recognise evil patterns, using tried and tested patterns, using tooling, and - if possible - switching to a regex engine that doesn't use backtracking. And of course, it's always important to validate and sanitise untrusted input.
