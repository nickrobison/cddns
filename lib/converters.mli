val duration_of_yojson : Yojson.Safe.t -> (Duration.t, string) result
val ipaddr_v4_of_yojson : Yojson.Safe.t -> (Ipaddr.V4.t, string) result
val ipaddr_v4_to_yojson : Ipaddr.V4.t -> Yojson.Safe.t
