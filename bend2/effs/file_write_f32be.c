// File
// ====

// x[at], ..., x[at+n-1] (indices wrap) as big-endian f32, written at the
// file's position, the array handed back unchanged.
Term file_write_f32be_run(Env e, Term* f, IoWork* w) {
  int  fd = (int)io_hand_v(f[0]);
  u64  n  = (u64)(u32)f[1];
  Term x  = f[2];
  u32  at = (u32)f[3];
  u32  code = 0;
  FT_WAIT();
  enum { CH = 1 << 20 };
  uint8_t* b = io_mem(malloc(4 * (size_t)CH));
  for (u64 i = 0; i < n && code == 0;) {
    u64 k = n - i < CH ? n - i : CH;
    for (u64 j = 0; j < k; j += 1) {
      u32      v = (u32)*ft_cell(e.mem, x, at + (u32)(i + j));
      uint8_t* p = b + 4 * j;
      p[0] = (uint8_t)(v >> 24);
      p[1] = (uint8_t)(v >> 16);
      p[2] = (uint8_t)(v >> 8);
      p[3] = (uint8_t)v;
    }
    for (u64 d = 0; d < 4 * k && code == 0;) {
      ssize_t r = write(fd, b + d, 4 * k - d);
      if (r < 0) {
        code = (u32)errno;
      } else {
        d += (u64)r;
      }
    }
    i += k;
  }
  free(b);
  Term r = code != 0 ? io_fail(e, code, NULL)
    : io_done(e, term_pak(CID(Unit), 0));
  return io_tup(e, io_hand(io_hand_v(f[0])), io_tup(e, x, r));
}

static void __attribute__((constructor)) file_write_f32be_use(void) {
  io_eff(CID(File.write_f32be), file_write_f32be_run, 0);
}
