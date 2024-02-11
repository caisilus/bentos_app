import React from "react";
import { createRoot } from "react-dom/client";
import {App} from "./app";

document.addEventListener("turbo:load", () => {
  const root = createRoot(
    document.body.appendChild(document.createElement("div"))
  );
  const element = <App />;
  root.render(element);
});
