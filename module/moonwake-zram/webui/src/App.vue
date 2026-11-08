<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import "@mdui/icons/memory.js";
import "@mdui/icons/memory--outlined.js";
import "@mdui/icons/tune.js";
import "@mdui/icons/tune--outlined.js";
import "@mdui/icons/bolt.js";
import "@mdui/icons/bolt--outlined.js";
import StatusPage from "./page/status.vue";
import ConfigPage from "./page/config.vue";
import ActionsPage from "./page/actions.vue";

type Tab = "status" | "config" | "actions";

const pages = {
  status: StatusPage,
  config: ConfigPage,
  actions: ActionsPage,
};

const titles: Record<Tab, string> = {
  status: "MoonWake ZRAM",
  config: "配置",
  actions: "操作",
};

const tab = ref<Tab>("status");
const main = ref<HTMLElement | null>(null);

const active = computed(() => pages[tab.value]);
const title = computed(() => titles[tab.value]);

function onTab(event: Event) {
  tab.value = (event.target as HTMLElement & { value: string }).value as Tab;
}

watch(tab, () => {
  main.value?.scrollTo({ top: 0 });
});

onMounted(() => {
  // Let the app bar / nav bar track <mdui-layout-main> instead of window,
  // so they position inside the safe-area insets and shrink on scroll.
  const target = main.value;
  if (!target) return;
  for (const tag of ["mdui-top-app-bar", "mdui-navigation-bar"]) {
    const el = document.querySelector(tag) as
      | (HTMLElement & { scrollTarget?: Element })
      | null;
    if (el) el.scrollTarget = target;
  }
});
</script>

<template>
  <div class="app">
    <mdui-layout>
      <mdui-top-app-bar variant="medium" scroll-behavior="shrink elevate">
        <mdui-top-app-bar-title>{{ title }}</mdui-top-app-bar-title>
      </mdui-top-app-bar>

      <mdui-layout-main ref="main">
        <Transition name="page" mode="out-in">
          <KeepAlive>
            <component :is="active" :key="tab" />
          </KeepAlive>
        </Transition>
      </mdui-layout-main>

      <mdui-navigation-bar :value="tab" @change="onTab">
        <mdui-navigation-bar-item value="status">
          <mdui-icon-memory--outlined slot="icon" />
          <mdui-icon-memory slot="active-icon" />
          状态
        </mdui-navigation-bar-item>
        <mdui-navigation-bar-item value="config">
          <mdui-icon-tune--outlined slot="icon" />
          <mdui-icon-tune slot="active-icon" />
          配置
        </mdui-navigation-bar-item>
        <mdui-navigation-bar-item value="actions">
          <mdui-icon-bolt--outlined slot="icon" />
          <mdui-icon-bolt slot="active-icon" />
          操作
        </mdui-navigation-bar-item>
      </mdui-navigation-bar>
    </mdui-layout>
  </div>
</template>
