# Hyperex

A macro-powered HTML renderer for Elixir.

```elixir
require Hyperex
import Hyperex

defp user_link(%{user: user}) do
  hyperex(
    a class: "user-link", href: "/user/#{user.id}" do
      ^user.name
    end
  )
end

hyperex(
  body do
    -user_link user: %{name: "foo", id: 123}
  end
)
|> render()
# → <body><a class="user-link" href="/user/123">foo</a></body>
```

See `example.exs`.

## Installation

Add `hyperex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hyperex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hyperex](https://hexdocs.pm/hyperex).

## License

   Copyright 2018 Antoine Motet

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
