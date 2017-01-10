# duprule

![](https://travis-ci.org/0xbsec/duprule.svg?branch=master)

# Why ?

Remove duplicate rules.

# How does it works ?

TL;DR: Each rule change is mapped, and a unique id is generated for each rule with functions count.

The mechanism is like this:

- A blank map is created with $n ( from 1 to 37 ) default characters.
- Each rule change will be applied to the map.
    Example rule: 'u', will change all characters cases from '?' ( unknown ) to 'u' ( upper case ).
    'sab', will add {'a' -> 'b'} to the map. And same logic apply for the other rules.
- An id is generated from the map.
- The ids are compared to detect duplicate rules.
- The rule with the least functions count will be choosed. ( there's a plan to add readability  to select the rule, check issue #4 for updates ).

# Which rules are supported ?

Currently all rules on [this page](https://hashcat.net/wiki/doku.php?id=rule_based_attack) are supported except:

    - Memory rules: X, 4, 6, M
    - Reject plains rules
    - E

# Usage

```
Usage: perl duprule.pl [options] < input_rules > uniq_rules
	options:
		-o	 optional	 file to write duplicate rules to
		-h	 optional	 print this help message
```

`duprule.pl` read input rules from STDIN and write uniq or unsupported rules to STDOUT.
If `-o` option is defined then save duplicate rules to the provided file.

Use cases:
  - `perl duprule.pl < rockyou.rule > rockyou.rule.uniq`
  - `perl duprule.pl -o duplicates.txt < rockyou.rule > rockyou.rule.uniq`
  - `perl duprule.pl -h`
