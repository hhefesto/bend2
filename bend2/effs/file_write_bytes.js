// File
// ====

function file_write_bytes(file, xs) {
  const fs = require("fs");
  const bs = [];
  for (let c = xs; c.$ === "Con"; c = c.tail) {
    bs.push(Number(c.head) & 255);
  }
  const b = Buffer.from(bs);
  try {
    let d = 0;
    while (d < b.length) {
      d += fs.writeSync(file, b, d, b.length - d, null);
    }
    return io_tup(file, io_done({ $: "Unit" }));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}
