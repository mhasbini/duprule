use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

use slots_map::SlotsMap;

// Maximum slots to create that the rule can affect
// currently hashcat only allow rules to use positions: 0 .. 9 + A .. Z (10 + 26 = 36)
const RULE_MAX: usize = 36;

struct Char(char);

struct Num(usize);

impl Num {
    pub fn conv(c: char) -> Result<Num, String> {
        if c.class_num() || c.class_upper() {
            if let Some(num) = c.to_digit(RULE_MAX as u32) {
                Ok(Num(num as usize))
            } else {
                Err(format!("Invalid positions: {}", c))
            }
        } else {
            Err(format!("Invalid positions: {}", c))
        }
    }
}

#[allow(non_camel_case_types)]
enum RuleFn {
    NOOP,
    LREST,
    UREST,
    LREST_UFIRST,
    UREST_LFIRST,
    TREST,
    TOGGLE_AT(Num),
    REVERSE,
    DUPEWORD,
    DUPEWORD_TIMES(Num),
    REFLECT,
    ROTATE_LEFT,
    ROTATE_RIGHT,
    APPEND(Char),
    PREPEND(Char),
    DELETE_FIRST,
    DELETE_LAST,
    DELETE_AT(Num),
    EXTRACT(Num, Num),
    OMIT(Num, Num),
    INSERT(Num, Char),
    OVERSTRIKE(Num, Char),
    TRUNCATE_AT(Num),
    REPLACE(Char, Char),
    PURGECHAR(Char),
    DUPECHAR_FIRST(Num),
    DUPECHAR_LAST(Num),
    DUPECHAR_ALL,
    SWITCH_FIRST,
    SWITCH_LAST,
    SWITCH_AT(Num, Num),
    REPLACE_NP1(Num),
    REPLACE_NM1(Num),
    DUPEBLOCK_FIRST(Num),
    DUPEBLOCK_LAST(Num),
    // CHR_SHIFTL(Num),
    // CHR_SHIFTR(Num),
    // CHR_INCR(Num),
    // CHR_DECR(Num),
    // MEMORIZE_WORD,
    // PREPEND_MEMORY,
    // APPEND_MEMORY,
    // EXTRACT_MEMORY(Num, Num, Num)
}

pub struct Rule {
    // rule: String,
    ast: Vec<RuleFn>,
    // fcount: usize
}

macro_rules! push_next {
    ($it:ident, $ast:ident, $fn:path) => ({
        $it.next();
        $ast.push($fn);
    })
}

macro_rules! push_next_num {
    ($it:ident, $ast:ident, $fn:path) => ({
        $it.next();
        match $it.peek() {
            None => return Err(format!("Missing argument for {:?} function", stringify!($fn))),
            Some(_) =>
                match Num::conv($it.next().unwrap()) {
                    Ok(pos) => $ast.push($fn(pos)),
                    Err(e) => return Err(e)
                }
        }
    })
}

macro_rules! push_next_num_num {
    ($it:ident, $ast:ident, $fn:path) => ({
        $it.next();
        if $it.peek().is_none() {
            return Err(format!("Missing position argument for {:?} function", stringify!($fn)));
        }
        let n1 = Num::conv($it.next().unwrap());
        if let Err(e) = n1 {
            return Err(e);
        }

        if $it.peek().is_none() {
            return Err(format!("Missing position argument for {:?} function", stringify!($fn)));
        }
        let n2 = Num::conv($it.next().unwrap());
        if let Err(e) = n2 {
            return Err(e);
        }

        $ast.push($fn(n1.unwrap(), n2.unwrap()))
    })
}

macro_rules! push_next_char {
    ($it:ident, $ast:ident, $fn:path) => ({
        $it.next();
        if $it.peek().is_none() {
            return Err(format!("Missing argument for {:?} function", stringify!($fn)));
        }
        $ast.push($fn(Char($it.next().unwrap())))
    })
}

macro_rules! push_next_char_char {
    ($it:ident, $ast:ident, $fn:path) => ({
        $it.next();
        if $it.peek().is_none() {
            return Err(format!("Missing argument for {:?} function", stringify!($fn)));
        }
        let c0 = $it.next().unwrap();

        if $it.peek().is_none() {
            return Err(format!("Missing argument for {:?} function", stringify!($fn)));
        }

        let c1 = $it.next().unwrap();

        $ast.push($fn(Char(c0), Char(c1)))
    })
}


macro_rules! push_next_num_char {
    ($it:ident, $ast:ident, $fn:path) => ({
        $it.next();

        match $it.peek() {
            None => return Err(format!("Missing argument for {:?} function", stringify!($fn))),
            Some(_) =>
                match Num::conv($it.next().unwrap()) {
                    Err(e) => return Err(e),
                    Ok(pos) => {
                        if $it.peek().is_none() {
                            return Err(
                                format!("Missing argument for {:?} function", stringify!($fn))
                            );
                        }

                        let c = $it.next().unwrap();

                        $ast.push($fn(pos, Char(c)))
                    }
                }
        }
    })
}

macro_rules! next {
    ($it:ident) => ({
        $it.next();
    })
}

impl Rule {

    #[cfg(test)]
    pub fn new(rule: &str) -> Rule {
        match Rule::parse(rule) {
            Ok(parsed) => parsed,
            Err(e) => panic!("rule `{}` is invalid: '{}'", rule, e),
        }
    }

    pub fn parse(rule: &str) -> Result<Rule, String> {
        match Rule::tokenize(rule) {
            Ok(ast) => Ok(Rule {
                ast: ast,
            }),
            Err(e) => Err(e),
        }
    }

    fn tokenize(rule: &str) -> Result<Vec<RuleFn>, String> {
        if rule == "" {
            return Err("Empty rule".to_string());
        }

        let mut ast: Vec<RuleFn> = Vec::new();

        let mut it = rule.chars().peekable();

        while let Some(&c) = it.peek() {
            match c {
                ':' => push_next!(it, ast, RuleFn::NOOP),
                'l' => push_next!(it, ast, RuleFn::LREST),
                'u' => push_next!(it, ast, RuleFn::UREST),
                'c' => push_next!(it, ast, RuleFn::LREST_UFIRST),
                'C' => push_next!(it, ast, RuleFn::UREST_LFIRST),
                't' => push_next!(it, ast, RuleFn::TREST),
                'T' => push_next_num!(it, ast, RuleFn::TOGGLE_AT),
                'r' => push_next!(it, ast, RuleFn::REVERSE),
                'd' => push_next!(it, ast, RuleFn::DUPEWORD),
                'p' => push_next_num!(it, ast, RuleFn::DUPEWORD_TIMES),
                's' => push_next_char_char!(it, ast, RuleFn::REPLACE),
                'f' => push_next!(it, ast, RuleFn::REFLECT),
                '{' => push_next!(it, ast, RuleFn::ROTATE_LEFT),
                '}' => push_next!(it, ast, RuleFn::ROTATE_RIGHT),
                '$' => push_next_char!(it, ast, RuleFn::APPEND),
                '^' => push_next_char!(it, ast, RuleFn::PREPEND),
                '[' => push_next!(it, ast, RuleFn::DELETE_FIRST),
                ']' => push_next!(it, ast, RuleFn::DELETE_LAST),
                'D' => push_next_num!(it, ast, RuleFn::DELETE_AT),
                'x' => push_next_num_num!(it, ast, RuleFn::EXTRACT),
                'O' => push_next_num_num!(it, ast, RuleFn::OMIT),
                'i' => push_next_num_char!(it, ast, RuleFn::INSERT),
                'o' => push_next_num_char!(it, ast, RuleFn::OVERSTRIKE),
                '\'' => push_next_num!(it, ast, RuleFn::TRUNCATE_AT),
                '@' => push_next_char!(it, ast, RuleFn::PURGECHAR),
                'z' => push_next_num!(it, ast, RuleFn::DUPECHAR_FIRST),
                'Z' => push_next_num!(it, ast, RuleFn::DUPECHAR_LAST),
                'q' => push_next!(it, ast, RuleFn::DUPECHAR_ALL),
                'k' => push_next!(it, ast, RuleFn::SWITCH_FIRST),
                'K' => push_next!(it, ast, RuleFn::SWITCH_LAST),
                '*' => push_next_num_num!(it, ast, RuleFn::SWITCH_AT),
                '.' => push_next_num!(it, ast, RuleFn::REPLACE_NP1),
                ',' => push_next_num!(it, ast, RuleFn::REPLACE_NM1),
                'y' => push_next_num!(it, ast, RuleFn::DUPEBLOCK_FIRST),
                'Y' => push_next_num!(it, ast, RuleFn::DUPEBLOCK_LAST),
                // 'L' => push_next_num!(it, ast, RuleFn::CHR_SHIFTL),
                // 'R' => push_next_num!(it, ast, RuleFn::CHR_SHIFTR),
                // '+' => push_next_num!(it, ast, RuleFn::CHR_INCR),
                // '-' => push_next_num!(it, ast, RuleFn::CHR_DECR),
                // 'M' => push_next!(it, ast, RuleFn::MEMORIZE_WORD),
                // '4' => push_next!(it, ast, RuleFn::APPEND_MEMORY),
                // '6' => push_next!(it, ast, RuleFn::PREPEND_MEMORY),
                // 'X' => push_next_num_num_num!(it, ast, RuleFn::EXTRACT_MEMORY),
                ' ' => next!(it),
                f => return Err(format!("unsupported function: {}", f)),
            }
        }

        Ok(ast)
    }

    pub fn eval(rule: Rule) -> Vec<SlotsMap> {
        let mut result: Vec<SlotsMap> = Vec::with_capacity(RULE_MAX);

        for id in 1..(RULE_MAX + 1) {
            let mut map = SlotsMap::new(id);

            for fun in &rule.ast {
                match *fun {
                    RuleFn::NOOP => continue,
                    RuleFn::LREST => map.lrest(),
                    RuleFn::UREST => map.urest(),
                    RuleFn::LREST_UFIRST => map.lrest_ufirst(),
                    RuleFn::UREST_LFIRST => map.urest_lfirst(),
                    RuleFn::TREST => map.trest(),
                    RuleFn::TOGGLE_AT(Num(pos)) => map.toggle_at(pos),
                    RuleFn::REVERSE => map.reverse(),
                    RuleFn::DUPEWORD => map.dupeword(),
                    RuleFn::DUPEWORD_TIMES(Num(times)) => map.dupeword_times(times),
                    RuleFn::REFLECT => map.reflect(),
                    RuleFn::ROTATE_LEFT => map.rotate_left(),
                    RuleFn::ROTATE_RIGHT => map.rotate_right(),
                    RuleFn::APPEND(Char(c)) => map.append(c),
                    RuleFn::PREPEND(Char(c)) => map.prepend(c),
                    RuleFn::DELETE_FIRST => map.delete_first(),
                    RuleFn::DELETE_LAST => map.delete_last(),
                    RuleFn::DELETE_AT(Num(pos)) => map.delete_at(pos),
                    RuleFn::INSERT(Num(pos), Char(c)) => map.insert(pos, c),
                    RuleFn::OVERSTRIKE(Num(pos), Char(c)) => map.overstrike(pos, c),
                    RuleFn::TRUNCATE_AT(Num(pos)) => map.truncate_at(pos),
                    RuleFn::PURGECHAR(Char(c)) => map.purgechar(c),
                    RuleFn::DUPECHAR_FIRST(Num(times)) => map.dupechar_first(times),
                    RuleFn::DUPECHAR_LAST(Num(times)) => map.dupechar_last(times),
                    RuleFn::DUPECHAR_ALL => map.dupechar_all(),
                    RuleFn::SWITCH_FIRST => map.switch_first(),
                    RuleFn::SWITCH_LAST => map.switch_last(),
                    RuleFn::OMIT(Num(start), Num(end)) => map.omit(start, end),
                    RuleFn::EXTRACT(Num(start), Num(end)) => map.extract(start, end),
                    RuleFn::SWITCH_AT(Num(src), Num(dest)) => map.switch_at(src, dest),
                    RuleFn::REPLACE(Char(from), Char(to)) => map.replace(from, to),
                    RuleFn::REPLACE_NP1(Num(pos)) => map.replace_np1(pos),
                    RuleFn::REPLACE_NM1(Num(pos)) => map.replace_nm1(pos),
                    RuleFn::DUPEBLOCK_FIRST(Num(pos)) => map.dupeblock_first(pos),
                    RuleFn::DUPEBLOCK_LAST(Num(pos)) => map.dupeblock_last(pos),
                }
            }

            result.push(map);
        }

        result
    }

    // pub fn hash<T: Hash>(t: &T) -> u64 {
    pub fn hash(rule: Rule) -> u64 {
        let evaled = Rule::eval(rule);
        Rule::calculate_hash(&evaled)
    }

    fn calculate_hash<T: Hash>(t: &T) -> u64 {
        let mut s = DefaultHasher::new();
        t.hash(&mut s);
        s.finish()
    }

}

trait Class {
    fn class_num(&self) -> bool;
    fn class_upper(&self) -> bool;
}

impl Class for char {
    fn class_num(&self) -> bool {
        (*self >= '0') && (*self <= '9')
    }

    fn class_upper(&self) -> bool {
        (*self >= 'A') && (*self <= 'Z')
    }
}

#[cfg(test)]
pub mod test {
    use super::Rule;

    #[cfg(test)]
    macro_rules! same {
        ($first:expr, $($next:expr),+) => {
            $({
                assert_eq!(
                    Rule::eval(Rule::new($first)),
                    Rule::eval(Rule::new($next)),
                    "`{}` should eq `{}`", $first, $next
                );
            })*
        }
    }

    #[cfg(test)]
    macro_rules! diff {
        ($lone:expr) => ();
        ($first:expr, $($next:expr),+) => (
            diff!($($next),+);
            $({
                assert_ne!(
                    Rule::eval(Rule::new($first)),
                    Rule::eval(Rule::new($next)),
                    "`{}` should ne `{}`", $first, $next
                );
            })*
        )
    }

    #[test]
    fn test_noop() {
        same!(":", "::", "::::");
        diff!(":", "l:", "u:");
    }

    #[test]
    fn test_noop_should_not_be_affected_by_case() {
        same!(":l", ":l:", "l");
        same!(":u", ":u:", "u");
    }

    #[test]
    fn test_lrest() {
        same!("l", "ll", "ul", "ulul");
        diff!("l", "u");
        diff!("lsaB", "l", "lsab", "sabl", "sAbl");
    }

    #[test]
    fn test_urest() {
        same!("u", "uu", "lu", "ululu");
        diff!("u", "l");
        diff!("usAb", "u", "usAB", "sabu", "sAbu");
    }

    #[test]
    fn test_replace() {
        same!("sab", "sabsaa", "sabsab");
        same!("sabscd", "scdsab");
        same!("sabsbc", "sacsbc");
        same!("sacsca", "sca");
        same!("sab sdc smn", "sdc sab smn");
        same!("r sab sca", "r sab sca");
        diff!("sabsbc", "sbcsab", "sac", "sbc");
        diff!("lsab", "sabl", "lsaB");
    }

    #[test]
    fn test_replace_should_take_order_into_account() {
        same!("sabsdc", "sdcsab");
    }

    #[test]
    fn test_replace_should_take_case_into_account() {
        same!("lsAb", "l", "lsAB");
        same!("usaB", "u", "usab");
        same!("saBl", "sabl");
        same!("sabu", "saBu");
        same!("lusab", "usab", "usabsab");
        same!("sAbsabl", "sAblsab", "lsab");
        same!("sAbsAA", "sAbsAa");
        same!("saBc", "sabc");
        same!("sabC", "saBC");
        diff!("usab", "sabu");
        diff!("sabu", "usaB");
        diff!("sabsaa", "saBsaa", "sAbsAa");
        diff!("sabc", "csab", "sabC", "Csab");
        diff!("saA", "saa", "sAa");
    }

    #[test]
    fn test_replace_should_take_numbers_and_symbols_into_account() {
        same!("s12s12", "s12");
        same!("s-+s-+", "s-+");
        same!("s12ls34", "s12s34l", "ls12s34", "us34s12l");
        same!("s-+ls!#", "s-+s!#l", "ls-+s!#", "us!#s-+l");
        same!("ts12", "s12t");
        diff!("s12s23", "s23s12");
        diff!("s-+s+#", "s+#s-+");
    }

    #[test]
    fn test_replace_should_bail_if_from_eq_to() {
        same!("sabsaa", "sab", "saasabsaa", "saasab");
    }

    #[test]
    fn test_replace_should_take_previous_replaces_into_account() {
        same!("sabsaa", "sab", "saasabsaa", "saasab");
        same!("sabsac", "sab");
    }

    #[test]
    fn test_lrest_ufirst() {
        same!("cl", "l");
        same!("cu", "u");
        same!("cC", "C");
        same!("uClc", "c");
        same!("saBct", "sabC");
        diff!("cu", "c");
        diff!("c", "l", "u");
        diff!("saBct", "sabc");
    }

    #[test]
    fn test_urest_lfirst() {
        same!("C", "uC");
        same!("Cc", "c");
        same!("lcuC", "C");
        same!("sAbCt", "sAbc");
        diff!("C", "l", "u");
        diff!("sAbCt", "sabc");
    }

    #[test]
    fn test_trest() {
        same!("ut", "l");
        same!("utsab", "lsab");
        same!("tt", ":");
        same!("tl", "l");
        same!("saBlt", "sabu");
        same!("^1l", "l^1");
        diff!("ttt", ":");
        diff!("tusAb", "u");
        diff!("tsab", "sabt");
    }

    #[test]
    fn test_toggle_at() {
        same!("T1T1T2T0T0", ":T2");
        same!("T1T0T2l", "l");
        same!("T1T0T2u", "u");
        same!("cT0", "l", "CT0t");
        same!("CT0", "u", "cT0t");
        same!("sAbCT0", "sAbu");
        same!("sAbcT0", "sAbl");
        same!("$? T9 u", "u $?");
        diff!("luT1", "T1");
        diff!("T1", "lT1", "uT1");
        diff!("T1sab", "sabT1", "T1sAb", "T1saB", "T0sab", "sabT0");
        diff!("c sl1 T2", "c T2 sl1", "c so0 T3", "c T3 so0");
    }

    #[test]
    fn test_reverse() {
        same!("rr", ":");
        same!("r", "rrr");
        same!("crt", "cccrrrttt");
        diff!("r", ":");
        diff!("r", "rr");
        diff!("sa!r", "s2*r", "sdXr", "r", "sw-r", "s1wr", "s9_r");
    }

    #[test]
    fn test_reverse_should_not_affect_replaces() {
        same!("rrsab", "sab", "sabrr");
        same!("sabr", "rsab");
        diff!("rsabr", "rsab");
    }

    #[test]
    fn test_reverse_should_not_affect_cases() {
        same!("rl", "lr", "rlrr");
        same!("ru", "ur", "rurr");
        same!("rt", "tr", "rtrr");
    }

    #[test]
    fn test_dupword() {
        same!("dd", "p3");
        diff!("dd", "p1");
        diff!("dddu", "p2u");
    }

    #[test]
    fn test_dupword_times() {
        same!("p0", ":");
        same!("p1", "d");
        same!("p5r", "rp5");
        same!("@ap3", "p3@a");
        same!("sabp2", "p2sab");
        same!("p5", "p2d", "p2p1");
        same!("{p2p1", "{p5");
        diff!("p0", "d");
        diff!("ld", "lp0");
    }

    #[test]
    fn test_dupword_should_not_affect_replaces() {
        same!("dsab", "sabd");
        same!("pDsab", "sabpD");
        same!("dsabp1scdd", "sabscdddp1", "dp1dsabscd");
    }

    #[test]
    fn test_reflect() {
        same!("fd", "ff");
        same!("fsab", "sabf");
        diff!("dr", "f", "d", "r");
    }

    #[test]
    fn test_rotate() {
        same!("{}", "{{}}", "{{{}}}", ":");
        same!("{sab", "sab{");
        same!("}sab", "sab}");
        same!("^!{", "$!");
        same!("} o0g", "] ^g");
        same!("} $e [", "] $e");
        same!("} o05", "] ^5");
        same!("o0C{", "[$C");
        same!("l {", "{ l");
        same!("u {", "{ u");
        diff!("O12 {", "{ O12");
        diff!("i12 {", "{ i12");
        diff!("i12 }", "} i12");
        diff!("O12 }", "} O12");
        diff!("T4 {", "{ T4");
        diff!("T0 {", "{ T0");
        diff!("{ c", "c {");
        diff!("} c", "c }");
        diff!("{", "}");
        diff!("{sab", "sab}", "sab");
        diff!("}sab", "sab{", "sab");
    }

    #[test]
    fn test_append() {
        same!("$Al", "l$a");
        same!("$au", "u$A");
        same!("$at", "t$A");
        same!("$ac", "c$a");
        same!("l$AsAb", "l$b");
        same!("$a}", "^a");
        same!("$asab", "$bsab", "sab$b");
        diff!("$a", "$b", "^a", "^b", "$A");
        diff!("$asab", "sab$a");
        diff!("$ac", "c$A");
    }

    #[test]
    fn test_prepend() {
        same!("^Al", "l^a");
        same!("^au", "u^A");
        same!("^at", "t^A");
        same!("l^AsAb", "l^b");
        same!("^a{", "$a");
        same!("^asab", "^bsab", "sab^b");
        same!("T0 ^b T0 o0a", "^a T1");
        diff!("^a", "^b", "$a", "$b", "^A");
        diff!("^asab", "sab^a");
        diff!("^a^A", "^A^A");
        diff!("^ac", "c^a", "c^A");
        diff!("^aC", "C^a");
    }

    #[test]
    fn test_delete_first() {
        same!("^a [", "^b [", ":");
        same!("^a^bl[[", "l");
        same!("l^A[sAb", "l");
        same!("{]", "[");
        same!("sab]", "]sab");
        same!("^a[^a", "^a");
        same!("$a [", "[ $a");
        diff!("[", ":", "]");
        diff!("[ $a", "] $a", "$a ]");
    }

    #[test]
    fn test_delete_last() {
        same!("$a ]", "$b ]", ":");
        same!("$a$b]]c", "c");
        same!("l$A]sAb", "l");
        same!("}[", "]");
        same!("sab[", "[sab");
        same!("^a ]", "] ^a");
        same!("} ^a ]", "} ] ^a");
        same!("} $a [", "] $a");
        diff!("]", ":", "[");
        diff!("^a ]", "^a [", "[ ^a");
    }

    #[test]
    fn test_delete_at() {
        same!("[", "D0");
        same!("^a^bD1", "^b");
        same!("^aD0", ":");
        same!("D0sab", "sabD0");
        same!("D3D2", "D2D2");
        same!("c D0", "l D0", "D0 l");
        same!("D1 Y5 C", "D1 C Y5");
        same!("D9", "O91");
        diff!("D0", "D1", "]");
    }

    #[test]
    fn test_insert() {
        same!("^a", "i0a");
        same!("i0ai0b", "^a^b");
        same!("i1c sab", "sab i1c");
        same!("li2AsAb", "li2b");
        same!("r ] i0Z", "r i0Z ]");
        diff!("i0a", "i0A");
        diff!("i0ac", "ci0a", "ci0A");
        diff!("i1asab", "sabi1a");
    }

    #[test]
    fn test_overstrike() {
        same!("o0a sab", "sab o0b");
        same!("o0c sab", "sab o0c");
        same!("o0a[", "[");
        same!("o0a", "[ ^a");
        same!("^bo0a", "^a");
        same!("lo1a", "o1Al");
        same!("o1ac", "co1a");
        same!("^d o1u", "o0d i1u");
        same!("l [ ^R", "o0r c");
        same!("o0GT5l", "l [ ^g");
        same!("o0a Y1", "Y1 o0a");
        same!("o06", "D0 ^6");
        same!("o0a", "D0i0a");
        diff!("o1a", "o1A");
        diff!("o0a sab", "sab o0a");
        diff!("o1ac", "co1A");
    }

    #[test]
    fn test_purgechar() {
        same!("^a@a", "@a");
        same!("t@1", "@1t", "t@1s12");
        same!("t@-", "@-t", "t@-s-+");
        diff!("@a", "@b");
        diff!("t@a", "@at");
    }

    #[test]
    fn test_purgechar_should_not_be_affected_by_order() {
        same!("@a@b", "@b@a");
    }

    #[test]
    fn test_purgechar_should_take_previous_purgedchars_into_account() {
        same!("@s@s", "@s");
    }

    #[test]
    fn test_replace_should_take_puredchars_into_account() {
        same!("@asab", "@a");
        same!("sab@a", "sab");
        same!("sab@b", "@b@a");
        same!("saa@a", "@asaa", "@a", "@asab");
        same!("@a@b", "sab@a@b");
        diff!("sab@b", "@b");
        diff!("@asab$a", "@a");
        diff!("@asab^a", "@a^asab");
    }

    #[test]
    fn test_purgechar_should_take_case_into_account() {
        same!("tu@a", "u", "u@b");
        diff!("@al", "l@a");
        diff!("@au", "u@a");
    }

    #[test]
    fn test_dupechar_first() {
        same!("z2[[", ":", "z0", "Z0");
        same!("^az1", "^a^a");
        same!("z1sab", "sabz1");
        same!("z1@a", "@az1");
        same!("^a^bz1", "^a^b^b");
        same!("z4*23", "z5D1", "z4");
        same!("z4z2", "z5y1");
        same!("z3", "z2z1");
        diff!("z0", "z1", "z2", "Z1", "Z2");
    }

    #[test]
    fn test_dupechar_last() {
        same!("Z2]]", ":", "z0", "Z0");
        same!("$aZ1", "$a$a");
        same!("Z1sab", "sabZ1");
        same!("Z1@a", "@aZ1");
        same!("$a$bZ1", "$a$b$b");
        same!("Z1]", ":");
        same!("$aZ1]]", ":");
        same!("Z1i0s", "^sY1");
        same!("^a Z1", "^a Z1");
        same!("Z3", "Z2Z1");
        diff!("Z1", "Y1");
        diff!("Z0", "Z1", "Z2", "z1", "z2");
    }

    #[test]
    fn test_dupechar_all() {
        same!("qsab", "sabq");
        same!("q@a", "@aq");
        same!("q^1^1", "^1q");
        same!("q$a$a", "$aq");
        same!("qd", "dq");
        diff!("q", "z1", "Z1", "qq", ":");
    }

    #[test]
    fn test_switch_first() {
        same!("kk", "KK", ":", "k*01");
        same!("^a^bk", "^b^a");
        same!("ksab", "sabk");
        same!("k@a", "@ak");
        same!("z4k", "z4");
    }

    #[test]
    fn test_switch_last() {
        same!("kk", "KK", ":");
        same!("$a$bK", "$b$a");
        same!("Ksab", "sabK");
        same!("K@a", "@aK");
        same!("Z4K", "Z4");
    }

    #[test]
    fn test_switch_at() {
        same!("*01", "k");
        same!("*23*32", ":", "*23*23");
        same!("*22", "*33", "*00", ":");
        same!("^a^b^c*12", "^b^a^c");
        same!("*23 l", "l *23");
        same!("*23 u", "u *23");
        same!("*23 T4", "T4 *23");
        same!("*23 sab", "sab *23");
        same!("*23 T1", "T1 *23");
        same!("*23 i5a", "i5a *23");
        diff!("*23 i1a", "i1a *23");
        diff!("*23 }", "} *23");
        diff!("*23 {", "{ *23");
        diff!("*23 T3", "T3 *23");
        diff!("i5w*57", "*65i7w"); // diffs at strings with length 5
        diff!("*12", "*23", "*01");
    }

    #[test]
    fn test_truncate_at() {
        same!("$a'0", "^a'0", "sab'0", "sAb'0", ":'0", "s12'0s32", "u'0l");
        same!("'0i0a", "'0$a", "'0^a");
        same!("'0i0at", "'0i0A");
        same!("sab '2", "'2 sab");
        same!("@a '2", "'2 @a");
        same!("^a^b'2", "'0^b^ar");
        same!("'5", "'5 Y5");
        diff!("^a'1", "'1^a");
        diff!("$a'1", "'1$a");
        diff!("'3i3a", "'3i4a", "'3$a"); // diffs at strings with length < 3
        diff!("$a'2", "'2$a", "'2^a", "^a'2", "'2");
        diff!("'3", "'4", "'0");
    }

    #[test]
    fn test_omit() {
        same!("O00", ":");
        same!("O12sab", "sabO12");
        same!("O12 @a", "@a O12");
        same!("O01", "[", "D0");
        same!("^aO01", ":");
        same!("o0(", "D0 ^(");
        same!("^k O13", "O03 ^k");
        same!("O21 O01 $a", "O21 $a O01");
        same!("Z1 $a O02", "Z1 O02 $a");
        same!("O03 i0T", "^T O13");
        same!("O14 [", "[ O04");
        same!("O36l", "z2*9AO56O12l");
        same!("O07", "i7CO08");
        diff!("O0ZO0B", "O0BO0Z");
        diff!("O12", "O23", "OAB", "OZZ");
        diff!("^aO12", "O12^a");
        diff!("$aO12", "O12$a"); // diffs at strigns with length = 2
        diff!("O02", "D0D0"); // diffs at strings with length = 1
        diff!("O61", "O62");
        diff!("[O61", "O62 [");
        diff!("O31", "D2");
    }

    #[test]
    fn test_extract() {
        same!("'4", "x04");
        same!("x35 sab", "sab x35");
        same!("x35 @a", "@a x35");
        same!("x06x05", "x05", "x0Zx05", "x05x06");
        same!("x05x03", "x03x05", "x03");
        same!("x06 iBm", "i8q '6");
        same!("O84 x08", "'8 *78 *A0", "'8");
        diff!("x03x05", "x05");
        diff!("x12x53", "x53x12");
    }

    #[test]
    fn test_replace_np1() {
        same!("^a^b.0", "^a^a");
        same!("^a.0", "^b.0");
        same!("^a^a.0", "^az1");
        same!("^a^b^c.1", "^a^a^c.1");
        same!(".1 sab", "sab .1");
        same!(".1 @a", "@a .1");
        same!(".1 l", "l .1");
        diff!(".1", ".2", ".3");
        diff!("O06 Z4", ".1 O06 Z4");
    }

    #[test]
    fn test_replace_nm1() {
        same!(",0", ":");
        same!("^a^b,1", "^b^b");
        same!("^a^a,1", "^az1");
        same!("^a^b^c.1", "^a^a^c.1");
        same!(",1 sab", "sab ,1");
        same!(",1 @a", "@a ,1");
        same!(",1 l", "l ,1");
        diff!(",1", ",2", ",3");
        diff!("^a,1", "^b,1");
        diff!("O06 Z4", ",1 O06 Z4");
    }

    #[test]
    fn test_dupeblock_first() {
        same!("^ay1", "^a^a");
        same!("y0", ":", "y3O23");
        same!("y1 sab", "sab y1");
        same!("y1 @a", "@a y1");
        same!("y1 l", "l y1");
        same!("'3y3", "y3'3");
        diff!("y3", "y2y1");
        diff!("y1 ^a", "^a y1");
        diff!("y1 c", "z1 c");
        diff!("'3y3", "'3d");
        diff!("y1", "y2");
        diff!("i8k y5 O69", "y5 O68"); // diffs on len = 8
        diff!("y2 D2", "y2 O31");
        diff!("y2", "y2 .0", "y2 *32", "y2 *10");
        diff!("y2 *10 $f", "y2 $f");
    }

    #[test]
    fn test_dupeblock_last() {
        same!("$bY1", "$b$b");
        same!("Y0", ":");
        same!("Y1 sab", "sab Y1");
        same!("Y1 @a", "@a Y1");
        same!("Y3 c", "c Y3");
        same!("Y2 C", "C Y2");
        diff!("Y3", "Y2Y1");
        diff!("^a Y1", "Y1 ^a");
        diff!("Y1 y2", "y2 Y1");
        diff!("'3Y3", "'3d");
        diff!("Y1", "Y2");
        diff!("i8k Y5 O69", "Y5 O68");
        // diff!("cY3", "Y3 c"); // waiting for hashcat issue
    }

    #[test]
    fn test_misc() {
        same!("^2 ^3 o21 r", "o03 i12 i21 r");
        same!("^t o1i", "o0t i1i");
    }

    // #[test]
    // fn test_chr_shiftl() {
    //     same!("^À", "^`L0");
    //     same!("L1R1", ":", "R1 L1");
    //     same!("L0z1", "z1L0L1");
    //     diff!("L1", "L2");
    //     diff!("LNt", "tLN");
    //     diff!("sab LA", "LA sab");
    //     diff!("@b L2", "L2 @b");
    //     diff!("tz2", "tz2L2");
    // }
    //
    // #[test]
    // fn test_chr_shiftr() {
    //     same!("+1+2-1-2", ":");
    //     same!("^ÀR0", "^`");
    //     same!("R0saa", "saaR0");
    //     same!("i1c R1 sab", "sab i1c R1");
    //     same!("R0z1", "z1R0R1");
    //     diff!("R1", "R2");
    //     diff!("sab RA", "RA sab");
    //     diff!("@b R2", "R2 @b");
    //     diff!("R2c", "cR2");
    //     diff!("i1c R1 sab", "sab R1 i1c");
    //     diff!("i1c R1 s12", "s12 i1c R1");
    // }
    //
    // #[test]
    // fn test_chr_incr() {
    //     same!("^0+0", "^1");
    //     same!("+1 -1", "-1 +1");
    //     same!("+0z1", "z1+0+1");
    //     diff!("+1l", "l+1");
    //     diff!("+1", "+2");
    //     diff!("sab +A", "+A sab");
    //     diff!("@b +2", "+2 @b");
    //     diff!("+8", "+9");
    //     diff!("} +3 u", "} u +3");
    //     diff!("+1 c", "+2 -1 c");
    //     diff!("+1", "+2 -1");
    //     diff!("i4b +5 l", "i4b l +5");
    //     diff!("R0 +3 t", "R0 t +3");
    //     diff!("i5E +6 c", "i5E c +6");
    //     diff!("tZ3", "tZ3+8");
    //     diff!("+1 O06 Z4", "L1 O06 Z4");
    // }
    //
    // #[test]
    // fn test_chr_decr() {
    //     same!("-0+0", "+0-0", ":");
    //     same!("^1-0", "^0");
    //     same!("u-0+0", "u+0-0");
    //     same!("l-0-0+0", "l+0+0-0-0-0", "l-0");
    //     same!("-0-0+0", "+0+0-0-0-0", "-0");
    //     same!("u-0u", "u-0lu", "u-0ulu");
    //     same!("u-0u", "u-0u sab", "u-0u @a");
    //     same!("-0z1", "z1-0-1");
    //     diff!("-1", "-2");
    //     diff!("-0u", "u-0");
    //     diff!("sab -A", "-A sab");
    //     diff!("@b -2", "-2 @b");
    //     diff!("-8", "-9");
    //     diff!("} -3 u", "} u -3");
    //     diff!("^b -5 s9l", "^b s9l -5");
    //     diff!("t", "t+2", "t+3", "t+6", "t+8", "t+9", "t-3", "t-6-1", "t-A", "tL4", "tR0");
    //     diff!("-0R0", "R0-0");
    //     diff!("u-0l", "ul-0", "-0ul");
    //     diff!("-0u+0", "+0u-0", "u-0+0");
    //     diff!("u-0u", "-0u", "u-0");
    //     diff!("u-0l-0", "l-0u-0");
    //     diff!("u-0u+0", "u-0+0");
    //     diff!("u-0u sAB", "sAB u-0u");
    //     diff!("u-0u @A", "@A u-0u");
    //     diff!("-0 sab +0", "-0+0sab", "+0 sab -0");
    // }
}
