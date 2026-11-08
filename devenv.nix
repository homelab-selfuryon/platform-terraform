# Shared base (hooks, treefmt, actionlint, zizmor, shellcheck, jq) comes from platform-kit.
{ pkgs, ... }:
{
  packages = with pkgs; [
    gh
    openbao
    opentofu
    tflint
  ];

  # OpenTofu is not `terraform`: point the formatter at it.
  treefmt.config.programs.terraform = {
    enable = true;
    package = pkgs.opentofu;
  };
}
