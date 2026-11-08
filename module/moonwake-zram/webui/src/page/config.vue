<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from "vue";
import { applyConf, getStatus, saveConf } from "../lib/api";
import { ALGOS } from "../lib/types";
import { toast } from "../lib/toast";

const pct = ref(50);
const algo = ref("lz4kd");
const recomp = ref("zstdn");
const auto = ref(true);
const wb = ref(false);
const backingMb = ref("2048");
const wbLimitMb = ref("1024");

const recompItems = ["zstdn", "zstd", "lz4k_oplus", "none"];

type SelectEl = HTMLElement & { value: string };
const algoSel = ref<SelectEl | null>(null);
const recompSel = ref<SelectEl | null>(null);

const capacityMb = computed(() => Math.round((8 * 1024 * pct.value) / 100));

function onPct(e: Event) {
  pct.value = Number((e.target as HTMLElement & { value: number }).value);
}

function onAlgo(e: Event) {
  algo.value = (e.target as HTMLElement & { value: string }).value;
}

function onRecomp(e: Event) {
  recomp.value = (e.target as HTMLElement & { value: string }).value;
}

function onAuto(e: Event) {
  auto.value = (e.target as HTMLElement & { selected: boolean }).selected;
}

function onWb(e: Event) {
  wb.value = (e.target as HTMLElement & { selected: boolean }).selected;
}

function onBacking(e: Event) {
  backingMb.value = (e.target as HTMLElement & { value: string }).value;
}

function onWbLimit(e: Event) {
  wbLimitMb.value = (e.target as HTMLElement & { value: string }).value;
}

onMounted(async () => {
  const s = await getStatus();
  pct.value = s.conf.disksize_pct;
  algo.value = s.conf.algo;
  recomp.value = s.conf.recomp_algo;
  auto.value = !!s.conf.auto_recomp;
  wb.value = !!s.conf.writeback;
  backingMb.value = String(s.conf.backing_mb);
  wbLimitMb.value = String(s.conf.wb_limit_mb);
  await nextTick();
  if (algoSel.value) algoSel.value.value = algo.value;
  if (recompSel.value) recompSel.value.value = recomp.value;
});

const saving = ref(false);

const paint = () =>
  new Promise<void>((resolve) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
  );

async function save() {
  if (saving.value) return;
  saving.value = true;
  toast.show("正在应用…");
  await paint();
  try {
    await saveConf({
      disksize_pct: pct.value,
      algo: algo.value,
      recomp_algo: recomp.value,
      auto_recomp: auto.value ? 1 : 0,
      writeback: wb.value ? 1 : 0,
      backing_mb: Number(backingMb.value),
      wb_limit_mb: Number(wbLimitMb.value),
    });
    await applyConf();
    toast.show("已应用");
  } catch {
    toast.show("应用失败");
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div class="page">
    <section class="section">
      <h2 class="section-title t-title-sm">容量</h2>
      <div class="card field">
        <div class="field__head">
          <span class="t-body-lg">交换区大小</span>
          <span class="t-body field__value">
            {{ pct }}% · 约 {{ capacityMb }} MB
          </span>
        </div>
        <md-slider
          :value="pct"
          :min="20"
          :max="80"
          :step="5"
          @input="onPct"
        ></md-slider>
        <p class="t-body-sm helper">改容量会重建 zram</p>
      </div>
    </section>

    <section class="section">
      <h2 class="section-title t-title-sm">算法</h2>
      <div class="group">
        <div class="field">
          <md-outlined-select
            ref="algoSel"
            label="主算法"
            :value="algo"
            @change="onAlgo"
          >
            <md-select-option v-for="a in ALGOS" :key="a" :value="a">
              <div slot="headline">{{ a }}</div>
            </md-select-option>
          </md-outlined-select>
        </div>
        <div class="field">
          <md-outlined-select
            ref="recompSel"
            label="次算法"
            supporting-text="冷页使用"
            :value="recomp"
            @change="onRecomp"
          >
            <md-select-option v-for="a in recompItems" :key="a" :value="a">
              <div slot="headline">{{ a === "none" ? "关闭" : a }}</div>
            </md-select-option>
          </md-outlined-select>
        </div>
        <div class="row">
          <span class="row__text">
            <span class="t-body-lg">自动重压缩</span>
            <span class="t-body helper">内存紧张时自动执行</span>
          </span>
          <md-switch
            aria-label="自动重压缩"
            :selected="auto"
            @change="onAuto"
          ></md-switch>
        </div>
      </div>
    </section>

    <section class="section">
      <h2 class="section-title t-title-sm">回写</h2>
      <div class="group">
        <div class="row">
          <span class="row__text">
            <span class="t-body-lg">启用回写</span>
            <span class="t-body helper">冷页写入 backing</span>
          </span>
          <md-switch
            aria-label="启用回写"
            :selected="wb"
            @change="onWb"
          ></md-switch>
        </div>
        <div class="field-row">
          <md-outlined-text-field
            type="number"
            label="backing MB"
            :value="backingMb"
            @input="onBacking"
          ></md-outlined-text-field>
          <md-outlined-text-field
            type="number"
            label="上限 MB"
            :value="wbLimitMb"
            @input="onWbLimit"
          ></md-outlined-text-field>
        </div>
      </div>
    </section>

    <div class="save">
      <md-linear-progress v-if="saving" indeterminate></md-linear-progress>
      <md-filled-button :disabled="saving" @click="save">
        保存并应用
      </md-filled-button>
      <span class="t-body-sm helper">立即生效</span>
    </div>
  </div>
</template>
