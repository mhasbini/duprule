use std::collections::HashMap;
use std::io::Write;
use std::io::stdout;
use std::io::BufWriter;

mod char_case;
mod value;
mod slot;
mod slots_map;
mod rule;

use rule::*;

#[cfg(test)]
#[cfg(feature = "pretty_assertions")]
#[macro_use]
extern crate pretty_assertions;

pub struct DupRule;

impl DupRule {
    pub fn new(lines: std::io::Lines<std::io::StdinLock>) {
        let mut checked: HashMap<u64, ()> = HashMap::new();

        let stdout = stdout();
        let handle = stdout.lock();
        let mut stream = BufWriter::new(handle);

        for raw_rule in lines {
            let raw_rule = raw_rule.unwrap();

            match Rule::parse(&raw_rule) {
                Err(_) => writeln!(stream, "{}", raw_rule).unwrap(),
                Ok(rule) => {
                    let key = Rule::hash(rule);

                    if !checked.contains_key(&key) {
                        writeln!(stream, "{}", raw_rule).unwrap();
                        checked.insert(key, ());
                    }
                }
            }
        }
    }

    pub fn new_with_output(lines: std::io::Lines<std::io::StdinLock>, output: &mut std::fs::File) {
        let mut checked: HashMap<u64, (String, Vec<String>)> = HashMap::new();

        let stdout = stdout();
        let handle = stdout.lock();
        let mut stream = BufWriter::new(handle);

        for raw_rule in lines {
            let raw_rule = raw_rule.unwrap();

            match Rule::parse(&raw_rule) {
                Err(_) => writeln!(stream, "{}", raw_rule).unwrap(),
                Ok(rule) => {
                    let key = Rule::hash(rule);

                    if checked.contains_key(&key) {
                        let dups = checked.get_mut(&key).unwrap();
                        dups.1.push(raw_rule);
                    } else {
                        writeln!(stream, "{}", raw_rule).unwrap();
                        checked.insert(key, (raw_rule, Vec::new()));
                    }
                }
            }
        }

        for (_, dups) in checked {
            let (original, duplicates) = dups;
            if !duplicates.is_empty() {
                writeln!(output, "{} -> {:?}", original, duplicates).unwrap();
            }
        }
    }

    pub fn print_supported_rules() {
        let supported_rules = [
            ':', 'l', 'u', 'c', 'C', 't', 'T', 'r', 'd', 'p', 's', 'f',
            '{', '}', '$', '^', '[', ']', 'D', 'x', 'O', 'i', 'o', '\'',
            '@', 'z', 'Z', 'q', 'k', 'K', '*', '.', ',', 'y', 'Y'
        ];

        for rule in supported_rules.iter() {
            println!("{}", rule);
        }
    }
}
