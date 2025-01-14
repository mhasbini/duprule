use std::collections::HashMap;
use std::fs::File;
use std::io::{BufWriter, Lines, StdinLock, Write};

mod char_case;
mod rule;
mod slot;
mod slots_map;
mod value;

use rule::*;

#[cfg(test)]
#[cfg(feature = "pretty_assertions")]
#[macro_use]
extern crate pretty_assertions;

#[derive(Clone)]
struct ParsedLine {
    original_line: String,
    ast_len: usize,
    is_main: bool,
}

pub struct DupRule;

impl DupRule {
    fn deduplicate_input(
        lines: Lines<StdinLock>,
    ) -> (Vec<ParsedLine>, HashMap<usize, Vec<String>>) {
        let mut all_lines = Vec::new();
        let mut duplicates_map = HashMap::new();
        let mut main_index_for_hash: HashMap<u64, usize> = HashMap::new();

        for raw_line_result in lines {
            let raw_line = match raw_line_result {
                Ok(l) => l,
                Err(e) => {
                    eprintln!("Error reading line: {}", e);
                    continue;
                }
            };

            match Rule::parse(&raw_line) {
                Err(_) => {
                    all_lines.push(ParsedLine {
                        original_line: raw_line,
                        ast_len: 0,
                        is_main: true,
                    });
                }
                Ok(rule) => {
                    let function_count = rule.function_count();
                    let hash = Rule::hash(&rule);

                    if let Some(&old_main_idx) = main_index_for_hash.get(&hash) {
                        let old_main_ast_len = all_lines[old_main_idx].ast_len;

                        if function_count < old_main_ast_len {
                            all_lines[old_main_idx].is_main = false;

                            let new_idx = all_lines.len();
                            all_lines.push(ParsedLine {
                                original_line: raw_line,
                                ast_len: function_count,
                                is_main: true,
                            });

                            duplicates_map
                                .entry(new_idx)
                                .or_insert_with(Vec::new)
                                .push(all_lines[old_main_idx].original_line.clone());

                            main_index_for_hash.insert(hash, new_idx);
                        } else {
                            let new_idx = all_lines.len();
                            all_lines.push(ParsedLine {
                                original_line: raw_line,
                                ast_len: function_count,
                                is_main: false,
                            });

                            duplicates_map
                                .entry(old_main_idx)
                                .or_insert_with(Vec::new)
                                .push(all_lines[new_idx].original_line.clone());
                        }
                    } else {
                        let new_idx = all_lines.len();
                        all_lines.push(ParsedLine {
                            original_line: raw_line,
                            ast_len: function_count,
                            is_main: true,
                        });
                        main_index_for_hash.insert(hash, new_idx);
                    }
                }
            }
        }

        (all_lines, duplicates_map)
    }

    fn print_results(
        all_lines: &[ParsedLine],
        duplicates_map: &HashMap<usize, Vec<String>>,
        output: Option<&mut File>,
    ) {
        let stdout = std::io::stdout();
        let mut out_stream = BufWriter::new(stdout.lock());

        for (_idx, parsed_line) in all_lines.iter().enumerate() {
            if parsed_line.is_main {
                writeln!(out_stream, "{}", parsed_line.original_line)
                    .expect("Failed to write to stdout");
            }
        }

        if let Some(file) = output {
            for (&main_idx, dups) in duplicates_map {
                if !dups.is_empty() {
                    let main_line = &all_lines[main_idx].original_line;
                    writeln!(file, "{} -> {:?}", main_line, dups)
                        .expect("Failed to write to duplicates file");
                }
            }
        }
    }

    pub fn new(lines: Lines<StdinLock>) {
        let (all_lines, duplicates_map) = Self::deduplicate_input(lines);
        Self::print_results(&all_lines, &duplicates_map, None);
    }

    pub fn new_with_output(lines: Lines<StdinLock>, output: &mut File) {
        let (all_lines, duplicates_map) = Self::deduplicate_input(lines);
        Self::print_results(&all_lines, &duplicates_map, Some(output));
    }

    pub fn print_supported_rules() {
        let supported_rules = [
            ':', 'l', 'u', 'c', 'C', 't', 'T', 'r', 'd', 'p', 's', 'f', '{', '}', '$', '^', '[',
            ']', 'D', 'x', 'O', 'i', 'o', '\'', '@', 'z', 'Z', 'q', 'k', 'K', '*', '.', ',', 'y',
            'Y',
        ];

        for rule in supported_rules.iter() {
            println!("{}", rule);
        }
    }
}
