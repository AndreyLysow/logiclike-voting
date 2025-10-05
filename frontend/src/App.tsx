import { useEffect, useState } from 'react';
import { fetchIdeas, vote } from './api';
import type { Idea } from './types';
import IdeaCard from './components/IdeaCard';

export default function App() {
  const [ideas, setIdeas] = useState<Idea[]>([]);
  const [ip, setIp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setError(null);
    try {
      const data = await fetchIdeas();
      setIdeas(data.ideas);
      setIp(data.ip);
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    }
  }

  useEffect(() => { load(); }, []);

  async function onVote(id: number) {
    setLoading(true);
    setError(null);
    try {
      await vote(id);
      await load();
    } catch (e: any) {
      setError(e.message || 'Не удалось проголосовать');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ maxWidth: 840, margin: '40px auto', padding: '0 12px' }}>
      <h1>Идеи для LogicLike</h1>
      <p style={{ color: '#4b5563' }}>Ваш IP: <code>{ip}</code>. Можно отдать голос не более чем за 10 разных идей.</p>
      {error && (
        <div style={{ background: '#fee2e2', color: '#991b1b', padding: 10, borderRadius: 6, marginBottom: 10 }}>
          {error}
        </div>
      )}
      {ideas.map(idea => (
        <IdeaCard key={idea.id} idea={idea} loading={loading} onVote={onVote} />
      ))}
    </div>
  );
}
