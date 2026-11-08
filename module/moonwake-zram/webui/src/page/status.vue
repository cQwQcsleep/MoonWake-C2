<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { MiuixCard, MiuixIcon, MiuixText } from "miuix-vue";
import { Ok } from "miuix-vue/icons";
import { getStatus } from "../lib/api";
import type { Status } from "../lib/types";

const s = ref<Status | null>(null);

const gib = (n: number) => (n / 1024 ** 3).toFixed(2);
const mib = (n: number) => (n / 1024 ** 2).toFixed(0);

const active = computed(() => !!s.value?.init);

const ratio = computed(() => {
  if (!s.value || !s.value.compr) return "--";
  return (s.value.orig / s.value.compr).toFixed(2) + "x";
});

const savedText = computed(() =>
  s.value
    ? `${(Math.max(0, s.value.orig - s.value.compr) / 1024 ** 2).toFixed(0)} MB`
    : "--",
);

const availGb = computed(() =>
  s.value ? ((s.value.avail_kb * 1024) / 1024 ** 3).toFixed(2) + " GB" : "--",
);

const shortKernel = computed(() => {
  const k = s.value?.kernel || "";
  return k.match(/MoonWake-([^\s]+)/)?.[1] || k || "-";
});

const statusStyle = computed(() => ({
  "--m-card-color": active.value ? "#DFFAE4" : "#FFE5E3",
}));

onMounted(async () => {
  s.value = await getStatus();
});
</script>

<template>
  <div class="page">
    <div class="status-grid">
      <MiuixCard class="mw-card status-card" :style="statusStyle">
        <div class="status-card__inner">
          <MiuixText size="20" weight="semibold" color="#101010">
            {{ active ? "运行中" : "未启用" }}
          </MiuixText>
          <MiuixText
            size="14"
            weight="medium"
            :color="active ? '#101010' : '#FF5A52'"
            class="status-card__sub"
          >
            {{ s ? `${gib(s.disksize)} GB · ${ratio}` : "--" }}
          </MiuixText>
          <MiuixIcon
            :icon="Ok"
            :size="110"
            :color="active ? '#36D167' : '#FF5A52'"
            class="status-card__mark"
          />
        </div>
      </MiuixCard>

      <div class="status-tiles">
        <MiuixCard class="mw-card stat">
          <MiuixText
            type="footnote1"
            color="var(--m-color-on-surface-variant-summary)"
          >
            压缩比
          </MiuixText>
          <MiuixText type="title2" weight="semibold">{{ ratio }}</MiuixText>
        </MiuixCard>
        <MiuixCard class="mw-card stat">
          <MiuixText
            type="footnote1"
            color="var(--m-color-on-surface-variant-summary)"
          >
            可用内存
          </MiuixText>
          <MiuixText type="title2" weight="semibold">{{ availGb }}</MiuixText>
        </MiuixCard>
      </div>
    </div>

    <MiuixCard class="mw-card info-card card-gap">
      <div class="info">
        <MiuixText type="headline1" weight="medium">ZRAM 容量</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ s ? `${gib(s.disksize)} GB` : "-" }}
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">已用内存</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ s ? `${mib(s.memused)} MB` : "-" }}
        </MiuixText>
      </div>
      <div class="info">
        <MiuixText type="headline1" weight="medium">压缩节省</MiuixText>
        <MiuixText type="body2" color="var(--m-color-on-surface-variant-summary)">
          {{ savedText }}
        </MiuixText>
      </div>
    </MiuixCard>

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

    <MiuixCard class="mw-card info-card card-gap">
      <div class="info">
        <MiuixText type="headline1" weight="medium">内核</MiuixText>
        <MiuixText
          type="body2"
          class="info__value"
          color="var(--m-color-on-surface-variant-summary)"
        >
          {{ shortKernel }}
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
