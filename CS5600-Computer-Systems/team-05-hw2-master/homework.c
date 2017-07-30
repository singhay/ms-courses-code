/*
 * file:        homework.c
 * description: skeleton file for CS 5600/7600 file system
 *
 * CS 5600, Computer Systems, Northeastern CCIS
 * Peter Desnoyers, November 2016
 */

#define FUSE_USE_VERSION 27
#define _GNU_SOURCE

#include <stdlib.h>
#include <stddef.h>
#include <unistd.h>
#include <fuse.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

#include "fsx600.h"
#include "blkdev.h"

#define TRAILING_SLASH '/'
#define END_OF_STRING '\0'
#define TOTAL_DIR_ENTRIES 32

extern int homework_part;       /* set by '-part n' command-line option */

/*
 * disk access - the global variable 'disk' points to a blkdev
 * structure which has been initialized to access the image file.
 *
 * NOTE - blkdev access is in terms of 1024-byte blocks
 */
extern struct blkdev *disk;

/* by defining bitmaps as 'fd_set' pointers, you can use existing
 * macros to handle them.
 *   FD_ISSET(##, inode_map);
 *   FD_CLR(##, block_map);
 *   FD_SET(##, block_map);
 */
fd_set *inode_map = NULL;              /* = malloc(sb.inode_map_size * FS_BLOCK_SIZE); */
fd_set *block_map = NULL;

// Store the inode table
struct fs_inode *inode_region = NULL;

int root_inode;
int inode_map_sz;
int block_map_sz;
int inode_region_sz;
int disk_total_blocks;

enum {PTRS_PER_INDIRECT_BLOCK = FS_BLOCK_SIZE / sizeof(uint32_t)};


/* init - this is called once by the FUSE framework at startup. Ignore
 * the 'conn' argument.
 * recommended actions:
 *   - read superblock
 *   - allocate memory, read bitmaps and inodes
 */
void* fs_init(struct fuse_conn_info *conn)
{
    struct fs_super sb;
    if (disk->ops->read(disk, 0, 1, &sb) < 0) {
        exit(1);
    }

    inode_map_sz      = sb.inode_map_sz;
    block_map_sz      = sb.block_map_sz;
    inode_region_sz   = sb.inode_region_sz;
    disk_total_blocks = sb.num_blocks;

    inode_map    = malloc(inode_map_sz * FS_BLOCK_SIZE);
    block_map    = malloc(block_map_sz * FS_BLOCK_SIZE);
    inode_region = malloc(inode_region_sz * FS_BLOCK_SIZE);

    // Store the location of the root inode
    root_inode = sb.root_inode;

    // super block always takes up first block, so read maps starting
    // from block index 1
    int next_block_start = 1;
    disk->ops->read(disk, next_block_start, inode_map_sz, inode_map);
    next_block_start += sb.inode_map_sz;
    disk->ops->read(disk, next_block_start, block_map_sz, block_map);
    next_block_start += sb.block_map_sz;
    disk->ops->read(disk, next_block_start, inode_region_sz, inode_region);

    return NULL;
}

/* Note on path translation errors:
 * In addition to the method-specific errors listed below, almost
 * every method can return one of the following errors if it fails to
 * locate a file or directory corresponding to a specified path.
 *
 * ENOENT - a component of the path is not present.
 * ENOTDIR - an intermediate component of the path (e.g. 'b' in
 *           /a/b/c) is not a directory
 */

/* note on splitting the 'path' variable:
 * the value passed in by the FUSE framework is declared as 'const',
 * which means you can't modify it. The standard mechanisms for
 * splitting strings in C (strtok, strsep) modify the string in place,
 * so you have to copy the string and then free the copy when you're
 * done. One way of doing this:
 *
 *    char *_path = strdup(path);
 *    int inum = translate(_path);
 *    free(_path);
 */

/**
 * Translates an absolute path into an inode number
 *
 * Inputs:
 * - path, the path as a const string
 *
 * Returns:
 * -ENOENT if the path does not exist
 * -ENOTDIR if a middle component of the path is not a directory
 * Else the inode number for the last component of the path
 */
int translate(const char *path)
{
    char *_path           = strdupa(path);
    char *part            = NULL;
    char *token           = NULL;
    int inode_num         = root_inode;
    struct fs_inode in;
    struct fs_dirent *dir = malloc(FS_BLOCK_SIZE);

    while((part = strsep(&_path, "/"))) {
        // Skip the empty string parts found by strsep
        if(strcmp(part, "") == 0) {
            continue;
        }

        // Check that this is actually a directory
        in = inode_region[inode_num];
        if(!S_ISDIR(in.mode)) {
            free(dir);
            return -ENOTDIR;
        }

        // Read the directory entry
        disk->ops->read(disk, in.direct[0], 1, dir);

        // Iterate over the directory, looking for the current part
        int i;
        for (i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
            if(dir[i].valid == 1 && strcmp(dir[i].name, part) == 0) {
                inode_num = dir[i].inode;
                break;
            }
        }
        if(i == TOTAL_DIR_ENTRIES) {
            free(dir);
            return -ENOENT;
        }
    }

    free(dir);
    return inode_num;
}

/**
 * Gets the leaf name from a path
 *
 * Inputs:
 * - path, the path as a const string
 *
 * Returns:
 * NULL if there is no leaf (i.e. the path is the root dir '/')
 * Otherwise, the portion of the path following the last '/'
 * (excluding trailing '/')
 */
char *leaf_name_from_path(const char *path)
{
    char *_path = strdupa(path);

    // Eliminate trailing slashes
    if(_path[strlen(_path) - 1] == TRAILING_SLASH) {
        _path[strlen(_path) - 1] = END_OF_STRING;
    }

    char *leaf = strrchr(_path, TRAILING_SLASH);
    if(leaf == NULL) {
        return NULL;
    }
    // Ignore the first character, which will be the matched '/'
    leaf++;
    return strdup(leaf);
}

/**
 * Translates a path into the inode number of the item just before
 * the leaf node.
 *
 * E.g. translate('a/b/c/d') will return the inode for 'c'
 *
 * Inputs:
 * - path, the path as a const string
 *
 * Returns:
 * -ENOENT if the path does not exist
 * -ENOTDIR if a middle component of the path is not a directory
 * Else the inode number for the second-to-last component of the path
 */
int translate_parent(const char *path)
{
    char *_path = strdupa(path);
    char *leaf = NULL;

    // Eliminate trailing slashes
    if(_path[strlen(_path) - 1] == TRAILING_SLASH) {
        _path[strlen(_path) - 1] = END_OF_STRING;
    }

    // Chop off the leaf portion of the path
    leaf  = strrchr(_path, TRAILING_SLASH);
    *leaf = END_OF_STRING;

    // Translate the remainder
    return translate(_path);
}

/**
 * Saves the in-memory inode bitmap back to disk
 */
void write_inode_bmap_to_disk()
{
    disk->ops->write(disk, 1, inode_map_sz, inode_map);
}

/**
 * Saves the in-memory block bitmap back to disk
 */
void write_data_bmap_to_disk()
{
    disk->ops->write(disk, 1 + inode_map_sz, block_map_sz, block_map);
}

/**
 * Saves the in-memory inodes back to disk
 */
void write_inodes_to_disk()
{
    disk->ops->write(disk, 1 + inode_map_sz + block_map_sz, inode_region_sz, inode_region);
}

/**
 * Writes a block on disk with all 0s.
 *
 * Inputs:
 * - block_num, the index of the block to clear
 * Effects:
 * Writes the indicated block with 0s.
 */
void clear_data_block(int block_num)
{
    char *empty = malloc(FS_BLOCK_SIZE);
    memset(empty, 0, FS_BLOCK_SIZE);
    disk->ops->write(disk, block_num, 1, empty);
    free(empty);
}

/**
 * Helper function for finding an allocating an index
 * in a bitmap.
 *
 * Inputs:
 * - int limit, the total number of items
 * - fd_set *map, the pointer to the bitmap
 * Returns:
 * The allocated index, or 0 if there are no free items
 */
int allocate_helper(int limit, fd_set *map)
{
    int i;
    for(i = 0; i < limit; i++) {
        if(!FD_ISSET(i, map)) {
            FD_SET(i, map);
            return i;
        }
    }
    return 0;
}

/**
 * Finds a free inode in the inode bitmap and claims it.
 *
 * Note that this does NOT update the inode bitmap on disk.
 *
 * Returns: The index of the allocated inode, or 0 if no inodes
 * are free.
 */
int allocate_inode()
{
    return allocate_helper(inode_region_sz * INODES_PER_BLK, inode_map);
}

/**
 * Finds a free data block in the data bitmap and claims it.
 *
 * Note that this does NOT update the data bitmap on disk.
 *
 * Returns: The index of the allocated block, or 0 if no blocks
 * are free.
 */
int allocate_block()
{
    return allocate_helper(disk_total_blocks, block_map);
}

/**
 * Given an inode number and a stat buffer, reads the attributes
 * of the indicated inode into the stat struct
 *
 * Inputs:
 * - inode_num, the index of the inode
 * - sb, a pointer to a stat buffer
 * Effects:
 * The attributes of the inode are read into the stat struct pointed
 * to by sb.
 */
void read_attrs(int inode_num, struct stat *sb)
{
    struct fs_inode inode = inode_region[inode_num];

    memset(sb, 0, sizeof(*sb));
    (*sb).st_uid     = inode.uid;
    (*sb).st_gid     = inode.gid;
    (*sb).st_mode    = inode.mode;
    (*sb).st_mtime   = inode.mtime;
    (*sb).st_ctime   = inode.ctime;
    (*sb).st_atime   = inode.mtime;
    (*sb).st_size    = inode.size;
    (*sb).st_nlink   = 1;
    (*sb).st_blksize = FS_BLOCK_SIZE;
    (*sb).st_blocks  = inode.size / FS_BLOCK_SIZE + (inode.size % FS_BLOCK_SIZE == 0 ? 0 : 1);
}

/* getattr - get file or directory attributes. For a description of
 *  the fields in 'struct stat', see 'man lstat'.
 *
 * Note - fields not provided in fsx600 are:
 *    st_nlink - always set to 1
 *    st_atime, st_ctime - set to same value as st_mtime
 *
 * errors - path translation, ENOENT
 */
static int fs_getattr(const char *path, struct stat *sb)
{
    int check_path = translate(path);

    // A negative result from translate indicates an error
    if(check_path < 0) {
        return check_path;
    }

    read_attrs(check_path, sb);

    return 0;
}

/* readdir - get directory contents.
 *
 * for each entry in the directory, invoke the 'filler' function,
 * which is passed as a function pointer, as follows:
 *     filler(buf, <name>, <statbuf>, 0)
 * where <statbuf> is a struct stat, just like in getattr.
 *
 * Errors - path resolution, ENOTDIR, ENOENT
 */
static int fs_readdir(const char *path, void *ptr, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi)
{
    int translate_result = translate(path);
    if(translate_result < 0) {
        return translate_result;
    }

    struct fs_inode inode = inode_region[translate_result];
    if(!S_ISDIR(inode.mode)) {
        return -ENOTDIR;
    }

    // Read the directory entry
    struct fs_dirent *dir = malloc(FS_BLOCK_SIZE);
    disk->ops->read(disk, inode.direct[0], 1, dir);

    // Iterate over the directory, invoking the callback function on
    // each valid entry
    int i;
    for (i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
        if(dir[i].valid == 1) {
            struct stat *attr = malloc(sizeof(*attr));
            read_attrs(dir[i].inode, attr);
            filler(ptr, dir[i].name, attr, 0);
            free(attr);
        }
    }

    free(dir);

    return 0;
}

/* see description of Part 2. In particular, you can save information
 * in fi->fh. If you allocate memory, free it in fs_releasedir.
 */
static int fs_opendir(const char *path, struct fuse_file_info *fi)
{
    return 0;
}

static int fs_releasedir(const char *path, struct fuse_file_info *fi)
{
    return 0;
}

/* mknod - create a new file with permissions (mode & 01777)
 *
 * Errors - path resolution, EEXIST
 *          in particular, for mknod("/a/b/c") to succeed,
 *          "/a/b" must exist, and "/a/b/c" must not.
 *
 * If a file or directory of this name already exists, return -EEXIST.
 * If this would result in >32 entries in a directory, return -ENOSPC
 * if !S_ISREG(mode) return -EINVAL [i.e. 'mode' specifies a device special
 * file or other non-file object]
 */
static int fs_mknod(const char *path, mode_t mode, dev_t dev)
{
    int node_status = translate(path);
    int new_inode, new_block;

    // A negative result from translate indicates an error
    if(node_status > 0) {
        return -EEXIST;
    }
    if(node_status != -ENOENT) {
        return node_status;
    }
    if(!S_ISREG(mode)) {
        return -EINVAL;
    }

    // Get Parent inode number and read parent dir from dir into buffer
    int pnod_inode = translate_parent(path);
    if(pnod_inode < 0) {
        return pnod_inode;
    }
    int pnod_parent_inode  = inode_region[pnod_inode].direct[0];
    struct fs_dirent *pdir = malloc(FS_BLOCK_SIZE);
    disk->ops->read(disk, pnod_parent_inode, 1, pdir);

    int i;
    for (i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
        if(pdir[i].valid == 0) {
            new_inode = allocate_inode();

            if(!new_inode) {
                // Failed to allocate a new inode
                return -ENOSPC;
            }

            struct fs_inode nod            = inode_region[new_inode];
            memset(&nod, 0, sizeof(nod));
            nod.uid                        = getuid();
            nod.gid                        = getgid();
            nod.mode                       = mode | S_IFREG;
            nod.ctime                      = time(NULL);
            nod.mtime                      = nod.ctime;
            inode_region[pnod_inode].mtime = nod.ctime;
            nod.size                       = 0;
            inode_region[new_inode]        = nod;

            pdir[i].valid = 1;
            pdir[i].isDir = 0;
            strcpy(pdir[i].name, leaf_name_from_path(path));
            pdir[i].inode = new_inode;
            disk->ops->write(disk, pnod_parent_inode, 1, pdir);

            write_inode_bmap_to_disk();
            write_inodes_to_disk();

            free(pdir);
            return 0;
        }
    }

    free(pdir);
    return -ENOSPC;
}

/* mkdir - create a directory with the given mode.
 * Errors - path resolution, EEXIST
 * Conditions for EEXIST are the same as for create.
 * If this would result in >32 entries in a directory, return -ENOSPC
 *
 * Note that you may want to combine the logic of fs_mknod and
 * fs_mkdir.
 */
static int fs_mkdir(const char *path, mode_t mode)
{
    // Check if the location already exists
    int check_path = translate(path);
    if(check_path > 0) {
        return -EEXIST;
    }
    if(check_path != -ENOENT) {
        return check_path;
    }

    // Get the inode of the parent directory and the leaf name
    int parent_dir_inode = translate_parent(path);
    if(parent_dir_inode < 0) {
        return parent_dir_inode;
    }

    // Read the directory entry
    struct fs_dirent *dir = malloc(FS_BLOCK_SIZE);
    disk->ops->read(disk, inode_region[parent_dir_inode].direct[0], 1, dir);

    // Iterate over the directory looking for an open spot
    int i;
    for (i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
        if(dir[i].valid == 0) {
            int new_dir_inode  = allocate_inode();
            int dir_data_block = allocate_block();

            if(!new_dir_inode || !dir_data_block) {
                // Return -ENOSPC if we failed to allocate an inode or block
                return -ENOSPC;
            }

            // Set up the dirent for the new directory
            dir[i].valid = 1;
            dir[i].isDir = 1;
            dir[i].inode = new_dir_inode;
            strcpy(dir[i].name, leaf_name_from_path(path));
            inode_region[parent_dir_inode].mtime = time(NULL);
            disk->ops->write(disk, inode_region[parent_dir_inode].direct[0], 1, dir);

            // Set up the inode for the new directory
            struct fs_inode dir_inode   = inode_region[new_dir_inode];
            memset(&dir_inode, 0, sizeof(dir_inode));
            dir_inode.uid               = getuid();
            dir_inode.gid               = getgid();
            dir_inode.mode              = mode | S_IFDIR;
            dir_inode.ctime             = time(NULL);
            dir_inode.mtime             = dir_inode.ctime;
            dir_inode.direct[0]         = dir_data_block;
            inode_region[new_dir_inode] = dir_inode;

            // Save the inode bitmap and inode region
            write_inode_bmap_to_disk();
            write_inodes_to_disk();

            // Save the block bitmap and clear data for the new directory
            write_data_bmap_to_disk();
            clear_data_block(dir_data_block);

            free(dir);

            return 0;
        }
    }
    free(dir);

    return -ENOSPC;
}

/**
 * Frees all the data associated with an inode.
 *
 * Notes that this does NOT write anything back to disk.
 * inodes and the block bitmap should be written after
 * using this function.
 *
 * Returns -EISDIR if the inode doesn't correspond
 * to a file, else 0
 */
int free_file_blocks(int inode_num)
{
    struct fs_inode in = inode_region[inode_num];
    if(S_ISDIR(in.mode)) {
        // Only files can be truncated
        return -EISDIR;
    }

    // Free direct data blocks
    int i, j;
    for(i = 0; i < N_DIRECT; i++) {
        if(in.direct[i] != 0) {
            FD_CLR(in.direct[i], block_map);
            in.direct[i] = 0;
        }
    }

    // Free indirect data blocks
    if(in.indir_1 != 0) {
        uint32_t ptrs[PTRS_PER_INDIRECT_BLOCK];
        disk->ops->read(disk, in.indir_1, 1, ptrs);
        for(i = 0; i < PTRS_PER_INDIRECT_BLOCK; i++) {
            if(ptrs[i] != 0) {
                FD_CLR(ptrs[i], block_map);
            }
        }
        FD_CLR(in.indir_1, block_map);
        in.indir_1 = 0;
    }

    // Free doubly-indirect data blocks
    if(in.indir_2 != 0) {
        uint32_t layer1_ptrs[PTRS_PER_INDIRECT_BLOCK];
        disk->ops->read(disk, in.indir_2, 1, layer1_ptrs);
        for(i = 0; i < PTRS_PER_INDIRECT_BLOCK; i++) {
            if(layer1_ptrs[i]) {
                uint32_t layer2_ptrs[PTRS_PER_INDIRECT_BLOCK];
                disk->ops->read(disk, layer1_ptrs[i], 1, layer2_ptrs);

                for(j = 0; j< PTRS_PER_INDIRECT_BLOCK; j++) {
                    if(layer2_ptrs[j]) {
                        FD_CLR(layer2_ptrs[j], block_map);
                    }
                }
                FD_CLR(layer1_ptrs[i], block_map);
            }
        }
        FD_CLR(in.indir_2, block_map);
        in.indir_2 = 0;
    }

    inode_region[inode_num] = in;

    return 0;
}

/* truncate - truncate file to exactly 'len' bytes
 * Errors - path resolution, ENOENT, EISDIR, EINVAL
 *    return EINVAL if len > 0.
 */
static int fs_truncate(const char *path, off_t len)
{
    // This implementation only supports truncating the entire file
    if(len != 0) {
        return -EINVAL;
    }

    // Error Handling
    int inode_num = translate(path);
    if(inode_num < 0) {
        return inode_num;
    }

    // Free all allocated blocks
    int free_blocks_result = free_file_blocks(inode_num);
    if(free_blocks_result < 0) {
        return free_blocks_result;
    }

    // Set file size to 0 and update timestamp
    inode_region[inode_num].size = 0;
    inode_region[inode_num].mtime = time(NULL);

    // Save block bitmap and inode to disk
    write_data_bmap_to_disk();
    write_inodes_to_disk();

    return 0;
}

/**
 * Traverses the parent directory of the given item and removes
 * the entry with the given inode.
 *
 * Note that the inode for the parent directory should be written
 * after invoking this.
 *
 * Inputs:
 * - char *path, the path to the file or directory to be deleted
 * - int rm_node, the inode number of the directory to be deleted
 */
void remove_entity_from_parent_directory(const char *path, int rm_inode)
{
    // Read and update the parent directory to remove the entry
    int parent_dir_inode = translate_parent(path);
    struct fs_dirent *parent_dir = malloc(FS_BLOCK_SIZE);
    disk->ops->read(disk, inode_region[parent_dir_inode].direct[0], 1, parent_dir);
    int i;
    for(i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
        if(parent_dir[i].valid == 1 && parent_dir[i].inode == rm_inode) {
            parent_dir[i].valid = 0;
            disk->ops->write(disk, inode_region[parent_dir_inode].direct[0], 1, parent_dir);
            break;
        }
    }
    free(parent_dir);

    // Update parent dir mod time
    inode_region[parent_dir_inode].mtime = time(NULL);
}

/* unlink - delete a file
 *  Errors - path resolution, ENOENT, EISDIR
 * Note that you have to delete (i.e. truncate) all the data.
 */
static int fs_unlink(const char *path)
{
    // A negative result from translate indicates a path resolution error
    int check_path = translate(path);
    if(check_path < 0) {
        return check_path;
    }

    // Free all allocated blocks (this may return -EISDIR)
    int free_blocks_result = free_file_blocks(check_path);
    if(free_blocks_result < 0) {
        return free_blocks_result;
    }

    // Read and update the parent directory to remove the entry
    remove_entity_from_parent_directory(path, check_path);

    // Free the inode and all of the files data blocks
    FD_CLR(check_path, inode_map);

    write_inode_bmap_to_disk();
    write_data_bmap_to_disk();
    write_inodes_to_disk();

    return 0;
}

/* rmdir - remove a directory
 *  Errors - path resolution, ENOENT, ENOTDIR, ENOTEMPTY
 */
static int fs_rmdir(const char *path)
{
    // A negative result from translate indicates a path resolution error
    int inode_num = translate(path);
    if(inode_num < 0) {
        return inode_num;
    }

    // Check that this path is a directory
    if(!S_ISDIR(inode_region[inode_num].mode)) {
        return -ENOTDIR;
    }

    // Read the directory entry
    struct fs_dirent *dir = malloc(FS_BLOCK_SIZE);
    disk->ops->read(disk, inode_region[inode_num].direct[0], 1, dir);

    // Make sure that the directory is empty
    int i;
    for (i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
        if(dir[i].valid) {
            return -ENOTEMPTY;
        }
    }
    free(dir);

    // Free the data block and inode for the directory
    FD_CLR(inode_num, inode_map);
    FD_CLR(inode_region[inode_num].direct[0], block_map);

    // Read and update the parent directory to remove the entry
    remove_entity_from_parent_directory(path, inode_num);

    write_inodes_to_disk();
    write_data_bmap_to_disk();
    write_inode_bmap_to_disk();

    return 0;
}

/* rename - rename a file or directory
 * Errors - path resolution, ENOENT, EINVAL, EEXIST
 *
 * ENOENT - source does not exist
 * EEXIST - destination already exists
 * EINVAL - source and destination are not in the same directory
 *
 * Note that this is a simplified version of the UNIX rename
 * functionality - see 'man 2 rename' for full semantics. In
 * particular, the full version can move across directories, replace a
 * destination file, and replace an empty directory with a full one.
 */
static int fs_rename(const char *src_path, const char *dst_path)
{
    int src_status = translate(src_path);
    int dst_status = translate(dst_path);

    // EEXIST - destination already exists
    if(dst_status > 0) {
        return -EEXIST;
    }
    if (dst_status != -ENOENT) {
        return dst_status;
    }

    // ENOENT - source does not exist
    if (src_status < 0) {
        return src_status;
    }

    // EINVAL - source and destination are not in the same directory
    if(translate_parent(src_path) != translate_parent(dst_path)) {
        return -EINVAL;
    }

    // Rename
    int pnod_inode        = translate_parent(src_path);
    int pnod_parent_inode = inode_region[pnod_inode].direct[0];
    struct fs_dirent *src_parent_dir = malloc(FS_BLOCK_SIZE);
    disk->ops->read(disk, pnod_parent_inode, 1, src_parent_dir);

    int i;
    for (i = 0; i < TOTAL_DIR_ENTRIES; ++i) {
        if(src_parent_dir[i].valid == 1 && strcmp(src_parent_dir[i].name, leaf_name_from_path(src_path)) == 0) {

            int timestamp = time(NULL);
            inode_region[src_parent_dir[i].inode].mtime = timestamp;
            inode_region[pnod_inode].mtime              = timestamp;

            strcpy(src_parent_dir[i].name, leaf_name_from_path(dst_path));
            disk->ops->write(disk, pnod_parent_inode, 1, src_parent_dir);

            write_inodes_to_disk();

            free(src_parent_dir);
            return 0;
        }
    }
    return 0;
}

/* chmod - change file permissions
 * utime - change access and modification times
 *         (for definition of 'struct utimebuf', see 'man utime')
 *
 * Errors - path resolution, ENOENT.
 */
static int fs_chmod(const char *path, mode_t mode)
{
    int node_inode = translate(path);
    if (node_inode < 0) {
        return node_inode;
    }

    inode_region[node_inode].mode = mode;

    write_inodes_to_disk();

    return 0;
}

int fs_utime(const char *path, struct utimbuf *ut)
{
    int node_inode = translate(path);
    if (node_inode < 0) {
         return node_inode;
     }

     inode_region[node_inode].mtime = ut->modtime;

     write_inodes_to_disk();

     return 0;
}

/* read - read data from an open file.
 * should return exactly the number of bytes requested, except:
 *   - if offset >= file len, return 0
 *   - if offset+len > file len, return bytes from offset to EOF
 *   - on error, return <0
 * Errors - path resolution, ENOENT, EISDIR
 */
static int fs_read(const char *path, char *buf, size_t len, off_t offset,
                    struct fuse_file_info *fi)
{
    int check_path = translate(path);

    // A negative result from translate indicates an error
    if(check_path < 0) {
        return check_path;
    }

    struct fs_inode inode = inode_region[check_path];

    // Return an error if the path points to a directory
    if(S_ISDIR(inode.mode)) {
        return -EISDIR;
    }

    // Offset past file length: EOF
    if(offset > inode.size) {
        return 0;
    }

    // Offset in valid range, but len goes beyond EOF
    if(offset + len > inode.size) {
        len = inode.size - offset;
    }

    int blk_offset            = offset / FS_BLOCK_SIZE;
    int offset_in_first_block = offset % FS_BLOCK_SIZE;
    int len_remaining         = len;
    int bytes_read            = 0;

    if(offset_in_first_block != 0) {
        // First block will be partial
        char beginning[FS_BLOCK_SIZE];
        disk->ops->read(disk, offset_to_block(&inode, blk_offset, 0), 1, beginning);

        // Read from offset to end of block if that size is less than length requested
        int len_to_read = len < FS_BLOCK_SIZE - offset_in_first_block ? len : FS_BLOCK_SIZE - offset_in_first_block;
        memcpy(buf, &beginning[offset_in_first_block], len_to_read);
        len_remaining -= len_to_read;
        bytes_read += len_to_read;
        blk_offset++;
    }

    // Middle blocks - entire blocks may be read
    while(len_remaining > FS_BLOCK_SIZE) {
        disk->ops->read(disk, offset_to_block(&inode, blk_offset, 0), 1, buf + bytes_read);
        len_remaining -= FS_BLOCK_SIZE;
        bytes_read    += FS_BLOCK_SIZE;
        blk_offset++;
    }

    // Ending block - a partial block remains
    if(len_remaining > 0) {
        char end[FS_BLOCK_SIZE];
        disk->ops->read(disk, offset_to_block(&inode, blk_offset, 0), 1, end);
        memcpy(buf + bytes_read, end, len_remaining);
    }

    return len;
}

/**
 * Translates a block number of the given file inode into a block
 * number on the disk.
 *
 * For write functionality, this function also supports allocating
 * blocks as needed.
 *
 * Inputs:
 * - *inode, a pointer to the file inode
 * - blk_offset, the offset into the file (in 1024-byte blocks)
 * - allocate, 1 if a non-existent block should be allocated, else 0
 *
 * Returns:
 * 0 if no such block exists, else the block number
 */
int offset_to_block(struct fs_inode *inode, int blk_offset, int allocate)
{
    if(blk_offset < N_DIRECT) {
        // Direct
        if(allocate && inode->direct[blk_offset] == 0) {
            inode->direct[blk_offset] = allocate_block();
        }
        return inode->direct[blk_offset];
    } else {
        blk_offset -= N_DIRECT;
        if(blk_offset < PTRS_PER_INDIRECT_BLOCK) {
            // Single indirect
            if(inode->indir_1 == 0) {
                if(!allocate) {
                    return 0;
                }
                // Allocate an indirect block and clear it
                inode->indir_1 = allocate_block();
                if(!inode->indir_1) {
                    return 0;
                }
                clear_data_block(inode->indir_1);
            }
            uint32_t ptrs[PTRS_PER_INDIRECT_BLOCK];
            disk->ops->read(disk, inode->indir_1, 1, ptrs);
            if(allocate && ptrs[blk_offset] == 0) {
                ptrs[blk_offset] = allocate_block();
                disk->ops->write(disk, inode->indir_1, 1, ptrs);
            }
            return ptrs[blk_offset];
        } else {
            // Double indirect
            if(inode->indir_2 == 0) {
                if(!allocate) {
                    return 0;
                }
                // Allocate an indirect block and clear it
                inode->indir_2 = allocate_block();
                if(!inode->indir_2) {
                    return 0;
                }
                clear_data_block(inode->indir_2);
            }
            blk_offset -= PTRS_PER_INDIRECT_BLOCK;

            // Read first level of tree
            uint32_t layer1_ptrs[PTRS_PER_INDIRECT_BLOCK];
            disk->ops->read(disk, inode->indir_2, 1, layer1_ptrs);

            // Find which second level indirect block to use
            int layer1_offset = 0;
            while(blk_offset >= PTRS_PER_INDIRECT_BLOCK) {
                blk_offset    -= PTRS_PER_INDIRECT_BLOCK;
                layer1_offset += 1;
            }

            if(layer1_ptrs[layer1_offset] == 0) {
                if(!allocate) {
                    return 0;
                }
                layer1_ptrs[layer1_offset] = allocate_block();
                if(!layer1_ptrs[layer1_offset]) {
                    return 0;
                }
                clear_data_block(layer1_ptrs[layer1_offset]);
                disk->ops->write(disk, inode->indir_2, 1, layer1_ptrs);
            }

            // Read the second-level indirect block
            uint32_t layer2_ptrs[PTRS_PER_INDIRECT_BLOCK];
            disk->ops->read(disk, layer1_ptrs[layer1_offset], 1, layer2_ptrs);

            if(allocate && layer2_ptrs[blk_offset] == 0) {
                layer2_ptrs[blk_offset] = allocate_block();
                disk->ops->write(disk, layer1_ptrs[layer1_offset], 1, layer2_ptrs);
            }

            return layer2_ptrs[blk_offset];
        }
    }
}

/* write - write data to a file
 * It should return exactly the number of bytes requested, except on
 * error.
 * Errors - path resolution, ENOENT, EISDIR
 *  return EINVAL if 'offset' is greater than current file length.
 *  (POSIX semantics support the creation of files with "holes" in them,
 *   but we don't)
 */
static int fs_write(const char *path, const char *buf, size_t len,
             off_t offset, struct fuse_file_info *fi)
{
    int i = translate(path);
    if(i < 0) {
        return i;
    }

    struct fs_inode inode = inode_region[i];

    // Return an error if the path points to a directory
    if(S_ISDIR(inode.mode)) {
        return -EISDIR;
    }

    // Don't allow creating files with "holes"
    if(offset > inode.size) {
        return -EINVAL;
    }

    int blk_offset            = offset / FS_BLOCK_SIZE;
    int offset_in_first_block = offset % FS_BLOCK_SIZE;
    int len_remaining         = len;
    int bytes_written         = 0;
    int block;
    int disk_full             = 0;

    // First block will be partial
    if(offset_in_first_block != 0) {
        block = offset_to_block(&inode, blk_offset, 1);
        if(!block) {
            disk_full = 1;
        } else {
            char beginning[FS_BLOCK_SIZE];
            disk->ops->read(disk, block, 1, beginning);

            // Write from offset to end of block if that size is less than length requested
            int len_to_write = len < FS_BLOCK_SIZE - offset_in_first_block ? len : FS_BLOCK_SIZE - offset_in_first_block;

            memcpy(beginning + offset_in_first_block, buf, len_to_write);
            disk->ops->write(disk, block, 1, beginning);
            len_remaining -= len_to_write;
            bytes_written += len_to_write;
            blk_offset++;
        }
    }

    // Middle blocks - entire blocks may be written
    while(len_remaining > FS_BLOCK_SIZE && !disk_full) {
        block = offset_to_block(&inode, blk_offset, 1);
        if(!block) {
            disk_full = 1;
            break;
        }
        char middle[FS_BLOCK_SIZE];
        memcpy(middle, buf+ bytes_written, FS_BLOCK_SIZE);
        disk->ops->write(disk, offset_to_block(&inode, blk_offset, 1), 1, middle);
        len_remaining -= FS_BLOCK_SIZE;
        bytes_written += FS_BLOCK_SIZE;
        blk_offset++;
    }

    // Ending block - a partial block remains
    if(len_remaining > 0 && !disk_full) {
        block = offset_to_block(&inode, blk_offset, 1);
        if(!block) {
            disk_full = 1;
        } else {
            char end[FS_BLOCK_SIZE];
            disk->ops->read(disk, block, 1, end);
            memcpy(end, buf + bytes_written, len_remaining);
            bytes_written += len_remaining;
            disk->ops->write(disk, offset_to_block(&inode, blk_offset, 1), 1, end);
        }
    }

    // Adjust the size and timestamp of the inode
    inode.mtime = time(NULL);
    if(offset + bytes_written > inode.size) {
        inode.size = offset + bytes_written;
    }
    inode_region[i] = inode;

    // Save inodes and block bitmap
    write_data_bmap_to_disk();
    write_inodes_to_disk();

    if(!disk_full) {
        return bytes_written;
    } else {
        return -ENOSPC;
    }

}

static int fs_open(const char *path, struct fuse_file_info *fi)
{
    return 0;
}

static int fs_release(const char *path, struct fuse_file_info *fi)
{
    return 0;
}

/**
 * Gets the number of free data blocks in the file system
 *
 * Inputs: none
 * Returns: an int representing the number of free blocks
 */
int count_free_blocks()
{
    int count = 0;
    int i;
    for(i = 0; i < disk_total_blocks; ++i) {
        if(!FD_ISSET(i, block_map)) {
            count++;
        }
    }
    return count;
}

/* statfs - get file system statistics
 * see 'man 2 statfs' for description of 'struct statvfs'.
 * Errors - none.
 */
static int fs_statfs(const char *path, struct statvfs *st)
{
    /* needs to return the following fields (set others to zero):
     *   f_bsize = BLOCK_SIZE
     *   f_blocks = total image - metadata
     *   f_bfree = f_blocks - blocks used
     *   f_bavail = f_bfree
     *   f_namelen = <whatever your max namelength is>
     */
    memset(st, 0, sizeof(*st));
    st->f_bsize   = FS_BLOCK_SIZE;
    st->f_blocks  = disk_total_blocks;
    st->f_bfree   = count_free_blocks();
    st->f_bavail  = st->f_bfree;
    st->f_namemax = 27;

    return 0;
}

/* operations vector. Please don't rename it, as the skeleton code in
 * misc.c assumes it is named 'fs_ops'.
 */
struct fuse_operations fs_ops = {
    .init       = fs_init,
    .getattr    = fs_getattr,
    .opendir    = fs_opendir,
    .readdir    = fs_readdir,
    .releasedir = fs_releasedir,
    .mknod      = fs_mknod,
    .mkdir      = fs_mkdir,
    .unlink     = fs_unlink,
    .rmdir      = fs_rmdir,
    .rename     = fs_rename,
    .chmod      = fs_chmod,
    .utime      = fs_utime,
    .truncate   = fs_truncate,
    .open       = fs_open,
    .read       = fs_read,
    .write      = fs_write,
    .release    = fs_release,
    .statfs     = fs_statfs,
};

