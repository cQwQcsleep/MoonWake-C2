<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import {
  MiuixBasicComponent,
  MiuixCard,
  MiuixIcon,
  MiuixSmallTitle,
  MiuixText,
} from "miuix-vue";
import { Info, Settings } from "miuix-vue/icons";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);

const gib = (n: number) => (n / 1024 ** 3).toFixed(2);
const mib = (n: number) => (n / 1024 ** 2).toFixed(0);

const ratio = computed(() => {
  if (!s.value || !s.value.compr) return "-";
  return (s.value.orig / s.value.compr).toFixed(2) + "x";
});

onMounted(async () => {
  s.value = await getStatus();
});
</script>

<template>
  <div class="page">
    <MiuixCard
      class="card-gap"
      show-indication
      style="--m-card-color: var(--m-color-primary-variant)"
    >
      <MiuixBasicComponent
        title="ZRAM 容量"
        titleColor="var(--m-color-on-primary-variant)"
        :summary="s ? `${gib(s.disksize)} GB` : '读取中'"
        summaryColor="var(--m-color-on-primary-variant)"
      >
        <template #start>
          <MiuixIcon color="var(--m-color-on-primary-variant)" :icon="Info" />
        </template>
      </MiuixBasicComponent>
      <MiuixBasicComponent
        :title="`压缩比 ${ratio}`"
        titleColor="var(--m-color-on-primary-variant)"
        :summary="s ? `占用 ${mib(s.memused)} MB` : ''"
        summaryColor="var(--m-color-on-primary-variant)"
      />
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
