.PHONY: clrf-to-lf lf-to-clrf fix-permissions sync-files copy

UID=1000
MOD_SUBDIR=$(MOD_DIR)/Mods/CombatMod

clrf-to-lf:
	fd -t file . $(MOD_SUBDIR) -x sed -i 's/\r$$//'

lf-to-clrf:
	fd -t file . $(MOD_SUBDIR) -x sed -i 's/$$/\r/'

fix-permissions:
	fd -t file . $(MOD_SUBDIR) -x chmod 644
	fd -t directory . $(MOD_SUBDIR) -x chmod 755
	chown -R $(UID) $(MOD_SUBDIR)

sync-files:
	@inotifywait -m -r -e modify,create,delete . | \
	while read path action file; do \
		rsync --verbose -avc --copy-links --delete "$(MOD_SUBDIR)/." "$(DEST_DIR)/."; \
	done

copy:
	rsync --verbose -avc --copy-links --delete "$(MOD_DIR)/." "$(MOUNT_DIR)/Temp/CombatMod/."

copy-back:
	cp $(MOUNT_DIR)/Temp/CombatMod.zip .
	unzip CombatMod.zip CombatMod.pak
	mv CombatMod.pak Releases/CombatMod.pak

mounts: # dont forgor to pacman -S cifs-utils
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Temp" $(MOUNT_DIR)/Temp
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Mods" $(MOUNT_DIR)/Mods
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/SE" $(MOUNT_DIR)/SE
