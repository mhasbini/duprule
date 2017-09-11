extern crate duprule;
use duprule::DupRule;

use std::io::{stdin, BufRead};
use std::fs::File;
use std::process::exit;
use std::env::args;

fn main() {
    for arg in args() {
        match &* arg {
            "-h" | "--help" => show_help(),
            "-v" | "--version" => show_version(),
            "-s" | "--supported" => show_supported(),
            _ => continue,
        }
    }

    let handler = stdin();

    let mut output = None;

    if let Some(idx) = args().rposition(|a| a == "-o" || a == "--output") {
        output = Some(args().nth(idx + 1));
    }

    match output {
        None => DupRule::new(handler.lock().lines()),
        Some(None) => {
            eprintln!("Missing output file name");
            exit(1);
        },
        Some(Some(output)) => {
            match File::create(output) {
                Err(e) => {
                    eprintln!("Failed to create output file: {}", e);
                    exit(1);
                },
                Ok(mut fh) => DupRule::new_with_output(handler.lock().lines(), &mut fh)
            }
        }
    }
}

fn show_help() {
    println!("
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
    ");

    exit(0);
}

fn show_version() {
    println!("{}", env!("CARGO_PKG_VERSION"));

    exit(0);
}

fn show_supported() {
    DupRule::print_supported_rules();

    exit(0);
}
