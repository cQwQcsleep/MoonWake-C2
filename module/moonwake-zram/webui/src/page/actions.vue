<script setup lang="ts">
import { onMounted, ref } from "vue";
import { snackbar } from "mdui/functions/snackbar.js";
import "@mdui/icons/compress.js";
import "@mdui/icons/swap-horiz.js";
import "@mdui/icons/sync.js";
import "@mdui/icons/refresh.js";
import { applyConf, getLogs, recompress, writeback } from "../lib/api";

const logs = ref("");

async function refresh() {
  logs.value = await getLogs();
}

async function doRecompress() {
  await recompress();
  snackbar({ message: "已触发重压缩" });
  await refresh();
}

async function doWriteback() {
  await writeback();
  snackbar({ message: "已触发空闲回写" });
  await refresh();
}

async function doApply() {
  await applyConf();
  snackbar({ message: "已应用配置" });
  await refresh();
}

onMounted(refresh);
</script>

<template>
  <div class="page">
    <section class="section">
      <div class="group actions">
        <mdui-button variant="filled" full-width @click="doRecompress">
          <mdui-icon-compress slot="icon" />
          立即重压缩
        </mdui-button>
        <mdui-button variant="tonal" full-width @click="doWriteback">
          <mdui-icon-swap-horiz slot="icon" />
          空闲回写
        </mdui-button>
        <mdui-button variant="outlined" full-width @click="doApply">
          <mdui-icon-sync slot="icon" />
          应用配置
        </mdui-button>
      </div>
      <p class="md-body-small helper">重压缩只处理冷页，可随时中断。</p>
    </section>

    <section class="section">
      <div class="section__head">
        <h2 class="md-title-small section__title">日志</h2>
        <mdui-button variant="text" @click="refresh">
          <mdui-icon-refresh slot="icon" />
          刷新
        </mdui-button>
      </div>
      <div class="group log">
        <pre>{{ logs || "暂无日志" }}</pre>
      </div>
    </section>
  </div>
</template>
