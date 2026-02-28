import { useState } from 'react';
import { Link } from 'react-router-dom';

interface Market {
  id: number;
  question: string;
  category: string;
  endBlock: number;
  yesPool: number;
  noPool: number;
  totalVolume: number;
  status: 'active' | 'resolved' | 'pending';
  outcome?: boolean;
}

const mockMarkets: Market[] = [
  {
    id: 1,
    question: 'Will Bitcoin reach $150,000 by end of 2026?',
    category: 'Crypto',
    endBlock: 950000,
    yesPool: 125000,
    noPool: 85000,
    totalVolume: 210000,
    status: 'active',
  },
  {
    id: 2,
    question: 'Will STX be listed on Coinbase in Q1 2026?',
    category: 'Crypto',
    endBlock: 920000,
    yesPool: 45000,
    noPool: 55000,
    totalVolume: 100000,
    status: 'active',
  },
  {
    id: 3,
    question: 'Will Stacks TVL exceed $500M by March 2026?',
    category: 'DeFi',
    endBlock: 915000,
    yesPool: 78000,
    noPool: 42000,
    totalVolume: 120000,
    status: 'active',
  },
  {
    id: 4,
    question: 'Will sBTC launch on mainnet before April 2026?',
    category: 'Stacks',
    endBlock: 910000,
    yesPool: 95000,
    noPool: 15000,
    totalVolume: 110000,
    status: 'active',
  },
  {
    id: 5,
    question: 'Will Ethereum ETF approval happen in 2025?',
    category: 'Crypto',
    endBlock: 880000,
    yesPool: 180000,
    noPool: 20000,
    totalVolume: 200000,
    status: 'resolved',
    outcome: true,
  },
];

export default function Markets() {
  const [filter, setFilter] = useState<'all' | 'active' | 'resolved'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredMarkets = mockMarkets.filter((market) => {
    const matchesFilter = filter === 'all' || market.status === filter;
    const matchesSearch = market.question.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const calculateOdds = (yesPool: number, noPool: number) => {
    const total = yesPool + noPool;
    return total > 0 ? ((yesPool / total) * 100).toFixed(1) : '50.0';
  };

  return (
    <div className="container" style={{ paddingTop: '40px', paddingBottom: '80px' }}>
      <div style={{ marginBottom: '48px' }}>
        <h1 style={{ fontSize: '48px', fontWeight: 700, marginBottom: '16px' }}>
          <span className="gradient-text">Prediction Markets</span>
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '18px', maxWidth: '600px' }}>
          Trade on the outcome of future events. Put your predictions to the test and earn rewards.
        </p>
      </div>

      <div style={{
        display: 'flex',
        gap: '16px',
        marginBottom: '32px',
        flexWrap: 'wrap',
        alignItems: 'center',
      }}>
        <input
          type="text"
          placeholder="Search markets..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          style={{ maxWidth: '400px' }}
        />
        <div style={{ display: 'flex', gap: '8px' }}>
          {(['all', 'active', 'resolved'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                padding: '10px 20px',
                borderRadius: '10px',
                border: 'none',
                background: filter === f ? 'var(--accent-green)' : 'var(--bg-card)',
                color: filter === f ? '#000' : 'var(--text-secondary)',
                fontWeight: 600,
                cursor: 'pointer',
                textTransform: 'capitalize',
              }}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(400px, 1fr))',
        gap: '24px',
      }}>
        {filteredMarkets.map((market) => (
          <Link
            key={market.id}
            to={`/market/${market.id}`}
            style={{ textDecoration: 'none' }}
          >
            <div className="card" style={{ height: '100%' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
                <span className={`tag tag-${market.status}`}>
                  {market.status}
                </span>
                <span style={{ color: 'var(--text-muted)', fontSize: '13px' }}>
                  {market.category}
                </span>
              </div>

              <h3 style={{
                fontSize: '18px',
                fontWeight: 600,
                marginBottom: '20px',
                lineHeight: 1.4,
                color: 'var(--text-primary)',
              }}>
                {market.question}
              </h3>

              <div style={{
                display: 'flex',
                gap: '12px',
                marginBottom: '20px',
              }}>
                <div style={{
                  flex: 1,
                  padding: '16px',
                  background: 'rgba(0, 255, 136, 0.1)',
                  borderRadius: '12px',
                  textAlign: 'center',
                }}>
                  <div style={{ color: 'var(--accent-green)', fontSize: '24px', fontWeight: 700 }}>
                    {calculateOdds(market.yesPool, market.noPool)}%
                  </div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '12px', marginTop: '4px' }}>
                    YES
                  </div>
                </div>
                <div style={{
                  flex: 1,
                  padding: '16px',
                  background: 'rgba(255, 68, 102, 0.1)',
                  borderRadius: '12px',
                  textAlign: 'center',
                }}>
                  <div style={{ color: 'var(--accent-red)', fontSize: '24px', fontWeight: 700 }}>
                    {(100 - parseFloat(calculateOdds(market.yesPool, market.noPool))).toFixed(1)}%
                  </div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '12px', marginTop: '4px' }}>
                    NO
                  </div>
                </div>
              </div>

              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                paddingTop: '16px',
                borderTop: '1px solid var(--border-color)',
              }}>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>Volume</div>
                  <div className="mono" style={{ fontWeight: 600 }}>
                    {(market.totalVolume / 1000000).toFixed(2)} STX
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>End Block</div>
                  <div className="mono" style={{ fontWeight: 600 }}>
                    #{market.endBlock.toLocaleString()}
                  </div>
                </div>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
