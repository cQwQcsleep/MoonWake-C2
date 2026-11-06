/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _F2FS_COMPRESS_OPS_H
#define _F2FS_COMPRESS_OPS_H

struct compress_ctx;
struct decompress_io_ctx;

struct f2fs_compress_ops {
	int (*init_compress_ctx)(struct compress_ctx *cc);
	void (*destroy_compress_ctx)(struct compress_ctx *cc);
	int (*compress_pages)(struct compress_ctx *cc);
	int (*init_decompress_ctx)(struct decompress_io_ctx *dic);
	void (*destroy_decompress_ctx)(struct decompress_io_ctx *dic);
	int (*decompress_pages)(struct decompress_io_ctx *dic);
};

#endif
