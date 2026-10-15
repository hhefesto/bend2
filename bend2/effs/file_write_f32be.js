// File
// ====

function file_write_f32be(file, n, x, at) {
  const fs = require("fs");
  const k = Number(n);
  const b = Buffer.alloc(4 * k);
  for (let j = 0; j < k; j += 1) {
    b.writeFloatBE(x[(Number(at) + j) % x.length], 4 * j);
  }
  try {
    let d = 0;
    while (d < b.length) {
      d += fs.writeSync(file, b, d, b.length - d, null);
    }
    return io_tup(file, x, io_done({ $: CID(Unit) }));
  } catch (e) {
    return io_tup(file, x, io_fail(Math.abs(e.errno ?? 5)));
  }
}

io_eff(CID(File.write_f32be), file_write_f32be);
