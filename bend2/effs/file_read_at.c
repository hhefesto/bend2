// File
// ====

// Up to max bytes at byte off, as they are, one List cell each (fewer at
// the end of the file); pread, so the file's own position stays.
static void file_read_at_call(IoWork* w) {
  int fd = (int)w->hand;
  w->size = io_sys_end(w, pread(fd, w->data, w->word, (off_t)w->made));
}

static Term file_read_at_pack(Env e, IoWork* w) {
  Term r;
  if (w->code) {
    r = io_fail(e, w->code, NULL);
  } else {
    Term xs = term_pak(CID_NIL, 0);
    for (u64 i = w->size; i > 0; i -= 1) {
      xs = io_node(e, CID_CON, ((uint8_t*)w->data)[i - 1], xs, IO_HOTS & 16);
    }
    r = io_done(e, xs);
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_read_at_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = (intptr_t)(u32)f[1];
  w->word = f[2] < INT32_MAX ? f[2] : INT32_MAX;
  w->data = io_mem(malloc(w->word + 1));
  return io_work(w, file_read_at_call, file_read_at_pack);
}

static void __attribute__((constructor)) file_read_at_use(void) {
  io_eff(CID_FILE_READ_AT, file_read_at_run, 0);
}
