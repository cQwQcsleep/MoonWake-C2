<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);

const gib = (n: number) => (n / 1024 ** 3).toFixed(2);
const mib = (n: number) => (n / 1024 ** 2).toFixed(0);

const ratio = computed(() => {
  if (!s.value || !s.value.compr) return "--";
  return (s.value.orig / s.value.compr).toFixed(2) + "x";
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
    <section class="hero">
      <div class="hero__text">
        <span class="t-label hero__label">ZRAM 容量</span>
        <span class="t-display hero__value">
          {{ s ? `${gib(s.disksize)} GB` : "--" }}
        </span>
        <span class="t-body hero__sub">
          已用 {{ s ? `${mib(s.memused)} MB` : "--" }}
        </span>
      </div>
      <div class="hero__ratio">
        <span class="t-title">{{ ratio }}</span>
        <span class="t-label">压缩比</span>
      </div>
    </section>

    <div class="stat-row">
      <div class="stat">
        <span class="t-label stat__label">压缩节省</span>
        <span class="t-headline">{{ savedText }}</span>
      </div>
      <div class="stat">
        <span class="t-label stat__label">可用内存</span>
        <span class="t-headline">{{ availText }}</span>
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
