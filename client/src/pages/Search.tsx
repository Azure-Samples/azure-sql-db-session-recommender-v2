import { Input, Spinner } from "@fluentui/react-components";
import { Search24Regular } from "@fluentui/react-icons";
import {
  Form,
  LoaderFunction,
  useLoaderData,
  useNavigation,
} from "react-router-dom";
import { NoSessions } from "../components/NoSessions";
import { SessionList } from "../components/SessionsList";
import type { ErrorInfo, SessionInfo } from "../api/sessions";
import { getSessions } from "../api/sessions";
import { FancyText } from "../components/FancyText";
import { PrimaryButton } from "../components/PrimaryButton";

type LoaderData = {
  sessions: SessionInfo[];
  searchQuery: string;
  isSearch: boolean;
  errorInfo: ErrorInfo | null;
};

const SEARCH_INPUT_ID = "q";

export const loader: LoaderFunction = async ({ request }) => {
  const url = new URL(request.url);
  const searchQuery = url.searchParams.get(SEARCH_INPUT_ID) ?? "";
  const isSearch = searchQuery !== "";

  if (!isSearch) {
    return { sessions: [] };
  }

  let { sessions, errorInfo } = await getSessions(searchQuery);
  if (!Array.isArray(sessions)) {
    errorInfo = { errorMessage: "Error: sessions is not an array" };
    sessions = [];
  }
  return { sessions, searchQuery, isSearch, errorInfo };
};

export default function SessionSearch() {
  const { sessions, searchQuery, isSearch, errorInfo } = useLoaderData() as LoaderData;
  const navigation = useNavigation();

  const searching =
    navigation.location &&
    new URLSearchParams(navigation.location.search).has(SEARCH_INPUT_ID);

  return (
    <>
      <FancyText>
        <>
          Use OpenAI to search for interesting sessions. Write the topic you're
          interested in, and (up to) the top ten most interesting and related
          session will be returned. The search is done using <a href="https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models" target="_blank">text embeddings</a> and 
          then using <a href="https://en.wikipedia.org/wiki/Cosine_similarity" target="_blank">cosine similarity</a> to find the most similar sessions.
        </>
      </FancyText>
      <div id="searchbox">
        <div>
          <Form id="search-form" role="search">
            <div>
              <Input
                id={SEARCH_INPUT_ID}
                size="large"                
                aria-label="Search sessions"
                placeholder="Search"
                type="search"
                name="q"
                defaultValue={searchQuery}
                style={{ width: "100%", marginBottom: "1rem" }}
                autoComplete="off"
              />
              <PrimaryButton
              icon={<Search24Regular />}              
            >Search</PrimaryButton>
              
            </div>
            {searching && <Spinner label="Searching..." />}
            <div className="sr-only" aria-live="polite"></div>
          </Form>
        </div>
      </div>
      <div
        id="sessions"
        className={navigation.state === "loading" ? "loading" : ""}
      >
        {!errorInfo ? (
          ""
        ) : (
          <p id="error">
            <i>{"Error" + errorInfo.errorMessage}</i>
          </p>
        )}
        {sessions.length > 0 && <SessionList sessions={sessions} />}
        {sessions.length === 0 && isSearch && <NoSessions />}
      </div>
    </>
  );
}

