{
  lib,
  stdenvNoCC,
  # build
  qt6,
  quickshell,
  makeWrapper,
  # runtime deps
  brightnessctl,
  cava,
  cliphist,
  ddcutil,
  wlsunset,
  wl-clipboard,
  imagemagick,
  wget,
  python3,
  wayland-scanner,
  # calendar support
  calendarSupport ? false,
  evolution-data-server,
  libical,
  glib,
  libsoup_3,
  json-glib,
  gobject-introspection,
  version ? "dirty",
  extraPackages ? [ ],
}:
let
  src = lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /.github
        /.gitignore
        /Assets/Screenshots
        /Scripts/dev
        /nix
        /LICENSE
        /README.md
        /flake.nix
        /flake.lock
        /shell.nix
        /lefthook.yml
        /CLAUDE.md
        /CREDITS.md
      ]);
  };

  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    evolution-data-server
    libical
    glib.out
    libsoup_3
    json-glib
    gobject-introspection
  ];

  runtimeDeps = [
    brightnessctl
    cava
    cliphist
    ddcutil
    wlsunset
    wl-clipboard
    imagemagick
    wget
    (if calendarSupport then
      python3.withPackages (pp: [ pp.pygobject3 ])
     else
      python3)
  ] ++ extraPackages;
in
stdenvNoCC.mkDerivation {
  pname = "noctalia-shell";
  inherit version src;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
    runtimeDeps
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/noctalia-shell $out/bin
    cp -r . $out/share/noctalia-shell

    makeWrapper ${quickshell}/bin/qs $out/bin/noctalia-shell \
      --prefix PATH : ${lib.makeBinPath runtimeDeps} \
      --prefix XDG_DATA_DIRS : ${wayland-scanner}/share \
      --add-flags "-p $out/share/noctalia-shell" \
      ${lib.optionalString calendarSupport "--prefix GI_TYPELIB_PATH : ${giTypelibPath}"}

    runHook postInstall
  '';

  meta = {
    description = "A sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell.";
    homepage = "https://github.com/noctalia-dev/noctalia-shell";
    license = lib.licenses.mit;
    mainProgram = "noctalia-shell";
  };
}
