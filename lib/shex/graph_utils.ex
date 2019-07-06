defmodule ShEx.GraphUtils do
  @moduledoc !"""
  A set of utility functions for access RDF graphs.
  """

  @doc !"""
  the set of triples in a graph with the given subject
  """
  def arcs_out(graph, node)

  def arcs_out(_, %RDF.Literal{}), do: []

  def arcs_out(graph, node) do
    if description = RDF.Graph.description(graph, node) do
      RDF.Description.triples(description)
    else
      []
    end
  end

  @doc !"""
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
