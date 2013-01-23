#! /usr/local/bin/bash

set -u -e
# note: naming change needed "machine" -> "node"

#destination paths
mfs_flavor="mcheck_linux"
tftpboot_dir="/tftpboot/${mfs_flavor}"
mfs_etc_testbed="${tftpboot_dir}/extracted_initramfs/etc/testbed"
mfs_usr_bin="${tftpboot_dir}/extracted_initramfs/usr/bin"

#source paths on boss
source_dir="/home/dreading/emulab-devel/clientside/tmcc/common/nodetest"
source_nodetest=${source_dir}
source_initramfs="tftpboot/mcheck_linux/extracted_initramfs"
source_etc_testbed="${source_dir}/${source_initramfs}/etc/testbed"

#source files
files_rc="rc.startcmd rc.mfs"
files_etc="disktest disktest.pl"
files_usr_bin="smartctl"

echo "update testbed/etc files"
(cd ${source_nodetest} ; rsync -a $files_etc ${mfs_etc_testbed})
echo "update testbed/etc/rc files"
(cd ${source_etc_testbed}/rc ; rsync -a $files_rc ${mfs_etc_testbed}/rc)
echo "update usr/bin files"
(cd ${source_nodetest}; rsync -a $files_usr_bin ${mfs_usr_bin})

echo "compress new initramfs"
cd ${tftpboot_dir}
./compress_initramfs

echo "update subboss for pc3000s"
sudo rsync -a --partial --progress ${tftpboot_dir} subboss2:/tftpboot


exit 0
