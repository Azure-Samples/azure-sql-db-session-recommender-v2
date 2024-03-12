import { Outlet } from "react-router-dom";
import { makeStyles, shorthands } from "@fluentui/react-components";
import { Header } from "../components/Header";
import { Navigation } from "../components/Navigation";

const margin = shorthands.margin("1rem", "3rem", "1rem");
const useStyles = makeStyles({
  root: {
    display: "grid",
    gridTemplateRows: "auto 1fr",
    gridTemplateAreas: `
      "header"
      "main"
    `,
    height: `calc(100vh - ${margin.marginTop} - ${margin.marginBottom})`,
    ...margin,
  },
});

export default function Root() {
  const classes = useStyles();
  return (
    <>
      <div className={classes.root}>
        <div>
          <Header />
          <Navigation />
        </div>
        <div>
          <Outlet />
        </div>
      </div>
    </>
  );
}
