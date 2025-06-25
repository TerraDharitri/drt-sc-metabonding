WALLET_PEM="/home/TerraDharitri/dharitri-sdk/drtpy-venv/lib/python3.8/site-packages/drtpy/testnet/wallets/users/mike.pem"
PROXY="https://devnet-gateway.dharitri.org"
CHAIN_ID="D"

METABONDING_WASM_PATH="/home/TerraDharitri/Github/sc-metabonding-rs/metabonding/output/metabonding.wasm"
DCDT_ISSUE_ADDRESS="drt1qqqqqqqqqqqqqqqpqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzllls6prdez"

CONTRACT_ADDRESS="drt1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq85hk5z"

SIGNER_PUB_KEY=0x52773868c13654355cca16adb389b09201fabf5d9d4b795ebbdae5b361b46f20
deployMetabondingSC() {
    drtpy --verbose contract deploy --recall-nonce \
        --bytecode=${METABONDING_WASM_PATH} \
        --pem=${WALLET_PEM} \
        --gas-limit=200000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --arguments ${SIGNER_PUB_KEY} \
        --send || return
}

upgradeMetabondingSC() {
    drtpy --verbose contract upgrade ${CONTRACT_ADDRESS} --recall-nonce \
        --bytecode=${METABONDING_WASM_PATH} \
        --pem=${WALLET_PEM} \
        --gas-limit=200000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --arguments ${SIGNER_PUB_KEY} \
        --send || return
}

TOKEN=0x4d5442
TOKEN_AMOUNT=0xfffffffffffffffffffffffffffffffffffff
TOKEN_DECIMALS=18
issueToken() {
    drtpy --verbose contract call ${DCDT_ISSUE_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=60000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --value=50000000000000000 \
        --function="issue" \
        --arguments ${TOKEN} ${TOKEN} ${TOKEN_AMOUNT} ${TOKEN_DECIMALS} \
        --send || return
}

unpause() {
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="unpause" \
        --send || return
}

changeSigner() {
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="changeSigner" \
        --arguments ${SIGNER_PUB_KEY} \
        --send || return
}

###PARAMS
#1 - ProjectId
PROJECT_OWNER="drt14nw9pukqyqu75gj0shm8upsegjft8l0awjefp877phfx74775dsqge8dz0"
REWARD_TOKEN=0x4d54422d613865653832
REWARD_SUPPLY=0x661efdf12d1653cf340000 
START_WEEK=2
DURATION_WEEK=10
LKMOA_REWARDS_PERCENTAGE=40
addProject() {
    project_owner="0x$(drtpy wallet bech32 --decode ${PROJECT_OWNER})"
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="addProject" \
        --arguments $1 $project_owner ${REWARD_TOKEN} ${REWARD_SUPPLY} ${START_WEEK} ${DURATION_WEEK} ${LKMOA_REWARDS_PERCENTAGE}\
        --send || return
}

###PARAMS
#1 - ProjectId
DEPOSIT_METHOD=0x6465706f73697452657761726473 #depositRewards 
depositRewards() {
    contract_address="0x$(drtpy wallet bech32 --decode ${CONTRACT_ADDRESS})"
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="DCDTTransfer" \
        --arguments ${REWARD_TOKEN} ${REWARD_SUPPLY} ${DEPOSIT_METHOD} $1 \
        --send || return
}

###PARAMS
#1 - Checkpoint week
#2 - Total delegation amount
#3 - Total lkmoa staked
addRewardsCheckpoint() {
    contract_address="0x$(drtpy wallet bech32 --decode ${CONTRACT_ADDRESS})"
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="addRewardsCheckpoint" \
        --arguments $1 $2 $3 \
        --send || return
}

###PARAMS
#1 - Claim week
#2 - User delegation amount
#3 - User lkmoa staked
#4 - Signature
# Signature Example -> 0xaf32d5d139e8616b109510ff5b78d8f6a0409ab98bca99e1cb2437d917a6b62b6b4217b136df23377d715c638eb1e6709d90edf6955c29823e93fc525dad9405
claimRewards() {
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="claimRewards" \
        --arguments $1 $2 $3 $4\
        --send || return
}

###PARAMS
#1 - ProjectId
removeProject() {
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="removeProject" \
        --arguments $1\
        --send || return
}

clearExpiredProjects() {
    drtpy --verbose contract call ${CONTRACT_ADDRESS} --recall-nonce \
        --pem=${WALLET_PEM} \
        --gas-limit=6000000 \
        --proxy=${PROXY} --chain=${CHAIN_ID} \
        --function="clearExpiredProjects" \
        --send || return
}

getCurrentWeek() {
    drtpy --verbose contract query ${CONTRACT_ADDRESS} \
        --proxy=${PROXY} \
        --function="getCurrentWeek"
}

###PARAMS
#1 - ProjectId
getProjectById() {
    drtpy --verbose contract query ${CONTRACT_ADDRESS} \
        --proxy=${PROXY} \
        --function="getProjectById" \
        --arguments $1
}

getAllProjectIds() {
    drtpy --verbose contract query ${CONTRACT_ADDRESS} \
        --proxy=${PROXY} \
        --function="getAllProjectIds"
}

###PARAMS
#1 - Check week
#2 - User delegation amount
#3 - User lkmoa staked
getRewardsForWeek() {
    drtpy --verbose contract query ${CONTRACT_ADDRESS} \
        --proxy=${PROXY} \
        --function="getRewardsForWeek" \
        --arguments $1 $2 $3
}

###PARAMS
#1 - Lookback weeks no
CHECK_USER_ADDRESS="drt14nw9pukqyqu75gj0shm8upsegjft8l0awjefp877phfx74775dsqge8dz0"
getUserClaimableWeeks() {
    check_user_address="0x$(drtpy wallet bech32 --decode ${CHECK_USER_ADDRESS})"
    drtpy --verbose contract query ${CONTRACT_ADDRESS} \
        --proxy=${PROXY} \
        --function="getUserClaimableWeeks" \
        --arguments $check_user_address ${LOOKBACK_WEEK_NO}
}
