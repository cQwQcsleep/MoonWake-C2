<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import {
  MiuixBasicComponent,
  MiuixCard,
  MiuixDivider,
  MiuixIcon,
  MiuixProgressIndicator,
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
  if (!s.value || !s.value.compr) return "--";
  return (s.value.orig / s.value.compr).toFixed(2) + "x";
});

const saved = computed(() => {
  if (!s.value || !s.value.orig) return 0;
  return Math.min(1, Math.max(0, 1 - s.value.compr / s.value.orig));
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
          <MiuixText class="hero__label">ZRAM 容量</MiuixText>
          <MiuixText class="hero__value">
            {{ s ? `${gib(s.disksize)} GB` : "--" }}
          </MiuixText>
          <MiuixText class="hero__sub">
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

    <MiuixSmallTitle text="算法" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent title="主算法" :summary="s?.algo || '-'">
        <template #start>
          <MiuixIcon :icon="Settings" />
        </template>
      </MiuixBasicComponent>
      <MiuixDivider />
      <MiuixBasicComponent title="次算法" :summary="s?.recomp_algo || '-'" />
      <MiuixDivider />
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
      <MiuixDivider />
      <MiuixBasicComponent
        title="MGLRU 最小 TTL"
        :summary="s ? `${s.lru_ttl} ms` : '-'"
      />
      <MiuixDivider />
      <MiuixBasicComponent
        title="回写页数"
        :summary="s ? `${s.bd_count} 页 / 写入 ${s.bd_writes}` : '-'"
      />
    </MiuixCard>

    <MiuixSmallTitle text="运行状态" />
    <MiuixCard class="mw-card card-gap">
      <MiuixBasicComponent title="内核" :summary="s?.kernel || '-'" />
      <MiuixDivider />
      <MiuixBasicComponent title="回写设备" :summary="s?.backing || 'none'" />
      <MiuixDivider />
      <MiuixBasicComponent
        title="最近一轮"
        :summary="s?.last || '尚未执行'"
      />
    </MiuixCard>
  </div>
</template>
