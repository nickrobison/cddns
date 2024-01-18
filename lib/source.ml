module type S = sig
  type t

  val id : string
  val name : t -> string
  val start : t -> Event.t Lwt_stream.t -> unit Lwt.t
  val create : string -> t
end
