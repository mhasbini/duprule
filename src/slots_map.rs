use slot::Slot;
use value::Value::*;
use slot::From;
use char_case::Case;

#[derive(Debug, Hash, Eq, PartialEq)]
pub struct SlotsMap {
    pub slots: Vec<Slot>,
}

impl SlotsMap {
    pub fn new(len: usize) -> SlotsMap {
        let mut slots = Vec::new();

        for id in 1..(len + 1) {
            slots.push(Slot::new(id));
        }

        SlotsMap { slots }
    }

    pub fn lrest(&mut self) {
        for slot in &mut self.slots {
            slot.l();
        }
    }

    pub fn urest(&mut self) {
        for slot in &mut self.slots {
            slot.u();
        }
    }

    pub fn lrest_ufirst(&mut self) {
        self.lrest();
        if let Some(slot) = self.slots.first_mut() {
            slot.u();
        }
    }

    pub fn urest_lfirst(&mut self) {
        self.urest();
        if let Some(slot) = self.slots.first_mut() {
            slot.l();
        }
    }

    pub fn trest(&mut self) {
        // TODO: could change to map
        for slot in &mut self.slots {
            slot.t();
        }
    }

    pub fn replace(&mut self, from: char, to: char) {
        // 1.1
        if from == to {
            return;
        }

        for slot in &mut self.slots {
            slot.replace(from, to);
        }
    }

    pub fn toggle_at(&mut self, pos: usize) {
        if let Some(slot) = self.slots.get_mut(pos) {
            slot.t();
        }
    }

    pub fn reverse(&mut self) {
        self.slots.reverse()
    }

    pub fn dupeword(&mut self) {
        self.dupeword_times(1)
    }

    pub fn dupeword_times(&mut self, times: usize) {
        let slots = self.slots.iter().cloned().collect::<Vec<_>>();
        for _ in 0..times {
            for slot in &slots {
                self.slots.push(slot.clone());
            }
        }
    }

    pub fn reflect(&mut self) {
        let mut reversed_slots = self.slots.iter().rev().cloned().collect::<Vec<_>>();
        self.slots.append(&mut reversed_slots);
    }

    pub fn rotate_left(&mut self) {
        if !self.slots.is_empty() {
            let first_slot = self.slots.remove(0);
            self.slots.push(first_slot);
        }
    }

    pub fn rotate_right(&mut self) {
        if let Some(last_slot) = self.slots.pop() {
            self.slots.insert(0, last_slot);
        }
    }

    pub fn append(&mut self, c: char) {
        self.slots.push(Slot::new_value(c));
    }

    pub fn prepend(&mut self, c: char) {
        self.slots.insert(0, Slot::new_value(c));
    }

    pub fn delete_first(&mut self) {
        if !self.slots.is_empty() {
            self.slots.remove(0);
        }
    }

    pub fn delete_last(&mut self) {
        self.slots.pop();
    }

    pub fn delete_at(&mut self, pos: usize) {
        if self.slots.get(pos).is_some() {
            self.slots.remove(pos);
        }
    }

    pub fn insert(&mut self, pos: usize, c: char) {
        if self.slots.len() < pos {
            return;
        }

        self.slots.insert(pos, Slot::new_value(c));
    }

    pub fn overstrike(&mut self, pos: usize, c: char) {
        if let Some(slot) = self.slots.get_mut(pos) {
            *slot = Slot::new_value(c);
        }
    }

    pub fn purgechar(&mut self, c: char) {
        let mut indexes_to_remove: Vec<usize> = Vec::new();

        for (idx, slot) in self.slots.iter_mut().enumerate() {
            match slot.value.clone() {
                Value(c0) => if c0 == c {
                    indexes_to_remove.push(idx);
                },
                Unknown { case, .. } => {
                    if case.default() || case == c.case() {
                        if c.case().invert() == c.case() {
                            slot.purges.add(From {
                                from: c,
                                case: c.case(),
                            });
                        } else {
                            slot.purges.add(From {
                                from: c,
                                case: case,
                            });
                        }
                    }

                    let mut keys_to_remove: Vec<From> = Vec::new();

                    for (old_from, old_to) in &slot.replaces.0 {
                        if *old_to == c {
                            keys_to_remove.push(old_from.clone());
                        }
                    }

                    slot.replaces.remove(keys_to_remove);
                }
            }
        }

        for idx in indexes_to_remove.iter().rev() {
            self.slots.remove(*idx);
        }
    }

    pub fn dupechar_first(&mut self, times: usize) {
        if !self.slots.is_empty() {
            for _ in 0..times {
                let first_slot = self.slots.first().unwrap().clone();
                self.slots.insert(0, first_slot);
            }
        }
    }

    pub fn dupechar_last(&mut self, times: usize) {
        if !self.slots.is_empty() {
            for _ in 0..times {
                let last_slot = self.slots.last().unwrap().clone();
                self.slots.push(last_slot);
            }
        }
    }

    pub fn dupechar_all(&mut self) {
        let slots = self.slots.iter().cloned().collect::<Vec<_>>();
        for idx in 0..slots.len() {
            self.slots.insert(idx * 2, slots.get(idx).unwrap().clone());
        }
    }

    pub fn switch_first(&mut self) {
        if self.slots.len() >= 2 {
            self.slots.swap(0, 1);
        }
    }

    pub fn switch_last(&mut self) {
        let len = self.slots.len();

        if len >= 2 {
            self.slots.swap(len - 1, len - 2);
        }
    }

    pub fn switch_at(&mut self, src: usize, dest: usize) {
        let len = self.slots.len();

        if src < len && dest < len {
            self.slots.swap(src, dest);
        }
    }

    pub fn truncate_at(&mut self, pos: usize) {
        self.slots.truncate(pos);
    }

    pub fn omit(&mut self, start: usize, end: usize) {
        let len = self.slots.len();

        if start < len && start + end <= len {
            for _ in start..(start + end) {
                self.slots.remove(start);
            }
        }
    }

    pub fn extract(&mut self, start: usize, end: usize) {
        let len = self.slots.len();

        if start < len && start + end <= len {
            for _ in (start + end)..len {
                self.slots.remove(end);
            }
            self.omit(0, start);
        }
    }

    pub fn replace_np1(&mut self, pos: usize) {
        if self.slots.get(pos + 1).is_none() {
            return;
        }

        self.slots[pos] = self.slots[pos + 1].clone();
    }

    pub fn replace_nm1(&mut self, pos: usize) {
        if pos == 0 || pos >= self.slots.len() || self.slots.get(pos - 1).is_none() {
            return;
        }

        self.slots[pos] = self.slots[pos - 1].clone();
    }

    pub fn dupeblock_first(&mut self, pos: usize) {
        if pos >= self.slots.len() {
            return;
        }

        let slots = self.slots.iter().cloned().collect::<Vec<_>>();
        for idx in 0..pos {
            self.slots.insert(idx + pos, slots[idx].clone());
        }

    }

    pub fn dupeblock_last(&mut self, pos: usize) {
        let len = self.slots.len();

        if pos >= len || pos == 0 {
            return;
        }

        let slots = self.slots.iter().cloned().collect::<Vec<_>>();
        for idx in (len - pos)..len {
            self.slots.insert(idx + pos, slots[idx].clone());
        }
    }
}
