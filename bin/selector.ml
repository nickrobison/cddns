open Lib
module C = Client.Make (Cohttp_lwt_unix.Client)

let source_of_id = function
  | "ipify" ->
      (module Ipify.Source.Make (Cohttp_lwt_unix.Client) (Time) : Source_intf.S)
  | _ -> raise (Invalid_argument "Unknown")

let target_of_id = function
  | "logging" -> (module Logging_target : Lib.Target_intf.S)
  | "cloudflare.dns" -> (module Cloudflare.Dns_target.Make (C))
  | id -> raise (Exceptions.Unkown_target id)
