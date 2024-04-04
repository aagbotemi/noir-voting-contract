mod types;

contract Voting {
    use dep::aztec::prelude::{
        AztecAddress, FunctionSelector, NoteHeader, NoteInterface, NoteGetterOptions, PrivateContext,
        Map, PublicMutable
    };
    use dep::aztec::context::Context;

    use crate::types::Candidate;

    // struct Candidate {
    //     name: Field,
    //     description: Field,
    // }

    struct Storage {
        admin: PublicMutable<AztecAddress>, // admin can end vote
        tally: Map<Field, PublicMutable<Field>>, // we will store candidate as key and number of votes as value
        candidates: Map<Field, PublicMutable<Candidate>>,
        vote_ended: PublicMutable<bool>, // vote_ended is boolean
        vote_delegation: Map<AztecAddress, PublicMutable<AztecAddress>>
    }

    #[aztec(public)]
    #[aztec(initializer)] // annotation to mark function as a constructor
    fn constructor(admin: AztecAddress) {
        storage.admin.write(admin);
        storage.vote_ended.write(false);
    }

    #[aztec(private)] // annotation to mark function as private and expose private context
    fn cast_vote(candidate: Field) {
        let secret = context.request_nullifier_secret_key(context.msg_sender()); // get secret key of caller of function
        let nullifier = dep::std::hash::pedersen_hash([context.msg_sender().to_field(), secret.low, secret.high]); // compute nullifier with this secret key so others can't descrypt it
        context.push_new_nullifier(nullifier, 0); // push nullifier
        context.call_public_function(
            context.this_address(),
            FunctionSelector::from_signature("add_to_tally_public(Field,Field)"),
            [candidate, 1]
        );
    }

    #[aztec(private)] // annotation to mark function as private and expose private context
    fn vote_by_delegation(candidate: Field, delegator: AztecAddress) {
        let your_delegated_address = storage.vote_delegation.at(delegator).read();
        assert(your_delegated_address == context.msg_sender(), "You are not delegated to vote!");
        
        let secret = context.request_nullifier_secret_key(context.msg_sender()); // get secret key of caller of function
        let nullifier = dep::std::hash::pedersen_hash([context.msg_sender().to_field(), secret.low, secret.high]); // compute nullifier with this secret key so others can't descrypt it
        context.push_new_nullifier(nullifier, 0); // push nullifier
        context.call_public_function(
            context.this_address(),
            FunctionSelector::from_signature("add_to_tally_public(Field,Field)"),
            [candidate, 1]
        );
    }

    #[aztec(public)]
    // #[aztec(internal)]
    fn add_to_tally_public(candidate: Field, vote_count: Field) {
        assert(storage.vote_ended.read() == false, "Vote has ended"); // assert that vote has not ended
        let new_tally = storage.tally.at(candidate).read() + vote_count;
        storage.tally.at(candidate).write(new_tally);
    }

    #[aztec(private)] // annotation to mark function as private and expose private context
    fn admin_distribute_votes(candidate: Field, vote_count: Field) {
        assert(storage.admin.read().eq(context.msg_sender()), "Only Admin can call this function"); // assert that vote has not ended
        // let secret = context.request_nullifier_secret_key(context.msg_sender()); // get secret key of caller of function
        // let nullifier = dep::std::hash::pedersen_hash([context.msg_sender().to_field(), secret.low, secret.high]); // compute nullifier with this secret key so others can't descrypt it
        // context.push_new_nullifier(nullifier, 0); // push nullifier
        context.call_public_function(
            context.this_address(),
            FunctionSelector::from_signature("add_to_tally_public(Field,Field)"),
            [candidate, vote_count]
        );
    }


    #[aztec(public)]
    #[aztec(internal)]
    fn register_candidate(candidateId: Field, name: Field, description: Field) {
        let caller = context.msg_sender();
        assert(storage.admin.read().eq(caller), "Only Admin can call this function"); // assert that vote has not ended
        
        // let candidate_details = Candidate {name, description};

        let candidate_details = Candidate::new(name, description, caller);
        storage.candidates.at(candidateId).write(candidate_details);
        
    }

    // @TODO: register voters into the contracts: can_vote
    // #[aztec(public)]
    // #[aztec(internal)]
    // fn register_voters(candidateId: Field, name: FieldCompressedString, description: FieldCompressedString) {
    //     let caller = context.msg_sender();
    //     assert(storage.admin.read().eq(caller), "Only Admin can call this function"); // assert that vote has not ended
        
    //     let candidate_details = Candidate {name, description};

    //     candidates.at(candidateId).write(candidate_details);
    // }

    // #[aztec(public)]
    // #[aztec(internal)]
    // fn register_candidate(candidateId: Field, name: Field, description: Field) {
    //     let caller = context.msg_sender();
    //     assert(storage.admin.read().eq(caller), "Only Admin can call this function"); // assert that vote has not ended
        
    //     let candidate_details = Candidate {name, description};

    //     storage.candidates.at(candidateId).write(candidate_details);
        
    // }

    #[aztec(public)]
    #[aztec(internal)]
    fn delegate_vote(delegate: AztecAddress) {
    
        let caller = context.msg_sender();
        
        // check the person that want's to delegate vote if they have the right to do so
        // assert(storage.has_voted.at(caller).read() == false, "You have no vote to delegate!");
        
        storage.vote_delegation.at(caller).write(delegate);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn end_vote() {
        // assert(storage.vote_ended.read().eq(false), "Vote has ended"); // assert that vote has not ended
        assert(storage.admin.read().eq(context.msg_sender()), "Only admin can end votes"); // assert that vote has not ended
        storage.vote_ended.write(true)
        //  .at(candidate).read() + 1;
        // storage.tally.at(candidate).write(new_tally);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn start_vote() {
        // assert(storage.vote_ended.read().eq(false), "Vote has ended"); // assert that vote has not ended
        assert(storage.admin.read().eq(context.msg_sender()), "Only admin can end votes"); // assert that vote has not ended
        storage.vote_ended.write(false)
        //  .at(candidate).read() + 1;
        // storage.tally.at(candidate).write(new_tally);
    }

    unconstrained fn get_vote(candidate: Field) -> pub Field {
        storage.tally.at(candidate).read()
    }
}


// contract Main {
//     fn double(x: Field) -> pub Field { x * 2 }
//     fn triple(x: Field) -> pub Field { x * 3 }
//     fn quadruple(x: Field) -> pub Field { double(double(x)) }
// }
