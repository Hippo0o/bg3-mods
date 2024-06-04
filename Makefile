.PHONY: clrf-to-lf lf-to-clrf fix-permissions sync-files copy

UID=1000
# CUR_MOD=CombatMod
CUR_MOD=DOLL
MOD_SUBDIR=$(MOD_DIR)/$(CUR_MOD)/Mods/$(CUR_MOD)

clrf-to-lf:
	fd -t file . $(MOD_SUBDIR) -x sed -i 's/\r$$//'

lf-to-clrf:
	fd -t file . $(MOD_SUBDIR) -x sed -i 's/$$/\r/'

fix-permissions:
	fd -t file . $(MOD_SUBDIR) -x chmod 644
	fd -t directory . $(MOD_SUBDIR) -x chmod 755
	chown -R $(UID) $(MOD_SUBDIR)

sync-files:
	@inotifywait -m -r -e modify,create,delete $(MOD_SUBDIR) | \
	while read path action file; do \
		rsync --verbose -avc --copy-links --delete "$(MOD_SUBDIR)/." "$(DEST_DIR)/$(CUR_MOD)/."; \
	done

copy:
	rsync --verbose -avc --copy-links --delete "$(MOD_DIR)/." "$(MOUNT_DIR)/Temp/$(CUR_MOD)/."

copy-back:
	cp $(MOUNT_DIR)/Temp/$(CUR_MOD).zip .
	unzip $(CUR_MOD).zip $(CUR_MOD).pak
	mv $(CUR_MOD).pak Releases/$(CUR_MOD).pak

mounts: # dont forgor to pacman -S cifs-utils
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Temp" $(MOUNT_DIR)/Temp
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Mods" $(MOUNT_DIR)/Mods
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/SE" $(MOUNT_DIR)/SE
