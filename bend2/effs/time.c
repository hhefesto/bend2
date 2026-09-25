// IO
// ==

Term io_time_run(Env e, Term* f, IoWork* w) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  return (Term)((u64)ts.tv_sec * 1000ull + (u64)ts.tv_nsec / 1000000ull);
}

static void __attribute__((constructor)) io_time_use(void) {
  io_eff(CID(IO.time), io_time_run, 0);
}
