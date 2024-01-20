let duration_of_yojson = function
  | `Int i -> Ok (Duration.of_sec i)
  | `Float f -> Ok (Duration.of_f f)
  | _ -> Error "Unexpected duration format"
