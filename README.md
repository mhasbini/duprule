# duprule

![](https://travis-ci.org/0xbsec/duprule.svg?branch=master)

# How does it works ?

Each rule change is mapped, and a uniq id is generated for each rule with functions count.

# Usage

`duprule.pl` take input rules from STDIN.

Example: `perl duprule.pl < /tmp/rockyou.rule`

Will print uniq, without order, rules to STDOUT. And save duplicate rules to `duplicates.txt`.
