import { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { UserSession } from '../App';

interface MarketDetailProps {
  userSession: UserSession;
}

const mockPriceHistory = Array.from({ length: 30 }, (_, i) => ({
  block: 900000 + i * 1000,
  yesPrice: 50 + Math.random() * 30 - 15 + (i * 0.5),
}));

export default function MarketDetail({ userSession }: MarketDetailProps) {
  const { id } = useParams();
  const [betAmount, setBetAmount] = useState('');
  const [selectedSide, setSelectedSide] = useState<'yes' | 'no' | null>(null);

  const market = {
    id: Number(id),
    question: 'Will Bitcoin reach $150,000 by end of 2026?',
    category: 'Crypto',
    creator: 'SP2PEBKJ2W1ZDDF2QQ6Y4FXKZEDPT9J9R2NKD9WJB',
    endBlock: 950000,
    yesPool: 125000000000,
    noPool: 85000000000,
    totalVolume: 210000000000,
    status: 'active' as const,
    createdAt: 890000,
  };

  const yesOdds = (market.yesPool / (market.yesPool + market.noPool) * 100).toFixed(1);
  const noOdds = (100 - parseFloat(yesOdds)).toFixed(1);

  const calculatePayout = () => {
    if (!betAmount || !selectedSide) return 0;
    const amount = parseFloat(betAmount) * 1000000;
    const pool = selectedSide === 'yes' ? market.yesPool : market.noPool;
    const oppositePool = selectedSide === 'yes' ? market.noPool : market.yesPool;
    return ((amount / (pool + amount)) * (pool + oppositePool + amount) / 1000000).toFixed(2);
  };

  const handleBet = async () => {
    if (!userSession.isConnected) {
      alert('Please connect your wallet first');
      return;
    }
    console.log('Placing bet:', { amount: betAmount, side: selectedSide });
  };

  return (
    <div className="container" style={{ paddingTop: '40px', paddingBottom: '80px' }}>
      <Link to="/" style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '8px',
        color: 'var(--text-secondary)',
        textDecoration: 'none',
        marginBottom: '24px',
      }}>
        ← Back to Markets
      </Link>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 400px', gap: '32px' }}>
        <div>
          <div className="card" style={{ marginBottom: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
              <span className="tag tag-active">{market.status}</span>
              <span style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{market.category}</span>
            </div>

            <h1 style={{ fontSize: '28px', fontWeight: 700, marginBottom: '24px', lineHeight: 1.4 }}>
              {market.question}
            </h1>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: '12px', marginBottom: '4px' }}>Volume</div>
                <div className="mono" style={{ fontSize: '18px', fontWeight: 600 }}>
                  {(market.totalVolume / 1000000000000).toFixed(2)} STX
                </div>
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: '12px', marginBottom: '4px' }}>YES Pool</div>
                <div className="mono" style={{ fontSize: '18px', fontWeight: 600, color: 'var(--accent-green)' }}>
                  {(market.yesPool / 1000000000000).toFixed(2)} STX
                </div>
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: '12px', marginBottom: '4px' }}>NO Pool</div>
                <div className="mono" style={{ fontSize: '18px', fontWeight: 600, color: 'var(--accent-red)' }}>
                  {(market.noPool / 1000000000000).toFixed(2)} STX
                </div>
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: '12px', marginBottom: '4px' }}>End Block</div>
                <div className="mono" style={{ fontSize: '18px', fontWeight: 600 }}>
                  #{market.endBlock.toLocaleString()}
                </div>
              </div>
            </div>
          </div>

          <div className="card">
            <h3 style={{ marginBottom: '24px', fontSize: '18px', fontWeight: 600 }}>
              Price History
            </h3>
            <div style={{ height: '300px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={mockPriceHistory}>
                  <XAxis
                    dataKey="block"
                    stroke="var(--text-muted)"
                    fontSize={12}
                    tickFormatter={(v) => `#${(v / 1000).toFixed(0)}k`}
                  />
                  <YAxis
                    stroke="var(--text-muted)"
                    fontSize={12}
                    domain={[0, 100]}
                    tickFormatter={(v) => `${v}%`}
                  />
                  <Tooltip
                    contentStyle={{
                      background: 'var(--bg-card)',
                      border: '1px solid var(--border-color)',
                      borderRadius: '8px',
                    }}
                    labelFormatter={(v) => `Block #${v}`}
                    formatter={(v: number) => [`${v.toFixed(1)}%`, 'YES Price']}
                  />
                  <Line
                    type="monotone"
                    dataKey="yesPrice"
                    stroke="var(--accent-green)"
                    strokeWidth={2}
                    dot={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        <div>
          <div className="card" style={{ position: 'sticky', top: '100px' }}>
            <h3 style={{ marginBottom: '24px', fontSize: '18px', fontWeight: 600 }}>
              Place Your Bet
            </h3>

            <div style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
              <button
                onClick={() => setSelectedSide('yes')}
                style={{
                  flex: 1,
                  padding: '20px',
                  borderRadius: '12px',
                  border: selectedSide === 'yes' ? '2px solid var(--accent-green)' : '2px solid var(--border-color)',
                  background: selectedSide === 'yes' ? 'rgba(0, 255, 136, 0.1)' : 'var(--bg-secondary)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                }}
              >
                <div style={{ color: 'var(--accent-green)', fontSize: '28px', fontWeight: 700 }}>
                  {yesOdds}%
                </div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '14px', marginTop: '4px' }}>
                  YES
                </div>
              </button>
              <button
                onClick={() => setSelectedSide('no')}
                style={{
                  flex: 1,
                  padding: '20px',
                  borderRadius: '12px',
                  border: selectedSide === 'no' ? '2px solid var(--accent-red)' : '2px solid var(--border-color)',
                  background: selectedSide === 'no' ? 'rgba(255, 68, 102, 0.1)' : 'var(--bg-secondary)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                }}
              >
                <div style={{ color: 'var(--accent-red)', fontSize: '28px', fontWeight: 700 }}>
                  {noOdds}%
                </div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '14px', marginTop: '4px' }}>
                  NO
                </div>
              </button>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
                Amount (STX)
              </label>
              <input
                type="number"
                value={betAmount}
                onChange={(e) => setBetAmount(e.target.value)}
                placeholder="Enter amount"
                min="1"
                step="1"
              />
              <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                {[10, 50, 100, 500].map((amount) => (
                  <button
                    key={amount}
                    onClick={() => setBetAmount(String(amount))}
                    style={{
                      flex: 1,
                      padding: '8px',
                      borderRadius: '8px',
                      border: 'none',
                      background: 'var(--bg-secondary)',
                      color: 'var(--text-secondary)',
                      cursor: 'pointer',
                      fontSize: '13px',
                    }}
                  >
                    {amount}
                  </button>
                ))}
              </div>
            </div>

            {betAmount && selectedSide && (
              <div style={{
                padding: '16px',
                background: 'var(--bg-secondary)',
                borderRadius: '12px',
                marginBottom: '24px',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Potential Payout</span>
                  <span className="mono" style={{ fontWeight: 600, color: 'var(--accent-green)' }}>
                    {calculatePayout()} STX
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Return</span>
                  <span className="mono" style={{ fontWeight: 600 }}>
                    {((parseFloat(calculatePayout()) / parseFloat(betAmount) - 1) * 100).toFixed(1)}%
                  </span>
                </div>
              </div>
            )}

            <button
              onClick={handleBet}
              disabled={!selectedSide || !betAmount}
              className={`btn ${selectedSide === 'yes' ? 'btn-yes' : selectedSide === 'no' ? 'btn-no' : 'btn-secondary'}`}
              style={{
                width: '100%',
                padding: '16px',
                fontSize: '16px',
                opacity: !selectedSide || !betAmount ? 0.5 : 1,
              }}
            >
              {!userSession.isConnected
                ? 'Connect Wallet'
                : !selectedSide
                ? 'Select YES or NO'
                : `Place ${selectedSide.toUpperCase()} Bet`}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
