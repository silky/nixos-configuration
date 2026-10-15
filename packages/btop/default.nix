{ btop, python3, makeWrapper, xvfb }:
let
  python = python3.withPackages (p: [ p.xlib ]);
  testPython = python3.withPackages (p: [ p.xlib p.pyte ]);
in
btop.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./window-follow.patch ];
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ makeWrapper ];
  nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ xvfb ];
  # Keep the upstream package's LTO build; its CMake test archive does not
  # propagate LTO to the test linker. Run our tests against the real executable.
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DBUILD_TESTING=OFF" ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    $CXX -std=c++23 -Wall -Wextra -Werror -I ../src ${./test-follow.cpp} -o test-window-follow
    ./test-window-follow
    ${testPython}/bin/python3 ${./test-window-follow.py} ${./window-follow.py} "$PWD/btop"
    runHook postCheck
  '';

  postInstall = (old.postInstall or "") + ''
    mkdir -p "$out/libexec"
    mv "$out/bin/btop" "$out/libexec/btop"
    cp ${./window-follow.py} "$out/share/btop/window-follow.py"
    makeWrapper ${python}/bin/python3 "$out/bin/btop" \
      --add-flags "$out/share/btop/window-follow.py" \
      --add-flags "$out/libexec/btop"
  '';
})
