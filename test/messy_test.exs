defmodule MessyTest do
  use ExUnit.Case
  doctest Server

  setup_all do
    {:ok, server} = Server.start_link(self())
    {:ok, socket} = :gen_tcp.connect(String.to_charlist("127.0.0.1"), Server.port, [:binary])
    %{socket: socket, server: server}
  end

  test "send msg to server", context do
    assert :ok == :gen_tcp.send(context.socket, "hey bro")
  end

  test "register user", context do
    # Как проверять? Подумаю...
    assert GenServer.cast(context.server, {:register, 5, self()})
  end

end
