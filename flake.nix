{
  description = "Canoziia's Custom Linux Kernel";

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
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          ath12kConfig = {
            name = "ath12k-enable-6ghz";
            patch = null;
            extraConfig = ''
              CFG80211_CERTIFICATION_ONUS y
              ATH_REG_DYNAMIC_USER_REG_HINTS y
              ATH_REG_DYNAMIC_USER_CERT_TESTING y
            '';
          };

          originalKernel = pkgs.linuxPackages_latest.kernel;

          customKernel = originalKernel.override {
            kernelPatches = originalKernel.kernelPatches ++ [ ath12kConfig ];
          };

          customKernelPackages = pkgs.linuxPackagesFor customKernel;
        in
        {
          default = customKernelPackages;
          kernel = customKernel;
        }
      );
    };
}
