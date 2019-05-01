defmodule ShEx.Schema do
  @moduledoc """
  A ShEx schema is a collection of `ShEx.ShapeExpression` that prescribes conditions that RDF data graphs must meet in order to be considered "conformant".

  """

  defstruct [
    :start_acts, # [SemAct+]?
    :start,      # shapeExpr?
    :imports,    # [IRI+]?
    :shapes      # [shapeExpr+]?
  ]
end
