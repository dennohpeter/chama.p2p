import { ConnectButton } from "@rainbow-me/rainbowkit";

{
  /* <a
  href=""
  className="bg-blue-500 text-white flex w-fit text-[26px] gap-[0.5em] align-middle rounded-[100px] px-[20px] py-[5px] font-funnel"
>
  <div className="flexCol leading-[1em]">+</div>
  <div className="flexCol">Join a Chama</div>
  <div className="flexCol">
    <svg
      className="w-[0.8em]"
      viewBox="0 0 13 12"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12.5346 6.526C12.8251 6.23074 12.8213 5.75588 12.526 5.46538L7.7144 0.731357C7.41913 0.440854 6.94427 0.444713 6.65377 0.739977C6.36327 1.03524 6.36713 1.5101 6.66239 1.8006L10.9394 6.00862L6.73136 10.2856C6.44085 10.5809 6.44471 11.0557 6.73998 11.3462C7.03524 11.6367 7.5101 11.6329 7.8006 11.3376L12.5346 6.526ZM0.00609568 6.84751L12.0061 6.74998L11.9939 5.25002L-0.00609568 5.34756L0.00609568 6.84751Z"
        fill="white"
      />
    </svg>
  </div>
</a>; */
}

export const ConnectWallet = () => {
  return (
    <ConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        authenticationStatus,
        mounted,
      }) => {
        // Note: If your app doesn't use authentication, you
        // can remove all 'authenticationStatus' checks
        const ready = mounted && authenticationStatus !== "loading";
        const connected =
          ready &&
          account &&
          chain &&
          (!authenticationStatus || authenticationStatus === "authenticated");
        return (
          <div
            {...(!ready && {
              "aria-hidden": true,
              style: {
                opacity: 0,
                pointerEvents: "none",
                userSelect: "none",
              },
            })}
          >
            {(() => {
              if (!connected) {
                return (
                  <button onClick={openConnectModal} type="button">
                    Connect Wallet
                  </button>
                );
              }
              if (chain.unsupported) {
                return (
                  <button onClick={openChainModal} type="button">
                    Wrong network
                  </button>
                );
              }
              return (
                <div style={{ display: "flex", gap: 12 }}>
                  <button
                    onClick={openChainModal}
                    style={{ display: "flex", alignItems: "center" }}
                    type="button"
                  >
                    {chain.hasIcon && (
                      <div
                        style={{
                          background: chain.iconBackground,
                          width: 12,
                          height: 12,
                          borderRadius: 999,
                          overflow: "hidden",
                          marginRight: 4,
                        }}
                      >
                        {chain.iconUrl && (
                          <img
                            alt={chain.name ?? "Chain icon"}
                            src={chain.iconUrl}
                            style={{ width: 12, height: 12 }}
                          />
                        )}
                      </div>
                    )}
                    {chain.name}
                  </button>
                  <button onClick={openAccountModal} type="button">
                    {account.displayName}
                    {account.displayBalance
                      ? ` (${account.displayBalance})`
                      : ""}
                  </button>
                </div>
              );
            })()}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
};
