import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Header from './components/Header';
import Markets from './components/Markets';
import CreateMarket from './components/CreateMarket';
import MarketDetail from './components/MarketDetail';
import Portfolio from './components/Portfolio';

export interface UserSession {
  isConnected: boolean;
  address: string | null;
}

function App() {
  const [userSession, setUserSession] = useState<UserSession>({
    isConnected: false,
    address: null,
  });

  return (
    <BrowserRouter>
      <div className="app">
        <Header userSession={userSession} setUserSession={setUserSession} />
        <main style={{ paddingTop: '100px', minHeight: '100vh' }}>
          <Routes>
            <Route path="/" element={<Markets />} />
            <Route path="/create" element={<CreateMarket userSession={userSession} />} />
            <Route path="/market/:id" element={<MarketDetail userSession={userSession} />} />
            <Route path="/portfolio" element={<Portfolio userSession={userSession} />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
