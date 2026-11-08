export interface Status {
  kernel: string;
  init: number;
  disksize: number;
  orig: number;
  compr: number;
  memused: number;
  algo: string;
  recomp_algo: string;
  auto_recomp: number;
  backing: string;
  bd: string;
  bd_count: number;
  bd_reads: number;
  bd_writes: number;
  avail_kb: number;
  lru_ttl: number;
  last: string;
  conf: Conf;
}

export interface Conf {
  disksize_pct: number;
  algo: string;
  recomp_algo: string;
  auto_recomp: number;
  writeback: number;
  backing_mb: number;
  wb_limit_mb: number;
}

export const ALGOS = [
  "lz4kd",
  "lz4k_oplus",
  "lz4k",
  "zstdn",
  "zstd",
  "lz4",
  "lzo-rle",
  "lzo",
];
