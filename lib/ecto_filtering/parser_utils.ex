defmodule EctoFiltering.ParserUtils do
  @moduledoc false
  import NimbleParsec

  def whitespace(), do: ascii_char([?\s, ?\t, ?\r, ?\n]) |> times(min: 1)

  def symbol(label) do
    label
    |> string()
    |> lookahead_not(utf8_char([?a..?z, ?A..?Z, ?0..?9, ?_, ??]))
  end

  def symbol(label, replacement) do
    label
    |> symbol()
    |> replace(replacement)
  end

  def ignore_surrounding_whitespace(parser) do
    ignore(optional(whitespace()))
    |> concat(parser)
    |> ignore(optional(whitespace()))
  end

  def fold_infixl(acc) do
    acc
    |> Enum.reverse()
    |> Enum.chunk_every(2)
    |> List.foldr([], fn
      [l], [] -> l
      [r, op], l -> {op, [l, r]}
    end)
  end
end
