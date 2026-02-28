import { UserSession } from '../App';
import { Link } from 'react-router-dom';

interface PortfolioProps {
  userSession: UserSession;
}

interface Position {
  marketId: number;
  question: string;
  side: 'yes' | 'no';
  amount: number;
  avgPrice: number;
  currentPrice: number;
  pnl: number;
  pnlPercent: number;
}

const mockPositions: Position[] = [
  {
    marketId: 1,
    question: 'Will Bitcoin reach $150,000 by end of 2026?',
    side: 'yes',
    amount: 50000000,
    avgPrice: 55,
    currentPrice: 59.5,
    pnl: 4090909,
    pnlPercent: 8.18,
  },
  {
    marketId: 3,
    question: 'Will Stacks TVL exceed $500M by March 2026?',
    side: 'yes',
    amount: 25000000,
    avgPrice: 60,
    currentPrice: 65,
    pnl: 2083333,
    pnlPercent: 8.33,
  },
  {
    marketId: 4,
    question: 'Will sBTC launch on mainnet before April 2026?',
    side: 'no',
    amount: 15000000,
    avgPrice: 20,
    currentPrice: 13.6,
    pnl: 4705882,
    pnlPercent: 31.37,
  },
];

export default function Portfolio({ userSession }: PortfolioProps) {
  if (!userSession.isConnected) {
    return (
      <div className="container" style={{
        paddingTop: '100px',
        paddingBottom: '80px',
        textAlign: 'center',
      }}>
        <div style={{
          width: '80px',
          height: '80px',
          borderRadius: '20px',
          background: 'var(--bg-card)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '40px',
          margin: '0 auto 24px',
        }}>
          🔒
        </div>
        <h2 style={{ fontSize: '28px', fontWeight: 700, marginBottom: '16px' }}>
          Connect Your Wallet
        </h2>
        <p style={{ color: 'var(--text-secondary)', marginBottom: '32px' }}>
          Connect your wallet to view your prediction positions and history.
        </p>
      </div>
    );
  }

  const totalValue = mockPositions.reduce((sum, p) => sum + p.amount, 0);
  const totalPnl = mockPositions.reduce((sum, p) => sum + p.pnl, 0);
  const totalPnlPercent = (totalPnl / (totalValue - totalPnl)) * 100;

  return (
    <div className="container" style={{ paddingTop: '40px', paddingBottom: '80px' }}>
      <div style={{ marginBottom: '48px' }}>
        <h1 style={{ fontSize: '40px', fontWeight: 700, marginBottom: '16px' }}>
          <span className="gradient-text">Your Portfolio</span>
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '16px' }}>
          Track your prediction positions and performance.
        </p>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '24px',
        marginBottom: '48px',
      }}>
        <div className="card">
          <div style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px' }}>
            Total Value
          </div>
          <div className="mono" style={{ fontSize: '28px', fontWeight: 700 }}>
            {(totalValue / 1000000).toFixed(2)} STX
          </div>
        </div>
        <div className="card">
          <div style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px' }}>
            Total P&L
          </div>
          <div className="mono" style={{
            fontSize: '28px',
            fontWeight: 700,
            color: totalPnl >= 0 ? 'var(--accent-green)' : 'var(--accent-red)',
          }}>
            {totalPnl >= 0 ? '+' : ''}{(totalPnl / 1000000).toFixed(2)} STX
          </div>
        </div>
        <div className="card">
          <div style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px' }}>
            Return
          </div>
          <div className="mono" style={{
            fontSize: '28px',
            fontWeight: 700,
            color: totalPnlPercent >= 0 ? 'var(--accent-green)' : 'var(--accent-red)',
          }}>
            {totalPnlPercent >= 0 ? '+' : ''}{totalPnlPercent.toFixed(2)}%
          </div>
        </div>
        <div className="card">
          <div style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '8px' }}>
            Active Positions
          </div>
          <div className="mono" style={{ fontSize: '28px', fontWeight: 700 }}>
            {mockPositions.length}
          </div>
        </div>
      </div>

      <div className="card">
        <h3 style={{ marginBottom: '24px', fontSize: '18px', fontWeight: 600 }}>
          Active Positions
        </h3>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)' }}>
                <th style={{ textAlign: 'left', padding: '12px 16px', color: 'var(--text-muted)', fontWeight: 500, fontSize: '13px' }}>
                  Market
                </th>
                <th style={{ textAlign: 'center', padding: '12px 16px', color: 'var(--text-muted)', fontWeight: 500, fontSize: '13px' }}>
                  Side
                </th>
                <th style={{ textAlign: 'right', padding: '12px 16px', color: 'var(--text-muted)', fontWeight: 500, fontSize: '13px' }}>
                  Amount
                </th>
                <th style={{ textAlign: 'right', padding: '12px 16px', color: 'var(--text-muted)', fontWeight: 500, fontSize: '13px' }}>
                  Avg Price
                </th>
                <th style={{ textAlign: 'right', padding: '12px 16px', color: 'var(--text-muted)', fontWeight: 500, fontSize: '13px' }}>
                  Current
                </th>
                <th style={{ textAlign: 'right', padding: '12px 16px', color: 'var(--text-muted)', fontWeight: 500, fontSize: '13px' }}>
                  P&L
                </th>
              </tr>
            </thead>
            <tbody>
              {mockPositions.map((position) => (
                <tr
                  key={position.marketId}
                  style={{ borderBottom: '1px solid var(--border-color)' }}
                >
                  <td style={{ padding: '16px' }}>
                    <Link
                      to={`/market/${position.marketId}`}
                      style={{
                        color: 'var(--text-primary)',
                        textDecoration: 'none',
                        fontWeight: 500,
                      }}
                    >
                      {position.question.length > 50
                        ? position.question.slice(0, 50) + '...'
                        : position.question}
                    </Link>
                  </td>
                  <td style={{ textAlign: 'center', padding: '16px' }}>
                    <span style={{
                      padding: '4px 12px',
                      borderRadius: '20px',
                      fontSize: '12px',
                      fontWeight: 600,
                      background: position.side === 'yes'
                        ? 'rgba(0, 255, 136, 0.15)'
                        : 'rgba(255, 68, 102, 0.15)',
                      color: position.side === 'yes'
                        ? 'var(--accent-green)'
                        : 'var(--accent-red)',
                      textTransform: 'uppercase',
                    }}>
                      {position.side}
                    </span>
                  </td>
                  <td className="mono" style={{ textAlign: 'right', padding: '16px' }}>
                    {(position.amount / 1000000).toFixed(2)} STX
                  </td>
                  <td className="mono" style={{ textAlign: 'right', padding: '16px', color: 'var(--text-secondary)' }}>
                    {position.avgPrice.toFixed(1)}%
                  </td>
                  <td className="mono" style={{ textAlign: 'right', padding: '16px' }}>
                    {position.currentPrice.toFixed(1)}%
                  </td>
                  <td style={{ textAlign: 'right', padding: '16px' }}>
                    <div className="mono" style={{
                      fontWeight: 600,
                      color: position.pnl >= 0 ? 'var(--accent-green)' : 'var(--accent-red)',
                    }}>
                      {position.pnl >= 0 ? '+' : ''}{(position.pnl / 1000000).toFixed(2)} STX
                    </div>
                    <div style={{
                      fontSize: '12px',
                      color: position.pnlPercent >= 0 ? 'var(--accent-green)' : 'var(--accent-red)',
                    }}>
                      {position.pnlPercent >= 0 ? '+' : ''}{position.pnlPercent.toFixed(2)}%
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
