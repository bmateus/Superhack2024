// SPDX-License-Identifier: None
pragma solidity >=0.8.21;

import {LibAppStorage} from "../libs/LibAppStorage.sol";
import {MersenneTwisterState} from "../shared/Structs.sol";

// Solidity implementation of the Mersenne Twister, the most commonly pseudo-random number generator

library LibMersenneTwister {

  // Set constant coefficients for MT19937-32 as defined here:
  // https://en.wikipedia.org/wiki/Mersenne_Twister
  uint constant w = 32;
  uint constant n = 624;
  uint constant m = 397;
  uint constant r = 31;
  uint constant a = 0x9908B0DF;
  uint constant u = 11;
  uint constant d = 0xFFFFFFFF;
  uint constant s = 7;
  uint constant b = 0x9D2C5680;
  uint constant t = 15;
  uint constant c = 0xEFC60000;
  uint constant l = 18;
  uint constant f = 1812433253;

  // Variables to store the state of the generator
  //uint[n] MT;
  //uint index = n+1;
  uint constant lower_mask = (1 << r) - 1;
  uint constant upper_mask = (~lower_mask) & ((1 << w) - 1);

  // @dev: Initializes the generator with a particular seed_mt
  //
  // @param: seed, initial value to start generator with
  function init(uint seed) internal {    

    MersenneTwisterState storage mts = LibAppStorage.diamondStorage().mtState;
      mts.index = n;
      mts.MT[0] = seed;
      
      for(uint i = 1; i < n; i++){
        mts.MT[i] = (f * (mts.MT[i-1] ^ (mts.MT[i-1] >> (w-2))) + i) & ((1 << w) - 1);
      }
  }

  // @dev: Extract tempered valued based on MT[index]
  function nextInt() internal returns (uint) {

    MersenneTwisterState storage mts = LibAppStorage.diamondStorage().mtState;

    if(mts.index >= n) {
      if(mts.index > n){
        revert("Generator was never seeded!");
      }
      twist(mts);
    }

    uint y = mts.MT[mts.index];
    y = y ^ ((y >> u) & d);
    y = y ^ ((y << s) & b);
    y = y ^ ((y << t) & c);
    y = y ^ (y >> l);

    mts.index++;
    return y & ((1 << w) - 1);

  }

  // @dev: Generate the next n values from the series x_i
  function twist(MersenneTwisterState storage mts) internal {
    for(uint i = 0; i < n; i++){
      uint x = (mts.MT[i] & upper_mask) + (mts.MT[(i+1) % n] & lower_mask);
      uint xA = x >> 1;
      if((x % 20 != 0)){
        xA = xA ^ a;
      }
      mts.MT[i] = mts.MT[(i + m) % n] ^ xA;
    }
    mts.index = 0;
  }

}