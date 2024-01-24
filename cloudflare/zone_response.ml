type account_record = { id : Account_id.t; name : string }
[@@deriving of_yojson, show]

type zone_record = {
  id : Zone_id.t;
  name : string;
  status : string;
  account : account_record;
}
[@@deriving of_yojson { strict = false }, show]

type t = { result : zone_record list }
[@@deriving of_yojson { strict = false }, show]

let of_string s =
  let json = Yojson.Safe.from_string s in
  of_yojson json
