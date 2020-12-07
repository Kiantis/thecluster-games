#include "fullinclude.lsl"

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

    if (llGetListLength(removed_acks) > 0 && item_id_is(removed_acks, ITEMID_BATTERY))
      channel_send([GIVE_POINTS, command_subject(removed_acks), 100]);
  }
  collision_start(integer num_detected) {
    channel_send([REMOVE_INVENTORY_ITEM, llDetectedKey(0), ITEMID_BATTERY]);
  }
}
