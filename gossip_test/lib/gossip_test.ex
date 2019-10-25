  defmodule GossipTest do
    use GenServer,restart: :transient

    def start_link(nodes, topology, algorithm) do
        GenServer.start_link(__MODULE__, {nodes, topology, algorithm}, name: {:global,:GossipTest})
    end

    def init({nodes,topology , algorithm}) do
      IO.puts(" Started main Process #{inspect self()}")
      gossip(nodes,topology , algorithm)
      {:ok,{0,[]}}
    end

    def listOfNodes(pid, list) do
      GenServer.cast(pid, {:listOfNodes, list})
    end

    def handle_cast({:listOfNodes, new_list}, {sum,_list}) do
        {:noreply, {sum,new_list}}
    end

    def gossip(numberOfNodes, topology, algorithm) do
      message = "hey wassup!"
      listProcesses=[]
      numberOfNodes = if topology =="rand2D" or topology =="randomhoneycomb" or topology =="honeycomb" do
        IO.puts("in sqroot")
        n =:math.sqrt(numberOfNodes) |> round
        numberOfNodes = n*n
        numberOfNodes
        else
        numberOfNodes
      end
      IO.puts numberOfNodes
      listProcesses = startProcesses(numberOfNodes, listProcesses, algorithm)
      listOfNodes(self(), listProcesses)
      case topology do
        "full" ->
            generateFullTopoloy(listProcesses)
        "honeycomb" ->
            generateHexagonTopology(listProcesses,topology)
        "line" ->
            generateLineTopology(listProcesses)
        "randomhoneycomb" ->
            generateHexagonTopology(listProcesses, topology)
        "rand2D" ->
            generateRand2DTopology(listProcesses)
        "3Dtorus" ->
            generate3DTorusTopology(listProcesses)
      end

      IO.puts("Topology #{inspect topology} created successfully")
      startNode = Enum.random(listProcesses)
      listOfNeighbors = GenServer.call(startNode,{:get_neighbors})
      IO.puts("neighbirs id atRTn nide #{inspect listOfNeighbors}")
      start_node = if listOfNeighbors ==[] do
        start_node = getstartNode(listProcesses)
        start_node
        else
        startNode
      end
      IO.inspect start_node
      if algorithm =="gossip" do
        Actor.receive_msg(start_node,message) #starting gossip

      else
        GenServer.cast(start_node, {:push_sum_receive,0,0})
      end
      start_time = System.system_time(:millisecond)
      #IO.inspect start_time
      recv(0,numberOfNodes,start_time,topology)
    end

    def startProcesses(numberOfNodes,listOfProcesses, algorithm) do
      if(numberOfNodes>=1) do
        {:ok, pid} = Actor.start_link(algorithm)
        listOfProcesses = [pid | listOfProcesses]
        startProcesses(numberOfNodes-1,listOfProcesses, algorithm)
      else
        listProcesses = listOfProcesses #returns the listOfProcesses
        listProcesses
      end
    end

    def generateFullTopoloy(listOfProcesses) do
      numberOfNodes = length(listOfProcesses) - 1
      for n<-0..numberOfNodes do
        Actor.configure_node(Enum.at(listOfProcesses,n),List.delete(listOfProcesses,Enum.at(listOfProcesses,n)),n+1,1)
      end
    end
    def generateHexagonTopology(listOfProcesses, topology) do
      numberOfNodes = length(listOfProcesses)
      n =:math.sqrt(numberOfNodes) |> round
      IO.inspect n
      if rem(n,2)==0 do #n is even
        for i <- 0..(n*n)-1 do
          neighbors = []
          neighbors = cond do
            i+1<=n ->  #top level
              cond do
                rem(i+1,2)==0 ->
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors
                rem(i+1,2)==1 ->
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors
              end

             i+1>n and i+1<=(n*(n-1)) ->
              cond do
                rem(i+1,n)==0 and rem(div(i+1,n),2)==1 ->  #right corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors

                rem(i+1,n)==0 and rem(div(i+1,n),2)==0 ->  #right corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors

                rem(i+1,n)==1 and rem(div(i+1,n),2)==1 -> #left corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors

                rem(i+1,n)==1 and rem(div(i+1,n),2)==0 -> #left corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==1 and rem(div(i+1,n),2)==1 ->  #center odd
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==0 and rem(div(i+1,n),2)==1 ->  #center odd
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==1 and rem(div(i+1,n),2)==0 ->  #center even
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==0 and rem(div(i+1,n),2)==0 ->  #center even
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors
              end

              i+1>(n*(n-1)) ->
              cond do
                rem(i+1,n) ==0 or rem(i+1,n)==1 ->
                neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                neighbors

              rem(rem(i+1,n),2) ==0 ->
                neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                neighbors

              rem(rem(i+1,n),2) ==1 ->
                neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                neighbors
              end
          end
           if topology=="randomhoneycomb" do
            node = Enum.at(listOfProcesses,i)
            IO.puts("in rand#{inspect [i, node,neighbors]}")
            neighbors =  randomhoneycomb(node,neighbors,listOfProcesses)
            Actor.configure_node(node,neighbors,i+1,1)
            else
              Actor.configure_node(Enum.at(listOfProcesses,i),neighbors,i+1,1)

           end
        end
      end

      if rem(n,2)==1 do #n is odd
         for i<-0..(n*n)-1 do
           neighbors =[]
           neighbors =  cond do
              i<=n -> #top level
                cond do
                 rem(i+1,n)==0 ->
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors
                rem(rem(i+1,n),2)==0 ->
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors
                rem(rem(i+1,n),2)==1 ->
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors
                end
              i+1>n and i+1<=(n*(n-1)) ->
              cond do
                rem(i+1,n)==0 and rem(i+1,2)==0 ->  #right corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors

                rem(i+1,n)==0 and rem(i+1,2)==1 ->  #right corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors

                rem(i+1,n)==1 and rem(i+1,2)==0 -> #left corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors

                rem(i+1,n)==1 and rem(i+1,2)==1 -> #left corner
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==1 and rem(div(i+1,n),2)==1 ->  #center odd
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==0 and rem(div(i+1,n),2)==1 ->  #center odd
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==1 and rem(div(i+1,n),2)==0 ->  #center even
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                  neighbors

                rem(rem(i+1,n),2)==0 and rem(div(i+1,n),2)==0 ->  #center even
                  neighbors=[Enum.at(listOfProcesses,(i+n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                  neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                  neighbors
              end
              i+1>(n*(n-1)) ->
              cond do
              rem(i+1,n) ==0 ->
                neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                neighbors

              rem(rem(i+1,n),2) ==0 ->
                neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                neighbors

              rem(rem(i+1,n),2) ==1 ->
                neighbors=[Enum.at(listOfProcesses,(i-n)) | neighbors]
                neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                neighbors
              end
             end
            if topology=="randomhoneycomb" do
               node = Enum.at(listOfProcesses,i)
               neighbors =  randomhoneycomb(node,neighbors,listOfProcesses)
               Actor.configure_node(node,neighbors,i+1,1)
            else
              Actor.configure_node(Enum.at(listOfProcesses,i),neighbors,i+1,1)
           end
         end
      end
    end

    def randomhoneycomb(i,neighbors,listOfProcesses) do
              IO.inspect neighbors
              listOfProcesses = List.delete(listOfProcesses, i)
              listOfProcesses = listOfProcesses--neighbors;
              Enum.filter(listOfProcesses, & !is_nil(&1))
              neighbors = [Enum.random(listOfProcesses)|neighbors]

              IO.puts("in randomhonehycomb #{inspect i}")
              neighbors
    end

    def generateRand2DTopology(listOfProcesses) do
        l = for i <- 0..length(listOfProcesses) do
        [Enum.at(listOfProcesses,i)] ++ [[:rand.uniform(),:rand.uniform()]]
        end
        for i<-0..length(listOfProcesses) do
          neigh = for j<-0..length(listOfProcesses) do
            x1 = Enum.at(Enum.at(Enum.at(l,i),1),0)
            y1 = Enum.at(Enum.at(Enum.at(l,i),1),1)

            x2 = Enum.at(Enum.at(Enum.at(l,j),1),0)
            y2 = Enum.at(Enum.at(Enum.at(l,j),1),0)

            if (:math.sqrt(:math.pow(x2-x1,2) + :math.pow(y2-y1,2)))<=0.1 && (:math.sqrt(:math.pow(x2-x1,2) + :math.pow(y2-y1,2))) > 0 do
              []++Enum.at(Enum.at(l,j),0)
            end
          end
        neigh = Enum.filter(neigh, & !is_nil(&1))
        Actor.configure_node(Enum.at(listOfProcesses,i),neigh,i+1,1)
        end
    end

    def generateLineTopology(listOfProcesses) do
            n = length(listOfProcesses)-1
            for i <- 0..n do
              neighbors =[]
           cond do
              i==0 ->
                neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                Actor.configure_node(Enum.at(listOfProcesses,i),neighbors,i+1,1)
              i==n ->
                neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                Actor.configure_node(Enum.at(listOfProcesses,i),neighbors,i+1,1)
              (i > 0 and i < n) ->
                neighbors=[Enum.at(listOfProcesses,(i-1)) | neighbors]
                neighbors=[Enum.at(listOfProcesses,(i+1)) | neighbors]
                Actor.configure_node(Enum.at(listOfProcesses,i),neighbors,i+1,1)
           end
         end
    end

    def generate3DTorusTopology(listOfProcesses) do
      rc = round(:math.pow(length(listOfProcesses), 1 / 3))
      cc = rc * rc
      total = rc*cc
      for i <- 0..(rc*cc)-1 do

        neigh = cond do
          rem(i,rc) == 0 ->
          a = i-1 + rc
          b = i+1
          c = rem(i,cc) |> checkup(i,rc,cc)
          d = rem(i,cc) |> checkdown(i,rc,cc)
          e = i-cc |> checkabove(i,rc,cc,total)
          f = i+cc |> checkbelow(i,rc,cc,total)
          [a,b,c,d,e,f]

          rem(i+1,rc) == 0 ->
          a = i-1
          b = i+1 - rc
          c = rem(i,cc) |> checkup(i,rc,cc)
          d = rem(i,cc) |> checkdown(i,rc,cc)
          e = i-cc |> checkabove(i,rc,cc,total)
          f = i+cc |> checkbelow(i,rc,cc,total)
          [a,b,c,d,e,f]

          true ->
          a = i-1
          b = i+1
          c = rem(i,cc) |> checkup(i,rc,cc)
          d = rem(i,cc) |> checkdown(i,rc,cc)
          e = i-cc |> checkabove(i,rc,cc,total)
          f = i+cc |> checkbelow(i,rc,cc,total)
          [a,b,c,d,e,f]
          end
          #IO.inspect(neigh)
          neigh = Enum.map(neigh, fn x -> Enum.at(listOfProcesses,x) end)
          #IO.inspect(neigh)
          neigh = Enum.filter(neigh, & !is_nil(&1))
          Actor.configure_node(Enum.at(listOfProcesses,i),neigh,i+1,1)
      end

    end

    def checkup(x,i,rc,cc)do
      if x >=0 && x<rc do
         i-rc + cc
        else
        i-rc
      end
    end

    def checkdown(x,i,rc,cc)do
      if (x>=(cc-rc) && x<=(cc-1))  do
         i+rc - cc
        else
        i+rc
      end

    end
    def checkabove(x,_i,_rc,_cc,total)do
      if x <= 0 do
      x+total
      else
      x
      end
    end
    def checkbelow(x,_i,_rc,_cc,total) do
      if x > total do
         x-total
      else
      x
      end
    end

    def recv(convergedNodes, numberOfNodes, start_time,topology) do
        receive do
            {:output,message} ->
              cond do
              message =="gossip" ->
              cond do

               topology == "full"->
                  if convergedNodes/numberOfNodes <= 0.8 do
                  #IO.puts("on convergence")
                  IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                  recv(convergedNodes+1,numberOfNodes,start_time,topology)
                  else
                    current_time = System.system_time(:millisecond)
                    diff = current_time-start_time
                    #IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")

                    IO.puts("80% of the actors reached convergence in #{inspect diff}")
                    exit(:shutdown)
                    end

               topology == "line"->
                  if convergedNodes/numberOfNodes <= 0.6 do
                  #IO.puts("on convergence")
                  IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                  recv(convergedNodes+1,numberOfNodes,start_time,topology)
                  else
                    current_time = System.system_time(:millisecond)
                    diff = current_time-start_time
                    IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")

                    IO.puts("60% of the actors reached convergence in #{inspect diff}")
                    exit(:shutdown)
                    end

               topology == "honeycomb"->
                  if convergedNodes/numberOfNodes <= 0.6 do
                  #IO.puts("on convergence")
                  IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                  recv(convergedNodes+1,numberOfNodes,start_time,topology)
                  else
                    current_time = System.system_time(:millisecond)
                    diff = current_time-start_time
                    IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                    IO.puts("60% of the actors reached convergence in #{inspect diff}")
                    exit(:shutdown)
                    end

               topology == "randomhoneycomb"->
                  if convergedNodes/numberOfNodes <= 0.65 do
                  #IO.puts("on convergence")
                  IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                  recv(convergedNodes+1,numberOfNodes,start_time,topology)
                  else
                    current_time = System.system_time(:millisecond)
                    diff = current_time-start_time
                    IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")

                    IO.puts("65% of the actors reached convergence in #{inspect diff}")
                    exit(:shutdown)
                    end
                topology == "rand2D"->
                  if convergedNodes/numberOfNodes <= 1 do
                  #IO.puts("on convergence")
                  IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                  recv(convergedNodes+1,numberOfNodes,start_time,topology)
                  else
                    current_time = System.system_time(:millisecond)
                    diff = current_time-start_time
                    IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")

                    IO.puts("80% of the actors reached convergence in #{inspect diff}")
                    exit(:shutdown)
                    end
               topology == "3Dtorus"->
                  if convergedNodes/numberOfNodes <= 0.65 do
                  #IO.puts("on convergence")
                  IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")
                  recv(convergedNodes+1,numberOfNodes,start_time,topology)
                  else
                    current_time = System.system_time(:millisecond)
                    diff = current_time-start_time
                    IO.puts(" #{inspect convergedNodes} #{inspect (convergedNodes/numberOfNodes)}")

                    IO.puts("65% of the actors reached convergence in #{inspect diff}")
                    exit(:shutdown)
                    end

               end
               message =="pushsum" ->
                current_time = System.system_time(:millisecond)
                #IO.inspect start_time
                diff = current_time-start_time
                IO.puts("Reached convergence in #{inspect diff}")
                Process.exit(self(),:kill)
              end
        end
    end

    def getstartNode(listProcesses) do
      start_node = Enum.random(listProcesses)
      listOfNeighbors = GenServer.call(start_node,{:get_neighbors})
      #IO.puts("neighbirs id atRTn nide #{inspect listOfNeighbors}")
      start_node = if listOfNeighbors ==[] do
        start_node = getstartNode(listProcesses)
      else
        start_node
      end
  end
  end

  GossipTest.start_link(100,"3Dtorus","pushsum")
