use std::collections::BTreeMap;

use char_case::{Case, CharCaseT};
use char_case::CharCaseT::*;
use value::Value;
use value::Value::*;

#[derive(Debug, PartialEq, Clone, Hash, Eq)]
pub struct Slot {
    pub value: Value, // needs to enforse that only Unknown values can have replaces & purges fields
    pub replaces: Replaces,
    pub purges: Purges,
}

impl Slot {
    pub fn new(id: usize) -> Slot {
        Slot {
            value: Value::new_unknown(id),
            replaces: Replaces::new(),
            purges: Purges::new(),
        }
    }

    pub fn new_value(c: char) -> Slot {
        Slot {
            value: Value(c),
            replaces: Replaces::new(),
            purges: Purges::new(),
        }
    }

    pub fn u(&mut self) {
        self.value = match self.value.clone() {
            Unknown { id, .. } => Unknown { case: UPPER, id },
            Value(c) => Value(c.uc()),
        };

        self.replaces.urest();
    }

    pub fn l(&mut self) {
        self.value = match self.value.clone() {
            Unknown { id, .. } => Unknown { case: LOWER, id },
            Value(c) => Value(c.lc()),
        };

        self.replaces.lrest();
    }

    pub fn t(&mut self) {
        self.value = match self.value.clone() {
            Unknown { id, case } => Unknown {
                case: case.invert(),
                id,
            },
            Value(c) => Value(c.switch_case()),
        };

        self.replaces.trest();
    }

    pub fn replace(&mut self, from: char, to: char) {
        match self.value {
            Unknown { ref case, .. } => {
                let mut slot_from = From {
                    from,
                    case: case.clone(),
                };

                // 1.2
                if self.replaces.contains(&slot_from) || self.purges.contains(&slot_from) {
                    return;
                }

                // 1.4: same! sAbsabl, sAblsab
                if self.replaces.update_invert_replaces_case_and_add_new_from(
                    from,
                    case.clone(),
                    to,
                ) {
                    self.purges.add(From { from, case: ANY });
                    self.purges.update_invert_from_case(from, case.clone());
                } else {
                    if !case.default() && from.case() == *case {
                        /*1.6*/
                        self.replaces.add(
                            From {
                                from: from.switch_case(),
                                case: ANY,
                            },
                            to,
                        );
                        self.replaces.add(From { from, case: ANY }, to);
                        self.purges.add(From {
                            from: from.switch_case(),
                            case: ANY,
                        });
                        self.purges.add(From { from, case: ANY });
                    } else if case.default() || from.case() == *case {
                        /*1.5*/
                        if from.is_numeric() {
                            slot_from = From { from, case: ANY };
                        }

                        /*1.3*/
                        self.replaces.add(slot_from.clone(), to);
                        self.purges.add(slot_from.clone());
                    }

                    /*2.1, 2.2*/
                    let mut keys_to_remove: Vec<From> = Vec::new();

                    for (old_from, old_to) in &mut self.replaces.0 {
                        if *old_to == from {
                            if old_from.from == to {
                                keys_to_remove.push(old_from.clone());
                            // or use retain method
                            } else {
                                *old_to = to;
                            }
                        }
                    }

                    self.replaces.remove(keys_to_remove.clone());
                    self.purges.remove(keys_to_remove);
                }
            }
            Value(c) => if c == from {
                self.value = Value(to);
            },
        }
    }
}

#[derive(Debug, PartialEq, Hash, Eq, Ord, PartialOrd, Clone)]
pub struct From {
    pub from: char,
    pub case: CharCaseT,
}

#[derive(Debug, PartialEq, Eq, Hash, Ord, PartialOrd, Clone)]
pub struct Purges(BTreeMap<From, ()>);

impl Purges {
    pub fn new() -> Purges {
        Purges(BTreeMap::new())
    }

    pub fn update_invert_from_case(&mut self, from: char, case: CharCaseT) {
        self.update_key(from, case, from, ANY);
    }

    pub fn update_key(
        &mut self,
        old_from: char,
        old_case: CharCaseT,
        new_from: char,
        new_case: CharCaseT,
    ) {
        self.0.remove(&From {
            from: old_from,
            case: old_case,
        });
        self.0.insert(
            From {
                from: new_from,
                case: new_case,
            },
            (),
        );
    }

    pub fn contains(&self, from: &From) -> bool {
        self.0.contains_key(from)
    }

    pub fn add(&mut self, from: From) {
        self.0.insert(from, ());
    }

    pub fn remove(&mut self, keys: Vec<From>) {
        for key in keys {
            self.0.remove(&key);
        }
    }
}

#[derive(Debug, PartialEq, Eq, Hash, Ord, PartialOrd, Clone)]
pub struct Replaces(pub BTreeMap<From, char>);

impl Replaces {
    pub fn new() -> Replaces {
        Replaces(BTreeMap::new())
    }

    pub fn update_invert_from_case(&mut self, from: char, case: CharCaseT, to: char) {
        self.update_key(from, case, from, ANY, to);
    }

    pub fn update_key(
        &mut self,
        old_from: char,
        old_case: CharCaseT,
        new_from: char,
        new_case: CharCaseT,
        new_to: char,
    ) {
        self.0.remove(&From {
            from: old_from,
            case: old_case,
        });
        self.0.insert(
            From {
                from: new_from,
                case: new_case,
            },
            new_to,
        );
    }

    pub fn update_invert_replaces_case_and_add_new_from(
        &mut self,
        from: char,
        case: CharCaseT,
        to: char,
    ) -> bool {
        if self.0
            .get(&From {
                from: from.switch_case(),
                case: case.clone(),
            })
            .is_some()
        {
            self.update_invert_from_case(from.switch_case(), case, to);
            self.0.insert(From { from, case: ANY }, to);
            return true;
        }

        false
    }

    pub fn add(&mut self, from: From, to: char) {
        self.0.insert(from, to);
    }

    pub fn lrest(&mut self) {
        self.update_case_to(LOWER);
    }

    pub fn urest(&mut self) {
        self.update_case_to(UPPER);
    }

    pub fn update_case_to(&mut self, case: CharCaseT) {
        for val in self.0.values_mut() {
            match case {
                LOWER => *val = val.lc(),
                UPPER => *val = val.uc(),
                _ => {}
            }
        }
    }

    pub fn trest(&mut self) {
        for val in self.0.values_mut() {
            *val = val.switch_case()
        }
    }

    pub fn contains(&self, from: &From) -> bool {
        self.0.contains_key(from)
    }

    pub fn remove(&mut self, keys: Vec<From>) {
        for key in keys {
            self.0.remove(&key);
        }
    }
}
