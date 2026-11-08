<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { snackbar } from "mdui/functions/snackbar.js";
import { applyConf, getStatus, saveConf } from "../lib/api";
import { ALGOS } from "../lib/types";

const pct = ref(50);
const algo = ref("lz4kd");
const recomp = ref("zstdn");
const auto = ref(true);
const wb = ref(false);
const backingMb = ref("2048");
const wbLimitMb = ref("1024");

const recompItems = ["zstdn", "zstd", "lz4k_oplus", "none"];

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
  auto.value = (e.target as HTMLElement & { checked: boolean }).checked;
}

function onWb(e: Event) {
  wb.value = (e.target as HTMLElement & { checked: boolean }).checked;
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
});

async function save() {
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
  snackbar({ message: "已保存并应用" });
}
</script>

<template>
  <div class="page">
    <section class="section">
      <h2 class="md-title-small section__title">容量</h2>
      <div class="group">
        <div class="row">
          <span class="md-body-large row__key">交换区大小</span>
          <span class="md-body-medium row__value">
            {{ pct }}% · 约 {{ capacityMb }} MB
          </span>
        </div>
        <div class="slider-wrap">
          <mdui-slider
            :value="pct"
            :min="20"
            :max="80"
            :step="5"
            @input="onPct"
          />
        </div>
        <p class="md-body-small helper">
          修改容量会重建 zram，当前 swap 内容会被清空。
        </p>
      </div>
    </section>

    <section class="section">
      <h2 class="md-title-small section__title">算法</h2>
      <div class="group">
        <div class="field-wrap">
          <mdui-select
            variant="outlined"
            label="主算法"
            :value="algo"
            @change="onAlgo"
          >
            <mdui-menu-item v-for="a in ALGOS" :key="a" :value="a">
              {{ a }}
            </mdui-menu-item>
          </mdui-select>
        </div>
        <div class="field-wrap">
          <mdui-select
            variant="outlined"
            label="次算法"
            helper="冷页重压缩使用"
            :value="recomp"
            @change="onRecomp"
          >
            <mdui-menu-item v-for="a in recompItems" :key="a" :value="a">
              {{ a === "none" ? "关闭" : a }}
            </mdui-menu-item>
          </mdui-select>
        </div>
        <div class="switch-row">
          <span class="switch-row__text">
            <span class="md-body-large">自动重压缩</span>
            <span class="md-body-medium switch-row__desc">
              内存紧张时由内核自动执行
            </span>
          </span>
          <mdui-switch
            aria-label="自动重压缩"
            :checked="auto"
            @change="onAuto"
          />
        </div>
      </div>
    </section>

    <section class="section">
      <h2 class="md-title-small section__title">回写</h2>
      <div class="group">
        <div class="switch-row">
          <span class="switch-row__text">
            <span class="md-body-large">启用回写</span>
            <span class="md-body-medium switch-row__desc">
              将冷页写入 backing 文件
            </span>
          </span>
          <mdui-switch aria-label="启用回写" :checked="wb" @change="onWb" />
        </div>
        <div class="field-row">
          <mdui-text-field
            variant="outlined"
            type="number"
            label="backing 文件 MB"
            :value="backingMb"
            @input="onBacking"
          />
          <mdui-text-field
            variant="outlined"
            type="number"
            label="回写上限 MB"
            :value="wbLimitMb"
            @input="onWbLimit"
          />
        </div>
      </div>
    </section>

    <div class="save">
      <mdui-button variant="filled" full-width @click="save">
        保存并应用
      </mdui-button>
      <span class="md-body-small helper">保存后立即应用到 zram0</span>
    </div>
  </div>
</template>
