let duration_of_yojson = function
  | `Int i -> Ok (Duration.of_sec i)
  | `Float f -> Ok (Duration.of_f f)
  | _ -> Error "Unexpected duration format"

let ipaddr_v4_of_yojson json =
  match json with
  | `String s -> (
      match Ipaddr.V4.of_string s with
      | Ok i -> Ok i
      | Error (`Msg str) -> Error str)
  | _ -> Error "Unexpected IP address format"

let ipaddr_v4_to_yojson t = `String (Ipaddr.V4.to_string t)
