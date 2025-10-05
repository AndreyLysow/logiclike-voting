import { Idea } from '../types';
type Props = { idea: Idea; onVote: (id: number) => void; loading: boolean; };
export default function IdeaCard({ idea, onVote, loading }: Props) {
  return (
    <div style={{ border: '1px solid #e5e7eb', borderRadius: 8, padding: 12, marginBottom: 10 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <h3 style={{ margin: '4px 0' }}>{idea.title}</h3>
          <p style={{ margin: '4px 0', color: '#4b5563' }}>{idea.description}</p>
        </div>
        <div style={{ textAlign: 'right', minWidth: 120 }}>
          <div style={{ fontWeight: 700, fontSize: 18 }}>{idea.votesCount}</div>
          <div style={{ fontSize: 12, color: '#6b7280' }}>votes</div>
          <button
            disabled={loading || idea.hasVoted}
            onClick={() => onVote(idea.id)}
            style={{ marginTop: 8, padding: '6px 10px', borderRadius: 6, border: '1px solid #d1d5db',
                     background: idea.hasVoted ? '#e5e7eb' : 'white', cursor: idea.hasVoted ? 'not-allowed' : 'pointer' }}
            title={idea.hasVoted ? 'Вы уже голосовали за эту идею' : 'Проголосовать'}
          >
            {idea.hasVoted ? 'Голос учтён' : 'Проголосовать'}
          </button>
        </div>
      </div>
    </div>
  );
}
