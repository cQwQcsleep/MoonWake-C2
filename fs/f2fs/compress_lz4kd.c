// SPDX-License-Identifier: GPL-2.0
/*
 * F2FS lz4kd compression backend.
 *
 * Must be a separate translation unit: include/linux/lz4kd.h redefines
 * the LZ4K_STATUS_* enumerators that include/linux/lz4k.h already
 * provides, so it cannot be included together with the lz4k header.
 */

#include <linux/fs.h>
#include <linux/f2fs_fs.h>
#include <linux/writeback.h>
#include <linux/backing-dev.h>
#include "f2fs.h"
#include <linux/lz4kd.h>
#include "compress_ops.h"

static int lz4kd_init_compress_ctx(struct compress_ctx *cc)
{
	cc->private = f2fs_kvmalloc(F2FS_I_SB(cc->inode),
				lz4kd_encode_state_bytes_min(), GFP_NOFS);
	if (!cc->private)
		return -ENOMEM;

	cc->clen = cc->rlen - PAGE_SIZE - COMPRESS_HEADER_SIZE;
	return 0;
}

static void lz4kd_destroy_compress_ctx(struct compress_ctx *cc)
{
	kvfree(cc->private);
	cc->private = NULL;
}

static int lz4kd_compress_pages(struct compress_ctx *cc)
{
	int ret;

	ret = lz4kd_encode(cc->private, cc->rbuf, cc->cbuf->cdata,
				cc->rlen, cc->clen, cc->clen);
	if (ret <= 0) {
		printk_ratelimited("%sF2FS-fs (%s): lz4kd compress failed, ret:%d\n",
				KERN_ERR, F2FS_I_SB(cc->inode)->sb->s_id, ret);
		return -EIO;
	}

	cc->clen = ret;
	return 0;
}

static int lz4kd_decompress_pages(struct decompress_io_ctx *dic)
{
	int ret;

	ret = lz4kd_decode(dic->cbuf->cdata, dic->rbuf, dic->clen, dic->rlen);
	if (ret < 0) {
		printk_ratelimited("%sF2FS-fs (%s): lz4kd decompress failed, ret:%d\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id, ret);
		return -EIO;
	}

	if (ret != dic->rlen) {
		printk_ratelimited("%sF2FS-fs (%s): lz4kd invalid rlen:%zu, expected:%lu\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id,
				dic->rlen, PAGE_SIZE << dic->log_cluster_size);
		return -EIO;
	}
	return 0;
}

const struct f2fs_compress_ops f2fs_lz4kd_ops = {
	.init_compress_ctx	= lz4kd_init_compress_ctx,
	.destroy_compress_ctx	= lz4kd_destroy_compress_ctx,
	.compress_pages		= lz4kd_compress_pages,
	.decompress_pages	= lz4kd_decompress_pages,
};
