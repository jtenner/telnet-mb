// Test-driven specification for the transport-independent Session layer.
// Session composes Parser + Negotiator + Encoder + option codecs, but does not
// own sockets, TLS streams, terminals, or application side effects.

///|
fn session_out(capacity : Int) -> Bytes {
  Bytes::make(capacity, byte(0))
}

///|
fn session_rule(
  option : Int,
  side : @telnet.OptionSide,
  decision : @telnet.PolicyDecision,
) -> @telnet.OptionPolicyRule {
  @telnet.OptionPolicyRule::{ option: opt(option), side, decision }
}

///|
fn session_policy(
  rules : Array[@telnet.OptionPolicyRule],
) -> @telnet.SessionPolicy {
  @telnet.SessionPolicy::{
    rules,
    default_local: @telnet.PolicyDecision::Reject,
    default_remote: @telnet.PolicyDecision::Reject,
  }
}

///|
fn session_config(policy : @telnet.SessionPolicy) -> @telnet.SessionConfig {
  @telnet.SessionConfig::{
    parser_config: preserve_config(),
    policy,
    incoming_text_policy: @telnet.SessionTextPolicy::Preserve,
    outgoing_text_policy: @telnet.SessionTextPolicy::Preserve,
    decode_known_options: true,
    emit_raw_subnegotiation: true,
    require_enabled_for_subnegotiation: false,
    reject_malformed_known_payloads: false,
    max_outbound_bytes: 8192,
  }
}

///|
test "TDD Session default is transport independent and reject-all safe" {
  let session = @telnet.Session::default()
  let out = session_out(8)
  match session.receive(bytes([255, 251, 1]), out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out[0] == byte(255))
      assert_true(out[1] == byte(254))
      assert_true(out[2] == byte(1))
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::NegotiationReceived(
            neg_event(@telnet.NegotiationVerb::Will, 1),
          ),
          @telnet.SessionEvent::NegotiationSent(
            neg_event(@telnet.NegotiationVerb::Dont, 1),
          ),
          @telnet.SessionEvent::OptionRejected(
            @telnet.OptionSide::Remote,
            opt(1),
          ),
        ],
      )
      assert_true(r.session.remote_option_enabled(opt(1)) == false)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session accepts remote option by policy and emits generated response" {
  let policy = session_policy([
    session_rule(1, @telnet.OptionSide::Remote, @telnet.PolicyDecision::Accept),
  ])
  let session = @telnet.Session::new(session_config(policy))
  let out = session_out(8)
  match session.receive(bytes([255, 251, 1]), out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out[0] == byte(255))
      assert_true(out[1] == byte(253))
      assert_true(out[2] == byte(1))
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::NegotiationReceived(
            neg_event(@telnet.NegotiationVerb::Will, 1),
          ),
          @telnet.SessionEvent::NegotiationSent(
            neg_event(@telnet.NegotiationVerb::Do, 1),
          ),
          @telnet.SessionEvent::OptionEnabled(
            @telnet.OptionSide::Remote,
            opt(1),
          ),
        ],
      )
      assert_true(r.session.remote_option_enabled(opt(1)))
      assert_true(!r.session.local_option_enabled(opt(1)))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session accepts local option by policy and emits WILL" {
  let policy = session_policy([
    session_rule(24, @telnet.OptionSide::Local, @telnet.PolicyDecision::Accept),
  ])
  let session = @telnet.Session::new(session_config(policy))
  let out = session_out(8)
  match session.receive(bytes([255, 253, 24]), out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out[0] == byte(255))
      assert_true(out[1] == byte(251))
      assert_true(out[2] == byte(24))
      assert_true(r.session.local_option_enabled(opt(24)))
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::NegotiationReceived(
            neg_event(@telnet.NegotiationVerb::Do, 24),
          ),
          @telnet.SessionEvent::NegotiationSent(
            neg_event(@telnet.NegotiationVerb::Will, 24),
          ),
          @telnet.SessionEvent::OptionEnabled(
            @telnet.OptionSide::Local,
            opt(24),
          ),
        ],
      )
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session request_option drives negotiator and encoder" {
  let session = @telnet.Session::default()
  let out = session_out(8)
  match session.request_option(opt(31), @telnet.OptionSide::Remote, true, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out[0] == byte(255))
      assert_true(out[1] == byte(253))
      assert_true(out[2] == byte(31))
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::NegotiationSent(
            neg_event(@telnet.NegotiationVerb::Do, 31),
          ),
        ],
      )
      assert_true(
        r.session.state_for(opt(31)).remote_state ==
        @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      )
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session decodes known subnegotiation while preserving raw event" {
  let session = @telnet.Session::default()
  assert_true(session.get_window_size() == None)
  let out = session_out(8)
  match session.receive(bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]), out) {
    Ok(r) => {
      assert_true(r.bytes_written == 0)
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::Subnegotiation(@telnet.SubnegotiationEvent::{
            option: opt(31),
            payload: span([0, 80, 0, 24]),
          }),
          @telnet.SessionEvent::OptionPayload(
            @telnet.OptionPayload::Naws(@telnet.NawsSize::{
              columns: (80).to_uint16(),
              rows: (24).to_uint16(),
            }),
          ),
        ],
      )
      assert_true(r.session.get_window_size() == None)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session unknown subnegotiation remains raw payload" {
  let session = @telnet.Session::default()
  let out = session_out(8)
  match session.receive(bytes([255, 250, 99, 1, 2, 255, 240]), out) {
    Ok(r) =>
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::Subnegotiation(@telnet.SubnegotiationEvent::{
            option: opt(99),
            payload: span([1, 2]),
          }),
          @telnet.SessionEvent::OptionPayload(
            @telnet.OptionPayload::Raw(opt(99), span([1, 2])),
          ),
        ],
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session tracks BINARY directions independently" {
  let policy = session_policy([
    session_rule(0, @telnet.OptionSide::Remote, @telnet.PolicyDecision::Accept),
    session_rule(0, @telnet.OptionSide::Local, @telnet.PolicyDecision::Accept),
  ])
  let session = @telnet.Session::new(session_config(policy))
  let out1 = session_out(8)
  match session.receive(bytes([255, 251, 0]), out1) {
    Ok(r1) => {
      assert_true(r1.session.incoming_binary())
      assert_true(!r1.session.outgoing_binary())
      let out2 = session_out(8)
      match r1.session.receive(bytes([255, 253, 0]), out2) {
        Ok(r2) => {
          assert_true(r2.session.incoming_binary())
          assert_true(r2.session.outgoing_binary())
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session parser preserves CR bytes so BINARY semantics stay session-level" {
  let policy = session_policy([
    session_rule(0, @telnet.OptionSide::Remote, @telnet.PolicyDecision::Accept),
  ])
  let session = @telnet.Session::new(session_config(policy))
  let out = session_out(8)
  match session.receive(bytes([255, 251, 0, 13, 88]), out) {
    Ok(r) =>
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::NegotiationReceived(
            neg_event(@telnet.NegotiationVerb::Will, 0),
          ),
          @telnet.SessionEvent::NegotiationSent(
            neg_event(@telnet.NegotiationVerb::Do, 0),
          ),
          @telnet.SessionEvent::OptionEnabled(
            @telnet.OptionSide::Remote,
            opt(0),
          ),
          @telnet.SessionEvent::Data(span([13, 88])),
        ],
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session send_data escapes IAC and leaves transport write to caller" {
  let session = @telnet.Session::default()
  let out = session_out(8)
  match session.send_data(span([65, 255, 66]), out) {
    Ok(r) => {
      assert_true(r.bytes_written == 4)
      assert_true(out[0] == byte(65))
      assert_true(out[1] == byte(255))
      assert_true(out[2] == byte(255))
      assert_true(out[3] == byte(66))
      assert_true(r.events == [])
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session send_payload frames option payload as subnegotiation" {
  let session = @telnet.Session::default()
  let out = session_out(16)
  match
    session.send_payload(
      @telnet.OptionPayload::TerminalType(
        @telnet.TerminalTypeMessage::Is("xterm"),
      ),
      out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 11)
      assert_true(
        out[0] == byte(255) && out[1] == byte(250) && out[2] == byte(24),
      )
      assert_true(out[3] == byte(0))
      assert_true(out[4] == byte(120))
      assert_true(out[9] == byte(255))
      assert_true(out[10] == byte(240))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session START_TLS FOLLOWS asks caller to upgrade transport" {
  let session = @telnet.Session::default()
  let out = session_out(8)
  match session.receive(bytes([255, 250, 46, 1, 255, 240]), out) {
    Ok(r) => {
      assert_true(r.session.tls_state == @telnet.StartTlsState::StartTlsFollows)
      assert_true(
        r.events ==
        [
          @telnet.SessionEvent::Subnegotiation(@telnet.SubnegotiationEvent::{
            option: opt(46),
            payload: span([1]),
          }),
          @telnet.SessionEvent::OptionPayload(
            @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
          ),
          @telnet.SessionEvent::StartTlsFollows,
          @telnet.SessionEvent::TransportUpgradeRequired,
        ],
      )
      assert_true(
        r.session.mark_tls_active().tls_state ==
        @telnet.StartTlsState::TlsActive,
      )
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session reports output capacity errors atomically" {
  let policy = session_policy([
    session_rule(1, @telnet.OptionSide::Remote, @telnet.PolicyDecision::Accept),
  ])
  let session = @telnet.Session::new(session_config(policy))
  let out = Bytes::make(2, byte(77))
  match session.receive(bytes([255, 251, 1]), out) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.SessionErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 3)
      assert_true(out == bytes([77, 77]))
    }
  }
}

///|
test "TDD Session receive streams split negotiation across chunks" {
  let policy = session_policy([
    session_rule(1, @telnet.OptionSide::Remote, @telnet.PolicyDecision::Accept),
  ])
  let session = @telnet.Session::new(session_config(policy))
  let out1 = session_out(8)
  match session.receive(bytes([255]), out1) {
    Ok(r1) => {
      assert_true(r1.events == [])
      assert_true(r1.bytes_written == 0)
      let out2 = session_out(8)
      match r1.session.receive(bytes([251]), out2) {
        Ok(r2) => {
          assert_true(r2.events == [])
          assert_true(r2.bytes_written == 0)
          let out3 = session_out(8)
          match r2.session.receive(bytes([1]), out3) {
            Ok(r3) => {
              assert_true(r3.bytes_written == 3)
              assert_true(out3[0] == byte(255))
              assert_true(out3[1] == byte(253))
              assert_true(out3[2] == byte(1))
              assert_true(r3.session.remote_option_enabled(opt(1)))
            }
            Err(_) => assert_true(false)
          }
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session receive streams split subnegotiation across chunks" {
  let session = @telnet.Session::default()
  match session.receive(bytes([255, 250, 31]), session_out(8)) {
    Ok(r1) =>
      match r1.session.receive(bytes([0, 80]), session_out(8)) {
        Ok(r2) =>
          match r2.session.receive(bytes([0, 24, 255]), session_out(8)) {
            Ok(r3) =>
              match r3.session.receive(bytes([240]), session_out(8)) {
                Ok(r4) => {
                  assert_true(
                    r4.events ==
                    [
                      @telnet.SessionEvent::Subnegotiation(@telnet.SubnegotiationEvent::{
                        option: opt(31),
                        payload: span([0, 80, 0, 24]),
                      }),
                      @telnet.SessionEvent::OptionPayload(
                        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
                          columns: (80).to_uint16(),
                          rows: (24).to_uint16(),
                        }),
                      ),
                    ],
                  )
                  assert_true(r4.session.get_window_size() == None)
                }
                Err(_) => assert_true(false)
              }
            Err(_) => assert_true(false)
          }
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session server local ECHO echoes received data when enabled" {
  let config = @telnet.SessionConfig::{
    parser_config: preserve_config(),
    policy: @telnet.SessionPolicy::default_server(),
    incoming_text_policy: @telnet.SessionTextPolicy::Preserve,
    outgoing_text_policy: @telnet.SessionTextPolicy::Preserve,
    decode_known_options: true,
    emit_raw_subnegotiation: true,
    require_enabled_for_subnegotiation: false,
    reject_malformed_known_payloads: false,
    max_outbound_bytes: 8192,
  }
  let session = @telnet.Session::new(config)
  let negotiate_out = session_out(8)
  match session.receive(bytes([255, 253, 1]), negotiate_out) {
    Ok(enabled) => {
      assert_true(enabled.session.local_option_enabled(opt(1)))
      assert_true(negotiate_out[0] == byte(255))
      assert_true(negotiate_out[1] == byte(253))
      assert_true(negotiate_out[2] == byte(31))
      assert_true(negotiate_out[3] == byte(255))
      assert_true(negotiate_out[4] == byte(251))
      assert_true(negotiate_out[5] == byte(1))
      let echo_out = session_out(8)
      match enabled.session.receive(bytes([65, 255, 255, 66]), echo_out) {
        Ok(echoed) => {
          assert_true(
            echoed.events ==
            [
              @telnet.SessionEvent::Data(span([65])),
              @telnet.SessionEvent::Data(span([255])),
              @telnet.SessionEvent::Data(span([66])),
            ],
          )
          assert_true(echoed.bytes_written == 4)
          assert_true(echo_out[0] == byte(65))
          assert_true(echo_out[1] == byte(255))
          assert_true(echo_out[2] == byte(255))
          assert_true(echo_out[3] == byte(66))
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD Session remote NAWS support is negotiated opaquely from policy" {
  let config = @telnet.SessionConfig::{
    parser_config: preserve_config(),
    policy: @telnet.SessionPolicy::default_server(),
    incoming_text_policy: @telnet.SessionTextPolicy::Preserve,
    outgoing_text_policy: @telnet.SessionTextPolicy::Preserve,
    decode_known_options: true,
    emit_raw_subnegotiation: true,
    require_enabled_for_subnegotiation: false,
    reject_malformed_known_payloads: false,
    max_outbound_bytes: 8192,
  }
  let session = @telnet.Session::new(config)
  let start_out = session_out(8)
  match session.receive(bytes([]), start_out) {
    Ok(started) => {
      assert_true(started.bytes_written == 3)
      assert_true(start_out[0] == byte(255))
      assert_true(start_out[1] == byte(253))
      assert_true(start_out[2] == byte(31))
      assert_true(
        started.session.state_for(opt(31)).remote_state ==
        @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      )
      match started.session.receive(bytes([255, 251, 31]), session_out(8)) {
        Ok(enabled) => {
          assert_true(enabled.session.remote_option_enabled(opt(31)))
          match
            enabled.session.receive(
              bytes([255, 250, 31, 0, 120, 0, 40, 255, 240]),
              session_out(8),
            ) {
            Ok(r) =>
              assert_true(
                r.session.get_window_size() ==
                Some(@telnet.WindowSize::{
                  width: (120).to_uint16(),
                  height: (40).to_uint16(),
                }),
              )
            Err(_) => assert_true(false)
          }
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}
