<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import {
  MiuixCard,
  MiuixProgressIndicator,
  MiuixSmallTitle,
  MiuixText,
} from "miuix-vue";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);

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

const savedMb = computed(() =>
  s.value ? Math.max(0, s.value.orig - s.value.compr) / 1024 ** 2 : 0,
);
const savedText = computed(() => `${savedMb.value.toFixed(0)} MB`);

const availGb = computed(() => (s.value ? (s.value.avail_kb * 1024) / 1024 ** 3 : 0));

onMounted(async () => {
  s.value = await getStatus();
});
</script>

<template>
  <div class="page">
    <MiuixCard
      class="mw-card card-gap"
      style="--m-card-color: var(--m-color-primary-variant)"
    >
      <div class="hero">
        <div class="hero__text">
          <MiuixText type="body2" class="hero__label">ZRAM 容量</MiuixText>
          <MiuixText type="title1" class="hero__value">
            {{ s ? `${gib(s.disksize)} GB` : "--" }}
          </MiuixText>
          <MiuixText type="footnote1" class="hero__sub">
            占用 {{ s ? `${mib(s.memused)} MB` : "--" }}
          </MiuixText>
        </div>
        <div class="hero__ring">
          <MiuixProgressIndicator
            type="circular"
            :progress="saved"
            :size="104"
            :stroke-width="9"
            color="#ffffff"
          />
          <div class="hero__ring-label">
            <span class="hero__ratio">{{ ratio }}</span>
            <span class="hero__unit">压缩比</span>
          </div>
        </div>
      </div>
    </MiuixCard>

    <div class="stat-row">
      <MiuixCard class="mw-card stat">
        <MiuixText type="footnote1" color="var(--m-color-on-surface-variant-summary)">
          压缩节省
        </MiuixText>
        <MiuixText type="title2" weight="semibold">
          {{ s ? savedText : "--" }}
        </MiuixText>
      </MiuixCard>
      <MiuixCard class="mw-card stat">
        <MiuixText type="footnote1" color="var(--m-color-on-surface-variant-summary)">
          可用内存
        </MiuixText>
        <MiuixText type="title2" weight="semibold">
          {{ s ? `${availGb.toFixed(2)} GB` : "--" }}
        </MiuixText>
      </MiuixCard>
    </div>

    <MiuixSmallTitle text="算法" />
    <MiuixCard class="mw-card info-card card-gap">
      <div class="info">
        <MiuixText type="headline1" weight="medium">主算法</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ s?.algo || "-" }}
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">次算法</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ s?.recomp_algo || "-" }}
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">自动重压缩</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ s?.auto_recomp ? "已开启" : "已关闭" }}
        </MiuixText>
      </div>
    </MiuixCard>

    <MiuixSmallTitle text="运行状态" />
    <MiuixCard class="mw-card info-card card-gap">
      <div class="info">
        <MiuixText type="headline1" weight="medium">内核</MiuixText>
        <MiuixText
          type="body2"
          class="info__value"
          color="var(--m-color-on-surface-variant-summary)"
        >
          {{ s?.kernel || "-" }}
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">MGLRU 最小 TTL</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ s ? `${s.lru_ttl} ms` : "-" }}
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">回写设备</MiuixText>
        <MiuixText
          type="body2"
          class="info__value"
          color="var(--m-color-on-surface-variant-summary)"
        >
          {{ s?.backing || "none" }}
          <template v-if="s && s.bd_count">
            · {{ s.bd_count }} 页 / 读 {{ s.bd_reads }} / 写 {{ s.bd_writes }}
          </template>
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">最近一轮</MiuixText>
        <MiuixText
          type="body2"
          class="info__value"
          color="var(--m-color-on-surface-variant-summary)"
        >
          {{ s?.last || "尚未执行" }}
        </MiuixText>
      </div>
    </MiuixCard>
  </div>
</template>
