<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import StatusPage from "./page/status.vue";
import ConfigPage from "./page/config.vue";
import ActionsPage from "./page/actions.vue";

const pages = [StatusPage, ConfigPage, ActionsPage];
const tab = ref(0);
const active = computed(() => pages[tab.value]);
const scrolled = ref(false);

function onScroll() {
  scrolled.value = window.scrollY > 0;
}

onMounted(() => window.addEventListener("scroll", onScroll, { passive: true }));
onBeforeUnmount(() => window.removeEventListener("scroll", onScroll));

function onTab(event: Event) {
  tab.value = (event.target as HTMLElement & { activeTabIndex: number })
    .activeTabIndex;
}

function reload() {
  window.location.reload();
}
</script>

<template>
  <header class="header" :class="{ scroll: scrolled }">
    <div id="title">MoonWake ZRAM</div>
    <div class="spacer"></div>
    <md-icon-button aria-label="刷新" @click="reload">
      <md-icon>refresh</md-icon>
    </md-icon-button>
  </header>

  <div class="tabs-bar">
    <md-tabs @change="onTab">
      <md-primary-tab>状态</md-primary-tab>
      <md-primary-tab>配置</md-primary-tab>
      <md-primary-tab>操作</md-primary-tab>
    </md-tabs>
  </div>

  <main class="body-content">
    <component :is="active" :key="tab" />
  </main>

  <div class="snackbar-host">
    <div class="snackbar hide"><div class="snackbar-text"></div></div>
  </div>
</template>
