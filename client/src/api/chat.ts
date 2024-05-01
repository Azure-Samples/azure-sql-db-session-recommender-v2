import { AskResponse } from "../models";
import { json } from 'react-router-dom';

type ChatTurn = {
  userPrompt: string;
  responseMessage?: string;
};

type UserQuestion = {
  question: string;
  askedOn: Date;
};

let questionAndAnswers: Record<number, [UserQuestion, AskResponse?]> = {};

export const ask = async (prompt: string) => {
  const history: ChatTurn[] = [];
  const currentMessageId = Date.now();
  const currentQuestion = {
    question: prompt,
    askedOn: new Date(),
  };
  questionAndAnswers[currentMessageId] = [currentQuestion, undefined];

  history.push({
    userPrompt: currentQuestion.question
  });
  
  const response = await fetch("/api/ask", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(history),
  })

  if (response.ok) {
    const askResponse: AskResponse = await response.json();
    questionAndAnswers[currentMessageId] = [
      currentQuestion,
      {
        answer: askResponse.answer,
        thoughts: askResponse.thoughts,
        dataPoints: askResponse.dataPoints,
        citationBaseUrl: askResponse.citationBaseUrl,
      }
    ];
  } else {
    throw json(response.statusText, response.status);
  }
  
  return await Promise.resolve(questionAndAnswers);
};
