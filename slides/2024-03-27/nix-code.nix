let double = x: x + x;

in {
  message = "2 + 2 = ${<|double <:2:>|>}";
  some-primes = [ <:2:> <:3:> <:5:> <:7:> <:11:> ];
  zero-is-even = true;
}
