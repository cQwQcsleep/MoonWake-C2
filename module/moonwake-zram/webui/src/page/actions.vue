<script setup lang="ts">
import { onMounted, ref } from "vue";
import {
  MiuixButton,
  MiuixCard,
  MiuixDivider,
  MiuixSmallTitle,
  MiuixText,
  showSnackbar,
} from "miuix-vue";
import { applyConf, getLogs, recompress, writeback } from "../lib/api";

const logs = ref("");

async function refresh() {
  logs.value = await getLogs();
}

async function doRecompress() {
  await recompress();
  showSnackbar({ message: "已触发重压缩" });
  await refresh();
}

async function doWriteback() {
  await writeback();
  showSnackbar({ message: "已触发空闲回写" });
  await refresh();
}

async function doApply() {
  await applyConf();
  showSnackbar({ message: "已应用配置" });
  await refresh();
}

onMounted(refresh);
</script>

<template>
  <div class="page">
    <MiuixCard class="mw-card card-gap">
      <div class="action-list">
        <MiuixButton type="primary" @click="doRecompress">立即重压缩</MiuixButton>
        <MiuixButton @click="doWriteback">空闲回写</MiuixButton>
        <MiuixButton @click="doApply">应用配置</MiuixButton>
      </div>
      <MiuixDivider />
      <div class="button-row">
        <MiuixText class="hint">重压缩只处理冷页，可随时中断</MiuixText>
        <MiuixButton @click="refresh">刷新日志</MiuixButton>
      </div>
    </MiuixCard>

    <MiuixSmallTitle text="日志" />
    <MiuixCard class="mw-card card-gap">
      <div class="log-box">
        <MiuixText class="mono">{{ logs || "暂无日志" }}</MiuixText>
      </div>
    </MiuixCard>
  </div>
</template>
