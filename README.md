# duprule

![](https://travis-ci.org/0xbsec/duprule.svg?branch=master)

# What

Remove duplicate Hashcat rules.

# How does it works ?

TL;DR: Each rule change is mapped, and a unique id is generated for each rule with functions count.

The mechanism is like this:

- A blank map is created with N ( from 1 to 36 ) slots.
- Each rule change will be applied to the map.
    Example rule: 'u', will change all characters cases from '?' ( unknown ) to 'u' ( upper case ).
    'sab', will add {'a' -> 'b'} to the map. And same logic apply for the other rules.
- An id is generated from the map.
- The ids are compared to detect duplicate rules.
- The rule with the least functions count will be selected.

# Which rules are supported ?

All rules on [this page](https://hashcat.net/wiki/doku.php?id=rule_based_attack) are supported except:

    - Memory rules: X, 4, 6, M
    - Reject plains rules
    - L, R, +, -
    - E, e

# Usage

```
Remove duplicate Hashcat rules.

Usage:
    duprule [options] < input


Reads input from STDIN and prints to STDOUT.

Options:
    -o, --output      optional	 file to write duplicate rules to
    -v, --version     optional	 print version info
    -h, --help        optional	 print this help message
    -s, --supported   optional	 list all supported rules

Examples:

duprule < rockyou.rule > rockyou.rule.uniq
duprule -o duplicates.txt < rockyou.rule > rockyou.rule.uniq
```

# Installation

duprule is written in Rust.

```
# run dev after clonning:
cargo run < input.rule
cargo run < input.rule -- -o duplicates.txt
```
