import { BrowserRouter, Route, Routes } from 'react-router-dom'
import Homepage from './pages/Homepage'
import DashboardPage from './pages/DashboardPage'

import { getDefaultConfig, RainbowKitProvider } from '@rainbow-me/rainbowkit'
import { WagmiProvider } from 'wagmi'
import { holesky, sepolia, gnosis } from 'wagmi/chains'
import { QueryClientProvider, QueryClient } from '@tanstack/react-query'

import '@rainbow-me/rainbowkit/styles.css'

const App = () => {
  const config = getDefaultConfig({
    appName: 'Chama P2P | Finance',
    projectId: 'YOUR_PROJECT_ID',
    chains: [holesky, sepolia, gnosis],
    ssr: false,
  })

  const queryClient = new QueryClient()

  return (
    <div className="bg-black">
      <BrowserRouter>
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            <RainbowKitProvider initialChain={sepolia}>
              <Routes>
                <Route path="/" element={<Homepage />} />
                <Route path="/Dashboard" element={<DashboardPage />} />
              </Routes>
            </RainbowKitProvider>
          </QueryClientProvider>
        </WagmiProvider>
      </BrowserRouter>
    </div>
  )
}

export default App
