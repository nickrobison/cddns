let ipv6_eq a b =
  match (a, b) with
  | Some a, Some b -> Ipaddr.V6.compare a b == 0
  | Some _, None -> false
  | None, Some _ -> false
  | None, None -> true

let ipv4_eq a b = Ipaddr.V4.compare a b == 0
