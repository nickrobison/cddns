module type S = sig
  type t

  val id : string
  val name : t -> string
  val start : t -> unit Lwt.t
  val create : string -> Duration.t -> (Event.t option -> unit) -> t
end
