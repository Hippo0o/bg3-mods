.PHONY: clrf-to-lf lf-to-clrf fix-permissions sync-files copy

UID=1000
MOD?=CombatMod
# MOD=DOLL
MOD_SUBDIR=$(MOD_DIR)/$(MOD)/Mods/$(MOD)

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
		rsync --verbose -avc --copy-links --delete "$(MOD_SUBDIR)/." "$(DEST_DIR)/$(MOD)/."; \
	done

copy:
	rsync --verbose --exclude=Mods/CombatMod/ScriptExtender/Lua/Exclude -avc --copy-links --delete "$(MOD_DIR)/$(MOD)/." "$(MOUNT_DIR)/Temp/$(MOD)/."

copy-back:
	cp $(MOUNT_DIR)/Temp/$(MOD).zip .
	cp $(MOUNT_DIR)/Temp/$(MOD)/Mods/$(MOD)/meta.lsx $(MOD_DIR)/$(MOD)/Mods/$(MOD)/meta.lsx
	sed -i 's/\r$$//' $(MOD_DIR)/$(MOD)/Mods/$(MOD)/meta.lsx
	unzip $(MOD).zip $(MOD).pak
	mv $(MOD).pak Releases/$(MOD).pak

mounts: # dont forgor to pacman -S cifs-utils
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Temp" $(MOUNT_DIR)/Temp
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/Mods" $(MOUNT_DIR)/Mods
	mount -t cifs -o rw,username=user,uid=$(UID),file_mode=0777,dir_mode=0777 "//$(WIN_IP)/SE" $(MOUNT_DIR)/SE
