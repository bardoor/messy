defmodule Server do
  @moduledoc """
  Сервер messy
  """
  use GenServer
  require Logger

  @port 12345

  def port, do: @port

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    # Открываем сокет с параметрами:
    # Ожидаемые даные - бинарные; Пакеты разделяются символом новой строки;
    # Пассивный режим; При перезапуске повторно используется адрес сокета
    {:ok, listen_socket} = :gen_tcp.listen(@port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Server listening port #{@port}")
    {:ok, Map.put(state, :listen_socket, listen_socket), {:continue, :accept}}
  end

  def handle_continue(:accept, state) do
    {:ok, socket} = :gen_tcp.accept(state.listen_socket)
    Logger.info("New connection accepted")
    {:ok, _} = ClientListener.start_link(socket, self())
    {:noreply, state, {:continue, :accept}}
  end

  def handle_cast({:register, client_id, pid}, state) do
    if Map.has_key?(state, client_id) do
      send(pid, {:error, "Given ID already exist"})
      :gen_tcp.close(pid)
      {:noreply, state}
    else
      Logger.info("Client #{client_id} connected")
      {:noreply, Map.put(state, client_id, pid)}
    end
  end

  def handle_cast({:send_message, sender_id, receiver_id, message}, state) do
    case Map.get(state, receiver_id) do
      nil ->
        sender_pid = Map.get(state, sender_id)
        if sender_pid do
          send(sender_pid, {:error, "Reciever with #{receiver_id} ID not found"})
        end
      receiver_pid ->
        send(receiver_pid, {:message, sender_id, message})
    end
    {:noreply, state}
  end

  def handle_cast({:disconnect, client_id}, state) do
    Logger.info("Client #{client_id} disconnected")
    {:noreply, Map.delete(state, client_id)}
  end
end
