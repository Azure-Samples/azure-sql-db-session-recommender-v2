import {
  Card,
  Textarea,
  TextareaProps,
  makeStyles,
  Spinner,
  Title2
} from "@fluentui/react-components";
import { SendRegular } from "@fluentui/react-icons";
import { useState } from "react";
import { ActionFunctionArgs, isRouteErrorResponse, useFetcher, useRouteError } from "react-router-dom";
import { ask } from "../api/chat";
import { FancyText } from "../components/FancyText";
import { PrimaryButton } from "../components/PrimaryButton";
import ReactMarkdown from "react-markdown";

var isThinking:boolean = false;
var intervalId = 0
var thinkingTicker = 0;
var thinkingMessages:string[] = [
  "Analyzing the question...",
  "Thinking...",
  "Querying the database...",
  "Extracting embeddings...",
  "Finding vectors in the latent space...", 
  "Identifying context...", 
  "Analyzing results...",  
  "Finding the best answer...", 
  "Formulating response...",
  "Double checking the answer...",
  "Correcting spelling...",
  "Doing an internal review...",
  "Checking for errors...",
  "Validating the answer...",
  "Adding more context...",
  "Analyzing potential response...",
  "Re-reading the original question...",
  "Adding more details...",
  "Improving the answer...",
  "Making it nice and polished...",
  "Removing typos...",
  "Adding punctuation...",
  "Checking grammar...",
  "Adding context...",
  "Sending response..."
]

const useClasses = makeStyles({
  container: {},
  chatArea: {},
  card: {},
  rm: { marginBottom: "-1em", marginTop: "-1em"},
  answersArea: { marginTop: "1em"},
  textarea: { width: "100%", marginBottom: "1rem" },
});

export async function action({ request }: ActionFunctionArgs) {
  let formData = await request.formData();
  const prompt = formData.get("prompt");
  if (!prompt) {
    return null;
  }

  const data = await ask(prompt.toString());
  return data;
}

const Answers = ({ data }: { data: Awaited<ReturnType<typeof action>> }) => {
  if (!data) {
    return null;
  }
  const components = [];
  const classes = useClasses();
  
  var cid:number = 0
  for (const id in data) { cid = Number(id) }
  const [question, answer] = data[cid];    
      
  components.push(
    <Card key={cid} className={classes.card}>        
      <Title2 as="h2" block={true} style={{ marginBottom: "0em", marginTop:"0px" }}>Your question</Title2>
      <FancyText>
        {question.question}
      </FancyText>
      <Title2 as="h2" block={true} style={{ marginBottom: "0em" }}>My answer</Title2>
      <FancyText>
        <ReactMarkdown className={classes.rm}>{answer?.answer}</ReactMarkdown>
      </FancyText>
      <Title2 as="h2" block={true} style={{ marginBottom: "0em" }}>My thoughts</Title2>
      <FancyText>
        {answer?.thoughts}
      </FancyText>
    </Card>
  );

  return <>{components}</>;
};

export const Chat = () => {
  const fetcher = useFetcher<Awaited<ReturnType<typeof action>>>();
  const classes = useClasses();

  const [thinking, setThinking] = useState(thinkingMessages[0]);
  const [prompt, setPrompt] = useState("");

  const submitting = fetcher.state !== "idle";
  const data = fetcher.data;  

  const onChange: TextareaProps["onChange"] = (_, data) =>
    setPrompt(() => data.value);

  const onKeyDown: TextareaProps["onKeyDown"] = (e) => {
    if (!prompt) {
      return;
    }

    if (e.key === "Enter" && !e.shiftKey) {
      const formData = new FormData();
      formData.append("prompt", prompt);
      fetcher.submit(formData, { method: "POST" });      
    }
  };

  if (submitting && !isThinking) {
    isThinking = true;
    thinkingTicker = 0;
    setThinking(thinkingMessages[thinkingTicker]);
    const updateThinking = () => {     
      thinkingTicker += 1;   
      var i = thinkingTicker > thinkingMessages.length - 1 ? 0 : thinkingTicker;
      setThinking(thinkingMessages[i]);      
    }
    intervalId = setInterval(updateThinking, 2000);
  }

  if (!submitting && isThinking) {
    isThinking = false;
    clearInterval(intervalId);
    setThinking(thinkingMessages[0]);
  }

  return (
    <div className={classes.container}>
      <div>
        <FancyText>
          <>
          Ask questions to the AI model in natural language and get meaningful answers 
          to help you navigate the conferences sessions and find the best ones for you.           
          Thanks to <a href="https://en.wikipedia.org/wiki/Prompt_engineering" target="_blank">Prompt Engineering</a> and <a href="https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview" target="_blank">Retrieval Augmented Generation (RAG) </a> finding
          details and recommendations on what session to attend is easier than ever.
          </>
        </FancyText>        
      </div>
      <div className={classes.chatArea}>
        <fetcher.Form method="POST">
          <Textarea
            className={classes.textarea}
            resize="vertical"
            size="large"
            placeholder="Ask a question..."
            name="prompt"
            id="prompt"
            disabled={submitting}
            onChange={onChange}
            value={prompt}
            onKeyDown={onKeyDown}
          ></Textarea>
          <PrimaryButton
            icon={<SendRegular />}
            disabled={submitting || !prompt}
          >
            Ask
          </PrimaryButton>
          {submitting && <Spinner label={thinking} />}
        </fetcher.Form>        
      </div>
      <div className={classes.answersArea}>
        {!submitting && data && <Answers data={data} />}
      </div>
    </div>
  );
};

export const ChatError = () => {
  const error = useRouteError();
  console.error(error);
  if (isRouteErrorResponse(error)) {
    return(
    <div>
      <Title2>
      {error.status} - {error.statusText} {error.data.statusText}
      </Title2>
      <FancyText>
        Sorry, there was a problem while processing your request. Please try again.
      </FancyText>
    </div>
    )
  }
  else {
    throw error;
  }
}