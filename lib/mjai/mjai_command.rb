require "optparse"
$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
require "tcp_active_game_server"
require "tcp_client_game"
require "tsumogiri_player"
require "shanten_player"
require "file_converter"
require "game_stats"


def server_url(params)  # 新たに実装
  return "mjsonp://localhost:%d/%s" % [params[:port], params[:room]]
end


def start_default_players_2(params)  # 新たに実装
  pids = []
  for command in params[:player_commands]
    command += " " + server_url(params)
    puts(command)
    pids.push(fork(){ exec(command) })
  end
end

module Mjai

    class MjaiCommand

        def self.execute(command_name, argv)

          Thread.abort_on_exception = true
          case command_name

            when "mjai"

              action = argv.shift()
              opts = OptionParser.getopts(argv, "",
                  "port:11600", "host:127.0.0.1", "room:default", "game_type:one_kyoku",
                  "games:auto", "repeat", "log_dir:", "output_type:")

              case action

                when "server"
                  $stdout.sync = true
                  player_commands = argv
                  if opts["repeat"]
                    $stderr.puts("--repeat is deprecated. Use --games=inifinite instead.")
                    exit(1)
                  end
                  case opts["games"]
                    when "auto"
                      num_games = player_commands.size == 4 ? 1 : 1.0/0.0
                    when "infinite"
                      num_games = 1.0/0.0
                    else
                      num_games = opts["games"].to_i()
                  end
                  server = TCPActiveGameServer.new({
                      :host => opts["host"],
                      :port => opts["port"].to_i(),
                      :room => opts["room"],
                      :game_type => opts["game_type"].intern,
                      :player_commands => player_commands,
                      :num_games => num_games,
                      :log_dir => opts["log_dir"],
                  })
                  server.run()
              #ここからclientというactoinを追加してclientだけを動かす様にしたい。
                when "client"
                  $stdout.sync = true
                  player_commands = argv
                  if opts["repeat"]
                    $stderr.puts("--repeat is deprecated. Use --games=inifinite instead.")
                    exit(1)
                  end
                  case opts["games"]
                    when "auto"
                      num_games = player_commands.size == 4 ? 1 : 1.0/0.0
                    when "infinite"
                      num_games = 1.0/0.0
                    else
                      num_games = opts["games"].to_i()
                  end
                  params = {
                      :host => opts["host"],
                      :port => opts["port"].to_i(),
                      :room => opts["room"],
                      :game_type => opts["game_type"].intern,
                      :player_commands => player_commands,
                      :num_games => num_games,
                      :log_dir => opts["log_dir"],
                  }
                  begin
                    start_default_players_2(params)
                  rescue puts("failed")
                  end


                when "convert"
                  conv = FileConverter.new()
                  if opts["output_type"]
                    for pattern in argv
                      paths = Dir[pattern]
                      if paths.empty?
                        $stderr.puts("No match: %s" % pattern)
                        exit(1)
                      end
                      for path in paths
                        conv.convert(path, "%s.%s" % [path, opts["output_type"]])
                      end
                    end
                  else
                    conv.convert(argv.shift(), argv.shift())
                  end

                when "stats"
                  GameStats.print(argv)

                else
                  $stderr.puts(
                      "Basic Usage:\n" +
                      "  #{$PROGRAM_NAME} server --port=PORT\n" +
                      "  #{$PROGRAM_NAME} server --port=PORT " +
                          "[PLAYER1_COMMAND] [PLAYER2_COMMAND] [...]\n" +
                      "  #{$PROGRAM_NAME} stats 1.mjson [2.mjson] [...]\n" +
                      "  #{$PROGRAM_NAME} convert hoge.mjson hoge.html\n" +
                      "  #{$PROGRAM_NAME} convert hoge.mjlog hoge.mjson\n\n" +
                      "Complete usage:\n" +
                      "  #{$PROGRAM_NAME} server \\\n" +
                      "    --host=IP_ADDRESS \\\n" +
                      "    --port=PORT \\\n" +
                      "    --room=ROOM_NAME \\\n" +
                      "    --game_type={one_kyoku|tonpu|tonnan} \\\n" +
                      "    --games={NUM_GAMES|infinite} \\\n" +
                      "    --log_dir=LOG_DIR_PATH \\\n" +
                      "    [PLAYER1_COMMAND] [PLAYER2_COMMAND] [...]\n\n" +
                      "See here for details:\n" +
                      "http://gimite.net/pukiwiki/index.php?" +
                      "Mjai%20%CB%E3%BF%FDAI%C2%D0%C0%EF%A5%B5%A1%BC%A5%D0\n")
                  exit(1)

              end

            when /^mjai-(.+)$/

              $stdout.sync = true
              $stderr.sync = true
              player_type = $1
              opts = OptionParser.getopts(argv, "", "t:", "name:")
              url = ARGV.shift()

              if !url
                $stderr.puts(
                    "Usage:\n" +
                    "  #{$PROGRAM_NAME} mjsonp://localhost:11600/default\n")
                exit(1)
              end
              case player_type
                when "tsumogiri"
                  player = TsumogiriPlayer.new()
                when "shanten"
                  player = Mjai::ShantenPlayer.new({:use_furo => opts["t"] == "f"})
                else
                  raise("should not happen")
              end
              game = TCPClientGame.new({
                  :player => player,
                  :url => url,
                  :name => opts["name"] || player_type,
              })
              game.play()

            else
              raise("should not happen")

          end

        end

    end

end
