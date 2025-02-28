import { useState } from 'react'
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi'
import { ABI, CHAMA_CONTRACT_ADDRESS } from '../constants'
import { parseUnits, zeroAddress } from 'viem'
import { ToastContainer, toast } from 'react-toastify'
import { useNavigate } from 'react-router-dom'

const DEFAULT_STATE = {
  name: '',
  description: '',
  maxMembers: 0,
  cycleDays: 0,
  contributionAmount: 0,
  joinFee: 0,
  lateFee: 0,
}

const CYCLE_DAYS = {
  daily: 1,
  weekly: 7,
  biweekly: 14,
  monthly: 30,
  annually: 365,
}

const CreateGroup = () => {
  const { data: hash, error, isPending, writeContract } = useWriteContract()

  const [state, setState] = useState(DEFAULT_STATE)

  const navigate = useNavigate()

  const onSubmit = async (e) => {
    e.preventDefault()

    // string name;
    //     string description;
    //     address vault;
    //     uint256 maxMembers;
    //     uint256 cycleDays;
    //     uint256 contributionAmount;
    //     uint256 joinFee;
    //     uint256 lateFee;

    let {
      name,
      description,
      maxMembers,
      cycleDays,
      contributionAmount,
      joinFee,
      lateFee,
    } = state

    // TODO: validate form data

    const vault = zeroAddress
    cycleDays = CYCLE_DAYS[cycleDays]

    toast('Creating group...', { type: 'info', toastId: 'creating' })

    contributionAmount = parseUnits(contributionAmount, 18)

    const args = [
      [
        name,
        description,
        vault,
        maxMembers,
        cycleDays,
        contributionAmount,
        joinFee,
        lateFee,
      ],
    ]

    writeContract({
      address: CHAMA_CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'createGroup',
      args,
    })
  }

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    })

  if (isConfirming) {
    toast('Waiting for confirmation...', {
      type: 'info',
      toastId: 'confirming',
    })
  }

  if (isConfirmed) {
    toast('Group created successfully!', {
      type: 'success',
      toastId: 'success',
    })
    navigate('/Dashboard')
  }

  if (error) {
    toast(`Error creating group: ${error.shortMessage || error.message}`, {
      type: 'error',
      toastId: 'error',
    })
  }

  return (
    <div>
      <h1 className="ml-[10%] pl-[5vw] text-[32px] font-orbitron font-bold pb-[1em]">
        Create New Group
      </h1>
      <form
        className="text-white text-[20px] font-funnel w-[80%] mx-auto px-[5vw] "
        onSubmit={onSubmit}
      >
        <label htmlFor="name" className="">
          Group Name
        </label>{' '}
        <br />
        <input
          type="text"
          name="name"
          id="name"
          placeholder="Group Name"
          value={state.name} // Bind the input value to state
          onChange={(e) => setState({ ...state, name: e.target.value })} // Update state on input change
          className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
          required
        />
        <textarea
          name="desciption"
          id="desciption"
          rows="4"
          value={state.description} // Bind the input value to state
          placeholder="A brief description of the group"
          onChange={(e) => setState({ ...state, description: e.target.value })} // Update state on input change
          // Bind the input value to state
          className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
          required
        />
        <div className="flex gap-[2vw] ">
          <div className="w-1/2">
            <label htmlFor="maxMembers" className="">
              Max Members
            </label>{' '}
            <br />
            <input
              type="number"
              name="maxMembers"
              id="maxMembers"
              value={state.maxMembers} // Bind the input value to state
              onChange={(e) =>
                setState({ ...state, maxMembers: e.target.value })
              } // Update state on input change
              className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
            />
          </div>
          <div className="w-1/2">
            <label htmlFor="contributionAmount" className="">
              Contribution Amount
            </label>{' '}
            <br />
            <input
              type="number"
              name="contributionAmount"
              id="contributionAmount"
              value={state.contributionAmount} // Bind the input value to state
              onChange={(e) =>
                setState({ ...state, contributionAmount: e.target.value })
              } // Update state on input change
              className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
            />{' '}
          </div>
        </div>
        <br />
        <div className="flex gap-[2vw] ">
          <div className="w-1/2">
            <label htmlFor="joinFee" className="">
              Join Fee
            </label>{' '}
            <br />
            <input
              type="number"
              name="joinFee"
              id="joinFee"
              value={state.joinFee} // Bind the input value to state
              onChange={(e) => setState({ ...state, joinFee: e.target.value })} // Update state on input change
              className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
            />
          </div>
          <div className="w-1/2">
            <label htmlFor="lateFee" className="">
              Late Fee
            </label>{' '}
            <br />
            <input
              type="number"
              name="lateFee"
              id="lateFee"
              value={state.lateFee} // Bind the input value to state
              onChange={(e) => setState({ ...state, lateFee: e.target.value })} // Update state on input change
              className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
            />{' '}
          </div>
        </div>
        <br />
        <label htmlFor="cycleDays" className="">
          Contribution Frequency
        </label>{' '}
        <br />
        <select
          name="cycleDays"
          id="cycleDays"
          className="mt-[0.6em] py-[0.8em] px-[1em] rounded-[10px] border-[1px] border-gray-500 w-full"
          value={state.cycleDays} // Bind the input value to state
          onChange={(e) => setState({ ...state, cycleDays: e.target.value })} // Update state on input change
        >
          <option value="daily">Daily</option>
          <option value="weekly">Weekly</option>
          <option value="biWeekly">Bi-Weekly</option>
          <option value="monthly">Monthly</option>
          <option value="annually">Annually</option>
        </select>
        <div className="flex justify-end mt-[40px] gap-[2vw]">
          <a
            href="/Dashboard"
            className="text-white bg-gray-800  border-[2px] border-white text-[24px] py-[0.5em]  px-[1em] rounded-[10px] "
            disabled={isPending}
          >
            Maybe Later
          </a>
          <button
            type="submit"
            className="bg-white text-gray-700 text-[24px] py-[0.5em]  px-[1em] rounded-[10px]"
            disabled={isPending}
          >
            {isPending ? `Creating group...` : 'Create Group'}
          </button>
        </div>
      </form>
      <ToastContainer />

      {/* Disclaimer Popup */}
      {/* {showDisclaimer && (
        <div className="fixed inset-0 lightGrayBg2 flex justify-center items-center z-50">
          <div className="bg-gray-900 p-6 rounded-lg w-1/3">
            <h3 className="text-xl font-semibold mb-4">Disclaimer</h3>
            <p className="text-sm mb-4">
              By joining this group, you agree to:{" "}
            </p>
            <ul className="list-disc ml-[1em]">
              <li>
                Contribute {contributionAmount} initially to the total pot.
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
              You are about to pay {contributionAmount} to form the the group{" "}
              {groupName}. Do you wish to proceed?
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
    </div>
  )
}

export default CreateGroup
