// File
// ====

// n big-endian f32 at byte off of the file, into x[at], x[at+1], ...
// (indices wrap, as Array.set's do), read with pread so the file's own
// position stays; the array is written in place, so no F32 is ever a
// Bend term on the way. A short read is EIO; the cells past it keep
// their values.
Term file_read_f32be_run(Env e, Term* f, IoWork* w) {
  int  fd  = (int)io_hand_v(f[0]);
  u64  off = (u64)(u32)f[1];
  u64  n   = (u64)(u32)f[2];
  Term x   = f[3];
  u32  at  = (u32)f[4];
  u32  code = 0;
  FT_WAIT();
  enum { CH = 1 << 20 };
  uint8_t* b = io_mem(malloc(4 * (size_t)CH));
  for (u64 i = 0; i < n && code == 0;) {
    u64     k = n - i < CH ? n - i : CH;
    ssize_t r = pread(fd, b, 4 * k, (off_t)(off + 4 * i));
    if (r < 0) {
      code = (u32)errno;
    } else if ((u64)r != 4 * k) {
      code = EIO;
    } else {
      for (u64 j = 0; j < k; j += 1) {
        const uint8_t* p = b + 4 * j;
        *ft_cell(e.mem, x, at + (u32)(i + j)) = ((u32)p[0] << 24)
          | ((u32)p[1] << 16) | ((u32)p[2] << 8) | (u32)p[3];
      }
      i += k;
    }
  }
  free(b);
  Term r = code != 0 ? io_fail(e, code, NULL)
    : io_done(e, term_pak(CID(Unit), 0));
  return io_tup(e, io_hand(io_hand_v(f[0])), io_tup(e, x, r));
}

static void __attribute__((constructor)) file_read_f32be_use(void) {
  io_eff(CID(File.read_f32be), file_read_f32be_run, 0);
}
