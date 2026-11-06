// SPDX-License-Identifier: GPL-2.0
/*
 * F2FS lz4k_oplus compression backend.
 *
 * Kept in a separate translation unit because lib/lz4k_oplus/lz4k.h
 * defines several unprefixed short type aliases.
 */

#include <linux/fs.h>
#include <linux/f2fs_fs.h>
#include <linux/writeback.h>
#include <linux/backing-dev.h>
#include "f2fs.h"
#include <lz4k.h>
#include "compress_ops.h"

static int lz4k_oplus_init_compress_ctx(struct compress_ctx *cc)
{
	cc->private = f2fs_kvmalloc(F2FS_I_SB(cc->inode),
					PAGE_SIZE * 2, GFP_NOFS);
	if (!cc->private)
		return -ENOMEM;

	cc->clen = cc->rlen - PAGE_SIZE - COMPRESS_HEADER_SIZE;
	return 0;
}

static void lz4k_oplus_destroy_compress_ctx(struct compress_ctx *cc)
{
	kvfree(cc->private);
	cc->private = NULL;
}

static int lz4k_oplus_compress_pages(struct compress_ctx *cc)
{
	int ret;

	ret = lz4k_compress(cc->private, cc->rbuf, cc->cbuf->cdata,
				cc->rlen, cc->clen);
	if (ret <= 0) {
		printk_ratelimited("%sF2FS-fs (%s): lz4k_oplus compress failed, ret:%d\n",
				KERN_ERR, F2FS_I_SB(cc->inode)->sb->s_id, ret);
		return -EIO;
	}

	cc->clen = ret;
	return 0;
}

static int lz4k_oplus_decompress_pages(struct decompress_io_ctx *dic)
{
	int ret;

	ret = lz4k_decompress(dic->cbuf->cdata, dic->rbuf,
				dic->clen, dic->rlen);
	if (ret < 0) {
		printk_ratelimited("%sF2FS-fs (%s): lz4k_oplus decompress failed, ret:%d\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id, ret);
		return -EIO;
	}

	if (ret != dic->rlen) {
		printk_ratelimited("%sF2FS-fs (%s): lz4k_oplus invalid rlen:%zu, expected:%lu\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id,
				dic->rlen, PAGE_SIZE << dic->log_cluster_size);
		return -EIO;
	}

	return 0;
}

const struct f2fs_compress_ops f2fs_lz4k_oplus_ops = {
	.init_compress_ctx	= lz4k_oplus_init_compress_ctx,
	.destroy_compress_ctx	= lz4k_oplus_destroy_compress_ctx,
	.compress_pages		= lz4k_oplus_compress_pages,
	.decompress_pages	= lz4k_oplus_decompress_pages,
};
