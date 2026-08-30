
#define A128_BASE_ADDRESS    (unsigned int)0x44A00000UL

#define A128_ADDR_CTRL       (unsigned int)0x00UL + A128_BASE_ADDRESS
#define A128_ADDR_STATUS     (unsigned int)0x04UL + A128_BASE_ADDRESS
#define A128_ADDR_KEY        (unsigned int)0x08UL + A128_BASE_ADDRESS
#define A128_ADDR_NONCE      (unsigned int)0x18UL + A128_BASE_ADDRESS
#define A128_ADDR_ASSOC_DATA (unsigned int)0x28UL + A128_BASE_ADDRESS
#define A128_ADDR_TEXT_IN    (unsigned int)0x38UL + A128_BASE_ADDRESS
#define A128_ADDR_TEXT_LEN   (unsigned int)0x48UL + A128_BASE_ADDRESS
#define A128_ADDR_TEXT_OUT   (unsigned int)0x4CUL + A128_BASE_ADDRESS
#define A128_ADDR_TAG_OUT    (unsigned int)0x5CUL + A128_BASE_ADDRESS

