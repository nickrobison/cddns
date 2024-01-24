module Make (C : Lib.Client_intf.S) : sig
  include Lib.Target_intf.S with type ctx = C.ctx
end
