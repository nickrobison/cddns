let duration_ofyojson json =
  match json with
  | `Int sec -> Ok (Duration.of_sec sec)
  | `Float sec -> Ok (Duration.of_f sec)
  | _o -> Error "Unspected type"

type source = {
  id : string;
  name : string;
  refresh : Duration.t; [@of_yojson duration_ofyojson]
}
[@@deriving of_yojson, show]

type target = { id : string; name : string; config : Yojson.Safe.t }
[@@deriving of_yojson, show]

type t = { source : source; targets : target list } [@@deriving of_yojson, show]
