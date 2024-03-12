import { SessionInfo } from "../api/sessions";
import { Session } from "./Session";

export const SessionList = ({ sessions }: { sessions: SessionInfo[] }) => {
  return (
    <section className="agenda-group">
      {sessions.map((session) => (
        <Session session={session} key={session.external_id} />
      ))}
    </section>
  );
};
