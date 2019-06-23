defmodule ShEx.GraphUtils do

  @doc """
  the set of triples in a graph with the given subject
  """
  def arcs_out(graph, node) do
    if description = RDF.Graph.description(graph, node) do
      RDF.Description.triples(description)
    else
      []
    end
  end

  @doc """
  the set of triples in a graph with the given object
  """
  def arcs_in(graph, node) do
    # TODO: This heavily used function is very slow.
    graph
    |> Enum.filter(fn
         {_, _, ^node} -> true
         _             -> false
       end)
  end
end
