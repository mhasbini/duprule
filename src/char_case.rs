use std::cmp::Ordering;

use self::CharCaseT::*;

#[derive(Debug, Hash, Clone)]
pub enum CharCaseT {
    LOWER,
    UPPER,
    DEFAULT,
    REDEFAULT,
    ANY,
}

impl CharCaseT {
    pub fn default(&self) -> bool {
        *self == DEFAULT || *self == REDEFAULT
    }

    pub fn invert(&self) -> CharCaseT {
        match *self {
            ANY => ANY,
            LOWER => UPPER,
            UPPER => LOWER,
            DEFAULT => REDEFAULT,
            REDEFAULT => DEFAULT,
        }
    }
}

impl Ord for CharCaseT {
    fn cmp(&self, other: &CharCaseT) -> Ordering {
        match (self, other) {
            (&ANY, _) |
            (_, &ANY) |
            (&LOWER, &LOWER) |
            (&UPPER, &UPPER) |
            (&DEFAULT, &DEFAULT) |
            (&REDEFAULT, &REDEFAULT) => Ordering::Equal,
            (&LOWER, &DEFAULT) |
            (&LOWER, &REDEFAULT) |
            (&UPPER, &DEFAULT) |
            (&UPPER, &REDEFAULT) => Ordering::Greater,
            _ => Ordering::Less,
        }
    }
}

impl PartialOrd for CharCaseT {
    fn partial_cmp(&self, other: &CharCaseT) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl PartialEq for CharCaseT {
    fn eq(&self, other: &CharCaseT) -> bool {
        match (self, other) {
            (&ANY, _) |
            (_, &ANY) |
            (&LOWER, &LOWER) |
            (&UPPER, &UPPER) |
            (&DEFAULT, &DEFAULT) |
            (&REDEFAULT, &REDEFAULT) => true,
            _ => false,
        }
    }
}
impl Eq for CharCaseT {}

pub trait Case {
    fn lc(&self) -> char;
    fn uc(&self) -> char;
    fn case(&self) -> CharCaseT;
    fn switch_case(&self) -> char;
}

impl Case for char {
    // Hashcat rules engine doesn't support unicode.
    // So they aren't supported with duprule
    fn lc(&self) -> char {
        self.to_lowercase().nth(0).unwrap()
    }

    fn uc(&self) -> char {
        self.to_uppercase().nth(0).unwrap()
    }

    fn case(&self) -> CharCaseT {
        if self.is_lowercase() {
            LOWER
        } else if self.is_uppercase() {
            UPPER
        } else {
            ANY
        }
    }

    fn switch_case(&self) -> char {
        match self.case() {
            LOWER => self.uc(),
            UPPER => self.lc(),
            _ => *self,
        }
    }
}


// pub trait Shift {
//     fn shiftl(&self) -> char;
//     fn shiftr(&self) -> char;
//     fn incr(&self) -> char;
//     fn decr(&self) -> char;
// }
//
// impl Shift for char {
//     // needs to check if valid first
//     fn shiftl(&self) -> char {
//         char::from_u32((*self as u32) << 1).unwrap()
//     }
//
//     fn shiftr(&self) -> char {
//         char::from_u32((*self as u32) >> 1).unwrap()
//     }
//
//     fn incr(&self) -> char {
//         char::from_u32((*self as u32) + 1).unwrap()
//     }
//
//     fn decr(&self) -> char {
//         char::from_u32((*self as u32) - 1).unwrap()
//     }
// }
