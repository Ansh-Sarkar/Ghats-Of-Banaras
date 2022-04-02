from brownie import accounts, GOBDAOContract

def deploy_contract():
    account = accounts.load("polygon-mumbai-ansh-sarkar")
    print("Using Account : ", account)
    deployed_contract = GOBDAOContract.deploy(
        "Ansh Sarkar", 
        {
            "from" : account
        }
    )
    print(deployed_contract)
    print(deployed_contract.getFounder())
    
    # print("registering user : ", accounts[1])
    # print("register 1 : ", deployed_contract.registerNewMember("Bonita", {"from" : accounts[1]}).return_value)
    # print("register 2 : ", deployed_contract.registerNewMember("Bonita", {"from" : accounts[1]}).return_value)

    # print("Name : ", deployed_contract.getName({"from" : accounts[1]}).return_value)
    # print("Changed Name : ", deployed_contract.setName("Binita Agarwala", {"from" : accounts[1]}).return_value)

    # print("Before Deposit : ", accounts[1].balance())

    # print("Balance : ", deployed_contract.getMemberBalance({"from" : accounts[1]}).return_value)
    # print("Updated Balance : ", deployed_contract.memberDeposit({"from" : accounts[1], "value" : 230}).return_value)

    # print("After Deposit : ", accounts[1].balance())

    # print("Balance after withdraw : ", deployed_contract.memberWithdraw(30, {"from" : accounts[1]}).return_value)
    # # print("Balance after withdraw : ", deployed_contract.memberWithdraw(210, {"from" : accounts[1]}).return_value)

    # print("After Withdraw : ", accounts[1].balance())

    # propTxn = deployed_contract.memberProposal("https://ipfs.io/ansh-sarkar/images/1.jpg", {"from" : accounts[1]}).return_value
    # print("Submitting Proposal : ", propTxn)
    # print("Fetching Proposal details : ", deployed_contract.getProposal(propTxn, {"from" : accounts[1]}))

    
def main():
    deploy_contract()