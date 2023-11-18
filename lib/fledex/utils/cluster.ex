defmodule Fledex.Utils.Cluster do
  # def create_cluster(config) do
  #   with
  #     # iex(1)> Node.self()
  #     # :nonode@nohost
  #     {:first_cluster_node_check, false} <- {:first_cluster_node_check, cluster_node?(config.node_name)},
  #     # iex(2)> Node.start(:"maze2@127.0.0.1")
  #     # {:ok, #PID<0.271.0>}
  #     {:start_node, {:ok, _pid}} <- {:start_node, Node.start(config.node_name)},
  #     # iex(maze2@127.0.0.1)3> Node.self()
  #     # :"maze2@127.0.0.1"
  #     {:second_cluster_node_check, true} = {:second_cluster_node_check, cluster_node?(config.node_name)},
  #     # iex(maze2@127.0.0.1)4> Node.connect(:"coyzsh3v-livebook@127.0.0.1")
  #     # false
  #     # iex(maze2@127.0.0.1)5> Node.set_cookie(:"c_lW7yE9bRtzcvhJ1JrWgIGjR-pugilBNZ1sGKFCvSH6iFQ-qeRVlw")
  #     # true
  #     true <- Node.set_cookie(config.node_cookie)
  #     # iex(maze2@127.0.0.1)6> Node.connect(:"coyzsh3v-livebook@127.0.0.1")
  #     # true
  #   do
  #     Node.connect(config.other_node)
  #   # else:
  #   #   something -> raise RuntimeError, message: "something went wrong #{inspect something}"
  #   end
  # end

  # defp cluster_node?(node_name) do
  #   case Node.self() do
  #     :nonode@nohost -> false
  #     ^node_name -> true
  #     _ -> raise ArgumentError, message: "node already running with another name?"
  #   end
  # end
end
