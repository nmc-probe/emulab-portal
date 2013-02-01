#! /usr/local/bin/bash

set -u -e
# note: naming change needed "machine" -> "node"

#destination paths
mfs_flavor="admin_nodetest_linux32"
tftpboot_dir="/tftpboot/${mfs_flavor}"
mfs_etc_testbed="${tftpboot_dir}/extracted_initramfs/etc/testbed"
mfs_usr_bin="${tftpboot_dir}/extracted_initramfs/usr/bin"

#source paths on boss
source_dir="/home/dreading/emulab-devel/clientside/tmcc/common/nodetest"
source_nodetest=${source_dir}
source_initramfs="tftpboot/nodetest_linux/extracted_initramfs"
source_etc_testbed="${source_dir}/${source_initramfs}/etc/testbed"

#source files
files_rc="rc.mfs"
files_etc="disktest disktest.pl"
files_usr_bin="smartctl"
file_grub=${source_dir}/tftpboot/grub.cfg

echo "update grub.cfg file"
(cd ${source_nodetest} ; sudo rsync -a $file_grub ${tftpboot_dir})
echo "update testbed/etc files"
(cd ${source_nodetest} ; sudo rsync -a $files_etc ${mfs_etc_testbed})
echo "update testbed/etc/rc files"
(cd ${source_etc_testbed}/rc ; sudo rsync -a $files_rc ${mfs_etc_testbed}/rc)
echo "update usr/bin files"
(cd ${source_nodetest}; sudo rsync -a $files_usr_bin ${mfs_usr_bin})

echo "compress new initramfs"
cd ${tftpboot_dir}
sudo ./compress_initramfs

echo "update subboss for pc3000s"
sudo rsync -a --partial --progress ${tftpboot_dir} subboss2:/tftpboot


exit 0
