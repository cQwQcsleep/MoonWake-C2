<script setup lang="ts">
import { onMounted, ref } from "vue";
import { applyConf, getLogs, recompress, writeback } from "../lib/api";
import { toast } from "../lib/toast";

const logs = ref("");

async function refresh() {
  logs.value = await getLogs();
}

async function doRecompress() {
  await recompress();
  toast.show("已触发重压缩");
  await refresh();
}

async function doWriteback() {
  await writeback();
  toast.show("已触发空闲回写");
  await refresh();
}

async function doApply() {
  await applyConf();
  toast.show("已应用配置");
  await refresh();
}

onMounted(refresh);
</script>

<template>
  <div class="page">
    <div class="action-list">
      <md-filled-button @click="doRecompress">
        <md-icon slot="icon">compress</md-icon>
        立即重压缩
      </md-filled-button>
      <md-filled-tonal-button @click="doWriteback">
        <md-icon slot="icon">swap_horiz</md-icon>
        空闲回写
      </md-filled-tonal-button>
      <md-outlined-button @click="doApply">
        <md-icon slot="icon">sync</md-icon>
        应用配置
      </md-outlined-button>
    </div>
    <p class="t-body-sm helper">重压缩只处理冷页，可随时中断。</p>

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
