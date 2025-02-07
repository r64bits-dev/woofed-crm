import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

window.Stimulus = Application.start();
const context = require.context("controllers", true, /_controller\.(js|ts)$/);
Stimulus.load(definitionsFromContext(context));
