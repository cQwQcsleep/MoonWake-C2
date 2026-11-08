<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import {
  MiuixBasicComponent,
  MiuixButton,
  MiuixCard,
  MiuixDivider,
  MiuixDropdownPreference,
  MiuixInput,
  MiuixSlider,
  MiuixSmallTitle,
  MiuixSwitchPreference,
  MiuixText,
  showSnackbar,
} from "miuix-vue";
import { applyConf, getStatus, saveConf } from "../lib/api";
import { ALGOS } from "../lib/types";

const pct = ref(50);
const algoIdx = ref(0);
const recompIdx = ref(0);
const auto = ref(true);
const wb = ref(false);
const backingMb = ref("2048");
const wbLimitMb = ref("1024");

const recompItems = ["zstdn", "zstd", "lz4k_oplus", "关闭"];

const capacityMb = computed(() => {
  const total = 8 * 1024;
  return Math.round((total * pct.value) / 100);
});

onMounted(async () => {
  const s = await getStatus();
  pct.value = s.conf.disksize_pct;
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
    disksize_pct: pct.value,
    algo: ALGOS[algoIdx.value],
    recomp_algo: recomp,
    auto_recomp: auto.value ? 1 : 0,
    writeback: wb.value ? 1 : 0,
    backing_mb: Number(backingMb.value),
    wb_limit_mb: Number(wbLimitMb.value),
  });
  await applyConf();
  showSnackbar({ message: "已保存并应用" });
}
</script>

<template>
  <div class="page">
    <MiuixSmallTitle text="容量" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent
        title="交换区大小"
        :summary="`${pct}% · 约 ${capacityMb} MB`"
      />
      <div class="slider-wrap">
        <MiuixSlider v-model="pct" :min="20" :max="80" :step="5" />
      </div>
      <MiuixDivider />
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
        :items="ALGOS"
      />
      <MiuixDivider />
      <MiuixDropdownPreference
        title="次算法"
        summary="冷页重压缩使用"
        v-model="recompIdx"
        :items="recompItems"
      />
      <MiuixDivider />
      <MiuixSwitchPreference
        title="自动重压缩"
        summary="内存紧张时由内核自动执行"
        v-model="auto"
      />
    </MiuixCard>

    <MiuixSmallTitle text="回写" />
    <MiuixCard class="mw-card card-gap">
      <MiuixSwitchPreference
        title="启用回写"
        summary="将冷页写入 backing 文件"
        v-model="wb"
      />
      <MiuixDivider />
      <div class="input-row">
        <MiuixInput v-model="backingMb" label="backing 文件 MB" single-line />
        <MiuixInput v-model="wbLimitMb" label="回写上限 MB" single-line />
      </div>
    </MiuixCard>

    <MiuixCard class="mw-card card-gap">
      <div class="button-row">
        <MiuixText class="hint">保存后立即应用到 zram0</MiuixText>
        <MiuixButton type="primary" @click="save">保存并应用</MiuixButton>
      </div>
    </MiuixCard>
  </div>
</template>
