-include .env

BASIC_NFT_CONTRACT := script/BasicNft.s.sol:BasicNftScript
MOOD_NFT_CONTRACT := script/MoodNft.s.sol:MoodNftScript
NETWORK_ARGS :=

ifeq ($(findstring local,$(network)),local)
	NETWORK_ARGS := --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv
endif

ifeq ($(findstring sepolia,$(network)),sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(REAL_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

build:; forge build

# BasicNFT
deploy-basic:; @forge script $(BASIC_NFT_CONTRACT) $(NETWORK_ARGS)

mint-basic:
	@cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "mintNft(string)" "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json" --private-key $(PRIVATE_KEY)

tokenUri-basic:
	@cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "tokenURI(uint256)" "18" | cast --to-ascii

# MoodNFT
deploy-mood:; @forge script $(MOOD_NFT_CONTRACT) $(NETWORK_ARGS)

mint-mood:
	@cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "mintNft()" --private-key $(PRIVATE_KEY)

flip-mood:
	@cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "flipMood(uint256)" "0" --private-key $(PRIVATE_KEY)

tokenUri-mood:
	@cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "tokenURI(uint256)" "0"
