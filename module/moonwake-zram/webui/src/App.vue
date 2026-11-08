<script setup lang="ts">
import { computed, ref } from "vue";
import {
  MiuixIcon,
  MiuixNavigationBar,
  MiuixScrollArea,
  MiuixSnackbarHost,
  MiuixTopAppBar,
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
</script>

<template>
  <div class="app">
    <MiuixScrollArea class="app__body">
      <MiuixTopAppBar :large="false" :title="titles[index]" />
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
