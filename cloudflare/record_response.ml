type dns_record = {
  name : string;
  id : Record_id.t;
  proxied : bool;
  zone_id : Zone_id.t;
  zone_name : string;
  record_type : string; [@key "type"]
}
[@@deriving of_yojson { strict = false }, show]

type t = { result : dns_record list }
[@@deriving of_yojson { strict = false }, show]

let of_string s =
  let json = Yojson.Safe.from_string s in
  of_yojson json
