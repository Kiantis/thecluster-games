#include "fullinclude.lsl"

integer flying = FALSE;
vector pos;

default {
  state_entry() {
    init_identify_script(INIT_ID_AVATAR);
    secret_read();
    channel_listen();
    inventory_changed();
    llSetTimerEvent(1);
    pos = llGetPos();
  }
  dataserver(key queryid, string data) {
    secret_dataserver_callback(queryid, data);
  }
  listen(integer channel, string name, key id, string message) {
    channel_change(channel, name, id, message);
    list added = inventory_receive_check(channel, name, id, message);
    list points_added = inventory_points_receive_check(channel, name, id, message);
    list removed = inventory_remove_check(channel, name, id, message);
    list added_acks = inventory_receive_ackd(channel, name, id, message);
    list points_added_acks = inventory_points_receive_ackd(channel, name, id, message);
    list removed_acks = inventory_remove_ackd(channel, name, id, message);
  }
  on_rez(integer start_param) {
    reset_game();
    pos = llGetPos();
  }
  attach(key id) {
    reset_game();
    pos = llGetPos();
  }
  changed(integer change) {
    if (change & CHANGED_TELEPORT)
      reset_game();
  }
  timer() {
    integer flystatus = llGetAgentInfo(llGetOwner()) & AGENT_FLYING;
    if (!flying && flystatus)
      reset_game();
    flying = flystatus;

    vector newpos = llGetPos();
    float distance = llVecDist(pos, newpos);
    if (distance > 15)
      reset_game();
    pos = newpos;
  }
}
