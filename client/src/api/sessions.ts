export type ErrorInfo = {
  errorSource?: string;
  errorCode?: number;
  errorMessage: string;
};

export type SessionInfo = {
  id: string;
  external_id: string;
  title: string;
  abstract: string;
  start_time_PST: string;
  end_time_PST: string;
  cosine_similarity: number;
  speakers: string;
};

export type SessionsResponse = {
  sessions: SessionInfo[];
  errorInfo?: ErrorInfo;
};

export async function getSessions(content: string): Promise<SessionsResponse> {
  const settings = {
    method: "post",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      text: content,
    }),
  };

  const response = await fetch("/data-api/rest/find", settings);
  if (!response.ok) {
    return {
      sessions: [],
      errorInfo: {
        errorSource: "Server",
        errorCode: response.status,
        errorMessage: response.statusText,
      },
    };
  }

  var sessions = [];
  var errorInfo = undefined;
  const data = await response.json();

  if (data.value.length > 0) {
    if (data.value[0].error_code) {
      errorInfo = {
        errorSource: data.value[0].error_source as string,
        errorCode: data.value[0].error_code as number,
        errorMessage: data.value[0].error_message as string,
      };
    } else {
      sessions = data.value;
    }
  }

  return { sessions: sessions, errorInfo: errorInfo };
}

export async function getSessionsCount(): Promise<number | string> {
  const response = await fetch("/data-api/rest/sessions-count");
  if (!response.ok) return "n/a";
  const data = await response.json();
  const totalCount = data ? data.value[0].total_sessions : "n/a";
  return totalCount;
}
