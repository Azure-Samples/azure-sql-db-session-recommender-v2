import { Title1 } from "@fluentui/react-components";
import siteConfig from "../site";

export const Header = () => {
  return (
    <Title1>
      <a href={siteConfig.website} target="_blank">{siteConfig.name}</a> 🤖 RAG Sample      
    </Title1>
  );
};
