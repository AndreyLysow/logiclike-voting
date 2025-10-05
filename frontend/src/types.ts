export type Idea = { id: number; title: string; description: string; votesCount: number; hasVoted?: boolean; };
export type IdeasResponse = { ideas: Idea[]; ip: string; };
