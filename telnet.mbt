// Public protocol model for a performant, transport-independent TELNET core.
//
// This file intentionally starts with data types only. The goal is to let the
// test suite lock down parser, encoder, and negotiation behavior before the
// implementation fills in executable state transitions.

///|
pub(all) enum Command {
  SE
  NOP
  DM
  BRK
  IP
  AO
  AYT
  EC
  EL
  GA
  SB
  WILL
  WONT
  DO
  DONT
  IAC
} derive(Eq, Debug)

///|
pub(all) enum NegotiationVerb {
  Will
  Wont
  Do
  Dont
} derive(Eq, Debug)

///|
pub(all) enum OptionSide {
  Local
  Remote
} derive(Eq, Debug)

///|
pub(all) enum QueueBit {
  Empty
  Opposite
} derive(Eq, Debug)

///|
pub(all) enum HalfState {
  No
  Yes
  WantNo(QueueBit)
  WantYes(QueueBit)
} derive(Eq, Debug)

///|
pub(all) struct OptionCode {
  value : Byte
} derive(Eq, Debug)

///|
pub(all) enum KnownOption {
  Binary
  Echo
  Reconnection
  SuppressGoAhead
  ApproxMessageSizeNegotiation
  Status
  TimingMark
  RemoteControlledTransAndEcho
  OutputLineWidth
  OutputPageSize
  OutputCarriageReturnDisposition
  OutputHorizontalTabStops
  OutputHorizontalTabDisposition
  OutputFormfeedDisposition
  OutputVerticalTabStops
  OutputVerticalTabDisposition
  OutputLinefeedDisposition
  ExtendedAscii
  Logout
  ByteMacro
  DataEntryTerminal
  Supdup
  SupdupOutput
  SendLocation
  TerminalType
  EndOfRecord
  TacacsUserIdentification
  OutputMarking
  TerminalLocationNumber
  Telnet3270Regime
  X3Pad
  Naws
  TerminalSpeed
  RemoteFlowControl
  Linemode
  XDisplayLocation
  Environment
  Authentication
  Encryption
  NewEnvironment
  Tn3270e
  Xauth
  Charset
  TelnetRemoteSerialPort
  ComPortControl
  TelnetSuppressLocalEcho
  TelnetStartTls
  KerberosV5
  SendUrl
  ForwardX
  ExtendedOptionsList
  Unknown(OptionCode)
} derive(Eq, Debug)

///|
pub(all) struct ByteSpan {
  bytes : Bytes
  start : Int
  length : Int
} derive(Eq, Debug)

///|
pub(all) struct DataEvent {
  span : ByteSpan
} derive(Eq, Debug)

///|
pub(all) struct CommandEvent {
  command : Command
} derive(Eq, Debug)

///|
pub(all) struct NegotiationEvent {
  verb : NegotiationVerb
  option : OptionCode
} derive(Eq, Debug)

///|
pub(all) struct SubnegotiationEvent {
  option : OptionCode
  payload : ByteSpan
} derive(Eq, Debug)

///|
pub(all) enum TelnetErrorKind {
  IncompleteIac
  IncompleteNegotiation
  IncompleteSubnegotiation
  InvalidCommandByte
  InvalidOptionByte
  SubnegotiationTooLarge
  UnexpectedSubnegotiationEnd
  PolicyRejected
  UnsupportedOption
} derive(Eq, Debug)

///|
pub(all) struct TelnetError {
  kind : TelnetErrorKind
  offset : Int
  byte : Byte?
  option : OptionCode?
} derive(Eq, Debug)

///|
pub(all) enum Event {
  Data(DataEvent)
  Command(CommandEvent)
  Negotiation(NegotiationEvent)
  Subnegotiation(SubnegotiationEvent)
  Error(TelnetError)
} derive(Eq, Debug)

///|
pub(all) enum ParserMode {
  Normal
  AfterIac
  AfterNegotiationVerb(NegotiationVerb)
  AfterSubnegotiationStart
  InSubnegotiation(OptionCode)
  InSubnegotiationAfterIac(OptionCode)
} derive(Eq, Debug)

///|
pub(all) enum CrPolicy {
  Preserve
  ValidateNvt
  NormalizeToLf
} derive(Eq, Debug)

///|
pub(all) enum DataCoalescing {
  EmitImmediately
  CoalesceUntilCommand
  CoalesceUntilCapacity
} derive(Eq, Debug)

///|
pub(all) struct ParserConfig {
  max_data_chunk_bytes : Int
  max_subnegotiation_bytes : Int
  cr_policy : CrPolicy
  data_coalescing : DataCoalescing
  strict_commands : Bool
} derive(Eq, Debug)

///|
pub(all) struct ParserCheckpoint {
  mode : ParserMode
  absolute_offset : Int
  buffered_data_length : Int
  buffered_subnegotiation_length : Int
} derive(Eq, Debug)

///|
pub(all) struct ParserState {
  config : ParserConfig
  checkpoint : ParserCheckpoint
} derive(Eq, Debug)

///|
pub(all) enum EncodeItem {
  RawData(ByteSpan)
  EscapedData(ByteSpan)
  Command(Command)
  Negotiation(NegotiationEvent)
  Subnegotiation(SubnegotiationEvent)
} derive(Eq, Debug)

///|
pub(all) enum EncodeErrorKind {
  CommandRequiresIacEscape
  InvalidSubnegotiationPayload
  OutputBufferTooSmall
  UnsupportedEncoding
} derive(Eq, Debug)

///|
pub(all) struct EncodeError {
  kind : EncodeErrorKind
  offset : Int
  required_capacity : Int
} derive(Eq, Debug)

///|
pub(all) enum BufferOwnership {
  BorrowedInput
  Copied
  Scratch
} derive(Eq, Debug)

///|
pub(all) struct BufferSlice {
  span : ByteSpan
  ownership : BufferOwnership
} derive(Eq, Debug)

///|
pub(all) struct OptionHalf {
  option : OptionCode
  side : OptionSide
  state : HalfState
} derive(Eq, Debug)

///|
pub(all) struct OptionState {
  option : OptionCode
  local_state : HalfState
  remote_state : HalfState
} derive(Eq, Debug)

///|
pub(all) enum PolicyDecision {
  Accept
  Reject
  Ignore
} derive(Eq, Debug)

///|
pub(all) struct PolicyQuestion {
  side : OptionSide
  option : OptionCode
  requested_by_peer : Bool
} derive(Eq, Debug)

///|
pub(all) enum NegotiationAction {
  Send(NegotiationEvent)
  MarkEnabled(OptionSide, OptionCode)
  MarkDisabled(OptionSide, OptionCode)
  NotifyApplication(OptionState)
  NoAction
} derive(Eq, Debug)

///|
pub(all) struct NegotiationTransition {
  before : OptionState
  input : NegotiationEvent
  decision : PolicyDecision
  after : OptionState
  actions : Array[NegotiationAction]
} derive(Eq, Debug)

///|
pub(all) enum TerminalTypeMessage {
  Send
  Is(String)
} derive(Eq, Debug)

///|
pub(all) struct NawsSize {
  columns : UInt16
  rows : UInt16
} derive(Eq, Debug)

///|
pub(all) enum EnvironmentVariableKind {
  Var
  UserVar
} derive(Eq, Debug)

///|
pub(all) struct EnvironmentVariable {
  kind : EnvironmentVariableKind
  name : String
  value : String?
} derive(Eq, Debug)

///|
pub(all) enum EnvironmentMessage {
  Is(Array[EnvironmentVariable])
  Send(Array[String])
  Info(Array[EnvironmentVariable])
} derive(Eq, Debug)

///|
pub(all) enum CharsetMessage {
  Request(Array[String])
  Accepted(String)
  Rejected
  TTableIs(String)
  TTableRejected
  TTableAck
  TTableNak
} derive(Eq, Debug)

///|
pub(all) enum LinemodeModeFlag {
  Edit
  TrapSig
  ModeAck
  SoftTab
  LitEcho
} derive(Eq, Debug)

///|
pub(all) struct LinemodeMode {
  flags : Array[LinemodeModeFlag]
} derive(Eq, Debug)

///|
pub(all) enum LinemodeForwardMask {
  Default
  None
  Bytes(ByteSpan)
} derive(Eq, Debug)

///|
pub(all) enum LinemodeMessage {
  Mode(LinemodeMode)
  ForwardMask(LinemodeForwardMask)
  Slc(ByteSpan)
} derive(Eq, Debug)

///|
pub(all) enum StartTlsMessage {
  StartTls
  Follows
} derive(Eq, Debug)

///|
pub(all) enum OptionPayload {
  Empty
  Raw(OptionCode, ByteSpan)
  TerminalType(TerminalTypeMessage)
  Naws(NawsSize)
  Environment(EnvironmentMessage)
  Charset(CharsetMessage)
  Linemode(LinemodeMessage)
  StartTls(StartTlsMessage)
} derive(Eq, Debug)
