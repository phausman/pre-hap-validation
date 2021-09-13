.PHONY: all
all: squashfs customize install-packages iso

ubuntu-desktop.iso:
	@printf "\nDownloading ISO...\n"
	wget -O ubuntu-desktop.iso https://releases.ubuntu.com/18.04/ubuntu-18.04.5-desktop-amd64.iso

squashfs: ubuntu-desktop.iso
	@printf "\nMounting ISO...\n"
	mkdir -p mnt
	if ! mountpoint --quiet mnt/ ; then \
		sudo mount -o loop,ro ubuntu-desktop.iso mnt; \
	fi

	@printf "\nExtracting squashfs...\n"
	mkdir -p extract-cd
	sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
	sudo rm -rf squashfs-root
	sudo unsquashfs -dest squashfs-root mnt/casper/filesystem.squashfs


# Copy Pre-HAP Validation script files to target directories in LiveCD filesystem
customize:
	@printf "\nCustomizing LiveCD...\n"
	sudo cp --recursive checks-available squashfs-root/opt
	sudo cp --recursive checks-enabled squashfs-root/opt
	sudo cp pre-hap-validation.py squashfs-root/opt
	sudo cp defaults.bashrc squashfs-root/opt
	sudo cp pre-hap-validation-launcher.desktop squashfs-root/etc/xdg/autostart/

# Install additional packages, e.g. freeipmi-tools and purge unnecessary packages
# to shrink down the resulting ISO
install-packages:
	cd squashfs-root && sudo mount -o bind /proc ./proc
	cd squashfs-root && sudo mount -o bind /dev ./dev
	cd squashfs-root && sudo mount -o bind /dev/pts ./dev/pts
	cd squashfs-root && sudo mount -o bind /run ./run
	cd squashfs-root && sudo mount -o bind /sys ./sys
	
	sudo chroot squashfs-root apt update
	sudo chroot squashfs-root apt install --yes freeipmi-tools
	sudo chroot squashfs-root apt purge --yes thunderbird libreoffice-common \
	    libreoffice-core fonts-noto-cjk tegaki-zinnia-japanese aisleriot brltty \
		duplicity example-content gnome-accessibility-themes gnome-mahjongg \
		gnome-mines gnome-sudoku gnome-video-effects landscape-common \
		libreoffice-avmedia-backend-gstreamer libreoffice-base-core libreoffice-calc \
		libreoffice-common libreoffice-core libreoffice-draw libreoffice-gnome \
		libreoffice-impress libreoffice-math libreoffice-ogltrans \
		libreoffice-pdfimport libreoffice-style-galaxy libreoffice-writer libsane1 \
		libsane-common python3-uno rhythmbox rhythmbox-plugins sane-utils shotwell \
		shotwell-common totem totem-common totem-plugins printer-driver-brlaser \
		printer-driver-foo2zjs printer-driver-foo2zjs-common printer-driver-m2300w \
		printer-driver-ptouch printer-driver-splix
	sudo chroot squashfs-root apt autoremove --yes
	sudo chroot squashfs-root apt clean
	
	cd squashfs-root && sudo umount ./proc
	cd squashfs-root && sudo umount ./sys
	cd squashfs-root && sudo umount ./dev/pts
	cd squashfs-root && sudo umount ./dev
	cd squashfs-root && sudo umount ./run

# Create customized ISO image
iso:
	@printf "\nConfiguring sudoers...\n"
	echo "ubuntu ALL=(ALL) NOPASSWD: ALL" | sudo tee squashfs-root/etc/sudoers.d/99ubuntu
	sudo chmod 440 squashfs-root/etc/sudoers.d/99ubuntu

	@printf "\nCreating squashfs...\n"
	sudo rm --force extract-cd/casper/filesystem.squashfs
	sudo rm --force extract-cd/casper/filesystem.size
	sudo rm --force extract-cd/md5sum.txt
	sudo mksquashfs squashfs-root extract-cd/casper/filesystem.squashfs -comp xz -e squashfs-root/boot

	@printf "\nPopulating filesystem.manifest...\n"
	sudo chmod +w extract-cd/casper/filesystem.manifest
	sudo chroot squashfs-root dpkg-query -W --showformat='${Package} ${Version}\n' \
	    | sudo tee extract-cd/casper/filesystem.manifest

	@printf "\nPopulating filesystem.size...\n"
	printf $(sudo du -sx --block-size=1 squashfs-root | cut -f1) | sudo tee extract-cd/casper/filesystem.size

	@printf "\nPopulating md5sum.txt...\n"
	cd extract-cd && find . -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

	@printf "\nCreating ISO...\n"
	sudo rm -f ubuntu-desktop-pre-hap-validation.iso
	sudo xorriso -as mkisofs -r \
		-checksum_algorithm_iso md5,sha1 \
		-V "Ubuntu with Pre-HAP Validation" \
		-o ubuntu-desktop-pre-hap-validation.iso \
		-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
		-cache-inodes -J -l \
		-b isolinux/isolinux.bin \
		-c isolinux/boot.cat \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		-eltorito-alt-boot \
		-e boot/grub/efi.img \
		-no-emul-boot \
		-isohybrid-gpt-basdat \
		-isohybrid-apm-hfsplus extract-cd

# Launch KVM instance using customised ISO image
.PHONY: test
test: 
	qemu-system-x86_64 -snapshot -enable-kvm -m 2048 -boot d \
		-cdrom ubuntu-desktop-pre-hap-validation.iso \
		-net nic,model=virtio -net user,hostfwd=tcp::22000-:22 &

# Umount mnt/ and remove temporary files
.PHONY: clean
clean:
	@echo "Cleaning up..."
	if mountpoint --quiet mnt/ ; then \
		sudo umount mnt; \
	fi
	sudo rm -rf extract-cd
	sudo rm -rf squashfs-root
	rm -rf mnt