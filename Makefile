.PHONY: clrf-to-lf lf-to-clrf fix-permissions sync-files

UID=1000

clrf-to-lf:
	fd -t file . $(MOD_DIR) -x sed -i 's/\r$$//'

lf-to-clrf:
	fd -t file . $(MOD_DIR) -x sed -i 's/$$/\r/'

fix-permissions:
	fd -t file . $(MOD_DIR) -x chmod 644
	fd -t directory . $(MOD_DIR) -x chmod 755
	chown -R $(UID) $(MOD_DIR)

sync-files:
	while sleep 0.1; do fd . $(MOD_DIR) | entr -d rsync --verbose -avc --delete "$(MOD_DIR)/." "$(DEST_DIR)/." ; done

mounts: # dont forgor to pacman -S cifs-utils
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/SE" $(MOUNT_DIR)/SE
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Mods" $(MOUNT_DIR)/Mods
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Temp" $(MOUNT_DIR)/Temp
