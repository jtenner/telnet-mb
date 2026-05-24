// Deterministic fuzzing helpers for TELNET property tests.
//
// These helpers intentionally live in test code so future fuzz properties can
// share reproducible seeds without changing the public TELNET API.

///|
struct FuzzRng {
  state : Int
} derive(Eq, Debug)

///|
fn fuzz_rng(seed : Int) -> FuzzRng {
  let normalized = seed % 65521
  let positive = if normalized < 0 { normalized + 65521 } else { normalized }
  FuzzRng::{ state: if positive == 0 { 1 } else { positive } }
}

///|
fn FuzzRng::next_int(self : FuzzRng) -> (FuzzRng, Int) {
  let next = (self.state * 25173 + 13849) % 65521
  (FuzzRng::{ state: next }, next)
}

///|
fn FuzzRng::bounded_int(self : FuzzRng, bound : Int) -> (FuzzRng, Int) {
  let (next, value) = self.next_int()
  if bound <= 0 {
    (next, 0)
  } else {
    (next, value % bound)
  }
}

///|
fn FuzzRng::byte(self : FuzzRng) -> (FuzzRng, Byte) {
  let (next, value) = self.bounded_int(256)
  (next, byte(value))
}

///|
fn FuzzRng::bool(self : FuzzRng) -> (FuzzRng, Bool) {
  let (next, value) = self.bounded_int(2)
  (next, value == 1)
}

///|
fn FuzzRng::chunk_boundary(self : FuzzRng, remaining : Int) -> (FuzzRng, Int) {
  if remaining <= 0 {
    let (next, _) = self.next_int()
    (next, 0)
  } else {
    self.bounded_int(remaining + 1)
  }
}

///|
fn fuzz_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (next, x) = rng.byte()
    out[i] = x
    rng = next
  }
  Bytes::from_array(out)
}

///|
fn fuzz_bytes_from_ints(ns : Array[Int]) -> Bytes {
  Bytes::from_array(ns.map(fn(n) { byte(n) }))
}

///|
fn fuzz_no_iac_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (next, x) = rng.byte()
    out[i] = if x == byte(255) { byte(254) } else { x }
    rng = next
  }
  Bytes::from_array(out)
}

///|
fn fuzz_telnet_biased_byte(choice : Int, fallback : Byte) -> Byte {
  match choice {
    0 | 1 | 2 => byte(255) // IAC, deliberately dense.
    3 => byte(240) // SE
    4 => byte(241) // NOP
    5 => byte(242) // DM
    6 => byte(250) // SB
    7 => byte(251) // WILL
    8 => byte(252) // WONT
    9 => byte(253) // DO
    10 => byte(254) // DONT
    11 => byte(13) // CR
    12 => byte(10) // LF
    13 => byte(0) // NUL / BINARY option
    14 => byte(1) // ECHO option
    15 => byte(3) // SUPPRESS-GO-AHEAD option
    16 => byte(24) // TERMINAL-TYPE option
    17 => byte(31) // NAWS option
    18 => byte(34) // LINEMODE option
    19 => byte(39) // NEW-ENVIRON option
    20 => byte(46) // START-TLS option
    _ => fallback
  }
}

///|
fn fuzz_telnet_biased_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (r1, choice) = rng.bounded_int(28)
    let (r2, fallback) = r1.byte()
    out[i] = fuzz_telnet_biased_byte(choice, fallback)
    rng = r2
  }
  Bytes::from_array(out)
}

///|
fn fuzz_parser_config(index : Int) -> @telnet.ParserConfig {
  if index == 0 {
    @telnet.Parser::default_config()
  } else if index == 1 {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 1,
      max_subnegotiation_bytes: 8,
      cr_policy: @telnet.CrPolicy::Preserve,
      data_coalescing: @telnet.DataCoalescing::EmitImmediately,
      strict_commands: true,
    }
  } else if index == 2 {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 4,
      max_subnegotiation_bytes: 4,
      cr_policy: @telnet.CrPolicy::ValidateNvt,
      data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
      strict_commands: true,
    }
  } else if index == 3 {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 3,
      max_subnegotiation_bytes: 3,
      cr_policy: @telnet.CrPolicy::NormalizeToLf,
      data_coalescing: @telnet.DataCoalescing::CoalesceUntilCapacity,
      strict_commands: false,
    }
  } else {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 0,
      max_subnegotiation_bytes: 0,
      cr_policy: @telnet.CrPolicy::Preserve,
      data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
      strict_commands: true,
    }
  }
}

///|
fn fuzz_assert_parser_smoke(
  config : @telnet.ParserConfig,
  input : Bytes,
) -> Unit raise {
  let fed = @telnet.Parser::new(config).feed(input)
  assert_true(fed.bytes_consumed == input.length())
  let fed_checkpoint = fed.parser.checkpoint()
  assert_true(fed_checkpoint.absolute_offset == input.length())
  assert_true(fed_checkpoint.buffered_data_length >= 0)
  assert_true(fed_checkpoint.buffered_subnegotiation_length >= 0)
  assert_true(fed.events.length() <= input.length() + 1)

  let finished = fed.parser.finish()
  assert_true(finished.events.length() <= 1)
  let reset_checkpoint = finished.parser.checkpoint()
  assert_true(reset_checkpoint.mode == @telnet.ParserMode::Normal)
  assert_true(reset_checkpoint.absolute_offset == 0)
  assert_true(reset_checkpoint.buffered_data_length == 0)
  assert_true(reset_checkpoint.buffered_subnegotiation_length == 0)
}

///|
test "fuzz rng is deterministic for representative seeds" {
  let seed_one = fuzz_rng(1)
  let (r1, v1) = seed_one.next_int()
  let (r2, v2) = r1.next_int()
  let (r3, v3) = r2.next_int()
  assert_true(v1 == 39022)
  assert_true(v2 == 23823)
  assert_true(v3 == 62036)
  assert_true(r3 == FuzzRng::{ state: 62036 })

  let zero_seed = fuzz_rng(0)
  let (zero_next, zero_value) = zero_seed.next_int()
  assert_true(zero_seed == seed_one)
  assert_true(zero_value == 39022)
  assert_true(zero_next == r1)

  let negative_seed = fuzz_rng(-1)
  let (_, negative_value) = negative_seed.next_int()
  assert_true(negative_seed == FuzzRng::{ state: 65520 })
  assert_true(negative_value == 54197)
}

///|
test "fuzz rng supports bounded ints booleans bytes and chunk boundaries" {
  let rng = fuzz_rng(1)
  let (r1, bounded) = rng.bounded_int(10)
  let (r2, b1) = r1.bool()
  let (r3, x) = r2.byte()
  let (r4, boundary) = r3.chunk_boundary(5)
  let (r5, empty_boundary) = r4.chunk_boundary(0)
  let (r6, negative_boundary) = r5.chunk_boundary(-7)

  assert_true(bounded == 2)
  assert_true(b1)
  assert_true(x == byte(84))
  assert_true(boundary == 5)
  assert_true(empty_boundary == 0)
  assert_true(negative_boundary == 0)
  assert_true(r6 == FuzzRng::{ state: 57598 })

  let (after_zero_bound, zero_bound) = fuzz_rng(42).bounded_int(0)
  assert_true(zero_bound == 0)
  assert_true(after_zero_bound == FuzzRng::{ state: 22779 })
}

///|
test "fuzz byte helper produces reproducible byte buffers" {
  let generated = fuzz_bytes(1, 8)
  let expected = bytes([110, 15, 84, 131, 124, 254, 14, 8])
  assert_true(generated == expected)
  assert_true(fuzz_bytes(99, 0).length() == 0)
}

///|
test "parser smoke fuzz covers empty and every single byte" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    fuzz_assert_parser_smoke(config, Bytes::new(0))
    for value = 0; value < 256; value = value + 1 {
      fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([value]))
    }
  }
}

///|
test "parser smoke fuzz covers targeted TELNET edge seeds" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 255]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 255, 255]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 241]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 251]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 251, 1]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 250]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 250, 31]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 250, 31, 255]))
    fuzz_assert_parser_smoke(
      config,
      fuzz_bytes_from_ints([255, 250, 31, 255, 240]),
    )
    fuzz_assert_parser_smoke(
      config,
      fuzz_bytes_from_ints([255, 250, 31, 255, 255, 255, 240]),
    )
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13, 10]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13, 0]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13, 88]))
  }
}

///|
test "parser smoke fuzz covers no-IAC fast paths and dense control streams" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    for iteration = 0; iteration < 24; iteration = iteration + 1 {
      let no_iac_length = iteration * 7 % 65
      fuzz_assert_parser_smoke(
        config,
        fuzz_no_iac_bytes(1000 + config_index * 97 + iteration, no_iac_length),
      )
      let dense_length = (iteration * 11 + 3) % 73
      fuzz_assert_parser_smoke(
        config,
        fuzz_telnet_biased_bytes(
          2000 + config_index * 131 + iteration,
          dense_length,
        ),
      )
    }
  }
}
