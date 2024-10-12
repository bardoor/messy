defmodule ClientListener do
  use GenServer
  require Logger

  def start_link(socket, server_pid) do
    GenServer.start_link(__MODULE__, {socket, server_pid}, name: :client_handler)
  end

  def init({socket, server_pid}) do
    spawn(fn -> loop(socket, server_pid) end)
    {:ok, socket}
  end

  defp loop(socket, server_pid) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, message} ->
        handle_message(socket, message, server_pid)
        loop(socket, server_pid)
      {:error, :closed} ->
        Logger.info("Client disconnected")
        :gen_tcp.close(socket)
      {:error, reason} ->
        Logger.error("Error due handling message: #{reason}")
        :gen_tcp.close(socket)
    end
  end

  defp handle_message(socket, message, server_pid) do
    case :erlang.binary_to_term(message) do
      # Регистрация клиента
      {:register, client_id} ->
        send(server_pid, {:register, client_id, self()})

      # Отправка сообщения
      {:send_message, sender_id, receiver_id, msg} ->
        send(server_pid, {:send_message, sender_id, receiver_id, msg})

      # Отключение клиента
      {:disconnect, client_id} ->
        send(server_pid, {:disconnect, client_id})
        :gen_tcp.close(socket)

      _ ->
        Logger.warning("Unexpected message: #{message}")
    end
  end
end
