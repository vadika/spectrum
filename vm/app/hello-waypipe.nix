# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

{ config ? import ../../../nix/eval-config.nix {} }:

import ../make-vm.nix { inherit config; } {
  providers.net = [ "netvm" ];
  run = config.pkgs.callPackage (
    { writeScript, waypipe, havoc, foot, hello-wayland, socat}:
    writeScript "run-waypipe-app" ''
      #!/bin/sh
      mkdir /run/0
      export XDG_RUNTIME_DIR=/run/0
      ${socat}/bin/socat  unix-listen:/run/waypipe.sock,reuseaddr,fork vsock-connect:2:5000 &
      sleep 1
      ${waypipe}/bin/waypipe --display wayland-local --socket /run/waypipe.sock server -- sleep inf &
      export WAYLAND_DISPLAY=wayland-local
      ${havoc}/bin/havoc
      ${hello-wayland}/bin/hello-wayland
      ${foot}/bin/foot
    ''
  ) { };
}
