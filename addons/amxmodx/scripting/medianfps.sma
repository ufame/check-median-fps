#include <amxmodx>
#include <reapi>

enum _: FpsData {
  fps_values[10],
  fps_current_index,
  Float: fps_start_time
};

new PlayerData[MAX_PLAYERS + 1][FpsData];

new hfc_max_fps;
new bool: hfc_chat_info;

public plugin_init() {
  register_plugin("Median fps", "1.0.1", "the_hunter");
  RegisterHookChain(RG_CBasePlayer_PreThink, "OnPlayerPreThink");

  register_dictionary("medianfps.txt");

  bind_pcvar_num(
    create_cvar(
      "hfc_max_fps",
      "100",
      _,
      "Maximum FPS"
    ),
    hfc_max_fps
  );

  bind_pcvar_num(
    create_cvar(
      "hfc_chat_info",
      "1",
      _,
      "Print kicked player in chat"
    ),
    hfc_chat_info
  );

  AutoExecConfig(true, "medianfps");
}

public client_connect(id) {
  ResetFpsData(id);
}

ResetFpsData(id) {
  arrayset(PlayerData[id], 0, FpsData);
  PlayerData[id][fps_current_index] = -1;
}

public OnPlayerPreThink(const id) {
  new Float: game_time = get_gametime();
  new currentIndex = PlayerData[id][fps_current_index];
 
  // Если значение current_index == -1, значит мы еще не считали фпс для этого игрока.
  if (PlayerData[id][fps_current_index] == -1) {
    PlayerData[id][fps_values][0]++;
    PlayerData[id][fps_current_index] = 0;
    PlayerData[id][fps_start_time] = game_time;
  }
  else {
    PlayerData[id][fps_values][currentIndex]++;
 
    if ((game_time - PlayerData[id][fps_start_time]) >= 1.0) {
      if (currentIndex == 9) {
        CheckMedianFPS(id);
        ResetFpsData(id);
      } else {
        PlayerData[id][fps_current_index]++;
        PlayerData[id][fps_start_time] = game_time;
      }
    }
  }
}

CheckMedianFPS(id) {
  SortIntegers(PlayerData[id][fps_values], sizeof(PlayerData[][fps_values]));

  // После сортировки массива, среднее значение фпс будет в середине массива (fps_values[5])
  // Чтобы еще больше сгладить неточности, возмем среднее значение от средних значений.
  // Т.е. (fps_values[4] + fps_values[5] + fps_values[6]) / 3 - 1
  new median_fps =
    (PlayerData[id][fps_values][4] + PlayerData[id][fps_values][5] + PlayerData[id][fps_values][6]) / 3 - 1;

  if (median_fps > hfc_max_fps) {
    server_cmd("kick #%d ^"You fps is %d. Max %d.^"", get_user_userid(id), median_fps, hfc_max_fps);

    if (hfc_chat_info)
      client_print_color(0, print_team_default, "%L", LANG_PLAYER, "MedianFps_PlayerKicked", id, hfc_max_fps);
  }
}