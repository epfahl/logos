WARNING: This is very much a work in progress! Expect missing, incomplete, or inconsistent code, tests, and documentation. 

# What is Logos?

**Logos: The Greek root (λόγοϚ) of the word _logic_.**

`Logos` is a relatively small Elixir-hosted _relational_ programming language adapted from 
miniKanren and microKanren. An attempt was made to create an interface that looks like idiomatic 
Elixir and feels approachable to someone who has no experience with relational programming 
beyond Elixir pattern matching. Many of the core concepts and implementation details were 
adopted directly from the book, _The Reasoned Schemer_, and the microKanren paper (see 
references below). However, many function names have been updated, either to be more 
descriptive and memorable, or due to Elixir conventions. Also, to enhance the user 
experience in Elixir, some of the relational primitives in `Logos` differ in structure from 
their counterparts in miniKanren.

This library grew out of a general interest in logic programming and its potential 
applications to software-based products. Because usage and extension of `Logos` are key 
design considerations, the library is broken into modules that reflect the different 
implementation concerns, including unification, a purely functional core reminiscent of 
microKanren, and a collection of macros that make up the main user interface. It is hoped 
that `Logos` can be applied, adapted, and grown with relative ease. Documentation for 
each of the modules, functions, and macros is extensive, and includes many usage examples, 
as well as notes on specific design choices and possible areas for future improvement 
(**WIP note: This is not yet true, but it will be!**).

## A sample of references that influenced this work

[The Reasoned Schemer](https://mitpress.mit.edu/9780262535519/the-reasoned-schemer/)

[microKanren: A Minimal Functional Core for Relational Programming](http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf)

[The Art of Prolog](https://mitpress.mit.edu/books/art-prolog-second-edition)

[Relational Programming in miniKanren: Techniques, Applications, and Implementations](https://scholarworks.iu.edu/dspace/bitstream/handle/2022/8777/Byrd_indiana_0093A_10344.pdf)

[Clojure's core.logic](https://github.com/clojure/core.logic)

[Build your own Logic Engine](https://youtu.be/y1bVJOAfhKY)

[ExKanren](https://github.com/lyons/ExKanren)

[Hello, declarative world](https://tomstu.art/hello-declarative-world)

# Quick start

To get started with Logos right away, type `use Logos` at the head of a module or in a 
Livebook session.

```elixir
use Logos
```

In the calling module, this expands to

```elixir
import Logos.Core, only: [all: 1, any: 1, equal: 2, failure: 0, success: 0]
import Logos.Interface, only: [ask: 2, fork: 1, with_vars: 2]
import Logos.Rule
```

This brings in a set of common logical rules as well as the macros `ask`, `with_vars`, and 
`fork`. Now that the basic functionality is accessible, let's see `Logos` in action with 
several small examples.

# Ask a question

To get acclimated to the usage of `Logos`, start with a simple algebra question: _What is 
the value of the variable `x` when `x` is equal to 1?_ This isn't a trick; the answer, 
`x = 1`, is in the phrasing of the question. In `Logos`, this question is expressed as

```elixir
ask [x] do
  equal(x, 1)
end

#Stream<[
  enum: #Function<51.58486609/2 in Stream.resource/3>,
  funs: [#Function<47.58486609/1 in Stream.map/2>]
]>
```

In words, this code could be read as, "Ask for the value of `x` when `x` equals 1." The 
macro `ask` takes a list of variables as its argument, a logical _goal_ as a body, and 
returns an Elixir `Stream`. Each item in the stream is a list of values of the variables 
passed to `ask` (`x` in the above example). To get a list of results, pipe the stream 
into `Enum.to_list`:

```elixir
ask [x] do
  equal(x, 1)
end
|> Enum.to_list()

[[1]]
```

When `Logos` evaluates a query, an attempt is made to satisfy the goal. However, it may 
be that the goal expresses a false relationship, as shown here:

```elixir
ask [x] do
  equal(1, 2)
end
|> Enum.to_list()

[]
```

The result is an empty stream, meaning that there is no state for which the goal is true.

Several specialized words are used above and in what follows, and it's important to have 
some early appreciation of their meanings. A _rule_ expresses a logical relationship 
among _terms_. A _term_ can be a variable, a constant (number, string, or atom), or a 
list of terms (yep, a term is defined recursively). The equivalence _rule_ is expressed 
as `equal(x, y)`, where `x`and `y` are any two _terms_. When `x` is a variable and `y` 
is set to the constant 1, `equal(x, 1)` is a logical _goal_ asserting that the variable 
`x` is equal to 1. When a goal is wrapped with `ask`, that goal is posed as a 
_query_ for which we'd like an answer.

To show that `equal` works for list terms, find `x` and `y` in the following query:

```elixir
ask [x, y] do
  equal([x, 2, 3], [1, 2, y])
end
|> Enum.to_list()

[[1, 3]]
```

Because the algorithm that performs this matching is recursive, list terms with any 
depth can be used:

```elixir
ask [x, y] do
  equal(
    [1, [2, [x, y]]],
    [1, [2, [3, [4, 5]]]]
  )
end
|> Enum.to_list()

[[3, [4, 5]]]
```

Here the value of `x` is 3, and `y` is the list `[4, 5]`.

# A stream of answers

Just like in algebra, a query in `Logos` can have more than one answer--possibly an 
_infinite_ number. This is why `ask` returns a stream. An open-ended question shows the 
need for a stream: _What are the lists for which the value `:item` is a member?_ The 
builtin `Logos` rule `member(item, list)` can be used to ask this question:

```elixir
ask [l] do
  member(:item, l)
end
|> Enum.take(20)

[
  [[:item]],
  [[:item, :_0]],
  [[:item, :_0, :_1]],
  [[:_0, :item]],
  [[:item, :_0, :_1, :_2]],
  [[:item, :_0, :_1, :_2, :_3]],
  [[:_0, :item, :_1]],
  [[:item, :_0, :_1, :_2, :_3, :_4]],
  [[:item, :_0, :_1, :_2, :_3, :_4, :_5]],
  [[:_0, :item, :_1, :_2]]
]
```

Intuitively, it's apparent that there is an infinite collection of lists that satisfy 
this query--lists of all possible lengths where `:item` is in any available position. The 
result above shows 10 such lists from the infinite stream. Other values in the lists of 
the form `:_<integer>` are variable slots that are not constrained by the query and can 
hold any value.

# Blending and sugaring rules

More interesting programs can be built by combining simple rules. The two mechanisms used 
to combine rules are _disjunction_ ("or" logic) and _conjunction_ ("and" logic). In 
`Logos`, the two corresponding rules are `any` and `all`, both of which take a list of 
zero or more goals as arguments.

This question illustrates the use of conjunctive logic: _If `x` equals `y` and `y` 
equals 1, what is the value of `x`?_ The following query asks this question in `Logos` and 
introduces `with_vars`, a macro that injects new variables into a goal:

```elixir
ask [x] do
  with_vars [y] do
    all([
      equal(x, y),
      equal(y, 1)
    ])
  end
end
|> Enum.to_list()

[[1]]
```

`Logos` allows implicit conjunctions in `ask`, where a list of goals `[g1, g2, ...]` 
is interpreted as `all([g1, g2, ...])`, so that the above query can be simplified to

```elixir
ask [x] do
  with_vars [y] do
    [
      equal(x, y),
      equal(y, 1)
    ]
  end
end
|> Enum.to_list()

[[1]]
```

Another simple question and corresponding `Logos` query demonstrate the use of `any`: 
_If `x` can equal "a" or "b" or "c", what are the values of `x`?_

```elixir
ask [x] do
  any([
    equal(x, "a"),
    equal(x, "b"),
    equal(x, "c")
  ])
end
|> Enum.to_list()

[["a"], ["b"], ["c"]]
```

As expected, the result has 3 possible solution states. Notice that `any([...])` in the 
above query could be replaced with `member(x, ["a", "b", "c"])`.

The primitive rules `any` and `all` can be combined to exhibit more interesting 
behaviors:

```elixir
ask [x, y] do
  any([
    all([equal(x, "a"), equal(y, 1)]),
    all([equal(x, "b"), equal(y, 2)]),
    all([equal(x, "c"), equal(y, 3)])
  ])
end
|> Enum.to_list()

[["a", 1], ["b", 2], ["c", 3]]
```

Queries like this--a disjunction of conjunctions--are common in logic programming. 
`Logos` offers the macro `fork` to reduce the syntactic load of these expressions:

```elixir
ask [x, y] do
  fork do
    [equal(x, "a"), equal(y, 1)]
    [equal(x, "b"), equal(y, 2)]
    [equal(x, "c"), equal(y, 3)]
  end
end
|> Enum.to_list()

[["a", 1], ["b", 2], ["c", 3]]
```

`Logos` goes one step further with syntactic sugar by making the `fork` syntax available 
in both `ask` and `with_vars`. The above query can be written more simply as

```elixir
ask [x, y] do
  [equal(x, "a"), equal(y, 1)]
  [equal(x, "b"), equal(y, 2)]
  [equal(x, "c"), equal(y, 3)]
end
|> Enum.to_list()

[["a", 1], ["b", 2], ["c", 3]]
```

When a conjunction clause has only one item, the list may be omitted:

```elixir
ask [x] do
  equal(x, 1)

  with_vars [y] do
    [equal(x, y), equal(y, 2)]
  end
end
|> Enum.to_list()

[[1], [2]]
```

# Where to go from here?

The `/notebooks` directory has a number of Livebooks that go deeper into the 
implementation of specific rules and applications of Logos.
