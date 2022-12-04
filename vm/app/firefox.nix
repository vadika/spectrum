# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

{ config ? import ../../../nix/eval-config.nix {} }:

import ../make-vm.nix { inherit config; } {
  providers.net = [ "netvm" ];
  run = config.pkgs.callPackage (
    { writeScript }:
    writeScript "run-as-root" ''
      #!/bin/sh
      /bin/sh
    ''
  ) { };

    run-as-user = config.pkgs.callPackage (
    { writeScript, socat, waypipe, havoc, firefox-wayland}:
    writeScript "run-firefox" ''
      #!/bin/sh
      mkdir /run/home/user/0
      export XDG_RUNTIME_DIR=/run/home/user/0
      ${socat}/bin/socat  unix-listen:/run/home/user/waypipe.sock,reuseaddr,fork vsock-connect:2:5000 &
      sleep 1
      ${waypipe}/bin/waypipe --display wayland-local-user --socket /run/home/user/waypipe.sock server -- sleep inf &
      export WAYLAND_DISPLAY=wayland-local-user

      ${firefox-wayland}/bin/firefox https://spectrum-os.org/
      /bin/sh
    ''
  ) { };
}
