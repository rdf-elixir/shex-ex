defmodule ShEx.ShExC.ParseHelper do
  @moduledoc false

  import RDF.Serialization.ParseHelper

  def code_str(value),
    do: value |> to_str() |> String.slice(1..-3)

  def repeat_range(value) do
    content = value |> to_str() |> String.slice(1..-2)

    case content |> String.split(",") |> Enum.map(&range_member/1) do
      [lower, upper] -> {lower, upper}
      [number] -> number
    end
  end

  defp range_member(""), do: -1
  defp range_member("*"), do: -1
  defp range_member(value), do: String.to_integer(value)

  def to_str(value), do: List.to_string(value)

  def lang_quoted_content_str('"' ++ value),
    do: value |> to_str() |> split_lang_from_string(~s["])

  def lang_quoted_content_str('\'' ++ value),
    do: value |> to_str() |> split_lang_from_string("'")

  def lang_long_quoted_content_str('"""' ++ value),
    do: value |> to_str() |> split_lang_from_string(~s["""])

  def lang_long_quoted_content_str('\'\'\'' ++ value),
    do: value |> to_str() |> split_lang_from_string("'''")

  defp split_lang_from_string(str, quotes),
    do: str |> String.split(quotes <> "@") |> List.to_tuple()

  def to_lang_literal({:lang_string_literal_quote, _line, {value, language}}),
    do: value |> string_unescape |> RDF.literal(language: language)
end
