<script setup lang="ts">
import { onMounted, ref } from "vue";
import { applyConf, getLogs, recompress, writeback } from "../lib/api";
import { toast } from "../lib/toast";

const logs = ref("");
const busy = ref(false);

const paint = () =>
  new Promise<void>((resolve) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
  );

async function refresh() {
  logs.value = await getLogs();
}

async function doRecompress() {
  if (busy.value) return;
  busy.value = true;
  toast.show("正在重压缩…");
  await paint();
  try {
    await recompress();
    toast.show("已开始重压缩");
    setTimeout(refresh, 2500);
  } catch {
    toast.show("重压缩启动失败");
  } finally {
    busy.value = false;
  }
}

async function doWriteback() {
  if (busy.value) return;
  busy.value = true;
  toast.show("正在回写…");
  await paint();
  try {
    await writeback();
    toast.show("已开始回写");
    setTimeout(refresh, 2500);
  } catch {
    toast.show("回写启动失败");
  } finally {
    busy.value = false;
  }
}

async function doApply() {
  if (busy.value) return;
  busy.value = true;
  toast.show("正在应用…");
  await paint();
  try {
    await applyConf();
    toast.show("已应用");
    await refresh();
  } catch {
    toast.show("应用失败");
  } finally {
    busy.value = false;
  }
}

onMounted(refresh);
</script>

<template>
  <div class="page">
    <div class="action-list">
      <md-linear-progress v-if="busy" indeterminate></md-linear-progress>
      <md-filled-button :disabled="busy" @click="doRecompress">
        <md-icon slot="icon">compress</md-icon>
        立即重压缩
      </md-filled-button>
      <md-filled-tonal-button :disabled="busy" @click="doWriteback">
        <md-icon slot="icon">swap_horiz</md-icon>
        空闲回写
      </md-filled-tonal-button>
      <md-outlined-button :disabled="busy" @click="doApply">
        <md-icon slot="icon">sync</md-icon>
        应用配置
      </md-outlined-button>
    </div>
    <p class="t-body-sm helper">只处理冷页，可中断</p>

    <div class="section-head">
      <h2 class="section-title t-title-sm">日志</h2>
      <md-text-button @click="refresh">
        <md-icon slot="icon">refresh</md-icon>
        刷新
      </md-text-button>
    </div>
    <div class="log">
      <pre>{{ logs || "暂无日志" }}</pre>
    </div>
  </div>
</template>
