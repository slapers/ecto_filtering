defmodule EctoFiltering.Parser do
  @moduledoc false

  import NimbleParsec
  import EctoFiltering.ParserUtils

  # Value expressions

  # <vexpr_bool> ::= "true" | "false"
  # <vexpr_num>  ::= <int> | <float>
  # <vexpr_null> ::= "null"
  # <int>        ::= ["-"]<digit>{<digit>}
  # <float>      ::= ["-"]<digit>{<digit>}"."<digit>{<digit>}
  # <vexpr_str>  ::= """ any-utf8-except-escaped-doublequote """
  # <vexpr_var>  ::= <lc_letter> {<lc_letter> | <digit> | "_"} ["?"]
  # <digit>      ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
  # <lc_letter>  ::= "a".."z"

  @reserved_sym ["true", "false", "null", "and", "or", "not"]

  true_ = symbol("true", true)
  false_ = symbol("false", false)
  vexpr_bool = [true_, false_] |> choice() |> label("boolean")

  vexpr_null = symbol("null", nil) |> label("null")

  digits = [?0..?9] |> ascii_string(min: 1) |> label("digits")

  int =
    optional(string("-"))
    |> concat(digits)
    |> reduce(:to_integer)
    |> label("integer")

  defp to_integer(acc), do: acc |> Enum.join() |> String.to_integer(10)

  float =
    optional(string("-"))
    |> concat(digits)
    |> ascii_string([?.], 1)
    |> concat(digits)
    |> reduce(:to_float)
    |> label("float")

  defp to_float(acc), do: acc |> Enum.join() |> String.to_float()

  vexpr_num = [float, int] |> choice() |> label("number")

  double_quotes = ascii_char([?"]) |> label("double quotes")

  vexpr_str =
    empty()
    |> ignore(double_quotes)
    |> repeat(
      empty()
      |> lookahead_not(double_quotes)
      |> choice([
        ~S(\") |> string() |> replace(?"),
        utf8_char([])
      ])
    )
    |> ignore(double_quotes)
    |> reduce({List, :to_string, []})
    |> label("literal string")

  var_label =
    ascii_char([?a..?z])
    |> repeat(ascii_char([?a..?z, ?0..?9, ?_]))
    |> optional(ascii_char([??]))
    |> post_traverse(:to_var_label)
    |> label("label")

  defp to_var_label(_rest, acc, context, _line, _offset) do
    name = acc |> Enum.reverse() |> List.to_string()

    if name in @reserved_sym do
      {:error, name <> " is a reserved symbol"}
    else
      {[name], context}
    end
  end

  vexpr_var =
    var_label
    |> repeat(
      empty()
      |> ignore(ascii_char([?.]))
      |> concat(var_label)
    )
    |> tag(:var)
    |> label("var")

  defparsec(
    :vexpr,
    [vexpr_bool, vexpr_num, vexpr_str, vexpr_null, vexpr_var]
    |> choice()
  )

  # Arithmetic expressions
  #
  # In order to follow operator precedence in math we should have the
  # parser work according to the following EBNF:
  #
  # <aexpr>  ::= <term> {+ | - <term>}
  # <term>   ::= <factor> {* | / <factor>}
  # <factor> ::= ( <aexpr> ) | <const>
  # <const>  ::= <vexpr_num> | <vexpr_var>

  plus = ascii_char([?+]) |> replace(:+) |> label("+")
  minus = ascii_char([?-]) |> replace(:-) |> label("-")
  times = ascii_char([?*]) |> replace(:*) |> label("*")
  divide = ascii_char([?/]) |> replace(:/) |> label("/")
  lparen = ascii_char([?(]) |> label("(")
  rparen = ascii_char([?)]) |> label(")")

  defcombinatorp(
    :aexpr_factor,
    [
      ignore(lparen) |> parsec(:aexpr) |> ignore(rparen),
      vexpr_num,
      vexpr_var
    ]
    |> choice()
    |> ignore_surrounding_whitespace()
  )

  defparsecp(
    :aexpr_term,
    parsec(:aexpr_factor)
    |> repeat([times, divide] |> choice() |> parsec(:aexpr_factor))
    |> reduce(:fold_infixl)
  )

  defparsec(
    :aexpr,
    parsec(:aexpr_term)
    |> repeat([plus, minus] |> choice() |> parsec(:aexpr_term))
    |> reduce(:fold_infixl)
  )

  #
  # Comparison expressions
  #
  # <cexpr>     ::= <factor> <eq_op> <factor> | <term>
  # <term>      ::= (<cexpr>) | <cexpr_ord>
  # <factor>    ::= (<bexpr>) | <term> | <aexpr> | <vexpr>
  # <cexpr_ord> ::= <aexpr> <ord_op> <aexpr>
  # <ord_op>    ::= > | >= | < | <=
  # <eq_op>     ::= != | ==

  # <ord_op>    ::= > | >= | < | <=
  ord_op =
    [
      string(">=") |> replace(:>=),
      string("<=") |> replace(:<=),
      string(">") |> replace(:>),
      string("<") |> replace(:<)
    ]
    |> choice()
    |> label("order operator")

  # <eq_op>     ::= != | ==
  eq_op =
    [
      string("==") |> replace(:==),
      string("!=") |> replace(:!=)
    ]
    |> choice()
    |> label("equality operator")

  # <aexpr> <ord_op> <aexpr>
  defcombinatorp(
    :cexpr_ord,
    parsec(:aexpr)
    |> concat(ord_op)
    |> parsec(:aexpr)
    |> reduce(:fold_infixl)
  )

  # (<bexpr>) | <term> | <aexpr> | <vexpr>
  defcombinatorp(
    :cexpr_factor,
    [
      ignore(lparen) |> parsec(:bexpr) |> ignore(rparen),
      parsec(:cexpr_term),
      parsec(:aexpr),
      parsec(:vexpr)
    ]
    |> choice()
    |> ignore_surrounding_whitespace()
  )

  # (<cexpr>) | <cexpr_ord>
  defcombinatorp(
    :cexpr_term,
    [
      ignore(lparen) |> parsec(:cexpr) |> ignore(rparen),
      parsec(:cexpr_ord)
    ]
    |> choice()
    |> ignore_surrounding_whitespace()
  )

  # <factor> <eq_op> <factor> | <term>
  defparsec(
    :cexpr,
    choice([
      parsec(:cexpr_factor) |> concat(eq_op) |> parsec(:cexpr_factor) |> reduce(:fold_infixl),
      parsec(:cexpr_term)
    ])
  )

  # Boolean logic expressions
  #
  # Priority order (high to low):  NOT, AND, OR
  # expressions in parens are evaluated first
  #
  # <bexpr>  ::= <term> {<or> <term>}
  # <term>   ::= <factor> {<and> <factor>}
  # <factor> ::= <not> <factor> | ( <bexpr> ) | <cexpr> | <vexpr_bool>
  # <or>     ::= '||' | 'or'
  # <and>    ::= '&&' | 'and'
  # <not>    ::= '!' | 'not'

  or_ =
    [
      string("||"),
      symbol("or")
    ]
    |> choice()
    |> replace(:||)

  not_ =
    [
      string("!"),
      symbol("not")
    ]
    |> choice()
    |> replace(:!)

  and_ =
    [
      string("&&"),
      symbol("and")
    ]
    |> choice()
    |> replace(:&&)

  defparsecp(
    :bexpr_factor,
    choice([
      ignore(not_) |> parsec(:bexpr_factor) |> tag(:!),
      ignore(lparen) |> parsec(:bexpr) |> ignore(rparen),
      parsec(:cexpr),
      vexpr_bool
    ])
    |> ignore_surrounding_whitespace()
    |> label("logic factor")
  )

  defparsecp(
    :bexpr_term,
    parsec(:bexpr_factor)
    |> repeat(and_ |> parsec(:bexpr_factor))
    |> reduce(:fold_infixl)
    |> label("logic term")
  )

  defparsec(
    :bexpr,
    parsec(:bexpr_term)
    |> repeat(or_ |> parsec(:bexpr_term))
    |> reduce(:fold_infixl)
    |> label("boolean logic expression")
  )
end
