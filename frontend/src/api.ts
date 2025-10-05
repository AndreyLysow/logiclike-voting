import type { IdeasResponse } from './types';
export async function fetchIdeas(): Promise<IdeasResponse> {
  const res = await fetch('/api/ideas');
  if (!res.ok) throw new Error('Failed to fetch ideas');
  return res.json();
}
export async function vote(ideaId: number): Promise<void> {
  const res = await fetch(`/api/ideas/${ideaId}/vote`, { method: 'POST' });
  if (res.status === 201) return;
  if (res.status === 409) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.error || 'Conflict: already voted or limit reached');
  }
  throw new Error('Failed to vote');
}
