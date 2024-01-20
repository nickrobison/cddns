module type S = sig
  type ctx
  type t
  type config [@@deriving of_yojson, show]

  val id : string
  val name : t -> string
  val start : ?ctx:ctx -> t -> unit Lwt.t
  val create : string -> config -> (Event.t option -> unit) -> t
end
