defmodule ShEx.ShExJ.Decoder do
  import ShEx.Utils

  def decode(content, options \\ []) do
    with {:ok, json_object} <- parse_json(content, options) do
      to_schema(json_object, options)
    end
  end

  defp to_schema(%{type: "Schema"} = schema, options) do
    with {:ok, shapes} <-
           schema
           |> Map.get(:shapes, [])
           |> map(&to_shape_expression/2, options)
           |> empty_to_nil(),
         {:ok, start} <-
           schema
           |> Map.get(:start)
           |> if_present(&to_shape_expression/2, options),
         {:ok, imports} <-
           schema
           |> Map.get(:imports, [])
           |> map(&to_import/2, options)
           |> empty_to_nil(),
         {:ok, start_acts} <-
           schema
           |> Map.get(:startActs, [])
           |> map(&to_semantic_action/2, options)
           |> empty_to_nil() do
      {:ok, ShEx.Schema.new(shapes, start, imports, start_acts)}
    end
  end

  defp to_shape_expression(%{type: "NodeConstraint"} = node_constraint, options) do
    with {:ok, id} <-
           node_constraint
           |> Map.get(:id)
           |> if_present(&to_shape_expression_label/2, options),
         {:ok, node_kind} <-
           node_constraint
           |> Map.get(:nodeKind)
           |> if_present(&to_node_kind/2, options),
         {:ok, datatype} <-
           node_constraint
           |> Map.get(:datatype)
           |> if_present(&to_iri/2, options),
         string_facets <-
           ShEx.NodeConstraint.StringFacets.new(node_constraint),
         numeric_facets <-
           ShEx.NodeConstraint.NumericFacets.new(node_constraint),
         {:ok, values} <-
           node_constraint
           |> Map.get(:values, [])
           |> map(&to_value_set_value/2, options)
           |> empty_to_nil() do
      {:ok,
       %ShEx.NodeConstraint{
         id: id,
         node_kind: node_kind,
         datatype: datatype,
         string_facets: string_facets,
         numeric_facets: numeric_facets,
         values: ShEx.NodeConstraint.Values.new(values)
       }}
    end
  end

  defp to_shape_expression(%{type: "Shape"} = shape, options) do
    with {:ok, id} <-
           shape
           |> Map.get(:id)
           |> if_present(&to_shape_expression_label/2, options),
         {:ok, expression} <-
           shape
           |> Map.get(:expression)
           |> if_present(&to_triple_expression/2, options),
         {:ok, closed} <-
           shape
           |> Map.get(:closed)
           |> if_present(&to_bool/2, options),
         {:ok, extra} <-
           shape
           |> Map.get(:extra, [])
           |> map(&to_iri/2, options)
           |> empty_to_nil(),
         {:ok, sem_acts} <-
           shape
           |> Map.get(:semActs, [])
           |> map(&to_semantic_action/2, options)
           |> empty_to_nil(),
         {:ok, annotations} <-
           shape
           |> Map.get(:annotations, [])
           |> map(&to_annotation/2, options)
           |> empty_to_nil() do
      {:ok,
       %ShEx.Shape{
         id: id,
         expression: expression,
         closed: closed,
         extra: extra,
         sem_acts: sem_acts,
         annotations: annotations
       }}
    end
  end

  defp to_shape_expression(%{type: type} = shape_expression_combinator, options)
       when type in ~w[ShapeOr ShapeAnd] do
    with type_mod = Module.concat([ShEx, type]),
         {:ok, id} <-
           shape_expression_combinator
           |> Map.get(:id)
           |> if_present(&to_shape_expression_label/2, options),
         {:ok, shape_exprs} <-
           shape_expression_combinator
           |> Map.get(:shapeExprs, [])
           |> map(&to_shape_expression/2, options) do
      if length(shape_exprs) >= 2 do
        {:ok,
         struct(type_mod,
           id: id,
           shape_exprs: shape_exprs
         )}
      else
        {:error, "Invalid #{type}: must have >= 2 shapeExprs, but has #{length(shape_exprs)}}"}
      end
    end
  end

  defp to_shape_expression(%{type: "ShapeNot"} = shape_not, options) do
    with {:ok, id} <-
           shape_not
           |> Map.get(:id)
           |> if_present(&to_shape_expression_label/2, options),
         {:ok, shape_expr} <-
           shape_not
           |> Map.get(:shapeExpr, [])
           |> to_shape_expression(options) do
      {:ok,
       %ShEx.ShapeNot{
         id: id,
         shape_expr: shape_expr
       }}
    end
  end

  defp to_shape_expression(%{type: "ShapeExternal"} = shape_external, options) do
    with {:ok, id} <-
           shape_external
           |> Map.get(:id)
           |> if_present(&to_shape_expression_label/2, options) do
      {:ok, %ShEx.ShapeExternal{id: id}}
    end
  end

  defp to_shape_expression(shape_expr_label, options) when is_binary(shape_expr_label) do
    to_shape_expression_label(shape_expr_label, options)
  end

  defp to_shape_expression(invalid, _) do
    {:error, "invalid shape expression: #{inspect(invalid)}}"}
  end

  defp to_triple_expression(
         %{type: "TripleConstraint", predicate: predicate} = triple_constraint,
         options
       ) do
    with {:ok, id} <-
           triple_constraint
           |> Map.get(:id)
           |> if_present(&to_triple_expression_label/2, options),
         {:ok, value_expr} <-
           triple_constraint
           |> Map.get(:valueExpr)
           |> if_present(&to_shape_expression/2, options),
         {:ok, predicate} <-
           to_iri(predicate, options),
         {:ok, inverse} <-
           triple_constraint
           |> Map.get(:inverse)
           |> if_present(&to_bool/2, options),
         {:ok, min} <-
           triple_constraint
           |> Map.get(:min)
           |> if_present(&to_integer/2, options),
         {:ok, max} <-
           triple_constraint
           |> Map.get(:max)
           |> if_present(&to_integer/2, options),
         {:ok, sem_acts} <-
           triple_constraint
           |> Map.get(:semActs, [])
           |> map(&to_semantic_action/2, options)
           |> empty_to_nil(),
         {:ok, annotations} <-
           triple_constraint
           |> Map.get(:annotations, [])
           |> map(&to_annotation/2, options)
           |> empty_to_nil() do
      {:ok,
       %ShEx.TripleConstraint{
         id: id,
         value_expr: value_expr,
         predicate: predicate,
         inverse: inverse,
         min: min,
         max: max,
         sem_acts: sem_acts,
         annotations: annotations
       }}
    end
  end

  defp to_triple_expression(%{type: "TripleConstraint"} = invalid, options) do
    {:error, "invalid TripleConstraint: #{inspect(invalid)}}"}
  end

  defp to_triple_expression(%{type: type} = triple_expression_combinator, options)
       when type in ~w[EachOf OneOf] do
    with type_mod = Module.concat([ShEx, type]),
         {:ok, id} <-
           triple_expression_combinator
           |> Map.get(:id)
           |> if_present(&to_triple_expression_label/2, options),
         {:ok, expressions} <-
           triple_expression_combinator
           |> Map.get(:expressions, [])
           |> map(&to_triple_expression/2, options),
         {:ok, min} <-
           triple_expression_combinator
           |> Map.get(:min)
           |> if_present(&to_integer/2, options),
         {:ok, max} <-
           triple_expression_combinator
           |> Map.get(:max)
           |> if_present(&to_integer/2, options),
         {:ok, sem_acts} <-
           triple_expression_combinator
           |> Map.get(:semActs, [])
           |> map(&to_semantic_action/2, options)
           |> empty_to_nil(),
         {:ok, annotations} <-
           triple_expression_combinator
           |> Map.get(:annotations, [])
           |> map(&to_annotation/2, options)
           |> empty_to_nil() do
      if length(expressions) >= 2 do
        {:ok,
         struct(type_mod,
           id: id,
           expressions: expressions,
           min: min,
           max: max,
           sem_acts: sem_acts,
           annotations: annotations
         )}
      else
        {:error, "Invalid #{type}: must have >= 2 shapeExprs, but has #{length(expressions)}}"}
      end
    end
  end

  defp to_triple_expression(triple_expr_ref, options) when is_binary(triple_expr_ref) do
    to_triple_expression_label(triple_expr_ref, options)
  end

  defp to_triple_expression(invalid, _) do
    {:error, "invalid triple expression: #{inspect(invalid)}}"}
  end

  defp to_import(iri, options) when is_binary(iri),
    do: to_iri(iri, options)

  defp to_import(invalid, _),
    do: {:error, "invalid import: #{inspect(invalid)}}"}

  defp to_semantic_action(%{type: "SemAct", name: name} = sem_act, options)
       when is_binary(name) do
    with {:ok, name_iri} <- to_iri(name, options) do
      {:ok,
       %ShEx.SemAct{
         name: name_iri,
         code: Map.get(sem_act, :code)
       }}
    end
  end

  defp to_semantic_action(%{type: "SemAct"} = invalid, _) do
    {:error, "invalid SemAct: #{inspect(invalid)}}"}
  end

  defp to_annotation(
         %{type: "Annotation", predicate: predicate, object: object} = annotation,
         options
       )
       when is_binary(predicate) do
    with {:ok, predicate_iri} <- to_iri(predicate, options),
         {:ok, object_value} <- to_object_value(object, options) do
      {:ok,
       %ShEx.Annotation{
         predicate: predicate_iri,
         object: object_value
       }}
    end
  end

  defp to_annotation(%{type: "Annotation"} = invalid, _) do
    {:error, "invalid Annotation: #{inspect(invalid)}"}
  end

  defp to_shape_expression_label("_:" <> bnode, options),
    do: {:ok, RDF.bnode(bnode)}

  defp to_shape_expression_label(iri, options) when is_binary(iri),
    do: to_iri(iri, options)

  defp to_shape_expression_label(invalid, _),
    do: {:error, "invalid shape expression label: #{inspect(invalid)}}"}

  defp to_triple_expression_label("_:" <> bnode, options),
    do: {:ok, RDF.bnode(bnode)}

  defp to_triple_expression_label(iri, options) when is_binary(iri),
    do: to_iri(iri, options)

  defp to_triple_expression_label(invalid, _),
    do: {:error, "invalid triple expression label: #{inspect(invalid)}}"}

  defp to_node_kind(node_kind, _) do
    if node_kind in ShEx.NodeConstraint.node_kinds() do
      {:ok, node_kind}
    else
      {:error, "invalid node kind: #{inspect(node_kind)}}"}
    end
  end

  defp to_value_set_value(iri, options) when is_binary(iri) do
    to_iri(iri, options)
  end

  defp to_value_set_value(%{value: _} = literal, options) do
    to_literal(literal, options)
  end

  defp to_value_set_value(%{type: "IriStem", stem: stem} = iri_stem, options) do
    with {:ok, iri} <- to_iri(stem, options) do
      {:ok, %{iri_stem | stem: iri}}
    end
  end

  defp to_value_set_value(
         %{type: "IriStemRange", stem: stem, exclusions: exclusions} = iri_stem_range,
         options
       ) do
    with {:ok, iri_or_wildcard} <-
           to_iri_or_wildcard(stem, options),
         {:ok, exclusion_values} <-
           map(exclusions, &to_value_set_value/2, options) do
      {:ok, %{iri_stem_range | stem: iri_or_wildcard, exclusions: exclusion_values}}
    end
  end

  defp to_value_set_value(%{type: "Language", languageTag: language_tag} = language, _) do
    {:ok, language}
  end

  defp to_value_set_value(%{type: type} = stem, _) when type in ~w[LanguageStem LiteralStem] do
    {:ok, stem}
  end

  defp to_value_set_value(%{exclusions: _} = stem_range, options) do
    {:ok, stem_range}
  end

  defp to_value_set_value(invalid, _) do
    {:error, "invalid value set value: #{inspect(invalid)}}"}
  end

  defp to_object_value(iri, options) when is_binary(iri),
    do: to_iri(iri, options)

  defp to_object_value(%{value: _} = literal, options),
    do: to_literal(literal, options)

  defp to_object_value(invalid, _),
    do: {:error, "invalid object value: #{inspect(invalid)}}"}

  defp to_iri_or_wildcard(%{type: "Wildcard"} = wildcard, _), do: {:ok, wildcard}
  defp to_iri_or_wildcard(iri, options), do: to_iri(iri, options)

  defp to_iri(iri, options) do
    if RDF.IRI.valid?(iri) do
      {:ok, RDF.iri(iri)}
    else
      # TODO: string must be resolved to IRI (via @context or IRIREF)
      {:ok, nil}
    end
  end

  defp to_literal(%{value: value, type: datatype}, _options),
    do: {:ok, RDF.literal(value, datatype: datatype)}

  defp to_literal(%{value: value, language: language}, _options),
    do: {:ok, RDF.literal(value, language: language)}

  defp to_literal(%{value: value}, _options),
    do: {:ok, RDF.literal(value)}

  defp to_literal(invalid, _),
    do: {:error, "invalid literal: #{inspect(invalid)}}"}

  defp to_integer(integer, _) when is_integer(integer),
    do: {:ok, integer}

  defp to_integer(invalid, _),
    do: {:error, "invalid integer: #{inspect(invalid)}}"}

  defp to_bool(bool, _) when is_boolean(bool),
    do: {:ok, bool}

  defp to_bool(invalid, _),
    do: {:error, "invalid boolean: #{inspect(invalid)}}"}

  defp parse_json(content, _opts \\ []) do
    Jason.decode(content, keys: :atoms!)
  rescue
    error in [ArgumentError] ->
      with [{:erlang, :binary_to_existing_atom, [bad_property, _], []} | _] <- __STACKTRACE__ do
        {:error, "invalid ShExJ property: #{bad_property}"}
      else
        _ ->
          reraise error, __STACKTRACE__
      end
  end

  defp parse_json!(content, _opts \\ []) do
    Jason.decode!(content)
  end

  @doc !"Some allowed keys which we don't want to cause to_existing_atom to fail"
  def allowed_keys_fix, do: ~w[@context valueExpr languageTag]a
end
