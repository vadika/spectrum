# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

{ pkgs ? import <nixpkgs> {} }:

let
  inherit (builtins) storeDir;
  inherit (pkgs) OVMF qemu_kvm writeShellScript;
  inherit (pkgs.lib) escapeShellArg;

  eosimages = import ../combined/eosimages.nix { inherit pkgs; };

  installer = import ./. {
    inherit pkgs;

    extraConfig = {
      boot.initrd.availableKernelModules = [ "9p" "9pnet_virtio" ];

      fileSystems.${storeDir} = {
        fsType = "9p";
        device = "store";
        # This can be removed when running Linux ≥5.15.
        options = [ "msize=131072" ];
      };
    };
  };
in

writeShellScript "run-spectrum-installer-vm.sh" ''
  img="$(mktemp spectrum-installer-target.XXXXXXXXXX.img)"
  truncate -s 10G "$img"
  exec 3<>"$img"
  rm -f "$img"
  exec ${qemu_kvm}/bin/.qemu-system-x86_64-wrapped -enable-kvm -cpu host -m 4G -machine q35 -snapshot \
    -display gtk,gl=on \
    -device virtio-vga-gl \
    -virtfs local,mount_tag=store,path=/nix/store,security_model=none,readonly=true \
    -drive file=${eosimages},format=raw,if=virtio,readonly=true \
    -drive file=/proc/self/fd/3,format=raw,if=virtio \
    -bios ${OVMF.fd}/FV/OVMF.fd \
    -kernel ${installer.kernel} \
    -initrd ${installer.initramfs} \
    -append ${escapeShellArg installer.kernelParams}
''