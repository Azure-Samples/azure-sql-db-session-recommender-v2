export type SupportingContentRecord = {
  title: string;
  content: string;
  url: string;
  similarity: number;
};

export type AskResponse = {
  answer: string;
  thoughts?: string;
  dataPoints: SupportingContentRecord[];
  citationBaseUrl: string;
  error?: string | null;
};
