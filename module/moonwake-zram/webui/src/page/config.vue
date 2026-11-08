<script setup lang="ts">
import { onMounted, ref } from "vue";
import {
  MiuixBasicComponent,
  MiuixButton,
  MiuixCard,
  MiuixDropdownPreference,
  MiuixInput,
  MiuixSmallTitle,
  MiuixSwitch,
  MiuixText,
  showSnackbar,
} from "miuix-vue";
import { applyConf, getStatus, saveConf } from "../lib/api";
import { ALGOS } from "../lib/types";

const pct = ref("50");
const algoIdx = ref(0);
const recompIdx = ref(0);
const auto = ref(true);
const wb = ref(false);
const backingMb = ref("2048");
const wbLimitMb = ref("1024");

const algoItems = ALGOS;
const recompItems = ["zstdn", "zstd", "lz4k_oplus", "关闭"];

onMounted(async () => {
  const s = await getStatus();
  pct.value = String(s.conf.disksize_pct);
  algoIdx.value = Math.max(0, ALGOS.indexOf(s.conf.algo));
  recompIdx.value =
    s.conf.recomp_algo === "none"
      ? recompItems.length - 1
      : Math.max(0, recompItems.indexOf(s.conf.recomp_algo));
  auto.value = !!s.conf.auto_recomp;
  wb.value = !!s.conf.writeback;
  backingMb.value = String(s.conf.backing_mb);
  wbLimitMb.value = String(s.conf.wb_limit_mb);
});

async function save() {
  const recomp =
    recompIdx.value === recompItems.length - 1
      ? "none"
      : recompItems[recompIdx.value];
  await saveConf({
    disksize_pct: Number(pct.value),
    algo: ALGOS[algoIdx.value],
    recomp_algo: recomp,
    auto_recomp: auto.value ? 1 : 0,
    writeback: wb.value ? 1 : 0,
    backing_mb: Number(backingMb.value),
    wb_limit_mb: Number(wbLimitMb.value),
  });
  await applyConf();
  showSnackbar({ message: "已保存，zram 可能被重建" });
}
</script>

<template>
  <div class="page">
    <MiuixSmallTitle text="容量" />
    <MiuixCard class="mw-card card-gap">
      <div style="padding: 16px">
        <MiuixInput v-model="pct" label="占内存百分比" single-line />
      </div>
      <MiuixBasicComponent
        title="修改容量会重建 zram"
        summary="当前 swap 内容会被清空，建议重启后观察"
      />
    </MiuixCard>

    <MiuixSmallTitle text="算法" />
    <MiuixCard class="mw-card card-gap">
      <MiuixDropdownPreference
        title="主算法"
        :summary="ALGOS[algoIdx]"
        v-model="algoIdx"
        :items="algoItems"
      />
      <MiuixDropdownPreference
        title="次算法"
        summary="冷页重压缩使用"
        v-model="recompIdx"
        :items="recompItems"
      />
      <MiuixBasicComponent>
        <template #start>
          <MiuixText>自动重压缩</MiuixText>
        </template>
        <template #end>
          <MiuixSwitch v-model="auto" label="Enabled" />
        </template>
      </MiuixBasicComponent>
    </MiuixCard>

    <MiuixSmallTitle text="回写" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent>
        <template #start>
          <MiuixText>启用回写</MiuixText>
        </template>
        <template #end>
          <MiuixSwitch v-model="wb" label="Enabled" />
        </template>
      </MiuixBasicComponent>
      <div style="padding: 0 16px 16px; display: flex; gap: 12px">
        <MiuixInput v-model="backingMb" label="backing 文件 MB" single-line />
        <MiuixInput v-model="wbLimitMb" label="回写上限 MB" single-line />
      </div>
    </MiuixCard>

    <div style="padding: 12px; display: flex">
      <MiuixButton type="primary" @click="save">保存并应用</MiuixButton>
    </div>
  </div>
</template>
