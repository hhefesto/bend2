// File
// ====

function file_read_f32be(file, off, n, x, at) {
  const fs = require("fs");
  const k = Number(n);
  const b = Buffer.alloc(4 * k);
  let got = 0;
  try {
    while (got < 4 * k) {
      const r = fs.readSync(file, b, got, 4 * k - got, Number(off) + got);
      if (r === 0) {
        break;
      }
      got += r;
    }
  } catch (e) {
    return io_tup(file, x, io_fail(Math.abs(e.errno ?? 5)));
  }
  for (let j = 0; j < Math.floor(got / 4); j += 1) {
    x[(Number(at) + j) % x.length] = b.readFloatBE(4 * j);
  }
  const r = got === 4 * k ? io_done({ $: CID(Unit) }) : io_fail(5);
  return io_tup(file, x, r);
}

io_eff(CID(File.read_f32be), file_read_f32be);
