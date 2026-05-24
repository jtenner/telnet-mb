// Public API skeleton for the TELNET implementation.
//
// Bodies intentionally use `...` placeholders. This file defines the API
// contract that behavioral tests and production code will fill in next.

///|
pub(all) struct Parser {
  config : ParserConfig
  checkpoint : ParserCheckpoint
} derive(Eq, Debug)

///|
pub(all) struct ParserFeedResult {
  parser : Parser
  events : Array[Event]
  bytes_consumed : Int
} derive(Eq, Debug)

///|
pub(all) struct ParserFinishResult {
  parser : Parser
  events : Array[Event]
  complete : Bool
} derive(Eq, Debug)

///|
pub fn Parser::default_config() -> ParserConfig {
  ...
}

///|
pub fn Parser::new(config : ParserConfig) -> Parser {
  ...
}

///|
pub fn Parser::default() -> Parser {
  ...
}

///|
pub fn Parser::feed(self : Parser, chunk : Bytes) -> ParserFeedResult {
  ...
}

///|
pub fn Parser::feed_span(self : Parser, span : ByteSpan) -> ParserFeedResult {
  ...
}

///|
pub fn Parser::finish(self : Parser) -> ParserFinishResult {
  ...
}

///|
pub fn Parser::checkpoint(self : Parser) -> ParserCheckpoint {
  ...
}

///|
pub fn Parser::restore(
  config : ParserConfig,
  checkpoint : ParserCheckpoint,
) -> Parser {
  ...
}

///|
pub fn Parser::reset(self : Parser) -> Parser {
  ...
}

///|
pub fn Parser::with_config(self : Parser, config : ParserConfig) -> Parser {
  ...
}

///|
pub(all) struct Encoder {
  canonical : Bool
} derive(Eq, Debug)

///|
pub(all) struct EncodeResult {
  bytes_written : Int
  required_capacity : Int
} derive(Eq, Debug)

///|
pub fn Encoder::new() -> Encoder {
  ...
}

///|
pub fn Encoder::canonical() -> Encoder {
  ...
}

///|
pub fn Encoder::required_capacity(self : Encoder, item : EncodeItem) -> Int {
  ...
}

///|
pub fn Encoder::encode_item(
  self : Encoder,
  item : EncodeItem,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn Encoder::encode_data(
  self : Encoder,
  data : ByteSpan,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn Encoder::encode_command(
  self : Encoder,
  command : Command,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn Encoder::encode_negotiation(
  self : Encoder,
  event : NegotiationEvent,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn Encoder::encode_subnegotiation(
  self : Encoder,
  event : SubnegotiationEvent,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub(all) struct Negotiator {
  states : Array[OptionState]
} derive(Eq, Debug)

///|
pub fn Negotiator::new() -> Negotiator {
  ...
}

///|
pub fn Negotiator::with_states(states : Array[OptionState]) -> Negotiator {
  ...
}

///|
pub fn Negotiator::receive(
  self : Negotiator,
  input : NegotiationEvent,
  decision : PolicyDecision,
) -> NegotiationTransition {
  ...
}

///|
pub fn Negotiator::request(
  self : Negotiator,
  option : OptionCode,
  side : OptionSide,
  enable : Bool,
) -> NegotiationTransition {
  ...
}

///|
pub fn Negotiator::state_for(
  self : Negotiator,
  option : OptionCode,
) -> OptionState {
  ...
}

///|
pub fn Negotiator::apply(
  self : Negotiator,
  transition : NegotiationTransition,
) -> Negotiator {
  ...
}

///|
pub fn Command::from_byte(byte : Byte) -> Command? {
  ...
}

///|
pub fn Command::to_byte(self : Command) -> Byte {
  ...
}

///|
pub fn NegotiationVerb::from_command(command : Command) -> NegotiationVerb? {
  ...
}

///|
pub fn NegotiationVerb::to_command(self : NegotiationVerb) -> Command {
  ...
}

///|
pub fn OptionCode::new(byte : Byte) -> OptionCode {
  ...
}

///|
pub fn OptionCode::to_byte(self : OptionCode) -> Byte {
  ...
}

///|
pub fn KnownOption::from_code(code : OptionCode) -> KnownOption {
  ...
}

///|
pub fn KnownOption::to_code(self : KnownOption) -> OptionCode {
  ...
}

///|
pub fn ByteSpan::new(bytes : Bytes, start : Int, length : Int) -> ByteSpan {
  ...
}

///|
pub fn ByteSpan::is_empty(self : ByteSpan) -> Bool {
  ...
}

///|
pub fn ByteSpan::to_bytes(self : ByteSpan) -> Bytes {
  ...
}

///|
pub fn OptionPayload::decode(
  option : OptionCode,
  payload : ByteSpan,
) -> Result[OptionPayload, TelnetError] {
  ...
}

///|
pub fn OptionPayload::encode(
  payload : OptionPayload,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn OptionPayload::required_capacity(payload : OptionPayload) -> Int {
  ...
}

///|
pub fn TerminalTypeMessage::decode(
  payload : ByteSpan,
) -> Result[TerminalTypeMessage, TelnetError] {
  ...
}

///|
pub fn TerminalTypeMessage::encode(
  message : TerminalTypeMessage,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn NawsSize::decode(payload : ByteSpan) -> Result[NawsSize, TelnetError] {
  ...
}

///|
pub fn NawsSize::encode(
  size : NawsSize,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn EnvironmentMessage::decode(
  payload : ByteSpan,
) -> Result[EnvironmentMessage, TelnetError] {
  ...
}

///|
pub fn EnvironmentMessage::encode(
  message : EnvironmentMessage,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn CharsetMessage::decode(
  payload : ByteSpan,
) -> Result[CharsetMessage, TelnetError] {
  ...
}

///|
pub fn CharsetMessage::encode(
  message : CharsetMessage,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn LinemodeMessage::decode(
  payload : ByteSpan,
) -> Result[LinemodeMessage, TelnetError] {
  ...
}

///|
pub fn LinemodeMessage::encode(
  message : LinemodeMessage,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}

///|
pub fn StartTlsMessage::decode(
  payload : ByteSpan,
) -> Result[StartTlsMessage, TelnetError] {
  ...
}

///|
pub fn StartTlsMessage::encode(
  message : StartTlsMessage,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  ...
}
