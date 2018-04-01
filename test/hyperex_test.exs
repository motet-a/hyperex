defmodule HyperexTest do
  use ExUnit.Case
  doctest Hyperex
  require Hyperex
  import Hyperex

  test "preprocess" do
  end

  defp rts(e), do: to_string(render(e))

  defmacrop hts(do: block) do
    quote do
      rts(hyperex(unquote(block)))
    end
  end

  defmacrop hts(ast) do
    quote do
      rts(hyperex(unquote(ast)))
    end
  end

  test "renders void elements properly" do
    assert "<br />" === rts({:br, %{}})
    assert "<br />" === rts({:br, %{children: :void}})
    assert "<br />" === rts({:br, %{children: nil}})
    assert "<div ></div>" === rts({:div, %{}})
    assert "<br >123</br>" === rts({:br, %{children: 123}})
    assert "<div />" === rts({:div, %{children: :void}})
    assert "<div ></div>" === rts({:div, %{children: nil}})
  end

  test "renders children" do
    assert "<div ><br /></div>" === rts({:div, %{children: {:br, %{}}}})
    assert "<div ><br /></div>" === rts({:div, %{children: [{:br, %{}}]}})
    assert "<div ><br />hello123</div>" === rts({:div, %{children: [{:br, %{}}, "hello", 123]}})
  end

  test "renders dangerously unescaped HTML" do
    assert "foo<hey&baz;" === rts({:dangerously_unescaped, "foo<", "hey", "&baz;"})
  end

  test "escapes HTML everywhere" do
    assert "ahe&lt;y&amp;b" === rts({:dangerously_unescaped, "a", "he<y&", "b"})
    assert "he&lt;y&amp;" === rts("he<y&")
    assert "he&lt;y&amp;" === rts(["he<y&"])
    assert ~s{<a href="he&lt;y&amp;" ></a>} === rts({:a, %{href: "he<y&"}})
    assert ~s{<a he&lt;y&amp;="a" ></a>} === rts({:a, %{"he<y&" => "a"}})
    assert ~s{<a >he&lt;y&amp;</a>} === rts({:a, %{children: "he<y&"}})
  end

  test "renders nil as an empty string" do
    assert "" === rts(nil)
  end

  test "renders valueless properties" do
    assert ~s{<script defer ></script>} === rts({:script, %{defer: true}})
    assert ~s{<script  ></script>} === rts({:script, %{defer: false}})
    assert ~s{<script  ></script>} === rts({:script, %{defer: nil}})
  end

  defp user_link(%{user: user, children: children}) do
    hyperex(
      a href: "/user/#{user.id}" do
        ^(children || user.name)
      end
    )
  end

  defp void_custom_element(_) do
    hyperex(custom_element(:void))
  end

  defp element_without_parameters(_) do
    hyperex(div("hello"))
  end

  test "hyperex macro" do
    assert "123" === hts(123)
    assert "123.45" === hts(123.45)
    assert "127" === hts(^(123 + 4))
    assert "" === hts(nil)
    assert "" === hts(^nil)
    assert "abc" === hts(^("ab" <> "c"))
    assert "abc" === hts(^"ab#{'c'}")

    assert ~s{<a href="example.com" >foo</a>} ===
             hts(
               a href: "example.com" do
                 "foo"
               end
             )

    assert ~s{<a ></a>} === hts(a())
    assert ~s{<a >abc</a>} === hts(a(do: "abc"))
    assert ~s{<a href="b" title="a" >abc</a>} === hts(a(title: "a", href: "b", do: "abc"))

    assert ~s{<a href="abc" >abc</a>} ===
             hts(
               a href: "abc" do
                 "abc"
               end
             )

    assert ~s{<a href="abc" ></a>} === hts(a(href: "ab" <> "c"))

    assert ~s{<a href="5" >9</a>} === hts(a(href: 2 + 3, do: ^(4 + 5)))

    assert ~s{<a href="5" >9</a>} ===
             hts(
               a href: 2 + 3 do
                 ^(4 + 5)
               end
             )

    assert ~s{<br class="a" />} === hts(br(class: "a"))

    assert "<p >a</p><p >12</p>" ===
             (hts do
                p("a")
                p(12)
              end)

    user = %{id: 12, name: "foo"}

    assert ~s{<article ><a href="/user/12" >foo</a><a href="/user/12" >Foo Bar</a></article>} ===
             hts(
               article do
                 -user_link(user: user)

                 -user_link user: user do
                   "Foo Bar"
                 end
               end
             )

    assert ~s{<custom_element />} === hts(-void_custom_element())
    assert ~s{<div ><div >hello</div></div>} === hts(div do
      -element_without_parameters
    end)
  end

  test "hyperex macro raises with invalid user-defined elements" do
    assert_raise RuntimeError, ~s{Invalid user-defined call: ["invalid"]}, fn ->
      Code.eval_quoted(
        quote do
          hyperex(-"invalid")
        end
      )
    end
  end
end
