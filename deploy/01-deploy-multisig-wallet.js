const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    log("----------------------------------------------------")
    const ownerAddresses = [
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    ]
    const arguments = [ownerAddresses]
    const multiSigWallet = await deploy("MultiSigWallet", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    log(`MultiSigWallet deployed at ${multiSigWallet.address}`)
    log(`Deployed by ${deployer}`)
    log(`Owner Addresses: ${ownerAddresses.join(", ")}`)

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(multiSigWallet.address, arguments)
    }
    log("----------------------------------------------------")
}

module.exports.tags = ["all", "multisigwallet", "main"]
