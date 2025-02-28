import Safe from '@safe-global/protocol-kit'

export const createSafe = async (provider, signer, safeOwners, threshold) => {
  const safeAccountConfig = {
    owners: safeOwners,
    threshold,
    // Additional optional parameters can be included here
  }

  const predictSafe = {
    safeAccountConfig,
    safeDeploymentConfig: {
      //   saltNonce, // optional parameter
      //   safeVersion, // optional parameter
    },
  }

  const protocolKit = await Safe.init({ provider, signer, predictSafe })

  const deploymentTransaction =
    await protocolKit.createSafeDeploymentTransaction()

  console.log(deploymentTransaction)

  //   const txHash = await client.sendTransaction({
  //     to: deploymentTransaction.to,
  //     value: BigInt(deploymentTransaction.value),
  //     data: `0x${deploymentTransaction.data}`,
  //   })
}
