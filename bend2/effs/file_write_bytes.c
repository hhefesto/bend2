// File
// ====

// The low byte of each U32 in the list, as it is (no UTF-8).
static void file_write_bytes_call(IoWork* w) {
  int     fd = (int)w->hand;
  ssize_t n  = 0;
  for (uint64_t at = 0; n >= 0 && at < w->size; at += (uint64_t)n) {
    n = write(fd, w->data + at, w->size - at);
  }
  io_sys_end(w, n);
}

static Term file_write_bytes_pack(Env e, IoWork* w) {
  Term r = w->code != 0 ? io_fail(e, w->code, NULL)
    : io_done(e, term_pak(CID_UNIT, 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_write_bytes_run(Env e, Term* f, IoWork* w) {
  u64   cap = 64;
  u64   n   = 0;
  char* buf = io_mem(malloc(cap));
  Term  s   = f[1];
  while (term_aux(s) == CID_CON) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, s, 2, fb));
    if (n + 1 > cap) {
      cap *= 2;
      buf = io_mem(realloc(buf, cap));
    }
    buf[n] = (char)(uint8_t)(u32)fb[0];
    n += 1;
    s = fb[1];
  }
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = buf;
  w->size = n;
  return io_work(w, file_write_bytes_call, file_write_bytes_pack);
}

static void __attribute__((constructor)) file_write_bytes_use(void) {
  io_eff(CID_FILE_WRITE_BYTES, file_write_bytes_run, 0);
}
