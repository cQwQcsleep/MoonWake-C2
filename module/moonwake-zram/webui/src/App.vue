<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import {
  MiuixIcon,
  MiuixNavigationBar,
  MiuixScrollArea,
  MiuixSnackbarHost,
  MiuixText,
} from "miuix-vue";
import { ScreenMirroring, Settings, Info } from "miuix-vue/icons";
import StatusPage from "./page/status.vue";
import ConfigPage from "./page/config.vue";
import ActionsPage from "./page/actions.vue";

const pages = [StatusPage, ConfigPage, ActionsPage];
const titles = ["MoonWake ZRAM", "配置", "操作"];
const navItems = [{ label: "状态" }, { label: "配置" }, { label: "操作" }];
const icons = [ScreenMirroring, Settings, Info];

const index = ref(0);
const active = computed(() => pages[index.value]);
const scrolled = ref(false);

let viewport: HTMLElement | null = null;

const onScroll = () => {
  scrolled.value = (viewport?.scrollTop ?? 0) > 16;
};

onMounted(() => {
  viewport = document.querySelector<HTMLElement>(
    ".app__body .m-scroll-area__viewport",
  );
  viewport?.addEventListener("scroll", onScroll, { passive: true });
});

onBeforeUnmount(() => {
  viewport?.removeEventListener("scroll", onScroll);
});

watch(index, () => {
  viewport?.scrollTo({ top: 0 });
  scrolled.value = false;
});
</script>

<template>
  <div class="app">
    <div class="app__bar" :class="{ 'app__bar--visible': scrolled }">
      <MiuixText type="headline1" weight="medium">{{ titles[index] }}</MiuixText>
    </div>

    <MiuixScrollArea class="app__body">
      <div class="app__large">
        <MiuixText type="title1">{{ titles[index] }}</MiuixText>
      </div>
      <Transition name="page" mode="out-in">
        <KeepAlive>
          <component :is="active" :key="index" />
        </KeepAlive>
      </Transition>
    </MiuixScrollArea>

    <div class="app__bottom">
      <MiuixNavigationBar v-model="index" :items="navItems">
        <template #icon="{ index: i }">
          <MiuixIcon :icon="icons[i]" :size="26" />
        </template>
      </MiuixNavigationBar>
    </div>
    <MiuixSnackbarHost />
  </div>
</template>
