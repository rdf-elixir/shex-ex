defmodule ShEx.Shape do
  defstruct [
    :id,          # shapeExprLabel?
    :expression,  # tripleExpr?
    :closed,      # BOOL?
    :extra,       # [IRI]?
    :sem_acts,    # [SemAct]?
    :annotations  # [Annotation+]?
  ]
end
