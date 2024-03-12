import { AskResponse } from "../models";

type ChatTurn = {
  userPrompt: string;
  responseMessage?: string;
};

type UserQuestion = {
  question: string;
  askedOn: Date;
};

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let questionAndAnswers: Record<number, [UserQuestion, AskResponse?]> = {};

export const ask = async (prompt: string) => {
  const history: ChatTurn[] = [];
  const currentMessageId = Date.now();
  const currentQuestion = {
    question: prompt,
    askedOn: new Date(),
  };
  questionAndAnswers[currentMessageId] = [currentQuestion, undefined];

  for (let id in questionAndAnswers) {
    const [question, answer] = questionAndAnswers[id];
    history.push({
      userPrompt: question.question,
      responseMessage: answer?.answer,
    });
  }

  const response = await fetch("/api/ask", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(history),
  });

  const askResponse: AskResponse = await response.json();

  questionAndAnswers[currentMessageId] = [
    currentQuestion,
    {
      answer: askResponse.answer,
      thoughts: askResponse.thoughts,
      dataPoints: askResponse.dataPoints,
      citationBaseUrl: askResponse.citationBaseUrl,
    },
  ];

  return await Promise.resolve(questionAndAnswers);
};
