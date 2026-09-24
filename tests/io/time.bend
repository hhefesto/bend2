import Base

# IO.time is the wall clock in milliseconds since the Unix epoch: it is past
# 2024-01-01 (1704067200 s) and does not run backwards across two reads.

def U32.of_ms(+ms: Nat) -> U32:
  U32.from_nat(Nat.div(ms, U32.to_nat(1000)))

def main() -> IO(Unit):
  do IO<Unit>:
    +a : Nat <- IO.time()
    +b : Nat <- IO.time()
    IO.print(Bool.show(U32.is_lt(1704067200, U32.of_ms(a))))
    IO.print(Bool.show(Nat.is_le(a, b)))
