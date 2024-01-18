module type S = sig
  type t
  type config

  val id : string
  val name : t -> string
  val config_of_yojson : Yojson.Safe.t -> config
  val create : config -> string -> Event.t Lwt_stream.t -> t
  val run : t -> unit Lwt.t
end
