<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import StatusPage from "./page/status.vue";
import ConfigPage from "./page/config.vue";
import ActionsPage from "./page/actions.vue";

const pages = [StatusPage, ConfigPage, ActionsPage];
const tab = ref(0);
const active = computed(() => pages[tab.value]);
const scrolled = ref(false);

type TabsEl = HTMLElement & { activeTabIndex: number };
const tabs = ref<TabsEl | null>(null);

let startX = 0;
let startY = 0;
let tracking = false;

function goTab(next: number) {
  const i = Math.min(pages.length - 1, Math.max(0, next));
  if (i === tab.value) return;
  tab.value = i;
  if (tabs.value) tabs.value.activeTabIndex = i;
  window.scrollTo(0, 0);
}

function onTouchStart(event: TouchEvent) {
  if (event.touches.length !== 1) return;
  const el = event.target as HTMLElement;
  if (
    el.closest(
      "md-slider, md-select, md-outlined-select, md-text-field, md-outlined-text-field",
    )
  ) {
    tracking = false;
    return;
  }
  tracking = true;
  startX = event.touches[0].clientX;
  startY = event.touches[0].clientY;
}

function onTouchEnd(event: TouchEvent) {
  if (!tracking) return;
  tracking = false;
  const dx = event.changedTouches[0].clientX - startX;
  const dy = event.changedTouches[0].clientY - startY;
  if (Math.abs(dx) < 56 || Math.abs(dx) < Math.abs(dy) * 1.4) return;
  goTab(tab.value + (dx < 0 ? 1 : -1));
}

function onScroll() {
  scrolled.value = window.scrollY > 0;
}

onMounted(() => window.addEventListener("scroll", onScroll, { passive: true }));
onBeforeUnmount(() => window.removeEventListener("scroll", onScroll));

function onTab(event: Event) {
  tab.value = (event.target as TabsEl).activeTabIndex;
  window.scrollTo(0, 0);
}

function reload() {
  window.dispatchEvent(new Event("mw:refresh"));
}
</script>

<template>
  <header class="header" :class="{ scroll: scrolled }">
    <div id="title">MoonWake ZRAM</div>
    <div class="spacer"></div>
    <md-icon-button v-if="tab === 0" aria-label="刷新" @click="reload">
      <md-icon>refresh</md-icon>
    </md-icon-button>
  </header>

  <div class="tabs-bar">
    <md-tabs ref="tabs" @change="onTab">
      <md-primary-tab>状态</md-primary-tab>
      <md-primary-tab>配置</md-primary-tab>
      <md-primary-tab>操作</md-primary-tab>
    </md-tabs>
  </div>

  <main
    class="body-content"
    @touchstart.passive="onTouchStart"
    @touchend="onTouchEnd"
  >
    <component :is="active" :key="tab" />
  </main>

  <div class="snackbar-host">
    <div class="snackbar hide"><div class="snackbar-text"></div></div>
  </div>
</template>
