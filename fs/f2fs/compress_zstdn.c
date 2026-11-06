// SPDX-License-Identifier: GPL-2.0
/*
 * F2FS zstdn compression backend.
 *
 * The zstdn wrapper exposes the same streaming API as zstd but with
 * prefixed symbols/types, so it must live in its own translation unit:
 * lib/zstdn/include/zstd.h uses the LINUX_ZSTD_H guard and cannot be
 * included together with <linux/zstd.h>.
 */

#include <linux/fs.h>
#include <linux/f2fs_fs.h>
#include <linux/writeback.h>
#include <linux/backing-dev.h>
#include "f2fs.h"
#include <zstd.h>
#include "compress_ops.h"

#define F2FS_ZSTDN_DEFAULT_CLEVEL	1

static int zstdn_init_compress_ctx(struct compress_ctx *cc)
{
	zstdn_parameters params;
	zstdn_cstream *stream;
	void *workspace;
	size_t workspace_size;

	params = zstdn_get_params(F2FS_ZSTDN_DEFAULT_CLEVEL, cc->rlen);
	workspace_size = zstdn_cstream_workspace_bound(&params.cParams);

	workspace = f2fs_kvmalloc(F2FS_I_SB(cc->inode),
					workspace_size, GFP_NOFS);
	if (!workspace)
		return -ENOMEM;

	stream = zstdn_init_cstream(&params, 0, workspace, workspace_size);
	if (!stream) {
		printk_ratelimited("%sF2FS-fs (%s): %s zstdn_init_cstream failed\n",
				KERN_ERR, F2FS_I_SB(cc->inode)->sb->s_id,
				__func__);
		kvfree(workspace);
		return -EIO;
	}

	cc->private = workspace;
	cc->private2 = stream;
	cc->clen = cc->rlen - PAGE_SIZE - COMPRESS_HEADER_SIZE;
	return 0;
}

static void zstdn_destroy_compress_ctx(struct compress_ctx *cc)
{
	kvfree(cc->private);
	cc->private = NULL;
	cc->private2 = NULL;
}

static int zstdn_compress_pages(struct compress_ctx *cc)
{
	zstdn_cstream *stream = cc->private2;
	zstdn_in_buffer inbuf;
	zstdn_out_buffer outbuf;
	int src_size = cc->rlen;
	int dst_size = src_size - PAGE_SIZE - COMPRESS_HEADER_SIZE;
	size_t ret;

	inbuf.pos = 0;
	inbuf.src = cc->rbuf;
	inbuf.size = src_size;

	outbuf.pos = 0;
	outbuf.dst = cc->cbuf->cdata;
	outbuf.size = dst_size;

	ret = zstdn_compress_stream(stream, &outbuf, &inbuf);
	if (zstdn_is_error(ret)) {
		printk_ratelimited("%sF2FS-fs (%s): %s zstdn_compress_stream failed, ret: %d\n",
				KERN_ERR, F2FS_I_SB(cc->inode)->sb->s_id,
				__func__, (int)zstdn_get_error_code(ret));
		return -EIO;
	}

	ret = zstdn_end_stream(stream, &outbuf);
	if (zstdn_is_error(ret)) {
		printk_ratelimited("%sF2FS-fs (%s): %s zstdn_end_stream returned %d\n",
				KERN_ERR, F2FS_I_SB(cc->inode)->sb->s_id,
				__func__, (int)zstdn_get_error_code(ret));
		return -EIO;
	}

	if (ret)
		return -EAGAIN;

	cc->clen = outbuf.pos;
	return 0;
}

static int zstdn_init_decompress_ctx(struct decompress_io_ctx *dic)
{
	zstdn_dstream *stream;
	void *workspace;
	size_t workspace_size;

	workspace_size = zstdn_dstream_workspace_bound(MAX_COMPRESS_WINDOW_SIZE);

	workspace = f2fs_kvmalloc(F2FS_I_SB(dic->inode),
					workspace_size, GFP_NOFS);
	if (!workspace)
		return -ENOMEM;

	stream = zstdn_init_dstream(MAX_COMPRESS_WINDOW_SIZE, workspace,
					workspace_size);
	if (!stream) {
		printk_ratelimited("%sF2FS-fs (%s): %s zstdn_init_dstream failed\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id,
				__func__);
		kvfree(workspace);
		return -EIO;
	}

	dic->private = workspace;
	dic->private2 = stream;
	return 0;
}

static void zstdn_destroy_decompress_ctx(struct decompress_io_ctx *dic)
{
	kvfree(dic->private);
	dic->private = NULL;
	dic->private2 = NULL;
}

static int zstdn_decompress_pages(struct decompress_io_ctx *dic)
{
	zstdn_dstream *stream = dic->private2;
	zstdn_in_buffer inbuf;
	zstdn_out_buffer outbuf;
	size_t ret;

	inbuf.pos = 0;
	inbuf.src = dic->cbuf->cdata;
	inbuf.size = dic->clen;

	outbuf.pos = 0;
	outbuf.dst = dic->rbuf;
	outbuf.size = dic->rlen;

	ret = zstdn_decompress_stream(stream, &outbuf, &inbuf);
	if (zstdn_is_error(ret)) {
		printk_ratelimited("%sF2FS-fs (%s): %s zstdn_decompress_stream failed, ret: %d\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id,
				__func__, (int)zstdn_get_error_code(ret));
		return -EIO;
	}

	if (dic->rlen != outbuf.pos) {
		printk_ratelimited("%sF2FS-fs (%s): %s zstdn invalid rlen:%zu, expected:%lu\n",
				KERN_ERR, F2FS_I_SB(dic->inode)->sb->s_id,
				__func__, dic->rlen,
				PAGE_SIZE << dic->log_cluster_size);
		return -EIO;
	}

	return 0;
}

const struct f2fs_compress_ops f2fs_zstdn_ops = {
	.init_compress_ctx	= zstdn_init_compress_ctx,
	.destroy_compress_ctx	= zstdn_destroy_compress_ctx,
	.compress_pages		= zstdn_compress_pages,
	.init_decompress_ctx	= zstdn_init_decompress_ctx,
	.destroy_decompress_ctx	= zstdn_destroy_decompress_ctx,
	.decompress_pages	= zstdn_decompress_pages,
};
