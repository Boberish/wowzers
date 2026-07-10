## NetProtocol — the wire format for Rift online (R2). JSON text frames over
## WebSocket; every message is a Dictionary with "t" = type. Tiny by design:
## lockstep streams INPUTS, not state (see RAID-PLAN.md §R2).
##
## client -> server:  join{room,name,ver} · claim{seat} · unclaim{}
##                    aspect{aspect} · class{cls} · ready{on} · boss{enc} (host) · start{}
##                    mapstart{} (host — MAP-3b) · node{id} (leader) · choice{i} (leader)
##                    arm{...} · pick{id} (online boons: this seat's drafted boon) ·
##                    input{action} · leave{}
## server -> client:  welcome{id,ver} · err{msg} · room{...lobby snapshot incl enc...}
##                    start{spec, you} · f{n, in:[[seat_i,action]..], cs?, ai?:[seat_i..]}
##                    end{won,n,cause} · arming{...}
##                    map{...campaign snapshot incl seed...} · mapstop{title,body,choices,accent}
##                    draft{} (online boons: pick a boon now) · campaign{won}
class_name NetProtocol
extends RefCounted

const VERSION := 13     # v13: THE PURGE — Voidcaller/Mender/Reckoner deleted; caster=Alchemist, healer=Well(default)/Bloomweaver; gates gone. v12: blade class toggle (dead). v11: THE KILL SWITCH — ⏻ charge + OVERCLOCK arm/cash-out at a Seal
const DEFAULT_PORT := 9077
const DEFAULT_ROOM := "RIFT"

static func encode(msg: Dictionary) -> PackedByteArray:
	return JSON.stringify(msg).to_utf8_buffer()

static func decode(pkt: PackedByteArray) -> Dictionary:
	var v = JSON.parse_string(pkt.get_string_from_utf8())
	return v if v is Dictionary else {}
