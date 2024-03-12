import { Suspense } from "react";
import { Await, LoaderFunction, defer, useLoaderData } from "react-router-dom";
import ls from "localstorage-slim";
import { getSessionsCount } from "../api/sessions";
import { FancyText } from "../components/FancyText";
import siteConfig from "../site";

function showSessionCount(
  sessionsCount: string | undefined | null = undefined
) {
  var sc = sessionsCount;
  if (sc === undefined) {
    sc = ls.get("sessionsCount");
    console.log("sessionsCount", sc);
  } else {
    ls.set("sessionsCount", sc, { ttl: 60 * 60 * 24 * 7 });
  }
  if (sc == null) {
    return <FancyText>Loading session count...</FancyText>;
  }
  return (
    <FancyText>
      There are <a href={siteConfig.website}>{sc} sessions indexed</a> so far.
    </FancyText>
  );
}

export const loader: LoaderFunction = async () => {
  const sessionsCount = getSessionsCount();
  return defer({ sessionsCount });
};

export const About = () => {
  const { sessionsCount } = useLoaderData() as {
    sessionsCount: string | number;
  };

  return (
    <>
      <FancyText>
        Source code and and related articles are <a href="https://github.com/Azure-Samples/azure-sql-db-session-recommender-v2">available on GitHub.</a>{" "}
        The AI model used generate embeddings is the <i>text-embedding-ada-002</i> and the AI model used to process and generate natural language content is <i>gpt-35-turbo</i>.
      </FancyText>
      <Suspense fallback={showSessionCount()}>
        <Await
          resolve={sessionsCount}
          errorElement={
            <FancyText>Unable to load session count 😥...</FancyText>
          }
        >
          {(sessionsCount) => showSessionCount(sessionsCount)}
        </Await>
      </Suspense>
    </>
  );
};
