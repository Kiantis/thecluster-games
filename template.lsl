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
    list removed = inventory_remove_check(channel, name, id, message);
    list added_acks = inventory_receive_ackd(channel, name, id, message);
    list removed_acks = inventory_remove_ackd(channel, name, id, message);
  }
}
