// IO
// ==

function io_time() {
  return BigInt(Date.now());
}

io_eff(CID(IO.time), io_time);
