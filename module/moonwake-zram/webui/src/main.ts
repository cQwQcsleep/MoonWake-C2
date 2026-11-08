import { createApp } from "vue";
import "mdui/mdui.css";
import "mdui";
import { setTheme } from "mdui/functions/setTheme.js";
import { setColorScheme } from "mdui/functions/setColorScheme.js";
import "./style.css";
import App from "./App.vue";

setTheme("auto");
setColorScheme("#3482ff");

createApp(App).mount("#app");
