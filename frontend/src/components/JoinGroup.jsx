import { useEffect } from 'react'
import {
  useAccount,
  useBlockNumber,
  useReadContracts,
  useSendTransaction,
  useWaitForTransactionReceipt,
  useWriteContract,
} from 'wagmi'
import { ABI, CHAMA_CONTRACT_ADDRESS } from '../constants'
import { formatEther } from 'viem'
import { ToastContainer, toast } from 'react-toastify'
import {
  createDepositTx,
  createRestakeRequest,
  getRestakeStatusWithRetry,
} from '../services'

const CYCLE_DAYS = {
  1: 'Daily',
  7: 'Weekly',
  14: 'Bi-Weekly',
  30: 'Monthly',
  365: 'Annually',
}

const JoinGroup = () => {
  const { address: user } = useAccount()
  const {
    data: depositHash,
    isPending: depositIsPending,
    error: depositError,
    sendTransaction,
  } = useSendTransaction()

  const {
    data: contributeHash,
    error: contributeError,
    isPending: contributeIsPending,
    writeContract,
  } = useWriteContract()

  const {
    isLoading: contributeIsConfirming,
    isSuccess: contributeIsConfirmed,
  } = useWaitForTransactionReceipt({
    hash: contributeHash,
  })

  const {
    data: joinGroupHash,
    error: joinGroupError,
    isPending: joinGroupIsPending,
    writeContract: writeJoinGroup,
  } = useWriteContract()

  const { isLoading: joinGroupIsConfirming, isSuccess: joinGroupIsConfirmed } =
    useWaitForTransactionReceipt({
      hash: joinGroupHash,
    })

  let {
    data: groups,
    error,
    isPending,
    refetch,
  } = useReadContracts({
    contracts: Array.from(Array(5).keys()).map((i) => ({
      address: CHAMA_CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'getGroup',
      args: [i + 1],
    })),
  })

  groups =
    groups
      ?.filter((group) => group.result)
      .map((group) => ({ ...group.result })) || []

  let { data: members } = useReadContracts({
    contracts: groups.map((g) => ({
      address: CHAMA_CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'members',
      args: [g.id],
    })),
    query: {
      enabled: groups.length > 0,
    },
  })

  {
    members =
      members
        ?.filter((member) => member.result)
        .map((m) => ({ ...m.result })) || []
  }

  // let { data: roundBalance } = useReadContracts({
  //   contracts: groups.map((g) => ({
  //     address: CHAMA_CONTRACT_ADDRESS,
  //     abi: ABI,
  //     functionName: 'roundBalance',
  //     args: [g.id, g.currentRound],
  //   })),
  //   query: {
  //     enabled: groups.length > 0,
  //   },
  // })

  const { data: blockNumber } = useBlockNumber({ watch: true })

  useEffect(() => {
    if (Number(blockNumber) % 5 === 0) refetch() // refetch every 5 blocks
  }, [refetch, blockNumber])

  const handleContribute = async (groupId) => {
    writeContract({
      address: CHAMA_CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'contribute',
      args: [groupId],
      value: groups.find((g) => g.id === groupId).contributionAmount,
    })
  }
  {
    if (contributeIsPending) {
      toast('Contribution in progress...', {
        type: 'info',
        toastId: 'contribute-pending',
      })
    }

    if (contributeIsConfirming) {
      toast('Confirming contribution...', {
        type: 'info',
        toastId: 'contribute-confirming',
      })
    }
    if (contributeIsConfirmed) {
      toast('Contribution successful!', {
        type: 'success',
        toastId: 'contribute-success',
      })
    }

    if (contributeError) {
      toast(
        `Failed to contribute: ${
          contributeError.shortMessage || contributeError.message
        }`,
        {
          type: 'error',
          toastId: 'contribute-error',
        },
      )
    }
  }

  const handleJoinGroup = async (groupId) => {
    writeJoinGroup({
      address: CHAMA_CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'joinGroup',
      args: [groupId],
    })
  }

  {
    if (joinGroupIsPending) {
      toast('Joining group...', {
        type: 'info',
        toastId: 'join-pending',
      })
    }

    if (joinGroupIsConfirming) {
      toast('Confirming group join...', {
        type: 'info',
        toastId: 'join-confirming',
      })
    }
    if (joinGroupIsConfirmed) {
      toast('Group join successful!', {
        type: 'success',
        toastId: 'join-success',
      })
    }

    if (joinGroupError) {
      toast(
        `Failed to join group: ${
          joinGroupError.shortMessage || joinGroupError.message
        }`,
        {
          type: 'error',
          toastId: 'join-error',
        },
      )
    }
  }

  const handleRestaking = async (groupId) => {
    console.log(`Restaking for group ${groupId}...`)

    toast('Initiating restaking request...', {
      type: 'info',
      toastId: 'restake-initiating',
    })
    let restakingResponse

    try {
      const eigenPodOwnerAddress = user
      const feeRecipientAddress = user
      const controllerAddress = user

      restakingResponse = await createRestakeRequest(
        eigenPodOwnerAddress,
        feeRecipientAddress,
        controllerAddress,
      )

      toast('Restaking request initiated!', {
        type: 'success',
        toastId: 'restake-success',
      })

      let restakeStatus

      try {
        toast('Checking restaking status...', {
          type: 'info',
          toastId: 'restake-status',
        })
        restakeStatus = await getRestakeStatusWithRetry(restakingResponse.uuid)

        console.log('Restaking Status:', restakeStatus)
      } catch (error) {
        toast.error(`Failed to get restaking status: ${error.message}`, {
          toastId: 'restake-status-error',
        })
      }

      let depositTxResponse

      try {
        toast('Creating deposit transaction...', {
          type: 'info',
          toastId: 'restake-deposit-tx',
        })
        depositTxResponse = await createDepositTx(restakeStatus)

        console.log('Deposit Transaction Response:', depositTxResponse)

        toast('Deposit transaction created!', {
          type: 'success',
          toastId: 'restake-deposit-tx-success',
        })

        toast('Sending deposit transaction...', {
          type: 'info',
          toastId: 'restake-deposit-tx-sending',
        })

        sendTransaction({
          to: depositTxResponse.to,
          data: depositTxResponse.data,
          value: depositTxResponse.value,
        })
      } catch (error) {
        toast.error(`Failed to create deposit transaction: ${error.message}`, {
          toastId: 'restake-deposit-tx-error',
        })
      }
    } catch (error) {
      toast.error(`Failed to initiate restaking: ${error.message}`, {
        toastId: 'restake-error',
      })
    }
  }

  const {
    isLoading: depositIsConfirming,
    depositIsSuccess: depositIsConfirmed,
  } = useWaitForTransactionReceipt({
    hash: depositHash,
  })

  {
    if (depositIsPending) {
      toast('Deposit transaction in progress...', {
        type: 'info',
        toastId: 'deposit-pending',
      })
    }

    if (depositIsConfirming) {
      toast('Confirming deposit transaction...', {
        type: 'info',
        toastId: 'deposit-confirming',
      })
    }

    if (depositIsConfirmed) {
      toast('Deposit transaction confirmed!', {
        type: 'success',
        toastId: 'deposit-confirmed',
      })
    }

    if (depositHash) {
      toast('Deposit transaction sent!', {
        type: 'success',
        toastId: 'deposit-success',
      })
    }

    if (depositError) {
      toast(
        `Failed to deposit: ${
          depositError.shortMessage || depositError.message
        }`,
        {
          type: 'error',
          toastId: 'deposit-error',
        },
      )
    }
  }

  return (
    <div className="p-5 font-funnel">
      <h1 className="text-3xl font-bold mb-4 font-orbitron">
        Available Groups
      </h1>
      <p className="text-gray-600 mb-6">Join an existing ROSCA group</p>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {isPending && <p>Loading...</p>}
        {error && <p>Error: {error?.shortMessage || error.message}</p>}

        {groups.map((group, i) => (
          <div
            key={i}
            className="p-4 border rounded-lg shadow-md bg-gray-700 text-white flex flex-col justify-between"
          >
            <div className="">
              <div className="flex justify-between items-center mb-2">
                <h2 className="text-lg font-semibold">{group.name}</h2>
                <span className="px-2 py-1 bg-gray-600 text-sm rounded">
                  {CYCLE_DAYS[group.cycleDays]}
                </span>
              </div>
              <p className="text-sm text-white">
                Members: {`${group.memberId} / ${group.maxMembers}`}
              </p>
              <p className="text-sm text-white">
                Contribution: {formatEther(group.contributionAmount)} ETH
              </p>
              <p className="text-sm text-white">
                Total Pot:{' '}
                {formatEther(group.contributionAmount * group.memberId) || 0}{' '}
                ETH
              </p>
              <p className="text-sm text-white">
                Next Payout:{' '}
                {formatEther(group.contributionAmount * group.memberId)} ETH
              </p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              {group.creator.toLowerCase() === user.toLowerCase() ? (
                <button
                  onClick={() => handleRestaking(group.id)}
                  className="mt-4 py-1 px-4 bg-white text-gray-700 rounded hover:bg-gray-400 hover:text-white cursor-pointer"
                  disabled={depositIsPending}
                >
                  {depositIsPending ? 'Restaking...' : 'Re/stake'}
                </button>
              ) : !members
                  .map((m, i) => m[i].member.toLowerCase())
                  .includes(user.toLowerCase()) ? (
                <button
                  onClick={() => handleJoinGroup(group.id)}
                  className="mt-4 py-1 px-4 bg-white text-gray-700 rounded hover:bg-gray-400 hover:text-white cursor-pointer"
                >
                  Join
                </button>
              ) : null}

              <button
                onClick={() => handleContribute(group.id)}
                className="mt-4 py-1 px-4 bg-white text-gray-700 rounded hover:bg-gray-400 hover:text-white cursor-pointer"
                disabled={contributeIsPending}
              >
                Contribute
              </button>
            </div>
          </div>
        ))}
      </div>
      <div className="flex justify-end mt-[4em]">
        <a
          href="/Dashboard"
          className="text-white bg-gray-800  border-[2px] border-white text-[24px] py-[0.5em]  px-[1em] rounded-[10px] "
        >
          Back
        </a>
      </div>
      {/* Disclaimer Popup */}
      {/* {showDisclaimer && (
        <div className="fixed inset-0 lightGrayBg2 flex justify-center items-center z-50">
          <div className="bg-gray-900 p-6 rounded-lg w-1/3">
            <h3 className="text-xl font-semibold mb-4">Disclaimer</h3>
            <p className="text-sm mb-4">
              By joining this group, you agree to:{' '}
            </p>
            <ul className="list-disc ml-[1em]">
              <li>
                Contribute {selectedGroup?.contribution_amount} to the total
                pot.
              </li>
              <li>Understand the payout schedule</li>
              <li>Agree to the group rules</li>
            </ul>
            <div className="flex justify-between mt-[2em]">
              <button
                onClick={handleDisclaimerCancel}
                className="py-2 px-4 bg-red-500 text-white rounded hover:bg-red-600"
              >
                Cancel
              </button>
              <button
                onClick={handleDisclaimerContinue}
                className="py-2 px-4 bg-green-500 text-white rounded hover:bg-green-600"
              >
                Continue
              </button>
            </div>
          </div>
        </div>
      )} */}

      {/* Confirmation Popup */}
      {/* {showConfirmation && (
        <div className="fixed inset-0 lightGrayBg2 flex justify-center items-center z-50">
          <div className="bg-gray-900 p-6 rounded-lg w-1/3">
            <h3 className="text-xl font-semibold mb-4">Confirm Payment</h3>
            <p className="text-sm mb-4">
              You are about to pay {selectedGroup?.contribution_amount} to join
              the group {selectedGroup?.name}. Do you wish to proceed?
            </p>
            <div className="flex justify-between">
              <button
                onClick={handlePaymentCancel}
                className="py-2 px-4 bg-red-500 text-white rounded hover:bg-red-600"
              >
                Cancel
              </button>
              <button
                onClick={handlePaymentConfirm}
                className="py-2 px-4 bg-green-500 text-white rounded hover:bg-green-600"
              >
                Pay
              </button>
            </div>
          </div>
        </div>
      )} */}

      <ToastContainer />
    </div>
  )
}

export default JoinGroup
