defmodule ShEx.NodeConstraint do
  defstruct [:id, :node_kind, :datatype, :string_facets, :numeric_facets, :values]

  alias RDF.{IRI, BlankNode, Literal}
  alias RDF.NS.XSD

  @xsd_string XSD.string()
  @node_kinds ~w[iri bnode nonliteral literal]

  def node_kinds(), do: @node_kinds

  def satisfies?(node_constraint, node) do
    node_satisfies_node_kind_constraint?(node_constraint.node_kind, node) &&
      node_satisfies_datatype_constraint?(node_constraint.datatype, node) &&
      ShEx.NodeConstraint.StringFacets.satisfies?(node_constraint.string_facets, node) &&
      ShEx.NodeConstraint.NumericFacets.satisfies?(node_constraint.numeric_facets, node) &&
      ShEx.NodeConstraint.Values.satisfies?(node_constraint.values, node)
  end

  defp node_satisfies_node_kind_constraint?(nil, _), do: true
  defp node_satisfies_node_kind_constraint?("iri", %IRI{}), do: true
  defp node_satisfies_node_kind_constraint?("bnode", %BlankNode{}), do: true
  defp node_satisfies_node_kind_constraint?("literal", %Literal{}), do: true
  defp node_satisfies_node_kind_constraint?("nonliteral", %IRI{}), do: true
  defp node_satisfies_node_kind_constraint?("nonliteral", %BlankNode{}), do: true
  defp node_satisfies_node_kind_constraint?(_, _), do: false

  defp node_satisfies_datatype_constraint?(nil, _), do: true
  defp node_satisfies_datatype_constraint?(datatype, %Literal{datatype: datatype}), do: true

  defp node_satisfies_datatype_constraint?(datatype, %Literal{datatype: @xsd_string} = node) do
    rdf_datatype = RDF.Datatype.get(datatype)
    !is_nil(rdf_datatype) && !is_nil(rdf_datatype.cast(node))
  end

  defp node_satisfies_datatype_constraint?(_, _), do: false
end
