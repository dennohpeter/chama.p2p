import axios from 'axios'
import { v4 as uuidv4 } from 'uuid'

const headers = {
  accept: 'application/json',
  authorization: `Bearer ${import.meta.env.VITE_P2P_API_KEY}`,
  'content-type': 'application/json',
}

const P2P_BASE_URL =
  import.meta.env.VITE_P2P_BASE_URL ||
  'https://api-test-holesky.p2p.org/api/v1/'

export const createEigenPod = async () => {
  const url = `${P2P_BASE_URL}eth/staking/eigenlayer/tx/create-pod`
  try {
    const response = await axios.post(url, {}, { headers })
    console.log('EigenPod Creation Response:', response.data)
    return response.data.result
  } catch (error) {
    console.error(
      'Error creating EigenPod:',
      error.response?.data || error.message,
    )
    throw error
  }
}

export const createRestakeRequest = async (
  eigenPodOwnerAddress,
  feeRecipientAddress,
  controllerAddress,
) => {
  const uuid = uuidv4()
  const url = `${P2P_BASE_URL}eth/staking/direct/nodes-request/create`
  const data = {
    id: uuid,
    type: 'RESTAKING',
    validatorsCount: 1,
    eigenPodOwnerAddress,
    feeRecipientAddress,
    controllerAddress,
    nodesOptions: { location: 'any', relaysSet: null },
  }
  try {
    const response = await axios({
      method: 'post',
      url,
      data,
      headers,
      credentials: 'same-origin',
      mode: 'no-cors',
    })

    return { uuid, result: response.data.result }
  } catch (error) {
    console.error(
      'Error initiating restake request:',
      error.response?.data || error.message,
    )
    throw error
  }
}

export const getRestakeStatusWithRetry = async (
  uuid,
  retries = 3,
  delay = 3000,
) => {
  const url = `${P2P_BASE_URL}eth/staking/direct/nodes-request/status/${uuid}`
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const response = await axios.get(url, {
        headers,
      })
      console.log(`Attempt ${attempt}: Restake Status Response:`, response.data)
      if (response.data.result.status !== 'processing') {
        return response.data.result
      }
    } catch (error) {
      console.error(
        'Error fetching restake status:',
        error.response?.data || error.message,
      )
      throw error
    }
    await new Promise((resolve) => setTimeout(resolve, delay))
  }
  throw new Error("Restake status is still 'processing' after maximum retries")
}

export const createDepositTx = async (result) => {
  const url = `${P2P_BASE_URL}eth/staking/direct/tx/deposit`
  const depositData = result.depositData[0]
  const data = {
    depositData: [
      {
        pubkey: depositData.pubkey,
        signature: depositData.signature,
        depositDataRoot: depositData.depositDataRoot,
      },
    ],
    withdrawalAddress: result.eigenPodAddress,
  }
  try {
    const response = await axios.post(url, data, {
      headers,
    })
    console.log('Deposit Transaction Response:', response.data)
    let pubkey = depositData.pubkey

    console.log('Pubkey:', pubkey)
    return response.data.result
  } catch (error) {
    console.error(
      'Error creating deposit transaction:',
      error.response?.data || error.message,
    )
    throw error
  }
}
