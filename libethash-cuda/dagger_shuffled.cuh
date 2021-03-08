#include "ethash_cuda_miner_kernel_globals.h"

#include "ethash_cuda_miner_kernel.h"

#include "cuda_helper.h"

#define _PARALLEL_HASH 4

DEV_INLINE bool compute_hash(uint64_t nonce, uint2* mix_hash)
{
    // sha3_512(header .. nonce)
    uint2 state[12];

    state[4] = vectorize(nonce);

    keccak_f1600_init(state);

    // Threads work together in this phase in groups of 8.
    const int thread_id = threadIdx.x & (THREADS_PER_HASH - 1);
    const int mix_idx = thread_id & 3;

    for (int i = 0; i < THREADS_PER_HASH; i += _PARALLEL_HASH)
    {
        uint4 mix[_PARALLEL_HASH];
        uint32_t offset[_PARALLEL_HASH];
        uint32_t init0[_PARALLEL_HASH];

        // share init among threads
        for (int p = 0; p < _PARALLEL_HASH; p++)
        {
            uint2 shuffle[8];
            for (int j = 0; j < 8; j++)
            {
                shuffle[j].x = SHFL(state[j].x, i + p, THREADS_PER_HASH);
                shuffle[j].y = SHFL(state[j].y, i + p, THREADS_PER_HASH);
            }
            switch (mix_idx)
            {
            case 0:
                mix[p] = vectorize2(shuffle[0], shuffle[1]);
                break;
            case 1:
                mix[p] = vectorize2(shuffle[2], shuffle[3]);
                break;
            case 2:
                mix[p] = vectorize2(shuffle[4], shuffle[5]);
                break;
            case 3:
                mix[p] = vectorize2(shuffle[6], shuffle[7]);
                break;
            }
            init0[p] = SHFL(shuffle[0].x, 0, THREADS_PER_HASH);
        }



    }


    return true;
}
