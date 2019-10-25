  defmodule Actor do
    @moduledoc false
    use GenServer, restart: :transient
      #client
      def start_link(algorithm) do
        GenServer.start_link(__MODULE__, algorithm)
      end

      def configure_node(pid, input_neighbors, input_state, input_weight) do
        GenServer.cast(pid, {:configure_node, List.delete(input_neighbors,self()), input_state, input_weight})
      end

      def receive_msg(pid, message) do
        GenServer.cast(pid, {:receive_msg, message})
      end


      def send_message(pid) do
        GenServer.cast(pid, {:send_message})
      end

      def push_sum_receive(pid, new_state, new_weight) do
        GenServer.cast(pid, {:push_sum_receive, new_state, new_weight})
      end



      def update_neighbors(pid) do
        GenServer.cast(pid, {:update_neighbors})

      end

      #server initially 0 to all
      def init(algorithm) do
        {:ok, {0,[],algorithm,0,0,""}} #number of messages, neighbors, algorithm, i=n, weight
      end

      def handle_cast({:configure_node, input_neighbors, input_state, input_weight}, {count,_neighbors,algorithm,_state,_weight,message}) do
                IO.puts("in configure #{inspect([self(), input_neighbors,input_state,input_weight])}")
        {:noreply, {count,input_neighbors,algorithm,input_state,input_weight,message}}
      end

      def handle_cast({:receive_msg, new_message}, {count,neighbors,algorithm,state,weight,_message}) do
        :global.sync()
        pid=:global.whereis_name(:GossipTest)
          # IO.inspect([self(),count,neighbors,algorithm,state,weight,new_message])
          #IO.puts("#{inspect neighbors}")
        if count ==30 do
          #IO.puts("************************************#{inspect self()}")
          send pid,{:output,"gossip"}
          {:noreply, {count+1,neighbors,algorithm,state,weight,new_message}}
        else
            if count ==0 do
             #send
             if length(neighbors) !=0 do
              send_message(Enum.random(neighbors))
              stop(100)
              end
           end

            {:noreply, {count+1,neighbors,algorithm,state,weight,new_message}}
        end
      end

      def stop(time) do
        Process.send_after(self(),:start,time)
      end
      def handle_cast({:send_message}, {count,neighbors,algorithm,state,weight,message}) do
        receive_msg(self(), message)
        {:noreply, {count,neighbors,algorithm,state,weight,message}}
      end

      def handle_info(:start, {count,neighbors,algorithm,state,weight,message}) do
      if  count <30 do
        send_message(Enum.random(neighbors))
        end
          stop(100)
        {:noreply, {count,neighbors,algorithm,state,weight,message}}
      end

      def handle_cast({:push_sum_receive, new_state, new_weight}, {count,neighbors,algorithm,state,weight,message}) do
        cond do
          length(neighbors)<=1 and count==3  ->
          :global.sync()
         parent=:global.whereis_name(:GossipTest)
          send parent,{:output,"pushsum"}
          {:noreply,{count,neighbors,algorithm,state,weight,message}}

          count ==3  ->
           if length(neighbors) !=0 do
              for i <- 0.. length(neighbors)-1 do
              IO.puts("inside for #{inspect self()} #{inspect Enum.at(neighbors,i)}" )
                pid= Enum.at(neighbors,i)
                if !is_nil(pid) do
                  #IO.inspect pid
                    GenServer.call(pid, {:delete_node,self()})

                end
              end
            end
             push_sum_receive(Enum.random(neighbors),((state + new_state)/2),((weight + new_weight)/2))
            {:noreply,{count,neighbors,algorithm,((state + new_state)/2),((weight + new_weight)/2),message}}

           count <3 ->
           state_update = (state + new_state)/2
           weight_update = (weight + new_weight)/2
            ratio = (state/weight) - (state_update/weight_update)
           IO.inspect(self())
           IO.inspect(ratio)
            count_update = if abs(ratio) <= abs(:math.pow(10,-10)) do
              count = count+1
              count
             else
               count = 0
               count
             end
              push_sum_receive(Enum.random(neighbors),state_update,weight_update)
              IO.inspect ([count_update,neighbors,algorithm,state_update,weight_update,message])
           {:noreply,{count_update,neighbors,algorithm,state_update,weight_update,message}}

        end
      end

      def handle_call({:delete_node, pid},_from,{count,neighbors,algorithm,state,weight,message}) do
        #IO.puts("delete #{inspect pid} from #{inspect self()}")
        neighbors_new = List.delete(neighbors,pid)
        {:reply,1,{count,neighbors_new,algorithm,state,weight,message}}

      end

      neighbors = def handle_call({:get_neighbors}, _from,{count,neighbors,algorithm,state,weight,message}) do
        {:reply,neighbors,{count,neighbors,algorithm,state,weight,message}}
      end

end
