## NetProtocol — the wire format for Rift online (R2). JSON text frames over
## WebSocket; every message is a Dictionary with "t" = type. Tiny by design:
## lockstep streams INPUTS, not state (see RAID-PLAN.md §R2).
##
## client -> server:  hello{name,ver} · join{room,name} · claim{seat} · unclaim{}
##                    aspect{aspect} · ready{on} · boss{enc} (host) · start{}
##                    input{action} · leave{}
## server -> client:  welcome{id,ver} · err{msg} · room{...lobby snapshot incl enc...}
##                    start{spec, you} · f{n, in:[[seat_i,action]..], cs?, ai?:[seat_i..]}
##                    end{won,n} · bye{msg}
class_name NetProtocol
extends RefCounted

const VERSION := 2      # v2: lobby Seal (boss) selection — spec carries `enc`
const DEFAULT_PORT := 9077
const DEFAULT_ROOM := "RIFT"

static func encode(msg: Dictionary) -> PackedByteArray:
	return JSON.stringify(msg).to_utf8_buffer()

static func decode(pkt: PackedByteArray) -> Dictionary:
	var v = JSON.parse_string(pkt.get_string_from_utf8())
	return v if v is Dictionary else {}
