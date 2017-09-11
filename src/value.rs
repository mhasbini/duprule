use std::hash::{Hash, Hasher};

use char_case::CharCaseT;
use char_case::CharCaseT::DEFAULT;

use self::Value::*;

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum Value {
    Unknown { case: CharCaseT, id: usize },
    Value(char),
}

impl Value {
    pub fn new_unknown(id: usize) -> Value {
        Unknown { case: DEFAULT, id }
    }
}

impl Hash for Value {
    fn hash<H: Hasher>(&self, state: &mut H) {
        match *self {
            Unknown {ref case, ref id} => {
                case.hash(state);
                id.hash(state);
            },
            Value(c) => c.hash(state)
        }
    }
}
