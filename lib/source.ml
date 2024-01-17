module type S = sig
  type t

  val id : string
  val name : t -> string
  val start : t -> Event.t Lwt_stream.t -> unit Lwt.t
  val create : string -> t
end

let sources : (string, (module S)) Hashtbl.t = Hashtbl.create 10
let register source name = Hashtbl.add sources name source
