import * as React from "react";
import * as ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import { FluentProvider, webLightTheme } from "@fluentui/react-components";

import Root from "./pages/Root";
import SessionSearch, { loader as sessionsListLoader } from "./pages/Search";
import { Chat, action as chatAction } from "./pages/Chat";
import { About, loader as aboutLoader } from "./pages/About";

const router = createBrowserRouter([
  {
    path: "/",
    element: <Root />,
    children: [
      {
        index: true,
        element: <Chat />,        
        action: chatAction,
      },
      {
        index: false,
        element: <SessionSearch />,
        path: "/search",
        loader: sessionsListLoader,
      },
      {
        index: false,
        element: <About />,
        path: "/about",
        loader: aboutLoader,
      },
    ],
  },
]);

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <FluentProvider theme={webLightTheme}>
      <RouterProvider router={router} />
    </FluentProvider>
  </React.StrictMode>
);
