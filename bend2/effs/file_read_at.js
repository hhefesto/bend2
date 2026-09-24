// File
// ====

function file_read_at(file, off, max) {
  const fs = require("fs");
  const len = Math.min(Number(max), 2147483647);
  const b = Buffer.alloc(Math.max(len, 1));
  let n = 0;
  try {
    n = fs.readSync(file, b, 0, len, Number(off));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
  let xs = { $: "Nil" };
  for (let i = n; i > 0; i -= 1) {
    xs = { $: "Con", head: b[i - 1], tail: xs };
  }
  return io_tup(file, io_done(xs));
}
