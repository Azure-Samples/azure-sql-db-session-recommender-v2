import {
  Body1,
  Card,
  CardHeader,
  Textarea,
  TextareaProps,
  Text,
  makeStyles,
  CardFooter,
  Spinner,
  Title2
} from "@fluentui/react-components";
import { SendRegular } from "@fluentui/react-icons";
import { useState } from "react";
import { ActionFunctionArgs, useFetcher } from "react-router-dom";
import { ask } from "../api/chat";
import { FancyText } from "../components/FancyText";
import { PrimaryButton } from "../components/PrimaryButton";
import ReactMarkdown from "react-markdown";

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

  const submitting = fetcher.state !== "idle";
  const data = fetcher.data;  

  const [prompt, setPrompt] = useState("");

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

  return (
    <div className={classes.container}>
      <div>
        <FancyText>
          <>
          Ask questions to the AI model in natural language and get meaningful answers 
          to help you navigate the conferences sessions and find the best ones for you.           
          Thanks to <a href="https://en.wikipedia.org/wiki/Prompt_engineering" target="_blank">Prompt Engineering</a> and <a href="https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview" target="_blank">Retrieval Augmented Generation (RAG) </a> finding
          details and recommendations on what session to attend is easier than ever. Please note that the AI model will remember your questions and answers to improve the quality of the answers and get more context on your requests.           
          If you want to start from scratch, <a href="/">click here</a> or refresh the page.
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
          {submitting && <Spinner label="Thinking..." />}
        </fetcher.Form>
      </div>
      <div className={classes.answersArea}>
        {!submitting && data && <Answers data={data} />}
      </div>
    </div>
  );
};
