/// The single screen-level state machine.
enum RunState {
  loading, // sprites still decoding
  title,
  countdown, // 3 · 2 · 1 · GO with input already buffered
  running,
  paused,
  gameOver,
}
