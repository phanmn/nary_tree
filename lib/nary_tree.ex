defmodule NaryTree do
  defstruct root: nil, nodes: %{}

  defmodule Node do
    @enforce_keys [:id]
    defstruct id: :empty, name: :empty, content: :empty, parent: :empty, level: 0, children: []

    @type t :: %__MODULE__{id: String.t, name: String.t, content: any(), parent: String.t, children: []}

    @doc ~S"""
    Create a new, empty node.
    """
    @spec new() :: __MODULE__.t()
    def new(), do: %__MODULE__{id: create_id(), name: :empty, content: :empty, parent: :empty, children: []}

    @doc ~S"""
    Create a new, empty node with name.

    ## Example
        iex> %NaryTree.Node{name: name, level: 0, children: []} = NaryTree.Node.new("Node")
        iex> name
        "Node"
    """
    def new(name), do: %__MODULE__{id: create_id(), name: name, content: :empty, parent: :empty, children: []}

    @doc ~S"""
    Create a new, empty node with name and content.

    ## Example
        iex> %NaryTree.Node{name: name, content: content, level: 0, children: []} = NaryTree.Node.new("Root", %{w: 100})
        iex> name
        "Root"
        iex> content
        %{w: 100}
    """
    def new(name, content), do: %__MODULE__{id: create_id(), name: name, content: content, parent: :empty, children: []}

    defp create_id, do: Integer.to_string(:rand.uniform(4294967296), 32)
  end

  alias NaryTree.Node

  @type t :: %__MODULE__{root: String.t, nodes: [%__MODULE__{}]}

  @doc ~S"""
  Create a new, empty tree.

  ## Example
      iex> NaryTree.new()
      %NaryTree{nodes: %{}, root: nil}
  """
  @spec new() :: __MODULE__.t()
  def new(), do: %__MODULE__{}

  @doc ~S"""
  Create a new tree with a root node.

  ## Example
      iex> %NaryTree{root: key, nodes: nodes} = NaryTree.new(NaryTree.Node.new "Root node")
      iex> nodes[key].name
      "Root node"
  """
  @spec new(Node.t()) :: __MODULE__.t()
  def new(%Node{} = node) do
    root = %Node{ node | parent: :empty, level: 0 }
    %__MODULE__{root: root.id, nodes: %{root.id => root}}
  end

  @doc ~S"""
  Add a child node to a tree root node. Returns an updated tree with added child.

          RootNode
           \
           ChildNode

  ## Example
      iex> tree = NaryTree.new(NaryTree.Node.new "Root node") |>
      ...>   NaryTree.add_child(NaryTree.Node.new("Child"))
      iex> %NaryTree{root: key, nodes: nodes} = tree
      iex> [child_id | _] = nodes[key].children
      iex> nodes[child_id].name
      "Child"
  """
  @spec add_child(__MODULE__.t(), Node.t()) :: __MODULE__.t()
  def add_child(%__MODULE__{} = tree, %Node{} = child) do
    add_child(tree, child, tree.root)
  end

  @doc ~S"""
  Add a child node to the specified tree node. Returns an updated tree with added child.

        RootNode
           \
           BranchNode
              \
              New node

  ## Example
      iex> branch = NaryTree.Node.new("Branch Node")
      iex> tree = NaryTree.new(NaryTree.Node.new("Root Node")) |>
      ...>   NaryTree.add_child(branch) |>
      ...>   NaryTree.add_child(NaryTree.Node.new("New node"), branch.id)
      iex> Enum.count tree.nodes
      3
  """
  def add_child(_, %Node{id: child_id}, parent_id) when parent_id == child_id do
    raise "Cannot add child to its own node"
  end
  def add_child(%__MODULE__{nodes: nodes} = tree, %Node{id: child_id} = child, parent_id) do
    parent = tree.nodes[parent_id]
    updated_nodes = nodes
      |> Map.put_new(child_id, %Node{child | parent: parent.id, level: parent.level + 1})
      |> Map.put(parent.id, %Node{parent | children: List.delete(parent.children, child_id) ++ [child_id] })
    %__MODULE__{tree | nodes: updated_nodes}
  end

  @doc ~S"""
  Check whether a node is a root node.

  ## Example
      iex> node = NaryTree.Node.new "Root node"
      iex> NaryTree.is_root? node
      true
  """
  @spec is_root?(Node.t()) :: boolean()
  def is_root?(%Node{} = node), do: node.parent == :empty || node.parent == nil

  @doc ~S"""
  Check whether a node is a leaf node.

  ## Example
      iex> tree = NaryTree.new(NaryTree.Node.new("Root node")) |>
      ...>   NaryTree.add_child(NaryTree.Node.new("Leaf node"))
      iex> [node_id] = tree.nodes[tree.root].children
      iex> leaf_node = tree.nodes[node_id]
      iex> NaryTree.is_leaf? leaf_node
      true
  """
  @spec is_leaf?(Node.t()) :: boolean()
  def is_leaf?(%Node{} = node), do: node.children == []

  @doc ~S"""
  Check whether a node has non-empty content.

  ## Example
      iex> node = NaryTree.Node.new "Node", content: %{c: "Content"}
      iex> NaryTree.has_content? node
      true
  """
  @spec has_content?(Node.t()) :: boolean()
  def has_content?(%Node{} = node), do: !(node.content == nil || node.content == :empty)

  @doc ~S"""
  Enumerates tree nodes, and applies function to each node's content.
  Returns updated tree, with new content for every nodes

  ## Example
      iex> tree = NaryTree.new(NaryTree.Node.new("Root node")) |>
      ...>   NaryTree.add_child(NaryTree.Node.new("Leaf node 1")) |>
      ...>   NaryTree.add_child(NaryTree.Node.new("Leaf node 2"))
      iex> Enum.map tree.nodes, fn({_,node}) -> node.content end
      [:empty, :empty, :empty]
      iex> NaryTree.update_content(tree, fn(_) -> %{x: 4} end) |>
      ...>   Map.get(:nodes) |> Enum.map(fn({_,node}) -> node.content end)
      [%{x: 4}, %{x: 4}, %{x: 4}]
  """
  @spec update_content(__MODULE__.t(), function()) :: __MODULE__.t()
  def update_content(%__MODULE__{nodes: nodes} = tree, func) do
    %__MODULE__{tree | nodes: do_update_content(nodes, func)}
  end

  defp do_update_content(nodes, func) do
    Enum.reduce(nodes, nodes, fn({id, node}, acc) ->
      Map.put(acc, id, Map.update!(node, :content, func))
    end)
  end

  @doc ~S"""
  Enumerates tree nodes, and applies function to each leaf nodes' content.
  Similar to update_content/2, but applies only to leaf nodes.

  """
  @spec each_leaf(__MODULE__.t(), function()) :: __MODULE__.t()
  def each_leaf(%__MODULE__{nodes: nodes} = tree, func) do
    %__MODULE__{tree | nodes: do_each_leaf(nodes, func)}
  end

  defp do_each_leaf(nodes, func) do
    Enum.reduce(nodes, nodes, fn({_,node}, acc) ->
      if is_leaf?(node) do
        Map.put(acc, node.id, Map.update!(node, :content, func))
      else
        acc
      end
    end)
  end

  @doc ~S"""
  Check whether the argument is of NaryTree type.

  ## Example
      iex> NaryTree.is_nary_tree? NaryTree.new(NaryTree.Node.new "Node")
      true
  """
  @spec is_nary_tree?(__MODULE__.t()) :: boolean()
  def is_nary_tree?(%__MODULE__{}), do: true
  def is_nary_tree?(_), do: false

  @doc ~S"""
  Move children nodes from one node to another node.

  """
  @spec move_nodes(__MODULE__.t(), [Node.t()], Node.t()) :: __MODULE__.t()
  def move_nodes(tree, [], _), do: tree
  def move_nodes(tree, nodes, %Node{} = new_parent) do
    move_nodes(tree, Enum.map(nodes, fn(n) -> n.id end), new_parent.id)
  end

  @spec move_nodes(__MODULE__.t(), [String.t()], String.t()) :: __MODULE__.t()
  def move_nodes(tree, child_ids, new_parent_id) do
    new_parent_node = tree.nodes[new_parent_id]
    pid = tree.nodes[hd child_ids].parent
    updated_nodes = Enum.reduce(child_ids, tree.nodes, fn(cid, acc) ->
        Map.put acc, cid, %Node{ acc[cid] | parent: new_parent_id, level: new_parent_node.level+1}
      end)
      |> Map.put(pid, %Node{ tree.nodes[pid] | children: tree.nodes[pid].children -- child_ids })
      |> Map.put(new_parent_id, %Node { new_parent_node | children: new_parent_node.children ++ child_ids })
    %__MODULE__{ tree | nodes: updated_nodes }
  end

  @doc ~S"""
  Get the node with the specified id from the tree.

  ## Example
      iex> node = NaryTree.Node.new("Node")
      iex> n = NaryTree.new(node) |>
      ...>     NaryTree.get(node.id)
      iex> n.name
      "Node"
  """
  def get(%__MODULE__{nodes: nodes}, id), do: Map.get nodes, id

  @doc ~S"""
  Put a node into the tree at the specified id.
  Put will replace the name and content attributes of the node at id with
  the attributes of the new nodes.
  The children and parent of the old node will remain the same so that
  the hierarchy structure remains the same.

  ## Example
      iex> tree = NaryTree.new NaryTree.Node.new("Root")
      iex> tree.nodes[tree.root].name
      "Root"
      iex> tree = NaryTree.put(tree, tree.root, NaryTree.Node.new("Node"))
      iex> tree.nodes[tree.root].name
      "Node"
  """
  def put(%__MODULE__{nodes: nodes} = tree, id, node_to_replace) do
    updated_node = %Node{nodes[id] | content: node_to_replace.content, name: node_to_replace.name}
    %__MODULE__{ tree | nodes: Map.put(nodes, id, updated_node) }
  end

  @doc ~S"""
  Delete a node in a tree.
  If the deleted node has children, the children will be moved up in hierarchy
  to become the children of the deleted node's parent.

  ## Example
      iex> branch = NaryTree.Node.new("Branch Node")
      iex> leaf = NaryTree.Node.new("Leaf")
      iex> tree = NaryTree.new(NaryTree.Node.new("Root Node")) |>
      ...>   NaryTree.add_child(branch) |>
      ...>   NaryTree.add_child(leaf, branch.id) |>
      ...>   NaryTree.delete(branch.id)
      iex> tree.nodes[branch.id]
      nil
      iex> tree.nodes[tree.root].children   # leaf becomes root's child
      [leaf.id]
  """
  @spec delete(NaryTree.t(), any()) :: :error
  def delete(%__MODULE__{} = tree, %Node{id: id}), do: delete(tree, id)
  def delete(%__MODULE__{nodes: nodes} = tree, id) do
    if Enum.member? tree, id do
      node = nodes[id]
      tree
      |> unlink_from_parent(node)
      |> move_nodes(node.children, node.parent)
      |> delete_node(id)
    else
      :error
    end
  end

  defp unlink_from_parent(tree, %Node{parent: parent}) when parent == :empty or parent == nil, do: tree
  defp unlink_from_parent(tree, node) do
    parent = tree.nodes[node.parent]
    updated_parent = %Node{ parent | children: (parent.children -- [node.id]) }
    %__MODULE__{ tree | nodes: Map.put(tree.nodes, node.parent, updated_parent) }
  end

  defp delete_node(tree, id) do
    %__MODULE__{ tree | nodes: Map.delete(tree.nodes, id) }
  end

  @doc ~S"""
  Detach a branch in a tree. Returns the detached branch conplete with all its
  descendents as a new tree struct.

  ## Example
      iex> branch = NaryTree.Node.new("Branch Node")
      iex> leaf = NaryTree.Node.new("Leaf")
      iex> tree = NaryTree.new(NaryTree.Node.new("Root Node")) |>
      ...>   NaryTree.add_child(branch) |>
      ...>   NaryTree.add_child(leaf, branch.id)
      iex> detached = NaryTree.detach(tree, branch.id)
      iex> Enum.count detached.nodes
      2
      iex> detached.root
      branch.id
  """
  def detach(%__MODULE__{} = tree, node_id) when is_binary(node_id) do
    if Enum.member? tree, node_id do
      root = get(tree, node_id)
      new_tree = new root
      Enum.reduce root.children, new_tree, fn(child_id, acc) ->
        add_all_descendents(acc, root.id, child_id, tree)
      end
    else
      :error
    end
  end

  defp add_all_descendents(tree, parent_id, node_id, old_tree) do
    node = get old_tree, node_id
    case node.children do
      [] ->
        add_child(tree, node, parent_id)
      _ ->
        new_tree = add_child(tree, node, parent_id)
        Enum.reduce node.children, new_tree, fn(child_id, acc) ->
          add_all_descendents(acc, node.id, child_id, old_tree)
        end
    end
  end

  @doc ~S"""
  Merges a tree into another tree at the specified node point.
  Returns the resulting combined tree or :error if the specified
  node point doesn't exist.

  ## Example
      iex> branch = NaryTree.Node.new("Branch Node")
      iex> tree1 = NaryTree.new(NaryTree.Node.new("Root Node")) |>
      ...>   NaryTree.add_child(branch)
      iex> tree2 = NaryTree.new(NaryTree.Node.new("Subtree")) |>
      ...>   NaryTree.add_child(NaryTree.Node.new("Leaf"))
      iex> combined = NaryTree.merge(tree1, tree2, branch.id)
      iex> Enum.count combined.nodes
      4
  """
  def merge(%__MODULE__{} = tree,
            %__MODULE__{} = branch,
            node_id)
            when is_binary(node_id) do
    if Enum.member? tree, node_id do
      node = get(tree, node_id)
      updated_node = node |> Map.put(:children, node.children ++ [branch.root])
      tree_nodes = Map.put tree.nodes, node_id, updated_node
      branch_nodes = branch.nodes
        |> Enum.reduce(branch.nodes, fn({id, n}, acc) ->
              Map.put acc, id, %Node{ n | level: n.level + node.level + 1 }
            end)
        |> Map.put(branch.root, %Node{ root(branch) | parent: node.id , level: node.level + 1 })
      %__MODULE__{ tree | nodes: Map.merge(tree_nodes, branch_nodes) }
    else
      :error
    end
  end

  # Familial Relationships

  @doc ~S"""
  Returns the root node of a tree.

  ## Example
      iex> tree = NaryTree.new(NaryTree.Node.new("Root Node"))
      iex> %NaryTree.Node{name: name} = NaryTree.root(tree)
      iex> name
      "Root Node"
  """
  def root(%__MODULE__{} = tree) do
    get tree, tree.root
  end

  def children(%Node{} = node, %__MODULE__{} = tree) do
    Enum.map node.children, &(get tree, &1)
  end

  @doc ~S"""
  Returns the parent node of a tree, or :empty if there is none

  ## Example
      iex> branch = NaryTree.Node.new("Branch Node")
      iex> tree = NaryTree.new(NaryTree.Node.new("Root Node")) |>
      ...>   NaryTree.add_child(branch)
      iex> %NaryTree.Node{name: name} = NaryTree.root(tree)
      iex> name
      "Root Node"
  """
  def parent(%Node{} = node, %__MODULE__{} = tree) do
    get tree, node.parent
  end

  def siblings(%Node{} = node, %__MODULE__{} = tree) do
   parent(node, tree)
    |> children(tree)
    |> List.delete(node)
  end

  def print_tree(%__MODULE__{} = tree, func \\ fn(x) -> "#{x.name}" end) do
    do_print_tree(%Node{} = tree.nodes[tree.root], tree.nodes, func)
  end

  defp do_print_tree(node, _, _) when is_nil(node), do: raise "Expecting %NaryTree.Node(), found nil."
  defp do_print_tree(%Node{children: children} = node, _nodes, func) when children == [] do
    IO.puts indent(node.level) <> "- " <> func.(node)
  end
  defp do_print_tree(%Node{children: children} = node, nodes, func) do
    IO.puts indent(node.level) <> "* " <> func.(node)
    Enum.each children, fn(child_id) -> do_print_tree(nodes[child_id], nodes, func) end
  end

  def indent(n, c \\ " ") do
    String.duplicate(c, n*2)
  end

  @behaviour Access

  @spec fetch(__MODULE__.t(), String.t()) :: {:ok, Node.t()} | :error
  def fetch(%__MODULE__{nodes: nodes}, id) do
    if Map.has_key?(nodes, id), do: {:ok, nodes[id]}, else: :error
  end

  def get_and_update(%__MODULE__{} = tree, id, fun) when is_function(fun, 1) do
    current = get(tree, id)
    case fun.(current) do
      {get, update} ->
        {get, put(tree, id, update)}
      :pop ->
        {current, delete(tree, id)}
      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  def pop(tree, id, default \\ nil) do
    case delete(tree, id) do
      %__MODULE__{} = new_tree ->
        {get(tree, id), new_tree}
      :error -> {default, tree}
    end
  end

  def to_list(%__MODULE__{nodes: nodes} = tree) do
    traverse(%Node{} = tree.nodes[tree.root], nodes, [])
    |> :lists.reverse()
  end

  defp traverse(node, _, _) when is_nil(node), do: raise "Expecting %NaryTree.Node(), found nil."
  defp traverse(%Node{children: children} = node, _nodes, acc) when children == [] do
    [node | acc]
  end
  defp traverse(%Node{children: children} = node, nodes, acc) do
    Enum.reduce children, [node | acc], fn(child_id, accumulator) ->
      traverse nodes[child_id], nodes, accumulator
    end
  end

  def list_to_nodes(list) when is_list(list) do
    Enum.reduce list, %{}, fn(node, acc) ->
      Map.put_new(acc, node.id, node)
    end
  end

  defimpl Enumerable do
    def count(%NaryTree{nodes: nodes}), do: {:ok, Map.size(nodes)}

    @doc """
    ## TODO
    ## Examples
        iex> r = NaryTree.new NaryTree.Node.new("Root", 3)
        ...> n = NaryTree.Node.new("Branch", 100)
        ...> NaryTree.add_child r, n
        ...> Enum.member? r, n.id
        true
    """
    def member?(%NaryTree{nodes: nodes}, id) do
      case Map.has_key? nodes, id do
        true -> {:ok, true}
        false -> {:ok, false}
      end
    end

    @doc """
    ## TODO
    ## Examples
        iex> Enum.reduce tt, tt, fn(n, acc) ->
        ...>   p = NaryTree.parent(n, acc)
        ...>   pz = if p, do: p.content.w, else: 0
        ...>   NaryTree.put acc, n.id, %NaryTree.Node{n | content: %{n.content | w: n.content.w + pz}}
        ...> end
    """

    def reduce(%NaryTree{} = tree, acc, f) do
      tree
      |> NaryTree.to_list()
      |> reduce_tree(acc, f)
    end

    defp reduce_tree(_, {:halt, acc}, _f), do: {:halted, acc}
    defp reduce_tree(nodes, {:suspend, acc}, f), do: {:suspended, acc, &reduce_tree(nodes, &1, f)}
    defp reduce_tree([], {:cont, acc}, _f), do: {:done, acc}
    defp reduce_tree([h | t], {:cont, acc}, f), do: reduce_tree(t, f.(h, acc), f)

    def slice(_tree) do
      {:error, NaryTree}        # let the default action take over
    end
  end
end

# alias NaryTree, as: NT
# alias NaryTree.Node, as: N
# root = N.new "Goal", %{w: 0.45}
# c1 = N.new "Cost", %{w: 0.33}
# c2 = N.new "Benefits", %{w: 0.67}
# a1 = N.new "Alt 1", %{w: 0.1}
# a2 = N.new "Alt 2", %{w: 0.4}
# a3 = N.new "Alt 3", %{w: 0.5}
# c11 = N.new "Speed", %{w: 0.2}
# c12 = N.new "Image", %{w: 0.3}
# c13 = N.new "Features", %{w: 0.5}

# tree = NT.new(root) |>
#   NT.add_child(c2, root.id) |>
#   NT.add_child(c1, root.id) |>
#   NT.add_child(a1, c1.id) |>
#   NT.add_child(a2, c1.id) |>
#   NT.add_child(a3, c1.id) |>
#   NT.add_child(c11, c2.id) |>
#   NT.add_child(c12, c2.id) |>
#   NT.add_child(c13, c2.id)

