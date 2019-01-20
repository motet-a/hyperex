defmodule HyperexTest do
  use ExUnit.Case
  doctest Hyperex
  require Hyperex
  import Hyperex

  test "preprocess" do
  end

  defp rts(e) do
    e
    |> render()
    |> to_string()
    # Deduplicate spaces
    |> String.replace(~r/ +/, " ")
  end

  test "renders void elements properly" do
    assert "<br />" === rts({"br", %{children: :void}})
    assert "<br />" === rts({"br", %{children: nil}})
    assert "<br >foo</br>" === rts({"br", %{children: "foo"}})
    assert "<br >123</br>" === rts({"br", %{children: 123}})
    assert "<div />" === rts({"div", %{children: :void}})
    assert "<div ></div>" === rts({"div", %{children: nil}})
  end

  test "renders children" do
    assert "<div ><br /></div>" === rts({"div", %{children: {"br", %{children: nil}}}})
    assert "<div ><br /></div>" === rts({"div", %{children: [{"br", %{children: nil}}]}})

    assert "<div ><br />hello123</div>" ===
             rts({"div", %{children: [{"br", %{children: nil}}, "hello", 123]}})
  end

  test "renders dangerously unescaped HTML" do
    assert "foo<hey&baz;" === rts({:dangerously_unescaped, "foo<", "hey", "&baz;"})
  end

  test "escapes HTML everywhere" do
    assert "ahe&lt;y&amp;b" === rts({:dangerously_unescaped, "a", "he<y&", "b"})
    assert "he&lt;y&amp;" === rts("he<y&")
    assert "he&lt;y&amp;" === rts(["he<y&"])
    assert ~s{<a href="he&lt;y&amp;"></a>} === rts({"a", %{href: "he<y&", children: nil}})
    assert ~s{<a he&lt;y&amp;="a"></a>} === rts({"a", %{"he<y&" => "a", children: nil}})
    assert ~s{<a >he&lt;y&amp;</a>} === rts({"a", %{children: "he<y&"}})
  end

  test "renders nil as an empty string" do
    assert "" === rts(nil)
  end

  test "renders valueless properties" do
    assert ~s{<script defer></script>} === rts({"script", %{defer: true, children: nil}})
    assert ~s{<script ></script>} === rts({"script", %{defer: false, children: nil}})
    assert ~s{<script ></script>} === rts({"script", %{defer: nil, children: nil}})
  end

  defp user_link(%{user: user, children: children}) do
    h :a, href: "/user/#{user.id}" do
      children || user.name
    end
  end

  test "`h` macro" do
    assert "123" === rts(123)
    assert "123.45" === rts(123.45)
    assert "" === rts(nil)
    assert "hey" === rts("hey")

    assert ~s{<a href="example.com">foo</a>} ===
             rts(
               h :a, href: "example.com" do
                 "foo"
               end
             )

    assert ~s{<a ></a>} === rts(h(:a))
    assert ~s{<custom-tag ></custom-tag>} === rts(h("custom-tag"))
    assert ~s{<a >abc</a>} === rts(h(:a, do: "abc"))
    assert ~s{<a href="b">abc</a>} === rts(h(:a, href: "b", do: "abc"))
    assert ~s{<a ><strong >b</strong></a>} === rts(h(:a, do: h(:strong, do: "b")))
    assert ~s{<a >bc</a>} === rts(h(:a, do: "b" <> "c"))
    assert ~s{<a >bc</a>} === rts(h(:a, children: "b" <> "c"))

    assert ~s{<a >c</a>} ===
             rts(
               h :a, children: "b" do
                 "c"
               end
             )

    assert ~s{<a >c</a>} ===
             rts(
               h :a, children: nil do
                 "c"
               end
             )

    assert ~s{<a ></a>} ===
             rts(
               h :a, children: "c" do
                 nil
               end
             )

    assert ~s{<a >c</a>} ===
             rts(
               h :a, children: :void do
                 "c"
               end
             )

    assert ~s{<a />} ===
             rts(
               h :a, children: "c" do
                 :void
               end
             )

    assert ~s{<hr title="b"/>} === rts(h(:hr, title: "a", title: "b"))
    assert ~s{<hr title="b"/>} === rts(h(:hr, %{title: "a"}, title: "b"))
    assert ~s{<hr title="b"/>} === rts(h(:hr, [title: "a"], %{title: "b"}))

    assert ~s{<a href="b" title="a">abc</a>} === rts(h(:a, title: "a", href: "b", do: "abc"))

    assert ~s{<a href="abc">abc</a>} ===
             rts(
               h :a, href: "abc" do
                 "abc"
               end
             )

    assert ~s{<a href="abc"></a>} === rts(h(:a, href: "ab" <> "c"))

    assert ~s{<a href="5">9</a>} === rts(h(:a, href: 2 + 3, do: 4 + 5))

    assert(
      ~s{<a href="5">9</a>} ===
        rts(
          h :a, href: 2 + 3 do
            4 + 5
          end
        )
    )

    assert ~s{<br class="a"/>} === rts(h(:br, class: "a"))

    assert(
      "<p >a</p><p >12</p>" ===
        rts(
          h do
            h(:p, "a")
            h(:p, 12)
          end
        )
    )

    user = %{id: 12, name: "foo"}

    assert ~s{<article ><a href="/user/12">foo</a>123<a href="/user/12">Foo Bar</a></article>} ===
             rts(
               h "article" do
                 h(user_link, user: user)
                 123

                 h user_link, user: user do
                   "Foo Bar"
                 end
               end
             )

    assert ~s{<custom_element />} === rts(h("custom_element", :void))

    assert ~s{<custom_element />} ===
             rts(
               h "custom_element" do
                 :void
               end
             )

    assert ~s{<custom_element ></custom_element>} === rts(h("custom_element"))

    assert ~s{<a href="b"></a>} === rts(h :a, %{href: "b", children: nil})
    assert ~s{<a href="b"></a>} === rts(h :a, href: "b", children: nil)
    props = %{href: "b", children: "d"}
    assert ~s{<a href="b">d</a>} === rts(h :a, props)

    assert ~s{<a href="b">c</a>} ===
             rts(
               h :a, props do
                 "c"
               end
             )

    assert ~s{<!DOCTYPE html>3} === rts(h Hyperex.html5_doctype do 3 end)

    # For the sake of code coverage…
    assert ~s{<div ></div>} === rts(h :div, %{}, %{}, %{})
    assert ~s{<div ></div>} === rts(h :div, %{}, %{}, %{}, %{})
    assert ~s{<div ></div>} === rts(h :div, %{}, %{}, %{}, %{}, %{})
    assert ~s{<div ></div>} === rts(h :div, %{}, %{}, %{}, %{}, %{}, %{})
    assert ~s{<div ></div>} === rts(h :div, %{}, %{}, %{}, %{}, %{}, %{}, %{})
  end
end
