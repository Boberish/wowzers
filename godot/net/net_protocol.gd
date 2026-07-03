## NetProtocol — the wire format for Rift online (R2). JSON text frames over
## WebSocket; every message is a Dictionary with "t" = type. Tiny by design:
## lockstep streams INPUTS, not state (see RAID-PLAN.md §R2).
##
## client -> server:  hello{name,ver} · join{room,name} · claim{seat} · unclaim{}
##                    aspect{aspect} · ready{on} · boss{enc} (host) · start{}
##                    mapstart{} (host — MAP-3b) · node{id} (leader) · choice{i} (leader)
##                    pick{id} (online boons: this seat's drafted boon) · input{action} · leave{}
## server -> client:  welcome{id,ver} · err{msg} · room{...lobby snapshot incl enc...}
##                    start{spec, you} · f{n, in:[[seat_i,action]..], cs?, ai?:[seat_i..]}
##                    end{won,n} · bye{msg}
##                    map{...campaign snapshot incl seed...} · mapstop{title,body,choices,accent}
##                    draft{} (online boons: pick a boon now) · campaign{won}
class_name NetProtocol
extends RefCounted

const VERSION := 10     # v10: ONLINE PRIOR — the claim msg carries the client's 📁 Prior tier; the server trusts it and folds it into each seat's check floor + starting ⚡
const DEFAULT_PORT := 9077
const DEFAULT_ROOM := "RIFT"

static func encode(msg: Dictionary) -> PackedByteArray:
	return JSON.stringify(msg).to_utf8_buffer()

static func decode(pkt: PackedByteArray) -> Dictionary:
	var v = JSON.parse_string(pkt.get_string_from_utf8())
	return v if v is Dictionary else {}
