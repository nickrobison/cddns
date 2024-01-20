type t = {
  ipv4addr : Ipaddr.V4.t; [@equal Comparators.ipv4_eq]
  ipv6addr : Ipaddr.V6.t option; [@equal Comparators.ipv6_eq]
}
[@@deriving show, eq]
