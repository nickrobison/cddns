module type S = sig
  type t
  type config [@@deriving of_yojson]
  type ctx

  val id : string
  val name : t -> string
  val create : config -> string -> Event.t Lwt_stream.t -> t
  val run : ?ctx:ctx -> t -> unit Lwt.t
end
