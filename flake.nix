{
  description = "Canoziia's Custom Linux Kernel";

  nixConfig = {
    extra-substituters = [ "https://nix-cache.projectk.org" ];
    extra-trusted-public-keys = [ "canoziia:qOX9w17KWcw6tKNpC6AF/dJDhybUcVYboKCpumctbVo=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      # 1. 导出 Overlay：这是给 NixOS 用户使用的最佳方式
      overlays.default = final: prev: {
        canoziiaKernel = prev.linuxPackages_latest.kernel.override {
          kernelPatches =
            prev.linuxPackages_latest.kernel.kernelPatches
            ++ [
              {
                name = "ath12k-enable-6ghz";
                patch = null;
                extraConfig = ''
                  CFG80211_CERTIFICATION_ONUS y
                  ATH_REG_DYNAMIC_USER_REG_HINTS y
                  ATH_REG_DYNAMIC_USER_CERT_TESTING y
                '';
              }
            ]
            ++ prev.lib.optionals prev.stdenv.hostPlatform.isAarch64 [
              {
                name = "enable-dynamic-preemption";
                patch = null;
                extraConfig = ''
                  PREEMPT_DYNAMIC y
                  PREEMPT_RCU y
                  PREEMPT_VOLUNTARY y
                '';
              }
              {
                name = "change-hz";
                patch = null;
                extraConfig = ''
                  HZ_1000 y
                  HZ 1000
                '';
              }
            ]
            ++ prev.lib.optionals prev.stdenv.hostPlatform.isx86_64 [ ];
        };
        linuxPackages_canoziia = final.linuxPackagesFor final.canoziiaKernel;
      };

      # 2. 导出 Packages：用于 CI 构建和测试
      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.linuxPackages_canoziia;
          kernel = pkgs.canoziiaKernel;
        }
      );
    };
}
