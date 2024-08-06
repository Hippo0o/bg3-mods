.PHONY: clrf-to-lf lf-to-clrf fix-permissions sync-files copy

UID=1000
MOD_SUBDIR=$(MOD_DIR)/Mods/JustCombat

clrf-to-lf:
	fd -t file . $(MOD_SUBDIR) -x sed -i 's/\r$$//'

lf-to-clrf:
	fd -t file . $(MOD_SUBDIR) -x sed -i 's/$$/\r/'

fix-permissions:
	fd -t file . $(MOD_SUBDIR) -x chmod 644
	fd -t directory . $(MOD_SUBDIR) -x chmod 755
	chown -R $(UID) $(MOD_SUBDIR)

sync-files:
	while sleep 0.1; do fd . $(MOD_SUBDIR) | entr -d rsync --verbose -avc --delete "$(MOD_SUBDIR)/." "$(DEST_DIR)/." ; done

copy:
	rsync --verbose -avc --delete "$(MOD_DIR)/." "$(MOUNT_DIR)/Temp/JustCombat/."

copy-back:
	cp $(MOUNT_DIR)/Temp/JustCombat.zip .
	unzip JustCombat.zip JustCombat.pak
	mv JustCombat.pak Releases/JustCombat.pak

mounts: # dont forgor to pacman -S cifs-utils
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/SE" $(MOUNT_DIR)/SE
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Mods" $(MOUNT_DIR)/Mods
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Temp" $(MOUNT_DIR)/Temp
