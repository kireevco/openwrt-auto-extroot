rootUUID=05d615b3-bef8-460c-9a23-52db8d09e000
dataUUID=05d615b3-bef8-460c-9a23-52db8d09e001
swapUUID=05d615b3-bef8-460c-9a23-52db8d09e002

dd if=/dev/zero of=/dev/sda bs=1M count=1

fdisk /dev/sda <<EOF
o
n
p
1

+128M
n
p
2

+1024M
n
p
3


t
1
82
w
q
EOF


log "Finished partitioning /dev/sda using fdisk"

sleep 2

until [ -e /dev/sda1 ]
do
    echo "Waiting for partitions to show up in /dev"
    sleep 1
done

# sda1 is 'swap'
# sda2 is 'root'
# sda3 is 'data'

mkswap -L swap -U $swapUUID /dev/sda1
mkfs.ext4 -L root -U $rootUUID /dev/sda2
mkfs.ext4 -L data -U $dataUUID /dev/sda3

log "Finished setting up filesystems"


cat /etc/opkg.conf <<EOF
dest root /
dest ram /tmp
lists_dir ext /var/opkg-lists
option overlay_root /overlay
src/gz chaos_calmer_base http://52.26.42.126/malta/packages/base
src/gz chaos_calmer_luci http://52.26.42.126/malta/packages/luci
src/gz chaos_calmer_management http://52.26.42.126/malta/packages/management
src/gz chaos_calmer_packages http://52.26.42.126/malta/packages/packages
src/gz chaos_calmer_routing http://52.26.42.126/malta/packages/routing
src/gz chaos_calmer_telephony http://52.26.42.126/malta/packages/telephony
option check_signature 1
EOF


opkg update ; opkg install block-mount kmod-fs-ext4 kmod-usb-storage-extras

mkdir -p /mnt/sda2
mount /dev/sda2 /mnt/sda2 ; tar -C /overlay -cvf - . | tar -C /mnt/sda2 -xf - ; umount /mnt/sda2

echo > /etc/config/fstab ; block detect > /etc/config/fstab ; vi /etc/config/fstab





# config 'global'
#         option  anon_swap       '0'
#         option  anon_mount      '0'
#         option  auto_swap       '1'
#         option  auto_mount      '1'
#         option  delay_root      '5'
#         option  check_fs        '0'

# config 'swap'
#         option  uuid    '05d615b3-bef8-460c-9a23-52db8d09e002'
#         option  enabled '1'

# config 'mount'
#         option  target  '/overlay'
#         option  uuid    '05d615b3-bef8-460c-9a23-52db8d09e000'
#         option  enabled '1'

# config 'mount'
#         option  target  '/mnt/sda3'
#         option  uuid    '05d615b3-bef8-460c-9a23-52db8d09e001'
#         option  enabled '1'





