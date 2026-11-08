<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);

const R = 52;
const CIRC = 2 * Math.PI * R;

const gib = (n: number) => (n / 1024 ** 3).toFixed(2);
const mib = (n: number) => (n / 1024 ** 2).toFixed(0);

const ratio = computed(() => {
  if (!s.value || !s.value.compr) return "--";
  return (s.value.orig / s.value.compr).toFixed(2) + "x";
});

const saved = computed(() => {
  if (!s.value || !s.value.orig) return 0;
  return Math.min(1, Math.max(0, 1 - s.value.compr / s.value.orig));
});

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

onMounted(async () => {
  s.value = await getStatus();
});
</script>

<template>
  <div class="page">
    <section class="hero" aria-label="ZRAM 概况">
      <div class="hero__text">
        <span class="md-label-large hero__label">ZRAM 容量</span>
        <span class="md-display-small hero__value">
          {{ s ? `${gib(s.disksize)} GB` : "--" }}
        </span>
        <span class="md-body-medium hero__sub">
          已用 {{ s ? `${mib(s.memused)} MB` : "--" }}
        </span>
      </div>
      <div class="hero__ring">
        <svg class="ring" viewBox="0 0 120 120" aria-hidden="true">
          <circle class="ring__track" cx="60" cy="60" :r="R" />
          <circle
            class="ring__value"
            cx="60"
            cy="60"
            :r="R"
            :stroke-dasharray="CIRC"
            :stroke-dashoffset="CIRC * (1 - saved)"
          />
        </svg>
        <div class="hero__ring-label">
          <span class="md-title-large hero__ratio">{{ ratio }}</span>
          <span class="md-label-small">压缩比</span>
        </div>
      </div>
    </section>

    <div class="stat-grid">
      <div class="stat">
        <span class="md-label-medium stat__label">压缩节省</span>
        <span class="md-headline-small stat__value">{{ savedText }}</span>
      </div>
      <div class="stat">
        <span class="md-label-medium stat__label">可用内存</span>
        <span class="md-headline-small stat__value">{{ availText }}</span>
      </div>
    </div>

    <section class="section">
      <h2 class="md-title-small section__title">算法</h2>
      <div class="group">
        <div class="row">
          <span class="md-body-large row__key">主算法</span>
          <span class="md-body-medium row__value">{{ s?.algo || "-" }}</span>
        </div>
        <div class="row">
          <span class="md-body-large row__key">次算法</span>
          <span class="md-body-medium row__value">
            {{ s?.recomp_algo || "-" }}
          </span>
        </div>
        <div class="row">
          <span class="md-body-large row__key">自动重压缩</span>
          <span class="md-body-medium row__value">
            {{ s?.auto_recomp ? "已开启" : "已关闭" }}
          </span>
        </div>
      </div>
    </section>

    <section class="section">
      <h2 class="md-title-small section__title">内存与回收</h2>
      <div class="group">
        <div class="row">
          <span class="md-body-large row__key">MGLRU 最小 TTL</span>
          <span class="md-body-medium row__value">
            {{ s ? `${s.lru_ttl} ms` : "-" }}
          </span>
        </div>
        <div class="row">
          <span class="md-body-large row__key">回写页数</span>
          <span class="md-body-medium row__value">
            {{ s ? `${s.bd_count} 页 / 写入 ${s.bd_writes}` : "-" }}
          </span>
        </div>
      </div>
    </section>

    <section class="section">
      <h2 class="md-title-small section__title">运行状态</h2>
      <div class="group">
        <div class="row">
          <span class="md-body-large row__key">内核</span>
          <span class="md-body-medium row__value">{{ shortKernel }}</span>
        </div>
        <div class="row">
          <span class="md-body-large row__key">回写设备</span>
          <span class="md-body-medium row__value">
            {{ s?.backing || "none" }}
          </span>
        </div>
        <div class="row row--stack">
          <span class="md-body-large row__key">最近一轮</span>
          <span class="md-body-medium row__value">
            {{ s?.last || "尚未执行" }}
          </span>
        </div>
      </div>
    </section>
  </div>
</template>
