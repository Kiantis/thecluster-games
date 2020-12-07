#include "fullinclude.lsl"

integer DAY = 86400;
integer last_given_timestamp;

default {
  state_entry() {
    init_identify_script(INIT_ID_KIOSK); // or INIT_ID_AVATAR
    secret_read();
    channel_listen();
    inventory_changed();
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
  collision_start(integer num_detected) {
    integer now = llGetUnixTime();
    if (now - last_given_timestamp < DAY) {
      llSay(0, "Remaining seconds for regeneration: "+(string)(DAY - (now - last_given_timestamp)));
      return;
    }
    key k = llDetectedKey(0);
    channel_send([GIVE_INVENTORY_ITEM, k, ITEMID_BATTERY]);
    last_given_timestamp = llGetUnixTime();
  }
}
