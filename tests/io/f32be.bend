# io (io_f32be): File.read_f32be and File.write_f32be are their
# meanings. Bytes with high bits go out through File.write_bytes and
# come back through File.read_bytes unchanged; read_f32be at a byte
# offset equals decoding those bytes (F32{w} of each big-endian word)
# into Array.set, including a wrapped index; write_f32be of that array
# gives back the same bytes; read_at from byte 13 is the last word's
# four bytes (a read past the end is short, not an error).
import Base

law bytes:
  List<&2, U32>

def bytes():
  [7, 63, 128, 0, 0, 191, 192, 0, 0, 255, 127, 255, 255, 65, 32, 0, 0]

# from byte 1 the words are 3F800000 (1.0), BFC00000 (-1.5), FF7FFFFF
# (-max) and 41200000 (10.0); set from index 1 of a 4-array, 10.0 wraps
# to index 0
law word:
  for a: U32
  for b: U32
  for c: U32
  for d: U32
  U32

def word(a, b, c, d):
  U32.add(U32.add(U32.mul(a, 16777216), U32.mul(b, 65536)), U32.add(U32.mul(c, 256), d))

law decode:
  for xs: List<&2, U32>
  for x: Array<F32>
  for +at: U32
  Array<F32>

def decode(xs, x, at):
  match xs:
    case []:
      x
    case a <> r1:
      match r1:
        case []:
          x
        case b <> r2:
          match r2:
            case []:
              x
            case c <> r3:
              match r3:
                case []:
                  x
                case d <> r4:
                  decode(r4, Array.set(F32, x, at, F32.of_bits(word(a, b, c, d))), U32.add(at, 1))

law bits:
  for xs: List<F32>
  List<&2, U32>

def bits(xs):
  match xs:
    case []:
      []
    case x <> r:
      F32.bits(x) <> bits(r)

law eq:
  for xs: List<&2, U32>
  for ys: List<&2, U32>
  Bool

def eq(xs, ys):
  match xs:
    case []:
      match ys:
        case []:
          True{}
        case y <> s:
          False{}
    case x <> r:
      match ys:
        case []:
          False{}
        case y <> s:
          U32.is_eq(x, y) && eq(r, s)

law after:
  List<&2, U32>

def after():
  [63, 128, 0, 0, 191, 192, 0, 0, 255, 127, 255, 255, 65, 32, 0, 0]

law say:
  for b: Bool
  for yes: String
  for no: String
  String

def say(b, yes, no):
  match b:
    case True{}:
      yes
    case False{}:
      no

law read_two:
  for f: File
  for r: Result<&1, &1, (U32 & String), Unit>
  for xy: Array<F32> & Array<F32>
  for want: Array<F32>
  IO(Array<F32>)

def read_two(f, r, xy, want):
  (x, y) = xy
  do IO<Array<F32>>:
    u : Unit <- IO.pass(Unit, r)
    c : Unit <- File.close(f)
    q : Unit <- IO.print(say(eq(bits(Array.to_list(~F32, y)), bits(Array.to_list(~F32, want))), "read-same", "read-differs"))
    return x

law read_go:
  for m: File & Array<F32> & Result<&1, &1, (U32 & String), Unit>
  for want: Array<F32>
  IO(Array<F32>)

def read_go(m, want):
  (f, x0, r) = m
  read_two(f, r, Array.clone(F32, x0), want)

law back_go:
  for m: File & Result<&1, &1, (U32 & String), List<&2, U32>>
  IO(U32)

def back_go(m):
  (f, r) = m
  do IO<U32>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    c : Unit <- File.close(f)
    p : Unit <- IO.print(say(eq(xs, after()), "write-same", "write-differs"))
    return 0

law tail_go:
  for m: File & Result<&1, &1, (U32 & String), List<&2, U32>>
  IO(U32)

def tail_go(m):
  (f, r) = m
  do IO<U32>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    c : Unit <- File.close(f)
    p : Unit <- IO.print(say(eq(xs, [65, 32, 0, 0]), "tail-same", "tail-differs"))
    return 0

law wrote:
  for m: File & Array<F32> & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def wrote(m):
  (f, x, r) = m
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law unit_go:
  for m: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def unit_go(m):
  (f, r) = m
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law main:
  IO(U32)

def main():
  do IO<U32>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_f32be.bin", "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write_bytes(f, bytes())
    a : Unit <- unit_go(w)
    g : File <- IO.try(File, File.open("/tmp/bend_io_f32be.bin", "r"))
    m : File & Array<F32> & Result<&1, &1, (U32 & String), Unit> <- File.read_f32be(g, 1, 4, Array.new(F32, 2n, 0.0), 1)
    x : Array<F32> <- read_go(m, decode(after(), Array.new(F32, 2n, 0.0), 1))
    h : File <- IO.try(File, File.open("/tmp/bend_io_f32be.out", "w"))
    n : File & Array<F32> & Result<&1, &1, (U32 & String), Unit> <- File.write_f32be(h, 4, x, 1)
    b : Unit <- wrote(n)
    k : File <- IO.try(File, File.open("/tmp/bend_io_f32be.out", "r"))
    o : File & Result<&1, &1, (U32 & String), List<&2, U32>> <- File.read_bytes(k, 64)
    z : U32 <- back_go(o)
    t : File <- IO.try(File, File.open("/tmp/bend_io_f32be.bin", "r"))
    u : File & Result<&1, &1, (U32 & String), List<&2, U32>> <- File.read_at(t, 13, 64)
    tail_go(u)

#|read-same
#|write-same
#|tail-same
