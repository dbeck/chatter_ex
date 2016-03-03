defmodule Chatter.Planner do

  alias Chatter.NetID
  alias Chatter.BroadcastID
  alias Chatter.PeerDB

  @spec plan( list(NetID.t ) ) :: list(list(NetID.t))
  def plan(netid_list)
  do
  	:ok = NetID.validate_list!(netid_list)
  	group_mcast_peers(netid_list) |> build_tree([])
  end

  @spec build_tree(list, list) :: list
  def build_tree([], acc), do: acc

  def build_tree(list, acc)
  when is_list(list) and is_list(acc)
  do
  	len = length(list)
    take_n = div(len, 2)
    {next, remainder} = list |> Enum.shuffle |> Enum.split(take_n)
    new_acc = [remainder|acc]
    build_tree(next, new_acc) |> Enum.reverse
  end

  @spec group_mcast_peers( list(NetID.t ) ) :: list(list(NetID.t))
  def group_mcast_peers(netid_list)
  do
  	:ok = NetID.validate_list!(netid_list)

  	{result, _set} = Enum.reduce(netid_list, {[], Enum.into(netid_list, HashSet.new)}, fn(x,acc) ->
  	  {result_list, netid_set} = acc
  	  if HashSet.member?(netid_set, x)
  	  do
	  	netid_set = HashSet.delete(netid_set, x)

	  	{:ok, seen_ids} = PeerDB.get_seen_id_list_(x)
	  	{mcast_group, netid_set} = Enum.reduce(seen_ids, {[x], netid_set}, fn(x2,acc2) ->
	  	  {result_list2, netid_set} = acc2
	  	  id = BroadcastID.origin(x2)
	  	  if HashSet.member?(netid_set, id)
	  	  do
	  	  	{[id|result_list2], HashSet.delete(netid_set, id)}
	  	  else
	  	  	acc2
	  	  end
	  	end)
	  	{[mcast_group|result_list], netid_set}
	  else
	  	acc
	  end
  	end)
  	result
  end
end
