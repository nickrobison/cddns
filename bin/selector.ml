let source_of_id = function
  | "ipify" -> (module Ipify.Main.Ipify_source : Lib.Source.S)
  | _ -> raise (Invalid_argument "Unknown")

let target_of_id = function _ -> raise (Invalid_argument "Unknown")
