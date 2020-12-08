debug(string message) {
  //llOwnerSay(message);
}

// ============================================================================

integer COMMANDS_CHANGE_CHANNEL = 1;

integer GIVE_INVENTORY_ITEM = 10;
integer GIVE_INVENTORY_ITEM_ACK = 11;
integer REMOVE_INVENTORY_ITEM = 20;
integer REMOVE_INVENTORY_ITEM_ACK = 21;

integer GIVE_POINTS = 30;
integer GIVE_POINTS_ACK = 31;

// ============================================================================
list itemDescriptions = [
  "Battery",
  "Scraps",
  "Processor unit"
];
// ============================================================================

string secret_secret;
string secret_secretNotecardId;
secret_read() {
  secret_secretNotecardId = llGetNotecardLine("SECRET", 0);
}

integer secret_valid(string secret) {
  if (secret_secret == "")
    return FALSE;
  if (secret_secret == secret)
    return TRUE;
  return FALSE;
}

integer secret_dataserver_callback(key query_id, string data) {
  if (query_id != secret_secretNotecardId)
    return FALSE;

  secret_secret = data;
  init_check();
  return TRUE;
}

// ============================================================================

integer channel_listen_handle;
integer channel_listen_channel = -2343487;

channel_send(list command) {
  if (secret_secret == "")
    return;
  llSay(channel_listen_channel, llDumpList2String([secret_secret] + command, ","));
}

integer item_id_is(list command, string item_id) {
  return llGetListLength(command) > 0 && llList2String(command, 1) == item_id;
}

key command_subject(list command) {
  return llList2Key(command, 0);
}

channel_listen() {
  channel_listen_handle = llListen(channel_listen_channel, "", "", "");
}

channel_change(integer channel, string name, key id, string smessage) {
  if (channel != channel_listen_channel)
    return;
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return;

  integer command = llList2Integer(message, 1);
  if (command != COMMANDS_CHANGE_CHANNEL)
    return;

  integer new_channel = llList2Integer(message, 2);
  if (new_channel != 0) {
    channel_listen_channel = new_channel;
    llListenRemove(channel_listen_handle);
    channel_listen_handle = llListen(channel_listen_channel, "", "", "");
  }
}

// ============================================================================

integer INIT_ID_KIOSK = 1;
integer INIT_ID_AVATAR = 2;

integer init_identification;

integer init_is_kiosk() {
  return init_identification == INIT_ID_KIOSK;
}

integer init_is_avatar() {
  return init_identification == INIT_ID_AVATAR;
}

init_check() {
  if (secret_secret == "")
    return;
  if (init_identification == 0)
    return;

  debug("Initialization complete.");
}

init_identify_script(integer id) {
  init_identification = id;
  init_check();
}

// ============================================================================

integer inventory_points;
list inventory_names;

list inventory_receive_check(integer channel, string name, key id, string smessage) {
  if (!init_is_avatar())
    return [];
  if (channel != channel_listen_channel)
    return [];
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return [];

  integer command = llList2Integer(message, 1);
  if (command != GIVE_INVENTORY_ITEM)
    return [];
  
  key destinationKey = llList2Key(message, 2);
  if (llGetOwner() != destinationKey)
    return [];

  string itemCode = llList2String(message, 3);
  inventory_names = inventory_names + [itemCode];
  channel_send([GIVE_INVENTORY_ITEM_ACK, llGetOwner(), itemCode]);
  inventory_changed();

  return [destinationKey, itemCode];
}

list inventory_points_receive_check(integer channel, string name, key id, string smessage) {
  if (!init_is_avatar())
    return [];
  if (channel != channel_listen_channel)
    return [];
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return [];

  integer command = llList2Integer(message, 1);
  if (command != GIVE_POINTS)
    return [];
  
  key destinationKey = llList2Key(message, 2);
  if (llGetOwner() != destinationKey)
    return [];

  integer points = llList2Integer(message, 3);
  inventory_points = inventory_points + points;
  channel_send([GIVE_POINTS_ACK, llGetOwner(), points]);
  inventory_changed();

  return [destinationKey, inventory_points];
}

list inventory_remove_check(integer channel, string name, key id, string smessage) {
  if (!init_is_avatar())
    return [];
  if (channel != channel_listen_channel)
    return [];
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return [];

  integer command = llList2Integer(message, 1);
  if (command != REMOVE_INVENTORY_ITEM)
    return [];
  
  key destinationKey = llList2Key(message, 2);
  if (llGetOwner() != destinationKey)
    return [];

  string itemCode = llList2String(message, 3);
  integer idx = llListFindList(inventory_names, [itemCode]);
  if (idx == -1)
    return [];

  inventory_names = llDeleteSubList(inventory_names, idx, idx);
  channel_send([REMOVE_INVENTORY_ITEM_ACK, llGetOwner(), itemCode]);
  inventory_changed();

  return [destinationKey, itemCode];
}

list inventory_points_receive_ackd(integer channel, string name, key id, string smessage) {
  if (init_is_avatar())
    return [];
  if (channel != channel_listen_channel)
    return [];
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return [];

  integer command = llList2Integer(message, 1);
  if (command != GIVE_POINTS_ACK)
    return [];
  
  key destinationKey = llList2Key(message, 2);
  integer points = llList2Integer(message, 3);
  return [destinationKey, points];
}

list inventory_receive_ackd(integer channel, string name, key id, string smessage) {
  if (init_is_avatar())
    return [];
  if (channel != channel_listen_channel)
    return [];
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return [];

  integer command = llList2Integer(message, 1);
  if (command != GIVE_INVENTORY_ITEM_ACK)
    return [];
  
  key destinationKey = llList2Key(message, 2);
  string itemCode = llList2String(message, 3);
  return [destinationKey, itemCode];
}

list inventory_remove_ackd(integer channel, string name, key id, string smessage) {
  if (init_is_avatar())
    return [];
  if (channel != channel_listen_channel)
    return [];
  
  list message = llParseString2List(smessage, [","], []);
  string secret = llList2String(message, 0);
  if (!secret_valid(secret))
    return [];

  integer command = llList2Integer(message, 1);
  if (command != REMOVE_INVENTORY_ITEM_ACK)
    return [];
  
  key destinationKey = llList2Key(message, 2);
  string itemCode = llList2String(message, 3);
  return [destinationKey, itemCode];
}

reset_game() {
  inventory_points = 0;
  inventory_names = [];
  inventory_changed();
  llOwnerSay("Game was reset");
}

inventory_changed() {
  string message;
  debug("Inventory changed");

  if (init_is_avatar())
    message = message + "Points: "+(string)(inventory_points)+"\n";

  integer list_len = llGetListLength(inventory_names);
  if (list_len != 0)
    message = message + "Inventory: " + llDumpList2String(inventory_names, ", ");

  llSetText(message, <1.0, 1.0, 1.0>, 1.0);
}
