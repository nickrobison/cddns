type t = {
  content : Ipaddr.V4.t; [@to_yojson Lib.Converters.ipaddr_v4_to_yojson]
  name : string;
  record_type : string; [@key "type"]
}
[@@deriving show, to_yojson]

let to_string t = Yojson.Safe.to_string (to_yojson t)

let of_dns (dns : Record_response.dns_record) (update : Lib.Record.t) : t =
  { content = update.ipv4addr; name = dns.name; record_type = dns.record_type }
