type source = { id : string; name : string; config : Yojson.Safe.t }
[@@deriving of_yojson, show]

type target = { id : string; name : string; config : Yojson.Safe.t }
[@@deriving of_yojson, show]

type t = { source : source; targets : target list } [@@deriving of_yojson, show]
