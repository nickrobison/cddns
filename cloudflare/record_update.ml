type t = {
  content : Ipaddr.V4.t; [@to_yojson Lib.Converters.ipaddr_v4_to_yojson]
  name : string;
  record_type : string; [@key "type"]
}
[@@deriving show, to_yojson]

let to_string t = Yojson.Safe.to_string (to_yojson t)

let of_record name (record : Lib.Record.t) =
  { content = record.ipv4addr; name; record_type = "A" }
