<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import {
  MiuixBasicComponent,
  MiuixCard,
  MiuixIcon,
  MiuixSmallTitle,
  MiuixText,
} from "miuix-vue";
import { Settings } from "miuix-vue/icons";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);

const gib = (n: number) => (n / 1024 ** 3).toFixed(2);
const mib = (n: number) => (n / 1024 ** 2).toFixed(0);

const ratio = computed(() => {
  if (!s.value || !s.value.compr) return "-";
  return (s.value.orig / s.value.compr).toFixed(2) + "x";
});

const RING_C = 2 * Math.PI * 50;

const ringOffset = computed(() => {
  if (!s.value || !s.value.orig) return RING_C;
  const saved = 1 - s.value.compr / s.value.orig;
  return RING_C * (1 - Math.min(1, Math.max(0, saved)));
});

onMounted(async () => {
  s.value = await getStatus();
});
</script>

<template>
  <div class="page">
    <MiuixCard
      class="mw-hero card-gap"
      style="--m-card-color: var(--m-color-primary-variant)"
    >
      <div class="hero">
        <div class="hero__text">
          <div class="hero__label">ZRAM 容量</div>
          <div class="hero__value">{{ s ? `${gib(s.disksize)} GB` : "--" }}</div>
          <div class="hero__sub">
            占用 {{ s ? `${mib(s.memused)} MB` : "--" }}
          </div>
        </div>
        <svg class="ring" viewBox="0 0 120 120" role="img" aria-label="压缩比">
          <circle class="ring__bg" cx="60" cy="60" r="50" />
          <circle
            class="ring__fg"
            cx="60"
            cy="60"
            r="50"
            :style="{ strokeDashoffset: ringOffset }"
          />
          <text class="ring__value" x="60" y="58">{{ ratio }}</text>
          <text class="ring__unit" x="60" y="78">压缩比</text>
        </svg>
      </div>
    </MiuixCard>

    <MiuixSmallTitle text="算法" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent
        title="主算法"
        :summary="s?.algo || '-'"
      >
        <template #start>
          <MiuixIcon :icon="Settings" />
        </template>
      </MiuixBasicComponent>
      <MiuixBasicComponent
        title="次算法"
        :summary="s?.recomp_algo || '-'"
      />
      <MiuixBasicComponent title="自动重压缩">
        <template #end>
          <MiuixText>{{ s?.auto_recomp ? "已开启" : "已关闭" }}</MiuixText>
        </template>
      </MiuixBasicComponent>
    </MiuixCard>

    <MiuixSmallTitle text="内存与回收" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent
        title="可用内存"
        :summary="s ? `${gib(s.avail_kb * 1024)} GB` : '-'"
      />
      <MiuixBasicComponent
        title="MGLRU min_ttl_ms"
        :summary="s ? String(s.lru_ttl) : '-'"
      />
      <MiuixBasicComponent
        title="回写页数"
        :summary="s ? `${s.bd_count} 页 / 写入 ${s.bd_writes}` : '-'"
      />
    </MiuixCard>

    <MiuixSmallTitle text="运行状态" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent title="内核" :summary="s?.kernel || '-'" />
      <MiuixBasicComponent
        title="回写设备"
        :summary="s?.backing || 'none'"
      />
      <MiuixBasicComponent
        title="最近一轮"
        :summary="s?.last || '尚未执行'"
      />
    </MiuixCard>
  </div>
</template>
