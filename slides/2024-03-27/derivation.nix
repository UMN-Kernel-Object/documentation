# This is a function that accepts an attrset with three fields:
{ coreutils, runtimeShell, system }:
# It returns the result of calling the function builtins.derivation with the
# attrset as an argument.
builtins.derivation {
  name = "example"; # The name part of the output file path.
  system = system; # The system on which the derivation can be built
                   # e.g. x86_64-linux.

  # The binary to use to build. In this case, the "default" shell.
  builder = runtimeShell;
  # The arguments to the builder program.
  args = [ "-c" "printf 'Hello, world!\\n' > $out" ];
}
