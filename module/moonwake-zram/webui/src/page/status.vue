<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);
const mounted = ref(false);
const pctShown = ref<number | null>(null);

const RING_R = 52;
const CIRC = 2 * Math.PI * RING_R;

const gib = (n: number) => (n / 1024 ** 3).toFixed(2);
const mib = (n: number) => (n / 1024 ** 2).toFixed(0);

const usagePct = computed(() => {
  if (!s.value || !s.value.disksize) return 0;
  return Math.round(
    Math.min(1, Math.max(0, s.value.memused / s.value.disksize)) * 100,
  );
});

const ratioPct = computed(() =>
  s.value && s.value.orig ? (s.value.compr / s.value.orig) * 100 : null,
);

const ratioFrac = computed(() =>
  ratioPct.value === null ? 0 : Math.min(1, Math.max(0, ratioPct.value / 100)),
);

const pctText = computed(() => {
  if (ratioPct.value === null) return "--";
  if (ratioPct.value > 0 && ratioPct.value < 1) return "<1%";
  return `${pctShown.value ?? Math.round(ratioPct.value)}%`;
});

const dashOffset = computed(() => CIRC * (1 - (mounted.value ? ratioFrac.value : 0)));

const savedText = computed(() =>
  s.value
    ? `${(Math.max(0, s.value.orig - s.value.compr) / 1024 ** 2).toFixed(0)} MB`
    : "--",
);

const availText = computed(() =>
  s.value ? `${((s.value.avail_kb * 1024) / 1024 ** 3).toFixed(2)} GB` : "--",
);

const shortKernel = computed(() => {
  const k = s.value?.kernel || "";
  return k.match(/MoonWake-([^\s]+)/)?.[1] || k || "-";
});

function countUp(to: number) {
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    pctShown.value = to;
    return;
  }
  const start = performance.now();
  const dur = 720;
  const tick = (now: number) => {
    const t = Math.min(1, (now - start) / dur);
    pctShown.value = Math.round(to * (1 - (1 - t) ** 3));
    if (t < 1) requestAnimationFrame(tick);
  };
  pctShown.value = 0;
  requestAnimationFrame(tick);
}

async function load(animate = false) {
  s.value = await getStatus();
  if (animate && ratioPct.value !== null) {
    countUp(Math.round(ratioPct.value));
    requestAnimationFrame(() => {
      mounted.value = true;
    });
  }
}

const onRefresh = () => void load();

onMounted(async () => {
  await load(true);
  window.addEventListener("mw:refresh", onRefresh);
});

onBeforeUnmount(() => window.removeEventListener("mw:refresh", onRefresh));
</script>

<template>
  <div class="page">
    <section class="hero">
      <div class="hero__text">
        <span class="t-label hero__label">ZRAM 容量</span>
        <span class="t-display hero__value">
          {{ s ? `${gib(s.disksize)} GB` : "--" }}
        </span>
        <span class="t-body hero__sub">
          已用 {{ s ? `${mib(s.memused)} MB` : "--" }} · {{ usagePct }}%
        </span>
      </div>
      <div
        class="ring"
        role="img"
        :aria-label="`压缩后占原始数据 ${pctText}`"
      >
        <svg class="ring__svg" viewBox="0 0 120 120">
          <circle class="ring__track" cx="60" cy="60" :r="RING_R" />
          <circle
            class="ring__bar"
            cx="60"
            cy="60"
            :r="RING_R"
            :stroke-dasharray="CIRC"
            :stroke-dashoffset="dashOffset"
          />
        </svg>
        <div class="ring__center">
          <span class="ring__pct">{{ pctText }}</span>
        </div>
      </div>
    </section>

    <div class="stat-row">
      <div class="stat">
        <div class="stat__head">
          <span class="t-label stat__label">压缩节省</span>
          <md-icon class="stat__icon" aria-hidden="true">compress</md-icon>
        </div>
        <span class="t-headline stat__value">{{ savedText }}</span>
      </div>
      <div class="stat">
        <div class="stat__head">
          <span class="t-label stat__label">可用内存</span>
          <md-icon class="stat__icon" aria-hidden="true">memory</md-icon>
        </div>
        <span class="t-headline stat__value">{{ availText }}</span>
      </div>
    </div>

    <section class="section">
      <h2 class="section-title t-title-sm">算法</h2>
      <div class="group">
        <div class="row">
          <span class="t-body-lg">主算法</span>
          <span class="t-body row__value">{{ s?.algo || "-" }}</span>
        </div>
        <div class="row">
          <span class="t-body-lg">次算法</span>
          <span class="t-body row__value">{{ s?.recomp_algo || "-" }}</span>
        </div>
        <div class="row">
          <span class="t-body-lg">自动重压缩</span>
          <span class="t-body row__value">
            {{ s?.auto_recomp ? "已开启" : "已关闭" }}
          </span>
        </div>
      </div>
    </section>

    <section class="section">
      <h2 class="section-title t-title-sm">内存与回收</h2>
      <div class="group">
        <div class="row">
          <span class="t-body-lg">MGLRU 最小 TTL</span>
          <span class="t-body row__value">
            {{ s ? `${s.lru_ttl} ms` : "-" }}
          </span>
        </div>
        <div class="row">
          <span class="t-body-lg">回写页数</span>
          <span class="t-body row__value">
            {{ s ? `${s.bd_count} 页 / 写入 ${s.bd_writes}` : "-" }}
          </span>
        </div>
      </div>
    </section>

    <section class="section">
      <h2 class="section-title t-title-sm">运行状态</h2>
      <div class="group">
        <div class="row">
          <span class="t-body-lg">内核</span>
          <span class="t-body row__value">{{ shortKernel }}</span>
        </div>
        <div class="row">
          <span class="t-body-lg">回写设备</span>
          <span class="t-body row__value">{{ s?.backing || "none" }}</span>
        </div>
        <div class="row">
          <span class="t-body-lg">最近一轮</span>
          <span class="t-body row__value row__value--long">
            {{ s?.last || "尚未执行" }}
          </span>
        </div>
      </div>
    </section>
  </div>
</template>
