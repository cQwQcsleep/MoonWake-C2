import type { Conf, Status } from "./types";

const BIN = "/data/adb/modules/moonwake-zram/bin/mwk-zram";

declare global {
  interface Window {
    ksu?: {
      exec: (
        cmd: string,
        opts?: Record<string, unknown>,
      ) => Promise<{ errno: number; stdout: string; stderr: string }>;
    };
  }
}

export const isReal = () => !!window.ksu;

async function run(cmd: string): Promise<string> {
  if (!window.ksu) throw new Error("not in KernelSU WebUI");
  const res = await window.ksu.exec(cmd, { cwd: "/" });
  return res.stdout || "";
}

/* ---------- mock ---------- */

const mockConf: Conf = {
  disksize_pct: 50,
  algo: "lz4kd",
  recomp_algo: "zstdn",
  auto_recomp: 1,
  writeback: 0,
  backing_mb: 2048,
  wb_limit_mb: 1024,
};

const mockStatus: Status = {
  kernel: "4.19.325-MoonWake-2.7.0-C2PN",
  init: 1,
  disksize: 3221225472,
  orig: 1073741824,
  compr: 356515840,
  memused: 402653184,
  algo: "lz4kd",
  recomp_algo: "zstdn",
  auto_recomp: 1,
  backing: "none",
  bd: "",
  bd_count: 0,
  bd_reads: 0,
  bd_writes: 0,
  avail_kb: 1843200,
  lru_ttl: 0,
  last: "recompressed 2048 pages, 12 refaults, cooldown 600000ms",
  conf: { ...mockConf },
};

/* ---------- api ---------- */

export async function getStatus(): Promise<Status> {
  if (!isReal()) return { ...mockStatus, conf: { ...mockConf } };
  const out = await run(`sh ${BIN} status`);
  return JSON.parse(out.trim()) as Status;
}

export async function saveConf(patch: Partial<Conf>): Promise<void> {
  if (!isReal()) {
    Object.assign(mockConf, patch);
    return;
  }
  for (const [k, v] of Object.entries(patch)) {
    await run(`sh ${BIN} set ${k} ${v}`);
  }
}

export async function applyConf(): Promise<void> {
  if (!isReal()) return;
  await run(`sh ${BIN} apply`);
}

export async function recompress(): Promise<void> {
  if (!isReal()) return;
  await run(`sh ${BIN} recompress`);
}

export async function writeback(): Promise<void> {
  if (!isReal()) return;
  await run(`sh ${BIN} writeback`);
}

export async function getLogs(): Promise<string> {
  if (!isReal()) {
    return [
      "[mock] mwk-zram: apply done: disksize=3221225472 algo=lz4kd recomp=zstdn auto=1 wb=0",
      "[mock] zram0: recompressed 2048 pages, 12 refaults, cooldown 600000ms",
    ].join("\n");
  }
  return run(`sh ${BIN} logs`);
}
