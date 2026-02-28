import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserSession } from '../App';

interface CreateMarketProps {
  userSession: UserSession;
}

export default function CreateMarket({ userSession }: CreateMarketProps) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    question: '',
    category: 'Crypto',
    duration: '7',
    initialLiquidity: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const categories = ['Crypto', 'DeFi', 'Stacks', 'Sports', 'Politics', 'Other'];
  const durations = [
    { value: '1', label: '1 Day (~144 blocks)' },
    { value: '7', label: '1 Week (~1,008 blocks)' },
    { value: '30', label: '1 Month (~4,320 blocks)' },
    { value: '90', label: '3 Months (~12,960 blocks)' },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userSession.isConnected) {
      alert('Please connect your wallet first');
      return;
    }

    setIsSubmitting(true);
    
    try {
      console.log('Creating market:', formData);
      await new Promise((resolve) => setTimeout(resolve, 2000));
      navigate('/');
    } catch (error) {
      console.error('Error creating market:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="container" style={{ paddingTop: '40px', paddingBottom: '80px', maxWidth: '800px' }}>
      <div style={{ marginBottom: '48px' }}>
        <h1 style={{ fontSize: '40px', fontWeight: 700, marginBottom: '16px' }}>
          <span className="gradient-text">Create Market</span>
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '16px' }}>
          Launch a new prediction market and let the community trade on outcomes.
        </p>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="card" style={{ marginBottom: '24px' }}>
          <h3 style={{ marginBottom: '24px', fontSize: '18px', fontWeight: 600 }}>
            Market Details
          </h3>

          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
              Question *
            </label>
            <textarea
              value={formData.question}
              onChange={(e) => setFormData({ ...formData, question: e.target.value })}
              placeholder="Will Bitcoin reach $150,000 by end of 2026?"
              required
              rows={3}
              style={{ resize: 'vertical' }}
            />
            <p style={{ marginTop: '8px', color: 'var(--text-muted)', fontSize: '12px' }}>
              Ask a clear yes/no question about a future event
            </p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
            <div>
              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
                Category
              </label>
              <select
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                style={{
                  width: '100%',
                  padding: '14px 18px',
                  background: 'var(--bg-secondary)',
                  border: '1px solid var(--border-color)',
                  borderRadius: '12px',
                  color: 'var(--text-primary)',
                  fontSize: '14px',
                }}
              >
                {categories.map((cat) => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
                Duration
              </label>
              <select
                value={formData.duration}
                onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                style={{
                  width: '100%',
                  padding: '14px 18px',
                  background: 'var(--bg-secondary)',
                  border: '1px solid var(--border-color)',
                  borderRadius: '12px',
                  color: 'var(--text-primary)',
                  fontSize: '14px',
                }}
              >
                {durations.map((d) => (
                  <option key={d.value} value={d.value}>{d.label}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="card" style={{ marginBottom: '24px' }}>
          <h3 style={{ marginBottom: '24px', fontSize: '18px', fontWeight: 600 }}>
            Initial Liquidity
          </h3>

          <div>
            <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
              Amount (STX)
            </label>
            <input
              type="number"
              value={formData.initialLiquidity}
              onChange={(e) => setFormData({ ...formData, initialLiquidity: e.target.value })}
              placeholder="100"
              min="10"
              step="1"
            />
            <p style={{ marginTop: '8px', color: 'var(--text-muted)', fontSize: '12px' }}>
              Minimum 10 STX. Higher liquidity attracts more traders.
            </p>
          </div>
        </div>

        <div className="card" style={{
          background: 'rgba(0, 255, 136, 0.05)',
          border: '1px solid rgba(0, 255, 136, 0.2)',
          marginBottom: '24px',
        }}>
          <h4 style={{ marginBottom: '12px', color: 'var(--accent-green)' }}>
            Market Creation Fee
          </h4>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '16px' }}>
            Creating a market requires a small fee to prevent spam.
          </p>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-muted)' }}>Fee:</span>
            <span className="mono" style={{ fontSize: '18px', fontWeight: 600 }}>0.5 STX</span>
          </div>
        </div>

        <button
          type="submit"
          className="btn btn-primary"
          disabled={isSubmitting || !userSession.isConnected}
          style={{
            width: '100%',
            padding: '18px',
            fontSize: '16px',
            opacity: isSubmitting ? 0.7 : 1,
          }}
        >
          {isSubmitting ? 'Creating Market...' : userSession.isConnected ? 'Create Market' : 'Connect Wallet to Create'}
        </button>
      </form>
    </div>
  );
}
