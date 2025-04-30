{ pkgs, ... }:

let
  # minimal latex bundle
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-small
      latexmk
      latexindent
      geometry
      titlesec
      charter
      xcolor
      enumitem
      fontawesome5
      amsmath
      hyperref
      eso-pic
      bookmark
      lastpage
      changepage
      paracol
      needspace
      iftex;
  };
in
{
  packages = with pkgs; [
    git
    tex
    reflex
    websocat
    http-server
  ];

  scripts.fmt.exec = "latexindent -w main.tex";

  scripts.build.exec = ''
    mkdir -p out
    latexmk -pdf -output-directory=out main.tex
  '';

  # serve index.html for hot-reloading PDF
  processes.webserver.exec = "http-server . -p 8080";

  # start broadcast socket for sending "reload" updates
  processes.socketserver.exec = ''
    websocat -t ws-l:127.0.0.1:35729 broadcast:mirror:
  '';

  # on latex file save, recompile and broadcast "reload"
  processes.watch.exec = ''
    open http://localhost:8080

    mkdir -p out
    reflex -r '\.tex$' -- sh -c '
      latexmk -pdf -output-directory=out main.tex &&
      echo reload | websocat -1 ws://localhost:35729
    '
  '';
}
