import { SessionInfo } from "../api/sessions";
import { Text, Title2 } from "@fluentui/react-components";
import { FancyText } from "./FancyText";
import dayjs from "dayjs";
import siteConfig from "../site";

function formatSubtitle(session: SessionInfo) {
  const speakers = JSON.parse(session.speakers).join(", ");

  const startTime = dayjs(session.start_time_PST);
  const endTime = dayjs(session.end_time_PST);

  const day = startTime.format("dddd")
  const start = startTime.format("hh:mm A");
  const end = endTime.format("hh:mm A");

  return `${speakers} | ${day}, ${start}-${end} | Similarity: ${session.cosine_similarity.toFixed(6)}`;
}

function formatSessionLink(session: SessionInfo) {
    const startTime = dayjs(session.start_time_PST);

    const day = startTime.format("D")    
    const url = new URL(`session-list.aspx?EventDay=${day}`, siteConfig.sessionUrl);

    return url;
}

export const Session = ({ session }: { session: SessionInfo }) => {
  return (
    <div key={session.external_id}>
      <Title2 as="h2" block={true} style={{ marginBottom: "3px" }}>
        <a href={formatSessionLink(session)}>
          {session.title}
        </a>
      </Title2>
      <Text className="session-similarity" weight="bold" size={400}>
        {formatSubtitle(session)}
      </Text>
      <FancyText weight="semibold" size={500} className="abstract" style={{ marginTop: "3px"}}>
        {session.abstract}
      </FancyText>
    </div>
  );
};
