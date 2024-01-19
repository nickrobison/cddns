let source_of_id = function
  | "ipify" ->
      (module Ipify.Source.Make (Cohttp_lwt_unix.Client) : Lib.Source_intf.S)
  | _ -> raise (Invalid_argument "Unknown")

let target_of_id = function
  | "logging" -> (module Lib.Logging_target : Lib.Target_intf.S)
  | _ -> raise (Invalid_argument "Unknown")
