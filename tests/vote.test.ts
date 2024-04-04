import {
  AccountContract,
  AccountManager,
  AccountWallet,
  CompleteAddress,
  Fr,
  GrumpkinPrivateKey,
  GrumpkinScalar,
  PXE,
  Wallet,
  createPXEClient,
} from '@aztec/aztec.js';
import { VotingContract } from '../contracts/voting_contract';

import { randomBytes } from 'crypto';


describe('e2e_voting_contracts', () => {
    let pxe: PXE;
    let owner: AccountWallet;
    let recipient: AccountWallet;
    let token: VotingContract;
  
    beforeEach(async () => {
      pxe = createPXEClient(PXE_URL);
    //   owner = await createAccount(pxe);
    //   recipient = await createAccount(pxe);
      token = await VotingContract.deploy(owner, owner.getCompleteAddress(), 'TokenName', 'TokenSymbol', 18)
        .send()
        .deployed();
    }, 60_000);
});
