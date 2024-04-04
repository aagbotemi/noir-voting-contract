use dep::aztec::{
    log::emit_encrypted_log,
    protocol_types::{address::AztecAddress, traits::{Deserialize, Serialize}},
    note::{note_header::NoteHeader, note_interface::NoteInterface, utils::compute_note_hash_for_consumption},
    oracle::{ unsafe_rand::unsafe_rand, nullifier_key::get_nullifier_secret_key, get_public_key::get_public_key},
    hash::pedersen_hash, context::PrivateContext
};

global CANDIDATE_NOTE_LEN: Field = 4;

#[aztec(note)]
struct Candidate {
    name: Field,
    description: Field,
    owner: AztecAddress,
    randomness: Field,
}

impl NoteInterface<CANDIDATE_NOTE_LEN>  for Candidate {

    fn compute_nullifier(self, context: &mut PrivateContext) -> Field {
        let note_hash_for_nullify = compute_note_hash_for_consumption(self);
        let secret = context.request_nullifier_secret_key(self.owner);
        pedersen_hash([
            note_hash_for_nullify,
            secret.low,
            secret.high,
        ],0)
    }

    fn compute_nullifier_without_context(self) -> Field {
        let note_hash_for_nullify = compute_note_hash_for_consumption(self);
        let secret = get_nullifier_secret_key(self.owner);
        pedersen_hash([
            note_hash_for_nullify,
            secret.low,
            secret.high,
        ],0)
    }

    // Broadcasts the note as an encrypted log on L1.
    fn broadcast(self, context: &mut PrivateContext, slot: Field) {
        let encryption_pub_key = get_public_key(self.owner);
        emit_encrypted_log(
            context,
            (*context).this_address(),
            slot,
            Self::get_note_type_id(),
            encryption_pub_key,
            self.serialize_content(),
        );
    }
}

impl Candidate {
    pub fn new( name: Field, description: Field, owner: AztecAddress) -> Self {
        let randomness = unsafe_rand();
        Candidate { name, description, owner, randomness, header: NoteHeader::empty() }
    }
}

impl Serialize<8> for Candidate {
    fn serialize(self) -> [Field; 8] {
        let header = self.header.serialize();

        [self.name, self.description, self.owner.to_field(), self.randomness, header[0], header[1], header[2], header[3]]
    }
}