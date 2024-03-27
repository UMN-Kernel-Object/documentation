{ stdenv }:

stdenv.mkDerivation {
  pname = "foo";
  version = "1.2.3";

  src = fetchurl { };
}
